#!/usr/bin/env bash
# Framework implementation self-tests. Uses disposable repositories only.
# Intended to run on both macOS and Linux.

set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PASS=0; FAIL=0
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/smart-ai-framework-tests.XXXXXX")"
trap 'rm -rf "$TMP_ROOT"' EXIT HUP INT TERM

ok(){ PASS=$((PASS+1)); printf 'PASS  %s\n' "$1"; }
bad(){ FAIL=$((FAIL+1)); printf 'FAIL  %s\n' "$1" >&2; }
expect_rc(){ name="$1" expected="$2"; shift 2; "$@" >/tmp/framework-test.out.$$ 2>&1; rc=$?; rm -f /tmp/framework-test.out.$$; if [[ "$rc" -eq "$expected" ]]; then ok "$name"; else bad "$name (expected rc=$expected got rc=$rc)"; fi; }
expect_contains(){ name="$1" needle="$2"; shift 2; out="$($@ 2>&1)"; rc=$?; if [[ "$rc" -eq 0 && "$out" == *"$needle"* ]]; then ok "$name"; else bad "$name"; printf '%s\n' "$out" >&2; fi; }

make_repo(){
  d="$1"; mkdir -p "$d/scripts" "$d/.framework/auto"
  cp "$ROOT"/scripts/*.sh "$d/scripts/"
  cp "$ROOT/.framework/validation.conf" "$d/.framework/validation.conf"
  cp "$ROOT/.framework/validation-ignore.txt" "$d/.framework/validation-ignore.txt"
  cp "$ROOT/.framework/smoke.conf" "$d/.framework/smoke.conf"
}

write_ready_spec(){
  f="$1"; status="${2:-DRAFT}"; rev="${3:-0}"
  cat > "$f" <<SPEC
# SPEC.md
## Template Conventions
Reserved marker documentation: \`{{TBD:\`
## 1. Project Controls
**Status:** $status
**Spec revision:** $rev
**Entry:** NEW
**Rigor:** STANDARD
**Monthly budget USD:** 0.00
## 2. Product
Ready fixture.
## 3. Requirements
- \`REQ-001\` - fixture works
## 4. Acceptance Criteria
### AC-001 - Fixture works
**Satisfies:** \`REQ-001\`
**Required proof:** NORMAL
Given: fixture
When: validated
Then: pass
## 5. Out of Scope
None.
## 6. Constraints
None.
## 7. Architecture
Single fixture.
## 8. Repository Shape
Fixture.
## 9. Data and State
**Applicability:** N/A
## 10. External Services and Dependencies
**Applicability:** N/A
## 11. UX / Design
**Applicability:** N/A
## 12. Security
**Applicability:** N/A
## 13. Deployment and Operations
**Applicability:** N/A
## 14. Important Decisions
None.
## 15. Open Questions
**State:** CLEAR
## Approval
Fixture approval section.
SPEC
}

write_todo(){
  f="$1"; status="${2:-Not Started}"; defined="${3:-—}"; completed="${4:-—}"; task="${5:- }"
  cat > "$f" <<TODO
# TODO.md
## Execution Strategy
**Strategy:** HYBRID
### Phase 1 - Fixture
\`\`\`text
Status: $status
Mode: MANUAL
Depends on: None
Defined against: $defined
Completed against: $completed
AUTO executor: —
AUTO iteration budget: —
\`\`\`
#### Agenda
Prove fixture.
#### Acceptance Coverage
- \`AC-001\`
#### To-do list
- [$task] fixture task
#### Blocker
None
TODO
}

write_evidence(){
  f="$1"; result="${2:-NOT VERIFIED}"; notes="${3:-pending}"
  cat > "$f" <<EVIDENCE
# EVIDENCE.md
## Acceptance Evidence
| AC | Required proof | Result | Evidence |
|---|---|---|---|
| \`AC-001\` | NORMAL | $result | fixture evidence |
## External Integration State
| Integration | Required final state | Achieved state | Evidence |
|---|---|---|---|
## Packaging / Deployment Evidence
| Gate | Result | Evidence |
|---|---|---|
## Final Certification Notes
$notes
EVIDENCE
}

# 1. Shipped template parser must see all three canonical phases while SPEC is DRAFT.
out="$(cd "$ROOT" && bash scripts/check-todo.sh 2>&1)"; rc=$?
if [[ "$rc" -eq 0 && "$out" == *"3 phase(s)"* ]]; then ok "fresh template parses 3 phases"; else bad "fresh template phase parsing"; printf '%s\n' "$out" >&2; fi

# 2. Phase-like but noncanonical headings must fail instead of passing as zero phases.
d="$TMP_ROOT/noncanonical"; make_repo "$d"; write_ready_spec "$d/SPEC.md" DRAFT 0; cp "$ROOT/TODO.md" "$d/TODO.md"; cp "$ROOT/EVIDENCE.md" "$d/EVIDENCE.md"
awk '{gsub(/^### Phase 1 - /,"### Phase 1 — ");print}' "$d/TODO.md" > "$d/TODO.tmp" && mv "$d/TODO.tmp" "$d/TODO.md"
expect_rc "noncanonical phase heading fails" 1 bash "$d/scripts/check-todo.sh"

# 3. PRE-SCAFFOLD is exit 2, not PASS or FAIL.
d="$TMP_ROOT/prescaffold"; make_repo "$d"; write_ready_spec "$d/SPEC.md" DRAFT 0; write_todo "$d/TODO.md"; write_evidence "$d/EVIDENCE.md"
expect_rc "pre-scaffold validate exits 2" 2 bash "$d/scripts/validate.sh"

# 4. Approval lifecycle works end-to-end.
d="$TMP_ROOT/approval"; make_repo "$d"; write_ready_spec "$d/SPEC.md" DRAFT 0; write_todo "$d/TODO.md"; write_evidence "$d/EVIDENCE.md"
if (cd "$d" && bash scripts/check-spec.sh >/dev/null 2>&1 && bash scripts/approve-spec.sh >/dev/null 2>&1); then
  st="$(awk '/^\*\*Status:\*\*/{print $2}' "$d/SPEC.md")"; rev="$(awk '/^\*\*Spec revision:\*\*/{print $3}' "$d/SPEC.md")"
  if [[ "$st" == "APPROVED" && "$rev" == "1" ]]; then ok "DRAFT rev0 approves atomically to APPROVED rev1"; else bad "approval state transition values"; fi
else bad "approval lifecycle"; fi

# 5. Invalid spec cannot be partially approved.
d="$TMP_ROOT/approval-fail"; make_repo "$d"; write_ready_spec "$d/SPEC.md" DRAFT 0; write_todo "$d/TODO.md"; write_evidence "$d/EVIDENCE.md"; printf '\n{{TBD: unresolved}}\n' >> "$d/SPEC.md"
expect_rc "invalid spec approval fails" 1 bash "$d/scripts/approve-spec.sh"
st="$(awk '/^\*\*Status:\*\*/{print $2}' "$d/SPEC.md")"; rev="$(awk '/^\*\*Spec revision:\*\*/{print $3}' "$d/SPEC.md")"; if [[ "$st" == "DRAFT" && "$rev" == "0" ]]; then ok "failed approval is atomic"; else bad "failed approval mutated SPEC"; fi

# 6. Detected executable surface must be registered.
d="$TMP_ROOT/unregistered"; make_repo "$d"; write_ready_spec "$d/SPEC.md" DRAFT 0; write_todo "$d/TODO.md"; write_evidence "$d/EVIDENCE.md"; mkdir -p "$d/app"; echo '{}' > "$d/app/package.json"
expect_rc "detected unregistered surface fails" 1 bash "$d/scripts/validate.sh"

# 7. Runtime mismatch fails before project success.
d="$TMP_ROOT/runtime"; make_repo "$d"; write_ready_spec "$d/SPEC.md" DRAFT 0; write_todo "$d/TODO.md"; write_evidence "$d/EVIDENCE.md"; mkdir -p "$d/app"; echo '{}' > "$d/app/package.json"; printf 'app|app|false|||true|\n' > "$d/.framework/validation.conf"
expect_rc "runtime mismatch fails validation" 1 bash "$d/scripts/validate.sh"

# 8. Normal validation ignores expensive smoke gates; smoke remains separate.
d="$TMP_ROOT/smoke"; make_repo "$d"; write_ready_spec "$d/SPEC.md" DRAFT 0; write_todo "$d/TODO.md"; write_evidence "$d/EVIDENCE.md"; mkdir -p "$d/app"; echo '{}' > "$d/app/package.json"; printf 'app|app|true|||true|\n' > "$d/.framework/validation.conf"; printf 'bad-smoke|.|false\n' > "$d/.framework/smoke.conf"
expect_rc "normal validation does not run smoke gate" 0 bash "$d/scripts/validate.sh"
expect_rc "smoke gate fails independently" 1 bash "$d/scripts/smoke.sh"

# 9. Durable AUTO accounting survives separate invocations and does not reset.
d="$TMP_ROOT/auto"; make_repo "$d"; write_ready_spec "$d/SPEC.md" DRAFT 0; write_todo "$d/TODO.md"; write_evidence "$d/EVIDENCE.md"
(cd "$d" && bash scripts/auto-state.sh init 1 ralph 3 >/dev/null && bash scripts/auto-state.sh consume 1 FAIL X first >/dev/null && bash scripts/auto-state.sh consume 1 PASS ok second >/dev/null)
used="$(awk -F= '$1=="iterations_consumed"{print $2}' "$d/.framework/auto/phase-1.state")"; if [[ "$used" == "2" ]]; then ok "AUTO ledger persists consumed iterations"; else bad "AUTO ledger iteration count"; fi
expect_rc "AUTO ledger cannot be reinitialized/reset" 1 bash "$d/scripts/auto-state.sh" init 1 ralph 3

# 10. Three identical failures stop executor.
d="$TMP_ROOT/auto-stop"; make_repo "$d"; write_ready_spec "$d/SPEC.md" DRAFT 0; write_todo "$d/TODO.md"; write_evidence "$d/EVIDENCE.md"; (cd "$d" && bash scripts/auto-state.sh init 1 ralph 5 >/dev/null && bash scripts/auto-state.sh consume 1 FAIL same a >/dev/null && bash scripts/auto-state.sh consume 1 FAIL same b >/dev/null && bash scripts/auto-state.sh consume 1 FAIL same c >/dev/null)
state="$(awk -F= '$1=="status"{print $2}' "$d/.framework/auto/phase-1.state")"; reason="$(awk -F= '$1=="stop_reason"{print $2}' "$d/.framework/auto/phase-1.state")"; if [[ "$state" == "STOPPED" && "$reason" == "REPEATED_IDENTICAL_FAILURE" ]]; then ok "three identical failures stop AUTO executor"; else bad "AUTO repeated-failure stop"; fi

# 11. Complete phase requires AC evidence PASS and configured validation, then transitions atomically.
d="$TMP_ROOT/complete"; make_repo "$d"; write_ready_spec "$d/SPEC.md" APPROVED 1; write_todo "$d/TODO.md" 'In Progress' 'Spec revision 1' '—' x; write_evidence "$d/EVIDENCE.md" PASS pending; mkdir -p "$d/app"; echo '{}' > "$d/app/package.json"; printf 'app|app|true|||true|\n' > "$d/.framework/validation.conf"
if (cd "$d" && bash scripts/complete-phase.sh 1 >/dev/null 2>&1); then
  st="$(awk '/^Status: /{print $2;exit}' "$d/TODO.md")"; comp="$(awk -F': ' '/^Completed against:/{print $2;exit}' "$d/TODO.md")"; if [[ "$st" == "Done" && "$comp" == "Spec revision 1" ]]; then ok "phase completion writes Done + completion revision"; else bad "phase completion values"; fi
else bad "phase completion lifecycle"; fi


# 12. Approved zero-phase plan fails closed.
d="$TMP_ROOT/zero-phase"; make_repo "$d"; write_ready_spec "$d/SPEC.md" APPROVED 1; write_evidence "$d/EVIDENCE.md" NOT\ VERIFIED pending
cat > "$d/TODO.md" <<'ZT'
# TODO.md
## Execution Strategy
**Strategy:** HYBRID
ZT
expect_rc "approved zero-phase plan fails" 1 bash "$d/scripts/check-todo.sh"

# 13. Dependency cycles remain mechanically rejected.
d="$TMP_ROOT/cycle"; make_repo "$d"; write_ready_spec "$d/SPEC.md" APPROVED 1; write_evidence "$d/EVIDENCE.md" NOT\ VERIFIED pending
cat > "$d/TODO.md" <<'CT'
# TODO.md
## Execution Strategy
**Strategy:** HYBRID
### Phase 1 - One
```text
Status: Not Started
Mode: MANUAL
Depends on: Phase 2
Defined against: —
Completed against: —
AUTO executor: —
AUTO iteration budget: —
```
#### Agenda
One.
#### Acceptance Coverage
- `AC-001`
#### To-do list
- [ ] one
#### Blocker
None
### Phase 2 - Two
```text
Status: Not Started
Mode: MANUAL
Depends on: Phase 1
Defined against: —
Completed against: —
AUTO executor: —
AUTO iteration budget: —
```
#### Agenda
Two.
#### Acceptance Coverage
- `AC-001`
#### To-do list
- [ ] two
#### Blocker
None
CT
expect_rc "dependency cycle fails" 1 bash "$d/scripts/check-todo.sh"

# 14. Final certification rejects insufficient external-integration state.
d="$TMP_ROOT/live"; make_repo "$d"; write_ready_spec "$d/SPEC.md" APPROVED 1
# Replace §10 N/A with a minimal applicable external-service table.
awk '
$0=="## 10. External Services and Dependencies"{print;getline;print "**Applicability:** YES";print "| Service | Need | Production Provider | Automated Test Provider | Required Final State | Free Tier / Limit | Estimated Monthly Cost USD | Variable-Cost Risk | Pricing Notes | Alternative |";print "|---|---|---|---|---|---|---:|---|---|---|";print "| DemoAPI | demo | real | stub | LIVE VERIFIED | none | 0.00 | LOW | none | none |";skip=1;next}
skip&&$0=="## 11. UX / Design"{skip=0;print;next}
!skip{print}
' "$d/SPEC.md" > "$d/SPEC.tmp" && mv "$d/SPEC.tmp" "$d/SPEC.md"
write_todo "$d/TODO.md" Done 'Spec revision 1' 'Spec revision 1' x
cat > "$d/EVIDENCE.md" <<'EVID'
# EVIDENCE.md
## Acceptance Evidence
| AC | Required proof | Result | Evidence |
|---|---|---|---|
| `AC-001` | NORMAL | PASS | fixture |
## External Integration State
| Integration | Required final state | Achieved state | Evidence |
|---|---|---|---|
| DemoAPI | LIVE VERIFIED | TESTED | stub |
## Packaging / Deployment Evidence
| Gate | Result | Evidence |
|---|---|---|
## Final Certification Notes
None
EVID
mkdir -p "$d/app"; echo '{}' > "$d/app/package.json"; printf 'app|app|true|||true|\n' > "$d/.framework/validation.conf"
expect_rc "applicable external-service SPEC parses" 0 bash "$d/scripts/check-spec.sh"
expect_rc "integration evidence matches approved service" 0 bash "$d/scripts/check-evidence.sh"
expect_rc "TESTED cannot satisfy LIVE VERIFIED" 1 bash "$d/scripts/certify-project.sh"

# 15. Final certification happy path succeeds when all proof contracts are satisfied.
python3 - "$d/EVIDENCE.md" <<'PY2'
from pathlib import Path
import sys
p=Path(sys.argv[1])
s=p.read_text().replace('| DemoAPI | LIVE VERIFIED | TESTED | stub |','| DemoAPI | LIVE VERIFIED | LIVE VERIFIED | real provider response |')
p.write_text(s)
PY2
expect_rc "final certification happy path passes" 0 bash "$d/scripts/certify-project.sh"

# 16. Human-authorized resume preserves consumed iterations and resets only the failure streak.
d="$TMP_ROOT/auto-resume"; make_repo "$d"; write_ready_spec "$d/SPEC.md" DRAFT 0; write_todo "$d/TODO.md"; write_evidence "$d/EVIDENCE.md"
(cd "$d" && bash scripts/auto-state.sh init 1 ralph 5 >/dev/null && bash scripts/auto-state.sh consume 1 FAIL same a >/dev/null && bash scripts/auto-state.sh consume 1 FAIL same b >/dev/null && bash scripts/auto-state.sh consume 1 FAIL same c >/dev/null && bash scripts/auto-state.sh resume 1 "human reviewed failure" >/dev/null)
used="$(awk -F= '$1=="iterations_consumed"{print $2}' "$d/.framework/auto/phase-1.state")"; state="$(awk -F= '$1=="status"{print $2}' "$d/.framework/auto/phase-1.state")"; same="$(awk -F= '$1=="consecutive_same_failure_count"{print $2}' "$d/.framework/auto/phase-1.state")"
if [[ "$used" == "3" && "$state" == "ACTIVE" && "$same" == "0" ]]; then ok "AUTO human resume preserves cumulative usage"; else bad "AUTO human resume contract"; fi

# 17. Exhausted executor cannot resume until a human-authorized rebudget preserves prior usage.
d="$TMP_ROOT/auto-rebudget"; make_repo "$d"; write_ready_spec "$d/SPEC.md" DRAFT 0; write_todo "$d/TODO.md"; write_evidence "$d/EVIDENCE.md"
(cd "$d" && bash scripts/auto-state.sh init 1 ralph 2 >/dev/null && bash scripts/auto-state.sh consume 1 PASS one a >/dev/null && bash scripts/auto-state.sh consume 1 PASS two b >/dev/null)
expect_rc "budget-exhausted AUTO cannot resume directly" 1 bash "$d/scripts/auto-state.sh" resume 1 "human resume"
(cd "$d" && bash scripts/auto-state.sh rebudget 1 4 "human approved larger budget" >/dev/null && bash scripts/auto-state.sh resume 1 "human resume after replan" >/dev/null)
used="$(awk -F= '$1=="iterations_consumed"{print $2}' "$d/.framework/auto/phase-1.state")"; budget="$(awk -F= '$1=="budget"{print $2}' "$d/.framework/auto/phase-1.state")"; state="$(awk -F= '$1=="status"{print $2}' "$d/.framework/auto/phase-1.state")"
if [[ "$used" == "2" && "$budget" == "4" && "$state" == "ACTIVE" ]]; then ok "AUTO rebudget preserves consumed iterations"; else bad "AUTO rebudget contract"; fi

# 18. Evidence Required proof must match the approved AC proof contract.
d="$TMP_ROOT/proof-drift"; make_repo "$d"; write_ready_spec "$d/SPEC.md" APPROVED 1; write_todo "$d/TODO.md"; write_evidence "$d/EVIDENCE.md" NOT\ VERIFIED pending
python3 - "$d/EVIDENCE.md" <<'PY2'
from pathlib import Path
import sys
p=Path(sys.argv[1]); p.write_text(p.read_text().replace('| `AC-001` | NORMAL |','| `AC-001` | SMOKE |'))
PY2
expect_rc "acceptance evidence proof-class drift fails" 1 bash "$d/scripts/check-evidence.sh"

# 19. Smoke registry rejects an empty command instead of treating it as PASS.
d="$TMP_ROOT/empty-smoke"; make_repo "$d"; write_ready_spec "$d/SPEC.md" DRAFT 0; write_todo "$d/TODO.md"; write_evidence "$d/EVIDENCE.md"; printf 'empty|.|\n' > "$d/.framework/smoke.conf"
expect_rc "empty smoke command fails closed" 1 bash "$d/scripts/smoke.sh"

# 20. A runtime-only surface is not enough; project behavior needs at least one real check.
d="$TMP_ROOT/runtime-only"; make_repo "$d"; write_ready_spec "$d/SPEC.md" DRAFT 0; write_todo "$d/TODO.md"; write_evidence "$d/EVIDENCE.md"; mkdir -p "$d/app"; echo '{}' > "$d/app/package.json"; printf 'app|app|true||||\n' > "$d/.framework/validation.conf"
expect_rc "runtime-only validation surface fails" 1 bash "$d/scripts/validate.sh"

# 21. TODO rejects executor names the durable ledger itself cannot consume.
d="$TMP_ROOT/bad-executor"; make_repo "$d"; write_ready_spec "$d/SPEC.md" APPROVED 1; write_todo "$d/TODO.md"; write_evidence "$d/EVIDENCE.md" NOT\ VERIFIED pending
python3 - "$d/TODO.md" <<'PY2'
from pathlib import Path
import sys
p=Path(sys.argv[1]); s=p.read_text().replace('Mode: MANUAL','Mode: AUTO').replace('AUTO executor: —','AUTO executor: ralph loop').replace('AUTO iteration budget: —','AUTO iteration budget: 3'); p.write_text(s)
PY2
expect_rc "invalid AUTO executor name fails TODO integrity" 1 bash "$d/scripts/check-todo.sh"

echo
printf 'Framework self-tests: %d passed, %d failed\n' "$PASS" "$FAIL"
[[ "$FAIL" -eq 0 ]]
