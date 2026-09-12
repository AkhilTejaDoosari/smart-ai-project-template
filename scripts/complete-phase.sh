#!/usr/bin/env bash
# Authorized atomic TODO transition: In Progress -> Done.
# Human/engineering review and semantic acceptance judgment happen before invocation.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SPEC="$ROOT_DIR/SPEC.md"
TODO="$ROOT_DIR/TODO.md"
EVIDENCE="$ROOT_DIR/EVIDENCE.md"
CHECK_TODO="$SCRIPT_DIR/check-todo.sh"
CHECK_FRAMEWORK="$SCRIPT_DIR/check-framework.sh"
VALIDATE="$SCRIPT_DIR/validate.sh"
LOCK="$ROOT_DIR/.todo-state.lock"
TMP=""; OUT=""; LOCKED=0

fail(){ printf 'FAIL: %s\n' "$*" >&2; exit 1; }
pass(){ printf 'PASS: %s\n' "$*"; }
info(){ printf 'INFO: %s\n' "$*"; }
cleanup(){
  [[ -z "${TMP:-}" || ! -f "$TMP" ]] || rm -f "$TMP"
  [[ -z "${OUT:-}" || ! -f "$OUT" ]] || rm -f "$OUT"
  if [[ "$LOCKED" -eq 1 ]]; then rm -f "$LOCK/pid" 2>/dev/null || true; rmdir "$LOCK" 2>/dev/null || true; fi
}
trap cleanup EXIT HUP INT TERM

