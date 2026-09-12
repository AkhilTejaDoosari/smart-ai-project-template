#!/usr/bin/env bash
# Verify that every detected executable project surface is registered for normal validation or explicitly ignored.
# Portable contract: Bash 3.2+, POSIX awk/find/sort.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CONF="$ROOT_DIR/.framework/validation.conf"
IGNORE="$ROOT_DIR/.framework/validation-ignore.txt"

fail(){ printf 'FAIL: %s\n' "$*" >&2; exit 1; }
[[ -f "$CONF" ]] || fail "missing .framework/validation.conf"
[[ -f "$IGNORE" ]] || fail "missing .framework/validation-ignore.txt"

TMP_DETECTED="$(mktemp "${TMPDIR:-/tmp}/validation-detected.XXXXXX")"
TMP_REGISTERED="$(mktemp "${TMPDIR:-/tmp}/validation-registered.XXXXXX")"
TMP_IGNORED="$(mktemp "${TMPDIR:-/tmp}/validation-ignored.XXXXXX")"
cleanup(){ rm -f "$TMP_DETECTED" "$TMP_REGISTERED" "$TMP_IGNORED"; }
trap cleanup EXIT HUP INT TERM

cd "$ROOT_DIR"

# One repository-relative root per manifest/tool surface. Exclude framework fixtures and dependency caches.
find . \
  \( -path './.git' -o -path './node_modules' -o -path './.framework' -o -path './tests/framework' -o -path './.venv' -o -path './venv' \) -prune -o \
  -type f \( -name package.json -o -name pyproject.toml -o -name go.mod -o -name Cargo.toml -o -name pom.xml -o -name build.gradle -o -name build.gradle.kts \) -print |
awk '{sub(/^\.\//,""); sub("/[^/]+$",""); if($0=="")$0="."; print}' > "$TMP_DETECTED"

# Terraform directories are executable project surfaces even without a package manifest.
find . \
  \( -path './.git' -o -path './node_modules' -o -path './.framework' -o -path './tests/framework' -o -path './.venv' -o -path './venv' \) -prune -o \
  -type f -name '*.tf' -print |
awk '{sub(/^\.\//,""); sub("/[^/]+$",""); if($0=="")$0="."; print}' >> "$TMP_DETECTED"

sort -u "$TMP_DETECTED" -o "$TMP_DETECTED"

awk -F'|' '
  /^[[:space:]]*#/ || /^[[:space:]]*$/ {next}
  NF != 7 {print "FAIL: invalid validation.conf record (expected 7 fields): " $0 > "/dev/stderr"; bad=1; next}
  {
    name=$1;path=$2;runtime=$3
    if(name==""||path==""){print "FAIL: validation surface requires non-empty name and path: " $0 > "/dev/stderr";bad=1;next}
    if(path ~ /^\// || path ~ /(^|\/)\.\.(\/|$)/){print "FAIL: validation surface path must stay repository-relative: " path > "/dev/stderr";bad=1}
    if(runtime==""){print "FAIL: validation surface " name " must define runtime_check" > "/dev/stderr";bad=1}
    if($4==""&&$5==""&&$6==""&&$7==""){print "FAIL: validation surface " name " must configure at least one project check (lint/typecheck/test/build)" > "/dev/stderr";bad=1}
    if(seen_name[name]++){print "FAIL: duplicate validation surface name: " name > "/dev/stderr";bad=1}
    if(seen_path[path]++){print "FAIL: duplicate validation surface path: " path > "/dev/stderr";bad=1}
    print path
  }
  END{if(bad)exit 1}
' "$CONF" > "$TMP_REGISTERED" || exit 1

awk '/^[[:space:]]*#/ || /^[[:space:]]*$/{next}{gsub(/^[[:space:]]+|[[:space:]]+$/,"",$0);print}' "$IGNORE" | sort -u > "$TMP_IGNORED"
sort -u "$TMP_REGISTERED" -o "$TMP_REGISTERED"

missing=0
while IFS= read -r path; do
  [[ -n "$path" ]] || continue
  if ! grep -Fqx "$path" "$TMP_REGISTERED" && ! grep -Fqx "$path" "$TMP_IGNORED"; then
    printf 'FAIL: detected executable surface is not registered or ignored: %s\n' "$path" >&2
    missing=1
  fi
done < "$TMP_DETECTED"

if [[ "$missing" -ne 0 ]]; then
  echo "FAIL: update .framework/validation.conf when a new executable surface appears." >&2
  exit 1
fi

DETECTED_COUNT="$(awk 'NF{n++}END{print n+0}' "$TMP_DETECTED")"
REGISTERED_COUNT="$(awk 'NF{n++}END{print n+0}' "$TMP_REGISTERED")"

echo "CHECK_VALIDATION_SURFACES_CONTRACT_VERSION=1"
echo "DETECTED_SURFACES=$DETECTED_COUNT"
echo "REGISTERED_SURFACES=$REGISTERED_COUNT"
echo "PASS: validation surface coverage is explicit."
