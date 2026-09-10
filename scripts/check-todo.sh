#!/usr/bin/env bash
#
# Deterministic TODO.md structural and cross-file integrity checker.
#
# Contract marker:
#   CHECK_TODO_CONTRACT_VERSION=1
#
# Usage:
#   bash scripts/check-todo.sh
#
# This script observes state only. It never mutates TODO.md or SPEC.md.

set -euo pipefail

CHECK_TODO_CONTRACT_VERSION=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SPEC_FILE="$ROOT_DIR/SPEC.md"
TODO_FILE="$ROOT_DIR/TODO.md"

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

[[ -f "$SPEC_FILE" ]] || fail "missing SPEC.md"
[[ -f "$TODO_FILE" ]] || fail "missing TODO.md"

SPEC_STATUS_COUNT="$(grep -Ec '^\*\*Status:\*\* (DRAFT|APPROVED)$' "$SPEC_FILE" || true)"
[[ "$SPEC_STATUS_COUNT" -eq 1 ]] || fail "SPEC.md must contain exactly one valid project Status field"
SPEC_STATUS="$(sed -n 's/^\*\*Status:\*\* \(DRAFT\|APPROVED\)$/\1/p' "$SPEC_FILE")"

SPEC_REV_COUNT="$(grep -Ec '^\*\*Spec revision:\*\* [0-9]+$' "$SPEC_FILE" || true)"
[[ "$SPEC_REV_COUNT" -eq 1 ]] || fail "SPEC.md must contain exactly one non-negative integer Spec revision"
SPEC_REV="$(sed -n 's/^\*\*Spec revision:\*\* \([0-9][0-9]*\)$/\1/p' "$SPEC_FILE")"