[[ $# -eq 1 ]] || fail "usage: bash scripts/complete-phase.sh <phase-number>"
PHASE="$1"; [[ "$PHASE" =~ ^[1-9][0-9]*$ ]] || fail "phase number must be a positive integer"
for f in "$SPEC" "$TODO" "$EVIDENCE" "$CHECK_TODO" "$CHECK_FRAMEWORK" "$VALIDATE"; do [[ -f "$f" ]] || fail "missing $f"; done

mkdir "$LOCK" 2>/dev/null || fail "TODO transition lock exists at $LOCK"
LOCKED=1; printf '%s\n' "$$" > "$LOCK/pid"

phase_count(){ awk -v n="$PHASE" '$0 ~ "^### Phase " n " - "{c++}END{print c+0}' "$TODO"; }
phase_block(){ awk -v n="$PHASE" '$0 ~ "^### Phase " n " - "{inside=1} inside && $0 ~ "^### Phase [1-9][0-9]* - " && $0 !~ "^### Phase " n " - "{exit} inside{print}' "$TODO"; }
phase_field(){ phase_block | awk -v k="$1" 'index($0,k ": ")==1{c++;v=substr($0,length(k)+3)}END{if(c!=1)exit 3;print v}'; }

[[ "$(phase_count)" -eq 1 ]] || fail "Phase $PHASE must exist exactly once using canonical heading syntax"
STATUS="$(phase_field Status)" || fail "Phase $PHASE Status field invalid"
DEFINED="$(phase_field 'Defined against')" || fail "Phase $PHASE Defined against invalid"
COMPLETED="$(phase_field 'Completed against')" || fail "Phase $PHASE Completed against invalid"
MODE="$(phase_field Mode)" || fail "Phase $PHASE Mode invalid"
EXECUTOR="$(phase_field 'AUTO executor')" || fail "Phase $PHASE AUTO executor invalid"
BUDGET="$(phase_field 'AUTO iteration budget')" || fail "Phase $PHASE AUTO iteration budget invalid"

if [[ "$STATUS" == "Done" ]]; then
  bash "$CHECK_FRAMEWORK" >/dev/null || fail "Phase $PHASE is Done but current framework state is inconsistent"
  pass "Phase $PHASE is already Done; no changes made."
  exit 0
fi
[[ "$STATUS" == "In Progress" ]] || fail "Phase $PHASE must be In Progress to complete; current status is '$STATUS'"
[[ "$DEFINED" =~ ^Spec\ revision\ ([0-9]+)$ ]] || fail "Phase $PHASE must have Defined against: Spec revision N"
DEFINED_REV="${BASH_REMATCH[1]}"
[[ "$COMPLETED" == "—" ]] || fail "active phase must have Completed against: —"

SPEC_STATUS="$(awk '/^\*\*Status:\*\* (DRAFT|APPROVED)$/{c++;v=$0;sub(/^\*\*Status:\*\* /,"",v)}END{if(c==1)print v}' "$SPEC")"
[[ "$SPEC_STATUS" == "APPROVED" ]] || fail "SPEC.md must be APPROVED before phase completion"
SPEC_REV="$(awk '/^\*\*Spec revision:\*\* [0-9]+$/{c++;v=$0;sub(/^\*\*Spec revision:\*\* /,"",v)}END{if(c==1)print v}' "$SPEC")"
[[ "$SPEC_REV" =~ ^[0-9]+$ ]] || fail "SPEC revision is malformed"
(( DEFINED_REV <= SPEC_REV )) || fail "Defined revision is newer than current SPEC revision"
if (( DEFINED_REV != SPEC_REV )); then info "revision drift detected: human invocation attests owned ACs were re-verified against current wording"; fi

TASKS="$(phase_block | awk '/^#### To-do list/{inside=1;next} inside&&/^#### /{inside=0} inside&&/^- \[[ xX]\][[:space:]]+/{t++;if($0~/^- \[ \]/)u++} END{print t+0, u+0}')"
read -r TOTAL UNCHECKED <<< "$TASKS"
[[ "$TOTAL" -gt 0 ]] || fail "Phase $PHASE has no task checkboxes"
[[ "$UNCHECKED" -eq 0 ]] || fail "Phase $PHASE has $UNCHECKED unchecked task(s)"

# Every AC owned by this phase must already be recorded PASS in EVIDENCE.md.
while IFS= read -r ac; do
  [[ -n "$ac" ]] || continue
  result="$(awk -F'|' -v target="$ac" '
    /^## Acceptance Evidence/{inside=1;next}/^## /{if(inside)inside=0}
    inside&&/^\|/{id=$2;gsub(/^[[:space:]]+|[[:space:]]+|`/,"",id);if(id==target){r=$4;gsub(/^[[:space:]]+|[[:space:]]+$/,"",r);print r;exit}}
  ' "$EVIDENCE")"
  [[ "$result" == "PASS" ]] || fail "$ac is owned by Phase $PHASE but EVIDENCE.md Result is '${result:-missing}', not PASS"
done < <(phase_block | awk '/^#### Acceptance Coverage/{inside=1;next} inside&&/^#### /{exit} inside&&/^- `AC-[0-9]+`/{x=$0;sub(/^- `/,"",x);sub(/`.*/,"",x);print x}')

# Executor-backed AUTO requires a durable ledger matching the phase contract.
if [[ "$MODE" == "AUTO" && "$EXECUTOR" != "NONE" ]]; then
  STATE="$ROOT_DIR/.framework/auto/phase-$PHASE.state"
  [[ -f "$STATE" ]] || fail "AUTO executor '$EXECUTOR' requires durable state at .framework/auto/phase-$PHASE.state"
  state_exec="$(awk -F= '$1=="executor"{print substr($0,10);exit}' "$STATE")"
  state_budget="$(awk -F= '$1=="budget"{print $2;exit}' "$STATE")"
  used="$(awk -F= '$1=="iterations_consumed"{print $2;exit}' "$STATE")"
  [[ "$state_exec" == "$EXECUTOR" ]] || fail "AUTO state executor '$state_exec' does not match TODO '$EXECUTOR'"
  [[ "$state_budget" == "$BUDGET" ]] || fail "AUTO state budget '$state_budget' does not match TODO '$BUDGET'"
  [[ "$used" =~ ^[0-9]+$ ]] || fail "AUTO state iterations_consumed is malformed"
  (( used <= BUDGET )) || fail "AUTO state exceeds phase budget"
  info "AUTO iterations consumed: $used / $BUDGET"
fi

info "running TODO integrity check..."
OUT="$(mktemp "${TMPDIR:-/tmp}/complete-todo.XXXXXX")"
set +e; bash "$CHECK_TODO" >"$OUT" 2>&1; rc=$?; set -e; cat "$OUT"
[[ "$rc" -eq 0 ]] || fail "check-todo.sh failed"
grep -Fqx 'CHECK_TODO_CONTRACT_VERSION=2' "$OUT" || fail "check-todo.sh succeeded without contract marker"
rm -f "$OUT"; OUT=""

info "running normal validation..."
OUT="$(mktemp "${TMPDIR:-/tmp}/complete-validation.XXXXXX")"
set +e; bash "$VALIDATE" >"$OUT" 2>&1; rc=$?; set -e; cat "$OUT"
[[ "$rc" -eq 0 ]] || fail "scripts/validate.sh must return 0 to complete a phase; got $rc"
rm -f "$OUT"; OUT=""

# TOCTOU guard on approval state/revision.
RE_STATUS="$(awk '/^\*\*Status:\*\* (DRAFT|APPROVED)$/{c++;v=$0;sub(/^\*\*Status:\*\* /,"",v)}END{if(c==1)print v}' "$SPEC")"
RE_REV="$(awk '/^\*\*Spec revision:\*\* [0-9]+$/{c++;v=$0;sub(/^\*\*Spec revision:\*\* /,"",v)}END{if(c==1)print v}' "$SPEC")"
[[ "$RE_STATUS" == "$SPEC_STATUS" && "$RE_REV" == "$SPEC_REV" ]] || fail "SPEC approval state changed during completion; rerun against current state"

TMP="$(mktemp "${TODO}.tmp.XXXXXX")"; cp -p "$TODO" "$TMP"
awk -v n="$PHASE" -v rev="$SPEC_REV" '
$0 ~ "^### Phase " n " - "{target=1}
target&&$0 ~ "^### Phase [1-9][0-9]* - "&&$0 !~ "^### Phase " n " - "{target=0}
target&&$0=="Status: In Progress"{if(s++)exit 41;print "Status: Done";next}
target&&$0=="Completed against: —"{if(c++)exit 42;print "Completed against: Spec revision " rev;next}
{print}
END{if(s!=1||c!=1)exit 43}
' "$TODO" > "$TMP" || fail "could not construct atomic TODO update"
mv -f "$TMP" "$TODO"; TMP=""
pass "Phase $PHASE completed against Spec revision $SPEC_REV."
