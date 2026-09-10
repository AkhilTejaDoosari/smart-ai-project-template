#!/usr/bin/env bash
#
# Single validation entrypoint for this project.
#
# Humans, agents, git hooks, and CI all run THIS FILE. The project commands below
# are the only authoritative copy — AGENTS.md points here rather than restating
# them, so there is nothing to keep in sync.
#
# Framework structural checks (check-todo.sh always, check-spec.sh when SPEC.md
# is APPROVED) are delegated to scripts/check-framework.sh, which fails closed:
# a required helper that is missing is a failure, not a skip. Executable
# permission is irrelevant -- helpers are invoked through bash, so a helper
# present but non-executable still runs and is never treated as absent.
# validate.sh and complete-phase.sh's Done fast-path both call the same helper
# so they cannot drift out of sync with each other.
#
# Exit codes:
#   0 = everything configured passed
#   1 = a configured check failed, or a framework structural check failed
#   2 = framework checks passed but no project checks are configured
#
# Fill in whichever project commands apply below. Leave the rest empty. Not every
# project has four checks: a Terraform repo has no typecheck, a Python CLI may have
# no build. An empty variable is skipped, not failed.

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.." || exit 1

LINT=""
TYPECHECK=""
TEST=""
BUILD=""

configured=0
failed=0

run_step() {
  local name="$1" cmd="$2"
  if [ -z "$cmd" ]; then
    echo "SKIP  $name (not configured)"
    return 0
  fi
  configured=$((configured + 1))
  echo "RUN   $name: $cmd"
  if eval "$cmd"; then
    echo "PASS  $name"
  else
    echo "FAIL  $name"
    failed=$((failed + 1))
  fi
}

if ! bash "$SCRIPT_DIR/check-framework.sh"; then
  echo
  echo "VALIDATION FAILED (framework structural check)"
  exit 1
fi

echo
echo "--- Project checks ---"

run_step lint      "$LINT"
run_step typecheck "$TYPECHECK"
run_step test      "$TEST"
run_step build     "$BUILD"

echo

if [ "$failed" -gt 0 ]; then
  echo "VALIDATION FAILED"
  exit 1
fi

if [ "$configured" -eq 0 ]; then
  echo "WARNING: no project validation commands configured. Framework structural"
  echo "checks passed, but there is no deterministic gate on the code itself."
  echo "Fill in scripts/validate.sh before claiming any phase complete."
  exit 2
fi

echo "VALIDATION PASSED ($configured project check(s), framework checks included)"
exit 0
