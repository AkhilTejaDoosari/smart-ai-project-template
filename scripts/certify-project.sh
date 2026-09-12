#!/usr/bin/env bash
# Final project certification gate. Read-only: it does not mutate project state.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SPEC="$ROOT_DIR/SPEC.md"; TODO="$ROOT_DIR/TODO.md"; EVIDENCE="$ROOT_DIR/EVIDENCE.md"
fail(){ printf 'FAIL: %s\n' "$*" >&2; exit 1; }

bash "$SCRIPT_DIR/check-framework.sh" || fail "framework state is not internally consistent"
STATUS="$(awk '/^\*\*Status:\*\* (DRAFT|APPROVED)$/{v=$0;sub(/^\*\*Status:\*\* /,"",v);print v;exit}' "$SPEC")"
[[ "$STATUS" == "APPROVED" ]] || fail "final certification requires APPROVED SPEC"

not_done="$(awk '/^Status: /{x=$0;sub(/^Status: /,"",x);if(x!="Done")n++}END{print n+0}' "$TODO")"
phases="$(awk '/^### Phase [1-9][0-9]* - /{n++}END{print n+0}' "$TODO")"
[[ "$phases" -gt 0 ]] || fail "final certification requires at least one phase"
[[ "$not_done" -eq 0 ]] || fail "$not_done phase(s) are not Done"

# Every approved AC must be PASS in the evidence ledger.
while IFS= read -r ac; do
  [[ -n "$ac" ]] || continue
  result="$(awk -F'|' -v target="$ac" '
    /^## Acceptance Evidence/{inside=1;next}/^## /{if(inside)inside=0}
    inside&&/^\|/{id=$2;gsub(/^[[:space:]]+|[[:space:]]+|`/,"",id);if(id==target){r=$4;gsub(/^[[:space:]]+|[[:space:]]+$/,"",r);print r;exit}}
  ' "$EVIDENCE")"
  [[ "$result" == "PASS" ]] || fail "$ac is not PASS in EVIDENCE.md"
done < <(awk '/^### AC-[0-9]+ ([-—]) /{x=$0;sub(/^### /,"",x);split(x,a,/ - | — /);print a[1]}' "$SPEC")

# Compare required/achieved integration state numerically.
rank(){ case "$1" in 'NOT STARTED') echo 0;; IMPLEMENTED) echo 1;; TESTED) echo 2;; 'LIVE VERIFIED') echo 3;; *) echo -1;; esac; }
while IFS='|' read -r name required achieved; do
  [[ -n "$name" ]] || continue
  rr="$(rank "$required")"; ar="$(rank "$achieved")"
  [[ "$rr" -ge 1 && "$ar" -ge 0 ]] || fail "invalid integration state for $name"
  (( ar >= rr )) || fail "integration $name achieved '$achieved' but requires '$required'"
done < <(awk -F'|' '
  /^## External Integration State/{inside=1;next}/^## /{if(inside)inside=0}
  inside&&/^\|/{n=$2;r=$3;a=$4;gsub(/^[[:space:]]+|[[:space:]]+$/,"",n);gsub(/^[[:space:]]+|[[:space:]]+$/,"",r);gsub(/^[[:space:]]+|[[:space:]]+$/,"",a);if(n!="Integration"&&n!~/^-+$/&&n!~/{{TBD:/)print n "|" r "|" a}
' "$EVIDENCE")

bash "$SCRIPT_DIR/validate.sh" || fail "normal validation failed during final certification"

if grep -Eq '^\*\*Required proof:\*\* .*SMOKE' "$SPEC"; then
  bash "$SCRIPT_DIR/smoke.sh" || fail "SMOKE proof is required but packaging/deployment smoke did not pass"
fi

notes="$(awk '/^## Final Certification Notes/{inside=1;next} inside&&/^## /{exit} inside&&NF{print;exit}' "$EVIDENCE")"
[[ "$notes" == "None" ]] || fail "Final Certification Notes must be exactly 'None' before certification; current value: '${notes:-empty}'"

echo "PROJECT CERTIFICATION: PASS"
echo "All phases Done, normal validation passed, required evidence satisfied, and integration target states met."
