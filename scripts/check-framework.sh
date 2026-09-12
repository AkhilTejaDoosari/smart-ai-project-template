#!/usr/bin/env bash
# Centralized framework current-state integrity check.
# Framework implementation self-tests live in tests/framework and are intentionally separate.

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SPEC="$ROOT_DIR/SPEC.md"
status=0

run_required(){
  label="$1"; file="$2"
  if [[ ! -f "$file" ]]; then echo "FAIL  $label missing at $file"; status=1; return; fi
  echo "RUN   $label"
  if bash "$file"; then echo "PASS  $label"; else echo "FAIL  $label"; status=1; fi
}

echo "--- Framework state checks ---"
run_required "check-todo.sh" "$SCRIPT_DIR/check-todo.sh"
run_required "check-evidence.sh" "$SCRIPT_DIR/check-evidence.sh"

SPEC_STATUS=""
if [[ -f "$SPEC" ]]; then
  SPEC_STATUS="$(awk '/^\*\*Status:\*\* (DRAFT|APPROVED)$/{c++;v=$0;sub(/^\*\*Status:\*\* /,"",v)}END{if(c==1)print v}' "$SPEC")"
fi

if [[ "$SPEC_STATUS" == "APPROVED" ]]; then
  run_required "check-spec.sh" "$SCRIPT_DIR/check-spec.sh"
elif [[ "$SPEC_STATUS" == "DRAFT" ]]; then
  echo "SKIP  check-spec.sh (SPEC.md is DRAFT; approval readiness is a separate gate)"
else
  echo "FAIL  SPEC.md Status is missing or malformed"
  status=1
fi

exit "$status"
