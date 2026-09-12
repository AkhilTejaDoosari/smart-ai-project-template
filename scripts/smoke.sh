#!/usr/bin/env bash
# Expensive packaging/deployment smoke entrypoint. Separate from scripts/validate.sh.
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CONF="$ROOT_DIR/.framework/smoke.conf"
[[ -f "$CONF" ]] || { echo "FAIL: missing .framework/smoke.conf" >&2; exit 1; }

# Validate the registry before executing anything. Pipelines/literal pipes belong in a project script.
if ! awk -F'|' '
function trim(s){sub(/^[[:space:]]+/,"",s);sub(/[[:space:]]+$/, "",s);return s}
/^[[:space:]]*#/ || /^[[:space:]]*$/ {next}
{
  if(NF!=3){print "FAIL: invalid smoke.conf record (expected 3 fields): " $0 > "/dev/stderr";bad=1;next}
  name=trim($1);path=trim($2);cmd=trim($3)
  if(name==""||path==""||cmd==""){print "FAIL: smoke gate requires non-empty name, path, and command: " $0 > "/dev/stderr";bad=1}
  if(path ~ /^\// || path ~ /(^|\/)\.\.(\/|$)/){print "FAIL: smoke gate path must stay repository-relative: " path > "/dev/stderr";bad=1}
  if(seen[name]++){print "FAIL: duplicate smoke gate name: " name > "/dev/stderr";bad=1}
}
END{if(bad)exit 1}
' "$CONF"; then
  exit 1
fi

count=0;failed=0
while IFS='|' read -r name path cmd; do
  [[ -n "$name" ]] || continue
  case "$name" in \#*) continue;; esac
  count=$((count+1))
  if [[ ! -d "$ROOT_DIR/$path" ]]; then
    echo "FAIL  smoke/$name path does not exist: $path"
    failed=$((failed+1))
    continue
  fi
  echo "RUN   smoke/$name: $cmd"
  if (cd "$ROOT_DIR/$path" && eval "$cmd"); then echo "PASS  smoke/$name"; else echo "FAIL  smoke/$name";failed=$((failed+1));fi
done < "$CONF"
if [[ "$count" -eq 0 ]]; then echo "SMOKE: NOT CONFIGURED"; exit 2; fi
[[ "$failed" -eq 0 ]] || { echo "SMOKE: FAIL"; exit 1; }
echo "SMOKE: PASS ($count gate(s))"
