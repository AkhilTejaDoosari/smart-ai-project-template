#!/usr/bin/env bash
#
# Centralized framework structural integrity check.
#
# Single responsibility, used by both validate.sh and complete-phase.sh's
# Done fast-path, so the two consumers cannot drift out of sync with each other.
#
# Contract:
#   - scripts/check-todo.sh is required and always runs.
#   - scripts/check-spec.sh is required and runs whenever SPEC.md's Status is
#     APPROVED.
#   - A required helper that is missing is a FAILURE, not a skip. Executable
#     permission is irrelevant: helpers are invoked with `bash`, so a helper
#     present but non-executable still runs and is not treated as absent.
#
# Usage:
#   bash scripts/check-framework.sh
#
# Exit codes:
#   0 = all required structural checks passed
#   1 = a required check failed, or a required helper file is missing

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SPEC_FILE="$ROOT_DIR/SPEC.md"
CHECK_TODO="$SCRIPT_DIR/check-todo.sh"
CHECK_SPEC="$SCRIPT_DIR/check-spec.sh"

status=0

echo "--- Framework structural checks ---"

if [[ ! -f "$CHECK_TODO" ]]; then
  echo "FAIL  check-todo.sh is required but missing at $CHECK_TODO"
  status=1
else
  echo "RUN   check-todo.sh"
  if bash "$CHECK_TODO"; then
    echo "PASS  check-todo.sh"
  else
    echo "FAIL  check-todo.sh"
    status=1
  fi
fi

SPEC_STATUS=""
if [[ -f "$SPEC_FILE" ]]; then
  SPEC_STATUS="$(sed -n 's/^\*\*Status:\*\* \(DRAFT\|APPROVED\)$/\1/p' "$SPEC_FILE")"
fi

if [[ "$SPEC_STATUS" == "APPROVED" ]]; then
  if [[ ! -f "$CHECK_SPEC" ]]; then
    echo "FAIL  check-spec.sh is required (SPEC.md is APPROVED) but missing at $CHECK_SPEC"
    status=1
  else
    echo "RUN   check-spec.sh (SPEC.md is APPROVED)"
    if bash "$CHECK_SPEC"; then
      echo "PASS  check-spec.sh"
    else
      echo "FAIL  check-spec.sh"
      status=1
    fi
  fi
else
  echo "SKIP  check-spec.sh (SPEC.md is not APPROVED)"
fi

exit "$status"
