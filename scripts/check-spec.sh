#!/usr/bin/env bash
#
# SPEC.md mechanical approval-readiness / approved-integrity checker.
#
# Contract marker:
#   CHECK_SPEC_CONTRACT_VERSION=1
#
# Usage:
#   bash scripts/check-spec.sh
#
# DRAFT:
#   non-zero means "not ready for approval yet", not a project build failure.
#
# APPROVED:
#   non-zero means the approved specification is mechanically inconsistent.
#
# POSIX-awk only: no GNU awk extensions are required.

set -euo pipefail

CHECK_SPEC_CONTRACT_VERSION=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SPEC_FILE="$ROOT_DIR/SPEC.md"

[[ -f "$SPEC_FILE" ]] || {
  printf 'FAIL: missing SPEC.md\n' >&2
  exit 1
}

set +e
awk '
  function trim(s) {
    sub(/^[[:space:]]+/, "", s)
    sub(/[[:space:]]+$/, "", s)
    return s
  }

  function add_issue(msg, weight) {
    if (weight == "") weight = 1
    issue_messages[++issue_message_count] = msg
    outstanding += weight
  }

  # Scan placeholder markers on one line.
  #
  #   {{TBD: description}}  -> complete placeholder
  #   {{TBD: description    -> malformed / unterminated marker
  #   `{{TBD:`              -> documentation reference; intentionally ignored
  #
  # Real placeholders never span lines. Counting is occurrence-based rather than
  # line-based, so multiple placeholders on one line are counted separately.
  #
  # Results are returned through scan_complete_tbd and scan_unterminated_tbd.
  function scan_tbd_markers(s,    doc_ref, token, pos, rest, close_pos, next_pos) {
    scan_complete_tbd = 0
    scan_unterminated_tbd = 0

    # Remove the one allowed bare documentation form before scanning.
    doc_ref = "`{{TBD:`"
    while ((pos = index(s, doc_ref)) > 0)
      s = substr(s, 1, pos - 1) substr(s, pos + length(doc_ref))

    token = "{{TBD:"

    while ((pos = index(s, token)) > 0) {
      rest = substr(s, pos + length(token))
      close_pos = index(rest, "}}")
      next_pos = index(rest, token)

      # A closing pair belongs to this marker only when it appears before another
      # marker starts. Otherwise this marker is malformed and scanning continues.
      if (close_pos > 0 && (next_pos == 0 || close_pos < next_pos)) {
        scan_complete_tbd++
        s = substr(rest, close_pos + length("}}"))
      } else {
        scan_unterminated_tbd++

        if (next_pos > 0)
          s = substr(rest, next_pos)
        else
          break
      }
    }
  }

  function money_cents(s,    parts) {
    split(s, parts, /\./)
    return (parts[1] + 0) * 100 + (parts[2] + 0)
  }

  function heading_key(line,    k) {
    if (line == "## Template Conventions") return "Template Conventions"
    if (line == "## 1. Project Controls") return "1"
    if (line == "## 2. Product") return "2"
    if (line == "## 3. Requirements") return "3"
    if (line == "## 4. Acceptance Criteria") return "4"
    if (line == "## 5. Out of Scope") return "5"
    if (line == "## 6. Constraints") return "6"
    if (line == "## 7. Architecture") return "7"
    if (line == "## 8. Repository Shape") return "8"
    if (line == "## 9. Data and State") return "9"
    if (line == "## 10. External Services and Dependencies") return "10"
    if (line == "## 11. UX / Design") return "11"
    if (line == "## 12. Security") return "12"
    if (line == "## 13. Deployment and Operations") return "13"
    if (line == "## 14. Important Decisions") return "14"
    if (line == "## 15. Open Questions") return "15"
    if (line == "## Approval") return "Approval"
    return ""
  }

  function section_number_from_key(k) {
    if (k ~ /^[0-9]+$/) return k + 0
    return 0
  }

  function is_conditional_section(n) {
    return (n >= 9 && n <= 13)
  }

  function extract_requirement_id(line,    s, a) {
    s = line
    sub(/^- `/, "", s)
    split(s, a, /`/)
    return a[1]
  }

  function extract_ac_id(line,    s, a) {
    s = line
    sub(/^### /, "", s)
    split(s, a, / — /)
    return a[1]
  }

  function parse_satisfies(line, ac,    s, n, parts, i, token, found) {
    s = line
    sub(/^\*\*Satisfies:\*\*[[:space:]]*/, "", s)
    gsub(/`/, "", s)
    gsub(/,/, " ", s)
    n = split(s, parts, /[[:space:]]+/)
    found = 0

    for (i = 1; i <= n; i++) {
      token = trim(parts[i])
      if (token ~ /^(REQ|NFR)-[0-9]+$/) {
        found++
        pair = ac SUBSEP token
        if (!ac_ref[pair])
          ac_ref_order[++ac_ref_count] = pair
        ac_ref[pair] = 1
        req_covered[token] = 1
      }
    }

    return found
  }

  # Split a markdown row while respecting escaped pipes (\|).
  # Returns the number of cells in mdcell[1..N].
  function split_md_row(line,    s, i, c, nextc, cell, count, escaped, k) {
    for (k in mdcell) delete mdcell[k]
    s = line

    if (substr(s, 1, 1) == "|") s = substr(s, 2)
    if (substr(s, length(s), 1) == "|") s = substr(s, 1, length(s) - 1)

    cell = ""
    count = 0
    escaped = 0

    for (i = 1; i <= length(s); i++) {
      c = substr(s, i, 1)

      if (escaped) {
        if (c == "|") {
          cell = cell "|"
        } else {
          cell = cell "\\" c
        }
        escaped = 0
        continue
      }

      if (c == "\\") {
        escaped = 1
        continue
      }

      if (c == "|") {
        mdcell[++count] = trim(cell)
        cell = ""
      } else {
        cell = cell c
      }
    }

    if (escaped) cell = cell "\\"
    mdcell[++count] = trim(cell)
    return count
  }

  BEGIN {
    heading_order[++required_heading_count] = "Template Conventions"
    heading_order[++required_heading_count] = "1"
    heading_order[++required_heading_count] = "2"
    heading_order[++required_heading_count] = "3"
    heading_order[++required_heading_count] = "4"
    heading_order[++required_heading_count] = "5"
    heading_order[++required_heading_count] = "6"
    heading_order[++required_heading_count] = "7"
    heading_order[++required_heading_count] = "8"
    heading_order[++required_heading_count] = "9"
    heading_order[++required_heading_count] = "10"
    heading_order[++required_heading_count] = "11"
    heading_order[++required_heading_count] = "12"
    heading_order[++required_heading_count] = "13"
    heading_order[++required_heading_count] = "14"
    heading_order[++required_heading_count] = "15"
    heading_order[++required_heading_count] = "Approval"

    for (i = 1; i <= required_heading_count; i++)
      required_heading[heading_order[i]] = 1

    current_section = 0
    current_ac = ""
  }

  {
    scan_tbd_markers($0)
    tbd_total += scan_complete_tbd
    unterminated_tbd_total += scan_unterminated_tbd
  }

  /^## / {
    key = heading_key($0)

    if (key != "") {
      heading_count[key]++
      current_section = section_number_from_key(key)
      if (key == "Approval") current_section = 100
      if (key == "Template Conventions") current_section = -1
    } else {
      # Unrecognized top-level headings are not rejected by this checker.
      # They still terminate the previous numbered section for parsing purposes.
      current_section = -2
    }

    current_ac = ""
    next
  }

  # Count subsections for the conditional N/A rule.
  /^### / {
    if (is_conditional_section(current_section))
      subsection_count[current_section]++

    if (current_section == 4 && $0 ~ /^### AC-[0-9]+ — /) {
      current_ac = extract_ac_id($0)
      if (!ac_exists[current_ac])
        ac_order[++ac_unique_count] = current_ac
      ac_heading_count[current_ac]++
      ac_exists[current_ac] = 1
      ac_total++
      next
    }

    if (current_section == 4)
      current_ac = ""

    next
  }

  # Project status is needed only to choose DRAFT-readiness vs APPROVED-integrity output.
  current_section == 1 && /^\*\*Status:\*\*/ {
    status_field_count++
    if ($0 == "**Status:** DRAFT") {
      spec_status = "DRAFT"
    } else if ($0 == "**Status:** APPROVED") {
      spec_status = "APPROVED"
    } else if (index($0, "{{TBD:") == 0) {
      status_invalid++
    }
    next
  }

  current_section == 1 && /^\*\*Spec revision:\*\*/ {
    revision_field_count++
    revision_raw = $0
    sub(/^\*\*Spec revision:\*\*[[:space:]]*/, "", revision_raw)

    if (revision_raw ~ /^[0-9]+$/) {
      revision_valid = 1
      spec_revision = revision_raw + 0
    } else if (index($0, "{{TBD:") == 0) {
      revision_invalid++
    }
    next
  }

  current_section == 1 && /^\*\*Monthly budget USD:\*\*/ {
    budget_field_count++
    budget_raw = $0
    sub(/^\*\*Monthly budget USD:\*\*[[:space:]]*/, "", budget_raw)

    if (budget_raw ~ /^[0-9]+\.[0-9][0-9]$/) {
      budget_valid = 1
      budget_cents = money_cents(budget_raw)
    } else if (index($0, "{{TBD:") == 0) {
      budget_invalid++
    }
    next
  }

  current_section == 1 && /^\*\*Entry:\*\*/ {
    entry_field_count++
    entry_raw = $0
    sub(/^\*\*Entry:\*\*[[:space:]]*/, "", entry_raw)

    if (entry_raw == "NEW" || entry_raw == "ADOPT") {
      entry_valid = 1
    } else if (index($0, "{{TBD:") == 0) {
      entry_invalid++
    }
    next
  }

  current_section == 1 && /^\*\*Rigor:\*\*/ {
    rigor_field_count++
    rigor_raw = $0
    sub(/^\*\*Rigor:\*\*[[:space:]]*/, "", rigor_raw)

    if (rigor_raw == "LEAN" || rigor_raw == "STANDARD" || rigor_raw == "STRICT") {
      rigor_valid = 1
    } else if (index($0, "{{TBD:") == 0) {
      rigor_invalid++
    }
    next
  }

  # Conditional applicability. A {{TBD: ...}} applicability line is already
  # represented by the reserved-marker failure, so do not double-report it.
  is_conditional_section(current_section) && /^\*\*Applicability:\*\*/ {
    applicability_line_count[current_section]++

    if ($0 == "**Applicability:** YES") {
      applicability[current_section] = "YES"
      applicability_valid_count[current_section]++
    } else if ($0 == "**Applicability:** N/A") {
      applicability[current_section] = "N/A"
      applicability_valid_count[current_section]++
    } else if (index($0, "{{TBD:") == 0) {
      applicability_invalid[current_section]++
    }
    next
  }

  # Requirements are defined only by the canonical bullets in §3.
  current_section == 3 && $0 ~ /^- `REQ-[0-9]+` — / {
    id = extract_requirement_id($0)
    if (!requirement_exists[id])
      requirement_order[++requirement_unique_count] = id
    requirement_count[id]++
    requirement_exists[id] = 1
    requirement_kind[id] = "REQ"
    next
  }

  current_section == 3 && $0 ~ /^- `NFR-[0-9]+` — / {
    id = extract_requirement_id($0)
    if (!requirement_exists[id])
      requirement_order[++requirement_unique_count] = id
    requirement_count[id]++
    requirement_exists[id] = 1
    requirement_kind[id] = "NFR"
    next
  }

  # Each AC owns exactly one Satisfies line mechanically.
  current_section == 4 && current_ac != "" && /^\*\*Satisfies:\*\*/ {
    satisfies_count[current_ac]++
    refs = parse_satisfies($0, current_ac)
    satisfies_valid_refs[current_ac] += refs
    next
  }

  # Open questions: a TBD-backed placeholder is already counted above, so do not
  # double-count that same fresh-template incompleteness.
  current_section == 15 && /^- \[ \]/ {
    if (index($0, "{{TBD:") == 0)
      unchecked_questions++
    next
  }

  # External-services table data rows. Parse rows only inside §10.
  current_section == 10 && /^\|/ {
    cols = split_md_row($0)

    # Header row.
    if (cols == 7 &&
        mdcell[1] == "Service" &&
        mdcell[2] == "Need" &&
        mdcell[3] == "Free Tier / Limit" &&
        mdcell[4] == "Estimated Monthly Cost USD" &&
        mdcell[5] == "Variable-Cost Risk" &&
        mdcell[6] == "Pricing Notes" &&
        mdcell[7] == "Alternative") {
      service_header_count++
      next
    }

    # Markdown separator row.
    separator = 1
    for (i = 1; i <= cols; i++) {
      c = trim(mdcell[i])
      if (c !~ /^:?-+:?$/) separator = 0
    }
    if (separator) {
      service_separator_count++
      next
    }

    service_row_count++
    row = service_row_count
    service_row_cols[row] = cols

    for (i = 1; i <= cols && i <= 7; i++)
      service_cell[row SUBSEP i] = mdcell[i]

    next
  }

  END {
    # Reserved placeholders are the canonical incompleteness token.
    if (tbd_total > 0)
      add_issue(tbd_total " complete {{TBD: ... }} placeholder(s) remain", tbd_total)
    if (unterminated_tbd_total > 0)
      add_issue(unterminated_tbd_total " unterminated placeholder marker(s) remain", unterminated_tbd_total)

    # Required structural headings: exactly one each.
    for (i = 1; i <= required_heading_count; i++) {
      key = heading_order[i]
      if (heading_count[key] == 0)
        add_issue("required top-level heading is missing: " key)
      else if (heading_count[key] > 1)
        add_issue("required top-level heading appears more than once: " key)
    }

    # Parser-critical project controls.
    if (status_field_count != 1)
      add_issue("§1 must contain exactly one Status field")
    else if (status_invalid > 0)
      add_issue("§1 Status must be DRAFT or APPROVED")

    if (revision_field_count != 1)
      add_issue("§1 must contain exactly one Spec revision field")
    else if (revision_invalid > 0 || !revision_valid)
      add_issue("Spec revision must be a non-negative integer")

    if (budget_field_count != 1)
      add_issue("§1 must contain exactly one Monthly budget USD field")
    else if (budget_invalid > 0 || !budget_valid)
      add_issue("Monthly budget USD must match ^[0-9]+\\.[0-9]{2}$")

    if (entry_field_count != 1)
      add_issue("§1 must contain exactly one Entry field")
    else if (entry_invalid > 0 || !entry_valid)
      add_issue("§1 Entry must be NEW or ADOPT")

    if (rigor_field_count != 1)
      add_issue("§1 must contain exactly one Rigor field")
    else if (rigor_invalid > 0 || !rigor_valid)
      add_issue("§1 Rigor must be LEAN, STANDARD, or STRICT")

    # A fresh project starts DRAFT at revision 0; the approval procedure requires
    # incrementing revision by exactly 1 on every DRAFT-to-APPROVED transition.
    # An APPROVED spec can therefore never legitimately sit at revision 0 -- that
    # state means the increment step of approval was skipped.
    if (spec_status == "APPROVED" && revision_valid && spec_revision < 1)
      add_issue("§1 Status is APPROVED but Spec revision is 0; approval must increment the revision to at least 1 (see Approval)")

    # Conditional sections 9-13.
    for (s = 9; s <= 13; s++) {
      if (applicability_line_count[s] != 1) {
        add_issue("§" s " must contain exactly one Applicability line")
      } else if (applicability_invalid[s] > 0) {
        add_issue("§" s " Applicability must be YES or N/A")
      } else if (applicability_valid_count[s] == 0) {
        # A TBD applicability was already counted as a reserved marker.
      } else if (applicability_valid_count[s] != 1) {
        add_issue("§" s " must contain exactly one valid Applicability value")
      }

      if (applicability[s] == "N/A" && subsection_count[s] > 0)
        add_issue("§" s " is N/A but still contains ### subsection content")
    }

    if (unchecked_questions > 0)
      add_issue(unchecked_questions " unchecked question(s) remain in §15", unchecked_questions)

    # Duplicate requirement IDs.
    for (i = 1; i <= requirement_unique_count; i++) {
      id = requirement_order[i]
      if (requirement_count[id] > 1)
        add_issue("duplicate requirement ID in §3: " id)
    }

    # Duplicate AC IDs and per-AC Satisfies integrity.
    for (i = 1; i <= ac_unique_count; i++) {
      ac = ac_order[i]
      if (ac_heading_count[ac] > 1)
        add_issue("duplicate acceptance criterion ID in §4: " ac)

      if (satisfies_count[ac] == 0)
        add_issue(ac " references no requirement")
      else if (satisfies_count[ac] > 1)
        add_issue(ac " contains more than one Satisfies line")
      else if (satisfies_valid_refs[ac] == 0)
        add_issue(ac " references no valid REQ-* or NFR-* ID")
    }

    # Every referenced requirement ID must exist.
    for (i = 1; i <= ac_ref_count; i++) {
      pair = ac_ref_order[i]
      split(pair, pieces, SUBSEP)
      ac = pieces[1]
      id = pieces[2]
      if (!requirement_exists[id])
        add_issue(ac " references requirement ID that does not exist: " id)
    }

    # Every REQ/NFR must be covered by at least one AC.
    for (i = 1; i <= requirement_unique_count; i++) {
      id = requirement_order[i]
      if (!req_covered[id])
        add_issue(id " lacks AC coverage")
    }

    # §10 service checks apply only when External Services is YES.
    if (applicability[10] == "YES") {
      if (service_header_count != 1)
        add_issue("§10 applicable service table must contain exactly one canonical header")
      if (service_separator_count < 1)
        add_issue("§10 applicable service table is missing its separator row")
      if (service_row_count == 0)
        add_issue("§10 Applicability is YES but the service table contains no service rows")

      for (row = 1; row <= service_row_count; row++) {
        if (service_row_cols[row] != 7) {
          add_issue("§10 service row " row " must contain exactly 7 columns")
          continue
        }

        service = trim(service_cell[row SUBSEP 1])
        need = trim(service_cell[row SUBSEP 2])
        free_limit = trim(service_cell[row SUBSEP 3])
        cost = trim(service_cell[row SUBSEP 4])
        risk = trim(service_cell[row SUBSEP 5])
        notes = trim(service_cell[row SUBSEP 6])
        alternative = trim(service_cell[row SUBSEP 7])

        if (service == "") add_issue("§10 service row " row " is missing Service")
        if (need == "") add_issue("§10 service row " row " is missing Need")
        if (free_limit == "") add_issue("§10 service row " row " is missing Free Tier / Limit")
        if (alternative == "") add_issue("§10 service row " row " is missing Alternative")

        if (cost == "") {
          add_issue("§10 service row " row " is missing Estimated Monthly Cost USD")
        } else if (cost !~ /^[0-9]+\.[0-9][0-9]$/) {
          add_issue("§10 service row " row " cost must match ^[0-9]+\\.[0-9]{2}$")
        } else {
          service_cost_cents += money_cents(cost)
        }

        if (risk != "LOW" && risk != "MEDIUM" && risk != "HIGH") {
          add_issue("§10 service row " row " Variable-Cost Risk must be LOW, MEDIUM, or HIGH")
        } else if ((risk == "MEDIUM" || risk == "HIGH") && notes == "") {
          add_issue("§10 service row " row " has " risk " Variable-Cost Risk but empty Pricing Notes")
        }
      }

      if (budget_valid && service_cost_cents > budget_cents) {
        add_issue("summed Estimated Monthly Cost USD exceeds Monthly budget USD")
      }
    }

    # Choose message semantics. If Status itself is malformed/missing, use FAIL because
    # the checker cannot safely classify the file as DRAFT readiness vs approved integrity.
    if (outstanding > 0) {
      if (spec_status == "DRAFT") {
        print "NOT READY FOR APPROVAL — " outstanding " item(s) outstanding." > "/dev/stderr"
      } else if (spec_status == "APPROVED") {
        print "FAIL: approved SPEC integrity check found " outstanding " issue(s)." > "/dev/stderr"
      } else {
        print "FAIL: SPEC mechanical check found " outstanding " issue(s)." > "/dev/stderr"
      }

      for (i = 1; i <= issue_message_count; i++)
        print "  - " issue_messages[i] > "/dev/stderr"

      exit 1
    }

    print "CHECK_SPEC_CONTRACT_VERSION=1"

    if (spec_status == "DRAFT")
      print "READY FOR HUMAN APPROVAL — mechanical checks passed."
    else
      print "PASS: approved SPEC integrity passed."
  }
' "$SPEC_FILE"
RC=$?
set -e

exit "$RC"
