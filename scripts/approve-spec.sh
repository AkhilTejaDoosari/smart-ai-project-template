#!/usr/bin/env bash
# Authorized atomic SPEC transition: DRAFT rev N -> APPROVED rev N+1.
# The human/engineering semantic gate must be completed before invoking this script.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SPEC="$ROOT_DIR/SPEC.md"
CHECK="$SCRIPT_DIR/check-spec.sh"
TMP=""
cleanup(){ [[ -z "${TMP:-}" || ! -f "$TMP" ]] || rm -f "$TMP"; }
trap cleanup EXIT HUP INT TERM
fail(){ printf 'FAIL: %s\n' "$*" >&2; exit 1; }

[[ -f "$SPEC" ]] || fail "missing SPEC.md"
[[ -f "$CHECK" ]] || fail "missing scripts/check-spec.sh"
STATUS="$(awk '/^\*\*Status:\*\* (DRAFT|APPROVED)$/{c++;v=$0;sub(/^\*\*Status:\*\* /,"",v)}END{if(c==1)print v}' "$SPEC")"
[[ "$STATUS" == "DRAFT" ]] || fail "SPEC.md must contain exactly one Status: DRAFT to approve"
REV="$(awk '/^\*\*Spec revision:\*\* [0-9]+$/{c++;v=$0;sub(/^\*\*Spec revision:\*\* /,"",v)}END{if(c==1)print v}' "$SPEC")"
[[ "$REV" =~ ^[0-9]+$ ]] || fail "SPEC.md must contain exactly one non-negative Spec revision"
NEW=$((REV+1))

echo "INFO: checking mechanical readiness..."
bash "$CHECK" || fail "SPEC.md is not mechanically ready for approval"
echo "INFO: invocation attests that the semantic/human approval gate is complete."

TMP="$(mktemp "${SPEC}.tmp.XXXXXX")"
cp -p "$SPEC" "$TMP"
awk -v new="$NEW" '
$0=="**Status:** DRAFT"{if(s++)exit 41;print "**Status:** APPROVED";next}
/^\*\*Spec revision:\*\* [0-9]+$/{if(r++)exit 42;print "**Spec revision:** " new;next}
{print}
END{if(s!=1||r!=1)exit 43}
' "$SPEC" > "$TMP" || fail "could not construct atomic SPEC update"
mv -f "$TMP" "$SPEC"; TMP=""

bash "$CHECK" || fail "approved SPEC failed immediate integrity re-check"
echo "PASS: SPEC.md approved: Spec revision $REV -> $NEW."
