#!/usr/bin/env bash

# Authorized TODO.md state transition: In Progress -> Done.
#
# Usage:
#   bash scripts/complete-phase.sh <phase-number>
#
# Human/engineering acceptance happens before invocation (WORKFLOW.md §13.A).
# This script verifies deterministic completion gates and atomically writes:
#   Status: Done
#   Completed against: Spec revision N

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SPEC_FILE="$ROOT_DIR/SPEC.md"
TODO_FILE="$ROOT_DIR/TODO.md"
VALIDATE_SCRIPT="$SCRIPT_DIR/validate.sh"
CHECK_TODO_SCRIPT="$SCRIPT_DIR/check-todo.sh"
LOCK_DIR="$ROOT_DIR/.todo-state.lock"
TMP_FILE=""
VALIDATION_OUTPUT=""
TODO_CHECK_OUTPUT=""
LOCK_HELD=0

info() { printf 'INFO: %s\n' "$*"; }
warn() { printf 'WARN: %s\n' "$*" >&2; }
pass() { printf 'PASS: %s\n' "$*"; }
fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }

usage() {
  printf 'Usage: bash scripts/complete-phase.sh <phase-number>\n' >&2
  exit 2
}

cleanup() {
  [[ -z "${TMP_FILE:-}" || ! -f "$TMP_FILE" ]] || rm -f "$TMP_FILE"
  [[ -z "${VALIDATION_OUTPUT:-}" || ! -f "$VALIDATION_OUTPUT" ]] || rm -f "$VALIDATION_OUTPUT"
  [[ -z "${TODO_CHECK_OUTPUT:-}" || ! -f "$TODO_CHECK_OUTPUT" ]] || rm -f "$TODO_CHECK_OUTPUT"
  if [[ "${LOCK_HELD:-0}" -eq 1 ]]; then
    rm -f "$LOCK_DIR/pid" 2>/dev/null || true
    rmdir "$LOCK_DIR" 2>/dev/null || true
  fi
}
trap cleanup EXIT HUP INT TERM

