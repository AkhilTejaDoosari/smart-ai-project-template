#!/usr/bin/env bash
# Single FAST/NORMAL validation entrypoint.
# Exit 0 = configured validation passed
# Exit 1 = framework/surface/runtime/project validation failed
# Exit 2 = pre-scaffold: framework is valid and there are no registered/detected project surfaces yet

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CONF="$ROOT_DIR/.framework/validation.conf"
FRAMEWORK="$SCRIPT_DIR/check-framework.sh"
SURFACES="$SCRIPT_DIR/check-validation-surfaces.sh"

cd "$ROOT_DIR" || exit 1

if ! bash "$FRAMEWORK"; then
  echo
  echo "OVERALL: FAIL (framework integrity)"
  exit 1
fi

echo
SURFACE_OUTPUT="$(mktemp "${TMPDIR:-/tmp}/surface-check.XXXXXX")"
trap 'rm -f "$SURFACE_OUTPUT"' EXIT HUP INT TERM
if ! bash "$SURFACES" >"$SURFACE_OUTPUT" 2>&1; then
  cat "$SURFACE_OUTPUT"
  echo "OVERALL: FAIL (validation surface coverage)"
  exit 1
fi
cat "$SURFACE_OUTPUT"
DETECTED="$(awk -F= '/^DETECTED_SURFACES=/{print $2}' "$SURFACE_OUTPUT")"
REGISTERED="$(awk -F= '/^REGISTERED_SURFACES=/{print $2}' "$SURFACE_OUTPUT")"

if [[ "${REGISTERED:-0}" -eq 0 && "${DETECTED:-0}" -eq 0 ]]; then
  echo
  echo "FRAMEWORK: PASS"
  echo "PROJECT SURFACES: NONE DETECTED"
  echo "PROJECT VALIDATION: NOT CONFIGURED"
  echo "OVERALL: PRE-SCAFFOLD"
  exit 2
fi

failed=0
configured_steps=0

echo
echo "--- Registered project surfaces ---"

while IFS='|' read -r name path runtime lint typecheck test build; do
  [[ -n "$name" ]] || continue
  case "$name" in \#*) continue;; esac
  if [[ ! -d "$ROOT_DIR/$path" ]]; then
    echo "FAIL  $name path does not exist: $path"
    failed=$((failed+1))
    continue
  fi
  echo "SURFACE $name ($path)"
  cd "$ROOT_DIR/$path" || { failed=$((failed+1)); cd "$ROOT_DIR"; continue; }
  for pair in "runtime|$runtime" "lint|$lint" "typecheck|$typecheck" "test|$test" "build|$build"; do
    step="${pair%%|*}"; cmd="${pair#*|}"
    if [[ -z "$cmd" ]]; then
      echo "SKIP  $name/$step (not applicable)"
      continue
    fi
    configured_steps=$((configured_steps+1))
    echo "RUN   $name/$step: $cmd"
    if eval "$cmd"; then echo "PASS  $name/$step"; else echo "FAIL  $name/$step"; failed=$((failed+1)); fi
  done
  cd "$ROOT_DIR" || exit 1
done < "$CONF"

echo
if [[ "$failed" -gt 0 ]]; then
  echo "PROJECT VALIDATION: FAIL"
  echo "OVERALL: FAIL"
  exit 1
fi
if [[ "$configured_steps" -eq 0 ]]; then
  echo "PROJECT VALIDATION: FAIL (registered surfaces have no executable checks)"
  echo "OVERALL: FAIL"
  exit 1
fi

echo "FRAMEWORK: PASS"
echo "PROJECT VALIDATION: PASS ($configured_steps configured check(s))"
echo "OVERALL: PASS"
exit 0