set +e
awk -v spec="$SPEC_FILE" -v todo="$TODO_FILE" -v spec_status="$SPEC_STATUS" -v spec_rev="$SPEC_REV" '
  function issue(msg) {
    errors++
    print "FAIL: " msg > "/dev/stderr"
  }

  function trim(s) {
    sub(/^[[:space:]]+/, "", s)
    sub(/[[:space:]]+$/, "", s)
    return s
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

  function phase_label(p) {
    return "Phase " p
  }

  function field_value(line, key,    prefix) {
    prefix = key ": "
    if (index(line, prefix) == 1) return substr(line, length(prefix) + 1)
    return ""
  }

  function add_field(p, key, value, inside_state,    fk) {
    fk = p SUBSEP key
    field_count[fk]++
    field_value_map[fk] = value
    if (!inside_state) field_outside[fk]++
  }

  function add_dependency(p, d) {
    edge[p SUBSEP d] = 1
    dep_count[p]++
  }

  FILENAME == spec {
    if ($0 ~ /^### AC-[0-9]+ — /) {
      line = $0
      sub(/^### /, "", line)
      split(line, parts, / — /)
      id = parts[1]
      if (ac_exists[id]) issue("SPEC.md contains duplicate acceptance criterion " id)
      ac_exists[id] = 1
      ac_total++
    }
    next
  }

  FILENAME != todo { next }

  {
    scan_tbd_markers($0)
    todo_tbd += scan_complete_tbd
    todo_unterminated_tbd += scan_unterminated_tbd
  }

  /^### Phase [1-9][0-9]* — / {
    line = $0
    sub(/^### Phase /, "", line)
    split(line, parts, / — /)
    p = parts[1] + 0
    current = p
    section = ""
    in_state = 0
    seen_subheading = 0

    heading_count[p]++
    if (!phase_exists[p]) {
      phase_exists[p] = 1
      unique_phase_total++
    }

    if (heading_count[p] > 1) issue("duplicate phase heading for Phase " p)

    name = $0
    sub(/^### Phase [1-9][0-9]* — /, "", name)
    if (trim(name) == "") issue("Phase " p " has an empty name")
    next
  }

  current == 0 { next }

  /^```text[[:space:]]*$/ {
    if (!seen_subheading) {
      state_fence_count[current]++
      if (in_state) issue(phase_label(current) " has nested state fences")
      in_state = 1
      next
    }
  }

  /^```[[:space:]]*$/ {
    if (in_state) {
      in_state = 0
      state_fence_closed[current]++
      next
    }
  }

  /^#### / {
    seen_subheading = 1
    in_state = 0
    section = $0
    sub(/^#### /, "", section)
    section_count[current SUBSEP section]++
    next
  }

  /^---[[:space:]]*$/ {
    in_state = 0
    section = ""
    next
  }

  {
    if (index($0, "Status: ") == 1) {
      add_field(current, "Status", field_value($0, "Status"), in_state)
      next
    }
    if (index($0, "Mode: ") == 1) {
      add_field(current, "Mode", field_value($0, "Mode"), in_state)
      next
    }
    if (index($0, "Depends on: ") == 1) {
      add_field(current, "Depends on", field_value($0, "Depends on"), in_state)
      next
    }
    if (index($0, "Defined against: ") == 1) {
      add_field(current, "Defined against", field_value($0, "Defined against"), in_state)
      next
    }
    if (index($0, "Completed against: ") == 1) {
      add_field(current, "Completed against", field_value($0, "Completed against"), in_state)
      next
    }
    if (index($0, "AUTO iteration budget: ") == 1) {
      add_field(current, "AUTO iteration budget", field_value($0, "AUTO iteration budget"), in_state)
      next
    }

    if (in_state && trim($0) != "") {
      state_extra[current]++
      next
    }

    if (section == "Agenda" && trim($0) != "") {
      agenda_nonempty[current]++
    }

    if (section == "Acceptance Coverage") {
      if ($0 ~ /^- `AC-[0-9]+`[[:space:]]*$/) {
        id = $0
        sub(/^- `/, "", id)
        sub(/`[[:space:]]*$/, "", id)
        ac_ref[current SUBSEP id] = 1
        ac_owned[id] = 1
      } else if (index($0, "AC-") > 0 && trim($0) != "") {
        bad_ac_syntax[current]++
      }
    }

    if (section == "To-do list") {
      if ($0 ~ /^- \[[ xX]\][[:space:]]+/) {
        task_total[current]++
      } else if ($0 ~ /^- \[[ xX]\]([^[:space:]]|$)/) {
        bad_task_syntax[current]++
      }
    }

    if (section == "Blocker" && trim($0) != "") {
      blocker_lines[current]++
      if (trim($0) == "None") blocker_none[current]++
      else blocker_detail[current]++
    }
  }

  END {
    if (unique_phase_total == 0) issue("TODO.md contains no phase headings")

    for (p in phase_exists) {
      if (state_fence_count[p] != 1 || state_fence_closed[p] != 1)
        issue(phase_label(p) " must contain exactly one closed ```text state block before its subsections")
      if (state_extra[p] != 0)
        issue(phase_label(p) " state block contains unexpected non-field content")

      split("Status|Mode|Depends on|Defined against|Completed against|AUTO iteration budget", keys, /\|/)
      for (i = 1; i <= 6; i++) {
        k = keys[i]
        fk = p SUBSEP k
        if (field_count[fk] != 1)
          issue(phase_label(p) " must contain exactly one " k " field")
        if (field_outside[fk] != 0)
          issue(phase_label(p) " has " k " outside the canonical state block")
      }

      status[p] = field_value_map[p SUBSEP "Status"]
      mode[p] = field_value_map[p SUBSEP "Mode"]
      deps[p] = field_value_map[p SUBSEP "Depends on"]
      defined[p] = field_value_map[p SUBSEP "Defined against"]
      completed[p] = field_value_map[p SUBSEP "Completed against"]
      budget[p] = field_value_map[p SUBSEP "AUTO iteration budget"]

      if (status[p] != "Not Started" && status[p] != "In Progress" &&
          status[p] != "Blocked" && status[p] != "Done")
        issue(phase_label(p) " has invalid Status: " status[p])

      if (todo_unterminated_tbd != 0)
      issue("TODO.md contains " todo_unterminated_tbd " unterminated placeholder marker(s)")

    if (spec_status == "APPROVED") {
        if (mode[p] != "MANUAL" && mode[p] != "AUTO")
          issue(phase_label(p) " has invalid Mode: " mode[p])

        if (mode[p] == "MANUAL" && budget[p] != "—")
          issue(phase_label(p) " is MANUAL and must use AUTO iteration budget: —")
        if (mode[p] == "AUTO" && budget[p] !~ /^[1-9][0-9]*$/)
          issue(phase_label(p) " is AUTO and must use a positive integer AUTO iteration budget")
      }

      if (status[p] == "Not Started") {
        if (defined[p] != "—")
          issue(phase_label(p) " is Not Started and must have Defined against: —")
        if (completed[p] != "—")
          issue(phase_label(p) " is Not Started and must have Completed against: —")
      }

      if (status[p] == "In Progress" || status[p] == "Blocked") {
        if (defined[p] !~ /^Spec revision [0-9]+$/)
          issue(phase_label(p) " is " status[p] " and must have Defined against: Spec revision N")
        if (completed[p] != "—")
          issue(phase_label(p) " is " status[p] " and must have Completed against: —")
      }

      if (status[p] == "Done") {
        if (defined[p] !~ /^Spec revision [0-9]+$/)
          issue(phase_label(p) " is Done and has malformed Defined against")
        if (completed[p] !~ /^Spec revision [0-9]+$/)
          issue(phase_label(p) " is Done and has malformed Completed against")

        d = defined[p]
        c = completed[p]
        sub(/^Spec revision /, "", d)
        sub(/^Spec revision /, "", c)
        if (d ~ /^[0-9]+$/ && c ~ /^[0-9]+$/ && (c + 0) < (d + 0))
          issue(phase_label(p) " completion revision predates its defined revision")
        if (c ~ /^[0-9]+$/ && (c + 0) > (spec_rev + 0))
          issue(phase_label(p) " completion revision is newer than current SPEC revision")
      }

      split("Agenda|Acceptance Coverage|To-do list|Blocker", sections, /\|/)
      for (i = 1; i <= 4; i++) {
        s = sections[i]
        if (section_count[p SUBSEP s] != 1)
          issue(phase_label(p) " must contain exactly one #### " s " section")
      }
      if (agenda_nonempty[p] == 0)
        issue(phase_label(p) " Agenda is empty")
      if (bad_task_syntax[p] != 0)
        issue(phase_label(p) " has task checkbox syntax without required whitespace after ]")
      if (task_total[p] == 0 && bad_task_syntax[p] == 0)
        issue(phase_label(p) " To-do list contains no task checkboxes")
      if (spec_status == "APPROVED" && bad_ac_syntax[p] != 0)
        issue(phase_label(p) " Acceptance Coverage contains malformed AC reference syntax")

      if (blocker_lines[p] == 0)
        issue(phase_label(p) " Blocker section is empty")
      if (status[p] == "Blocked") {
        if (blocker_detail[p] == 0 || blocker_none[p] != 0)
          issue(phase_label(p) " is Blocked and must describe the blocking condition instead of None")
      } else {
        if (blocker_lines[p] != 1 || blocker_none[p] != 1)
          issue(phase_label(p) " is not Blocked and its Blocker section must be exactly None")
      }

      if (spec_status == "APPROVED") {
        if (deps[p] == "None") {
          # no dependencies
        } else {
          raw = deps[p]
          n = split(raw, dep_parts, /,[[:space:]]*/)
          if (n == 0) issue(phase_label(p) " has malformed Depends on")
          for (i = 1; i <= n; i++) {
            item = trim(dep_parts[i])
            if (item !~ /^Phase [1-9][0-9]*$/) {
              issue(phase_label(p) " has malformed dependency: " item)
              continue
            }
            dnum = item
            sub(/^Phase /, "", dnum)
            dnum += 0
            add_dependency(p, dnum)
            if (dnum == p) issue(phase_label(p) " depends on itself")
          }
        }
      }
    }

    if (spec_status == "APPROVED") {
      for (e in edge) {
        split(e, pair, SUBSEP)
        p = pair[1]
        d = pair[2]
        if (!phase_exists[d]) {
          issue(phase_label(p) " depends on missing Phase " d)
          continue
        }

        if ((status[p] == "In Progress" || status[p] == "Blocked" || status[p] == "Done") &&
            status[d] != "Done")
          issue(phase_label(p) " is " status[p] " but dependency Phase " d " is " status[d] " (must be Done)")
      }

      for (p in phase_exists) {
        indegree[p] = 0
        removed[p] = 0
      }
      for (e in edge) {
        split(e, pair, SUBSEP)
        if (phase_exists[pair[1]] && phase_exists[pair[2]])
          indegree[pair[1]]++
      }

      processed = 0
      changed = 1
      while (changed) {
        changed = 0
        for (p in phase_exists) {
          if (!removed[p] && indegree[p] == 0) {
            removed[p] = 1
            processed++
            changed = 1
            for (e in edge) {
              split(e, pair, SUBSEP)
              if (pair[2] == p && phase_exists[pair[1]] && !removed[pair[1]])
                indegree[pair[1]]--
            }
          }
        }
      }
      if (processed != unique_phase_total)
        issue("phase dependency graph contains a cycle")

      for (r in ac_ref) {
        split(r, pair, SUBSEP)
        p = pair[1]
        id = pair[2]
        if (!ac_exists[id])
          issue(phase_label(p) " references acceptance criterion " id " which does not exist in SPEC.md")
      }

      if (todo_tbd != 0)
        issue("TODO.md contains " todo_tbd " complete {{TBD: ... }} placeholder(s) while SPEC.md is APPROVED")
      for (id in ac_exists) {
        if (!ac_owned[id])
          issue("approved acceptance criterion " id " is not owned by any TODO phase")
      }
    }

    if (errors != 0) {
      print "FAIL: TODO integrity check found " errors " issue(s)." > "/dev/stderr"
      exit 1
    }

    print "CHECK_TODO_CONTRACT_VERSION=1"
    if (spec_status == "DRAFT")
      print "PASS: TODO structure passed (SPEC DRAFT; semantic planning checks deferred, " unique_phase_total " phase(s))."
    else
      print "PASS: TODO integrity passed (" unique_phase_total " phase(s), " ac_total " acceptance criterion/criteria in SPEC)."
  }
' "$SPEC_FILE" "$TODO_FILE"
RC=$?
set -e

exit "$RC"
