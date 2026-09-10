#!/usr/bin/env bash
#
# Single validation entrypoint for this project.
#
# Humans, agents, git hooks, and CI all run THIS FILE. The commands below are the
# only authoritative copy — AGENTS.md points here rather than restating them, so
# there is nothing to keep in sync.
#
# Fill in whichever apply. Leave the rest empty. Not every project has four checks:
# a Terraform repo has no typecheck, a Python CLI may have no build. An empty
# variable is skipped, not failed.

set -uo pipefail
cd "$(dirname "$0")/.." || exit 1

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

run_step lint      "$LINT"
run_step typecheck "$TYPECHECK"
run_step test      "$TEST"
run_step build     "$BUILD"

echo
if [ "$configured" -eq 0 ]; then
  echo "WARNING: no validation commands configured. This project has no deterministic"
  echo "gate. Fill in scripts/validate.sh before claiming any phase complete."
  exit 0
fi

if [ "$failed" -gt 0 ]; then
  echo "VALIDATION FAILED ($failed of $configured checks)"
  exit 1
fi

echo "VALIDATION PASSED ($configured checks)"
