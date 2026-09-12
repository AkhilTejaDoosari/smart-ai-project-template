#!/usr/bin/env bash
# Durable AUTO executor ledger. Used only when TODO selects a real AUTO executor.
# Policy-only AUTO (`AUTO executor: NONE`) does not use this ledger.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
STATE_DIR="$ROOT_DIR/.framework/auto"
mkdir -p "$STATE_DIR"

LOCK_DIR=""
LOCK_HELD=0
fail(){ printf 'FAIL: %s\n' "$*" >&2; exit 1; }
state_file(){ printf '%s/phase-%s.state\n' "$STATE_DIR" "$1"; }
readv(){ awk -F= -v k="$2" '$1==k{print substr($0,length(k)+2);exit}' "$1"; }
write_state(){
  file="$1"; shift
  tmp="$(mktemp "${file}.tmp.XXXXXX")"
  printf '%s\n' "$@" > "$tmp"
  mv -f "$tmp" "$file"
}
release_lock(){
  if [[ "$LOCK_HELD" -eq 1 ]]; then
    rm -f "$LOCK_DIR/pid" 2>/dev/null || true
    rmdir "$LOCK_DIR" 2>/dev/null || true
    LOCK_HELD=0
  fi
}
trap release_lock EXIT HUP INT TERM
acquire_lock(){
  phase="$1"
  LOCK_DIR="$STATE_DIR/.phase-$phase.state.lock"
  if ! mkdir "$LOCK_DIR" 2>/dev/null; then
    fail "AUTO state lock exists for Phase $phase at $LOCK_DIR; another mutation may be running. Remove it only after confirming it is stale."
  fi
  LOCK_HELD=1
  printf '%s\n' "$$" > "$LOCK_DIR/pid"
}
validate_phase(){ [[ "$1" =~ ^[1-9][0-9]*$ ]] || fail "phase must be a positive integer"; }