[[ $# -eq 1 ]] || usage
PHASE_NUMBER="$1"
[[ "$PHASE_NUMBER" =~ ^[1-9][0-9]*$ ]] || fail "phase number must be a positive integer"

[[ -f "$SPEC_FILE" ]] || fail "missing SPEC.md"
[[ -f "$TODO_FILE" ]] || fail "missing TODO.md"
[[ -f "$VALIDATE_SCRIPT" ]] || fail "missing scripts/validate.sh"
[[ -f "$CHECK_TODO_SCRIPT" ]] || fail "missing scripts/check-todo.sh"

# Serialize TODO state transitions so parallel phase completions cannot overwrite each other.
if ! mkdir "$LOCK_DIR" 2>/dev/null; then
  fail "TODO transition lock exists at $LOCK_DIR; another transition may be running. Remove it only after confirming it is stale."
fi
LOCK_HELD=1
printf '%s\n' "$$" > "$LOCK_DIR/pid"

phase_heading_count() {
  awk -v n="$1" '$0 ~ "^### Phase " n " — " { c++ } END { print c + 0 }' "$TODO_FILE"
}

phase_block() {
  awk -v n="$1" '
    $0 ~ "^### Phase " n " — " {
      if (inside) exit
      inside=1
    }
    inside && $0 ~ "^### Phase [0-9]+ — " && $0 !~ "^### Phase " n " — " { exit }
    inside { print }
  ' "$TODO_FILE"
}

phase_field() {
  local key="$1"
  phase_block "$PHASE_NUMBER" | awk -v key="$key" '
    index($0, key ": ") == 1 {
      count++
      value=substr($0, length(key) + 3)
    }
    END {
      if (count != 1) exit 3
      print value
    }
  '
}

[[ "$(phase_heading_count "$PHASE_NUMBER")" -eq 1 ]] \
  || fail "Phase $PHASE_NUMBER must exist exactly once"

STATUS="$(phase_field "Status")" \
  || fail "Phase $PHASE_NUMBER must contain exactly one Status field"
DEFINED_AGAINST="$(phase_field "Defined against")" \
  || fail "Phase $PHASE_NUMBER must contain exactly one Defined against field"
COMPLETED_AGAINST="$(phase_field "Completed against")" \
  || fail "Phase $PHASE_NUMBER must contain exactly one Completed against field"

# Re-entrant: an already-valid Done phase is a successful no-op.
if [[ "$STATUS" == "Done" ]]; then
  [[ "$DEFINED_AGAINST" =~ ^Spec\ revision\ ([0-9]+)$ ]] \
    || fail "Phase $PHASE_NUMBER is Done but Defined against is malformed"
  DEFINED_REV="${BASH_REMATCH[1]}"

  [[ "$COMPLETED_AGAINST" =~ ^Spec\ revision\ ([0-9]+)$ ]] \
    || fail "Phase $PHASE_NUMBER is Done but Completed against is malformed"
  COMPLETED_REV="${BASH_REMATCH[1]}"

  (( COMPLETED_REV >= DEFINED_REV )) \
    || fail "Phase $PHASE_NUMBER is Done but completion revision predates its defined revision"

  pass "Phase $PHASE_NUMBER is already Done (Spec revision $COMPLETED_REV); no changes made."
  exit 0
fi

[[ "$STATUS" == "In Progress" ]] \
  || fail "Phase $PHASE_NUMBER must be In Progress to complete; current status is '$STATUS'"
[[ "$DEFINED_AGAINST" =~ ^Spec\ revision\ ([0-9]+)$ ]] \
  || fail "Phase $PHASE_NUMBER must have 'Defined against: Spec revision N'"
DEFINED_REV="${BASH_REMATCH[1]}"
[[ "$COMPLETED_AGAINST" == "—" ]] \
  || fail "Phase $PHASE_NUMBER is In Progress but Completed against is not '—'; refusing to repair partial state"

# SPEC supplies the completion revision. The script never accepts one from the caller.
SPEC_STATUS_COUNT="$(grep -Ec '^\*\*Status:\*\* (DRAFT|APPROVED)$' "$SPEC_FILE" || true)"
[[ "$SPEC_STATUS_COUNT" -eq 1 ]] || fail "SPEC.md must contain exactly one valid project Status field"
SPEC_STATUS="$(sed -n 's/^\*\*Status:\*\* \(DRAFT\|APPROVED\)$/\1/p' "$SPEC_FILE")"
[[ "$SPEC_STATUS" == "APPROVED" ]] || fail "SPEC.md must be APPROVED before completion"

SPEC_REV_COUNT="$(grep -Ec '^\*\*Spec revision:\*\* [0-9]+$' "$SPEC_FILE" || true)"
[[ "$SPEC_REV_COUNT" -eq 1 ]] || fail "SPEC.md must contain exactly one non-negative integer Spec revision"
SPEC_REV="$(sed -n 's/^\*\*Spec revision:\*\* \([0-9][0-9]*\)$/\1/p' "$SPEC_FILE")"

(( DEFINED_REV <= SPEC_REV )) \
  || fail "Defined against revision $DEFINED_REV is newer than current Spec revision $SPEC_REV"

if (( DEFINED_REV != SPEC_REV )); then
  warn "Revision drift: defined against $DEFINED_REV, current approved revision $SPEC_REV."
  warn "Invocation attests that every owned AC was re-verified against its current wording."
fi

# Completion-only task gate. Cross-file/state integrity belongs to check-todo.sh.
TASK_COUNTS="$(phase_block "$PHASE_NUMBER" | awk '
  /^#### To-do list[[:space:]]*$/ { in_tasks=1; headings++; next }
  in_tasks && /^#### / { in_tasks=0 }
  in_tasks && /^- \[[ xX]\][[:space:]]+/ {
    total++
    if ($0 ~ /^- \[ \][[:space:]]+/) unchecked++
    next
  }
  in_tasks && /^- \[[ xX]\]([^[:space:]]|$)/ { malformed++ }
  END { printf "%d %d %d %d\n", headings + 0, total + 0, unchecked + 0, malformed + 0 }
')"
read -r TASK_HEADINGS TASK_TOTAL TASK_UNCHECKED TASK_MALFORMED <<< "$TASK_COUNTS"
[[ "$TASK_HEADINGS" -eq 1 ]] || fail "Phase $PHASE_NUMBER must contain exactly one '#### To-do list' section"
[[ "$TASK_MALFORMED" -eq 0 ]] || fail "Phase $PHASE_NUMBER has $TASK_MALFORMED task checkbox(es) without required whitespace after ]"
[[ "$TASK_TOTAL" -gt 0 ]] || fail "Phase $PHASE_NUMBER has no task checkboxes"
[[ "$TASK_UNCHECKED" -eq 0 ]] || fail "Phase $PHASE_NUMBER has $TASK_UNCHECKED unchecked task(s)"

info "Running TODO integrity check..."
TODO_CHECK_OUTPUT="$(mktemp "${TMPDIR:-/tmp}/complete-phase-check-todo.XXXXXX")"
set +e
bash "$CHECK_TODO_SCRIPT" >"$TODO_CHECK_OUTPUT" 2>&1
TODO_CHECK_RC=$?
set -e
cat "$TODO_CHECK_OUTPUT"

[[ "$TODO_CHECK_RC" -eq 0 ]] \
  || fail "scripts/check-todo.sh failed with exit code $TODO_CHECK_RC; TODO.md was not modified"

if ! grep -Fxq 'CHECK_TODO_CONTRACT_VERSION=1' "$TODO_CHECK_OUTPUT"; then
  fail "scripts/check-todo.sh returned success without the required contract marker CHECK_TODO_CONTRACT_VERSION=1; refusing completion"
fi

rm -f "$TODO_CHECK_OUTPUT"
TODO_CHECK_OUTPUT=""
pass "TODO integrity check passed"

info "Running project validation..."
VALIDATION_OUTPUT="$(mktemp "${TMPDIR:-/tmp}/complete-phase-validation.XXXXXX")"
set +e
bash "$VALIDATE_SCRIPT" >"$VALIDATION_OUTPUT" 2>&1
VALIDATION_RC=$?
set -e
cat "$VALIDATION_OUTPUT"

[[ "$VALIDATION_RC" -eq 0 ]] \
  || fail "scripts/validate.sh failed with exit code $VALIDATION_RC; TODO.md was not modified"

# validate.sh v1.3 exits 0 when no project checks are configured; AGENTS.md says
# an empty check set is not a passing build, so completion rejects that state.
if grep -Fq 'WARNING: no validation commands configured.' "$VALIDATION_OUTPUT"; then
  fail "scripts/validate.sh has no project checks configured; an empty validation set cannot complete a phase"
fi
rm -f "$VALIDATION_OUTPUT"
VALIDATION_OUTPUT=""
pass "Project validation passed"

info "Invocation attests that the WORKFLOW.md human/engineering completion gate was completed."

# Build the entire replacement beside TODO.md, verify it, then rename atomically.
TMP_FILE="$(mktemp "${TODO_FILE}.tmp.XXXXXX")"
# Preserve TODO.md permissions on the replacement inode. The following awk redirect
# rewrites the temp file contents but keeps the mode copied here.
cp -p "$TODO_FILE" "$TMP_FILE"

if ! awk -v n="$PHASE_NUMBER" -v rev="$SPEC_REV" '
  $0 ~ "^### Phase " n " — " { target=1 }
  target && $0 ~ "^### Phase [0-9]+ — " && $0 !~ "^### Phase " n " — " { target=0 }

  target && $0 == "Status: In Progress" {
    if (status_changed) exit 41
    print "Status: Done"
    status_changed=1
    next
  }

  target && $0 == "Completed against: —" {
    if (completed_changed) exit 42
    print "Completed against: Spec revision " rev
    completed_changed=1
    next
  }

  { print }

  END {
    if (status_changed != 1 || completed_changed != 1) exit 43
  }
' "$TODO_FILE" > "$TMP_FILE"; then
  fail "could not construct the atomic TODO.md update; original file is unchanged"
fi

NEW_STATUS="$(awk -v n="$PHASE_NUMBER" '
  $0 ~ "^### Phase " n " — " { inside=1; next }
  inside && $0 ~ "^### Phase [0-9]+ — " { exit }
  inside && index($0, "Status: ") == 1 { print substr($0, 9); exit }
' "$TMP_FILE")"
NEW_COMPLETED="$(awk -v n="$PHASE_NUMBER" '
  $0 ~ "^### Phase " n " — " { inside=1; next }
  inside && $0 ~ "^### Phase [0-9]+ — " { exit }
  inside && index($0, "Completed against: ") == 1 { print substr($0, 20); exit }
' "$TMP_FILE")"

[[ "$NEW_STATUS" == "Done" ]] || fail "replacement verification failed: Status is not Done"
[[ "$NEW_COMPLETED" == "Spec revision $SPEC_REV" ]] \
  || fail "replacement verification failed: Completed against is incorrect"

mv -f "$TMP_FILE" "$TODO_FILE"
TMP_FILE=""

pass "Phase $PHASE_NUMBER completed against Spec revision $SPEC_REV."
