#!/usr/bin/env bash
#
# Authorized SPEC.md state transition: DRAFT -> APPROVED.
#
# This is the human's approval action. Running this script IS the approval --
# there is no separate manual edit to forget. It reads the current Spec revision
# and atomically writes current+1 alongside Status: APPROVED, so the revision
# increment can never be skipped the way a two-field hand edit could be.
#
# Usage:
#   bash scripts/approve-spec.sh
#
# This script does NOT perform the human/engineering judgment gate (do the
# requirements represent the intended product, is the architecture sufficient,
# etc.) -- that judgment happens before you run this. This script only performs
# the mechanical half: verify readiness, then atomically transition.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SPEC_FILE="$ROOT_DIR/SPEC.md"
CHECK_SPEC_SCRIPT="$SCRIPT_DIR/check-spec.sh"
TMP_FILE=""

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
pass() { printf 'PASS: %s\n' "$*"; }
info() { printf 'INFO: %s\n' "$*"; }

cleanup() {
  [[ -z "${TMP_FILE:-}" || ! -f "$TMP_FILE" ]] || rm -f "$TMP_FILE"
}
trap cleanup EXIT HUP INT TERM

[[ -f "$SPEC_FILE" ]] || fail "missing SPEC.md"
[[ -f "$CHECK_SPEC_SCRIPT" ]] || fail "missing scripts/check-spec.sh"

STATUS_COUNT="$(grep -Ec '^\*\*Status:\*\* (DRAFT|APPROVED)$' "$SPEC_FILE" || true)"
[[ "$STATUS_COUNT" -eq 1 ]] || fail "SPEC.md must contain exactly one valid Status field"
STATUS="$(sed -n 's/^\*\*Status:\*\* \(DRAFT\|APPROVED\)$/\1/p' "$SPEC_FILE")"
[[ "$STATUS" == "DRAFT" ]] || fail "SPEC.md Status must be DRAFT to approve; current status is '$STATUS'"

REV_COUNT="$(grep -Ec '^\*\*Spec revision:\*\* [0-9]+$' "$SPEC_FILE" || true)"
[[ "$REV_COUNT" -eq 1 ]] || fail "SPEC.md must contain exactly one non-negative integer Spec revision"
CURRENT_REV="$(sed -n 's/^\*\*Spec revision:\*\* \([0-9][0-9]*\)$/\1/p' "$SPEC_FILE")"
NEW_REV=$((CURRENT_REV + 1))

info "Checking mechanical readiness..."
if ! bash "$CHECK_SPEC_SCRIPT"; then
  fail "SPEC.md is not mechanically ready for approval; see the output above."
fi
pass "Mechanical readiness confirmed."

info "This invocation attests that the human/engineering judgment gate (does the"
info "architecture satisfy the requirements, is the cost acceptable, etc.) has"
info "been completed. This script does not and cannot verify that judgment."

TMP_FILE="$(mktemp "${SPEC_FILE}.tmp.XXXXXX")"
cp -p "$SPEC_FILE" "$TMP_FILE"

if ! awk -v new_rev="$NEW_REV" '
  $0 == "**Status:** DRAFT" {
    if (status_changed) exit 41
    print "**Status:** APPROVED"
    status_changed = 1
    next
  }
  /^\*\*Spec revision:\*\* [0-9]+$/ {
    if (revision_changed) exit 42
    print "**Spec revision:** " new_rev
    revision_changed = 1
    next
  }
  { print }
  END {
    if (status_changed != 1 || revision_changed != 1) exit 43
  }
' "$SPEC_FILE" > "$TMP_FILE"; then
  fail "could not construct the atomic SPEC.md update; original file is unchanged"
fi

NEW_STATUS="$(sed -n 's/^\*\*Status:\*\* \(DRAFT\|APPROVED\)$/\1/p' "$TMP_FILE")"
NEW_REV_CHECK="$(sed -n 's/^\*\*Spec revision:\*\* \([0-9][0-9]*\)$/\1/p' "$TMP_FILE")"
[[ "$NEW_STATUS" == "APPROVED" ]] || fail "replacement verification failed: Status is not APPROVED"
[[ "$NEW_REV_CHECK" == "$NEW_REV" ]] || fail "replacement verification failed: revision is not $NEW_REV"

mv -f "$TMP_FILE" "$SPEC_FILE"
TMP_FILE=""

info "Re-verifying integrity of the now-APPROVED spec..."
if ! bash "$CHECK_SPEC_SCRIPT"; then
  fail "SPEC.md failed integrity check immediately after approval; this should not happen. Investigate before proceeding."
fi

pass "SPEC.md approved: Spec revision $CURRENT_REV -> $NEW_REV, Status: APPROVED."