cmd="${1:-}"; shift || true
case "$cmd" in
  init)
    [[ $# -eq 3 ]] || fail "usage: auto-state.sh init <phase> <executor> <budget>"
    phase="$1"; executor="$2"; budget="$3"
    validate_phase "$phase"
    [[ "$executor" =~ ^[A-Za-z0-9._-]+$ ]] || fail "executor name must use letters, numbers, dot, underscore, or hyphen"
    [[ "$budget" =~ ^[1-9][0-9]*$ ]] || fail "budget must be a positive integer"
    acquire_lock "$phase"
    file="$(state_file "$phase")"
    [[ ! -e "$file" ]] || fail "AUTO state already exists for Phase $phase; do not reset durable iteration accounting"
    write_state "$file" \
      "phase=$phase" "executor=$executor" "budget=$budget" "iterations_consumed=0" \
      "last_result=NONE" "last_failure_fingerprint=NONE" "consecutive_same_failure_count=0" \
      "status=ACTIVE" "stop_reason=NONE" "last_reason=INITIALIZED"
    echo "PASS: initialized Phase $phase AUTO executor ledger (0/$budget)."
    ;;
  consume)
    [[ $# -ge 4 ]] || fail "usage: auto-state.sh consume <phase> <PASS|FAIL> <fingerprint> <reason...>"
    phase="$1"; result="$2"; fingerprint="$3"; shift 3; reason="$*"
    validate_phase "$phase"
    [[ "$result" == "PASS" || "$result" == "FAIL" ]] || fail "result must be PASS or FAIL"
    [[ -n "$fingerprint" ]] || fail "fingerprint must be non-empty"
    acquire_lock "$phase"
    file="$(state_file "$phase")"; [[ -f "$file" ]] || fail "missing AUTO state for Phase $phase"
    status="$(readv "$file" status)"; [[ "$status" == "ACTIVE" ]] || fail "AUTO executor is not ACTIVE (status=$status)"
    budget="$(readv "$file" budget)"; used="$(readv "$file" iterations_consumed)"; executor="$(readv "$file" executor)"
    last_fp="$(readv "$file" last_failure_fingerprint)"; same="$(readv "$file" consecutive_same_failure_count)"
    [[ "$used" =~ ^[0-9]+$ && "$budget" =~ ^[1-9][0-9]*$ ]] || fail "AUTO state is malformed"
    (( used < budget )) || fail "AUTO iteration budget already exhausted ($used/$budget)"
    used=$((used+1))
    if [[ "$result" == "FAIL" ]]; then
      if [[ "$fingerprint" == "$last_fp" ]]; then same=$((same+1)); else same=1; fi
      last_fp="$fingerprint"
    else
      same=0; last_fp="NONE"
    fi
    new_status="ACTIVE"; stop_reason="NONE"
    if [[ "$result" == "FAIL" && "$same" -ge 3 ]]; then new_status="STOPPED"; stop_reason="REPEATED_IDENTICAL_FAILURE"; fi
    if [[ "$used" -ge "$budget" && "$new_status" == "ACTIVE" ]]; then new_status="STOPPED"; stop_reason="BUDGET_EXHAUSTED"; fi
    write_state "$file" \
      "phase=$phase" "executor=$executor" "budget=$budget" "iterations_consumed=$used" \
      "last_result=$result" "last_failure_fingerprint=$last_fp" "consecutive_same_failure_count=$same" \
      "status=$new_status" "stop_reason=$stop_reason" "last_reason=$reason"
    echo "PASS: recorded AUTO iteration $used/$budget for Phase $phase ($result)."
    [[ "$new_status" == "ACTIVE" ]] || echo "STOP: $stop_reason"
    ;;
  stop)
    [[ $# -ge 2 ]] || fail "usage: auto-state.sh stop <phase> <reason...>"
    phase="$1"; shift; reason="$*"
    validate_phase "$phase"
    acquire_lock "$phase"
    file="$(state_file "$phase")"; [[ -f "$file" ]] || fail "missing AUTO state for Phase $phase"
    status="$(readv "$file" status)"; [[ "$status" == "ACTIVE" ]] || fail "AUTO executor is not ACTIVE (status=$status)"
    executor="$(readv "$file" executor)"; budget="$(readv "$file" budget)"; used="$(readv "$file" iterations_consumed)"
    lr="$(readv "$file" last_result)"; fp="$(readv "$file" last_failure_fingerprint)"; same="$(readv "$file" consecutive_same_failure_count)"
    write_state "$file" "phase=$phase" "executor=$executor" "budget=$budget" "iterations_consumed=$used" \
      "last_result=$lr" "last_failure_fingerprint=$fp" "consecutive_same_failure_count=$same" \
      "status=STOPPED" "stop_reason=$reason" "last_reason=$reason"
    echo "PASS: stopped Phase $phase AUTO executor ($used/$budget): $reason"
    ;;
  resume)
    [[ $# -ge 2 ]] || fail "usage: auto-state.sh resume <phase> <reason...>"
    phase="$1"; shift; reason="$*"
    validate_phase "$phase"
    acquire_lock "$phase"
    file="$(state_file "$phase")"; [[ -f "$file" ]] || fail "missing AUTO state for Phase $phase"
    status="$(readv "$file" status)"; [[ "$status" == "STOPPED" ]] || fail "AUTO executor must be STOPPED before human-authorized resume (status=$status)"
    executor="$(readv "$file" executor)"; budget="$(readv "$file" budget)"; used="$(readv "$file" iterations_consumed)"; lr="$(readv "$file" last_result)"
    [[ "$used" =~ ^[0-9]+$ && "$budget" =~ ^[1-9][0-9]*$ ]] || fail "AUTO state is malformed"
    (( used < budget )) || fail "cannot resume Phase $phase: budget exhausted ($used/$budget); replan and rebudget first"
    write_state "$file" "phase=$phase" "executor=$executor" "budget=$budget" "iterations_consumed=$used" \
      "last_result=$lr" "last_failure_fingerprint=NONE" "consecutive_same_failure_count=0" \
      "status=ACTIVE" "stop_reason=NONE" "last_reason=HUMAN_RESUME:$reason"
    echo "PASS: resumed Phase $phase AUTO executor with cumulative usage $used/$budget."
    ;;
  rebudget)
    [[ $# -ge 3 ]] || fail "usage: auto-state.sh rebudget <phase> <new-budget> <reason...>"
    phase="$1"; new_budget="$2"; shift 2; reason="$*"
    validate_phase "$phase"
    [[ "$new_budget" =~ ^[1-9][0-9]*$ ]] || fail "new budget must be a positive integer"
    acquire_lock "$phase"
    file="$(state_file "$phase")"; [[ -f "$file" ]] || fail "missing AUTO state for Phase $phase"
    status="$(readv "$file" status)"; [[ "$status" == "STOPPED" ]] || fail "rebudget requires a STOPPED executor while the phase is being human-replanned"
    executor="$(readv "$file" executor)"; old_budget="$(readv "$file" budget)"; used="$(readv "$file" iterations_consumed)"
    lr="$(readv "$file" last_result)"; fp="$(readv "$file" last_failure_fingerprint)"; same="$(readv "$file" consecutive_same_failure_count)"
    [[ "$old_budget" =~ ^[1-9][0-9]*$ && "$used" =~ ^[0-9]+$ ]] || fail "AUTO state is malformed"
    (( new_budget > old_budget )) || fail "rebudget must increase the existing budget ($old_budget); requested $new_budget"
    (( new_budget > used )) || fail "new budget must exceed iterations already consumed ($used)"
    write_state "$file" "phase=$phase" "executor=$executor" "budget=$new_budget" "iterations_consumed=$used" \
      "last_result=$lr" "last_failure_fingerprint=$fp" "consecutive_same_failure_count=$same" \
      "status=STOPPED" "stop_reason=REBUDGETED_REQUIRES_RESUME" "last_reason=HUMAN_REBUDGET:$reason"
    echo "PASS: Phase $phase AUTO budget changed $old_budget -> $new_budget; consumed iterations remain $used."
    ;;
  show)
    [[ $# -eq 1 ]] || fail "usage: auto-state.sh show <phase>"
    validate_phase "$1"
    file="$(state_file "$1")"; [[ -f "$file" ]] || fail "missing AUTO state for Phase $1"; cat "$file"
    ;;
  *) fail "usage: auto-state.sh {init|consume|stop|resume|rebudget|show} ..." ;;
esac
