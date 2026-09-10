# SPEC.md

Current project truth.

This file defines what the project is, what it must do, and the constraints under
which it must be built.

Execution state belongs in `TODO.md`.
Reusable procedures belong in `WORKFLOW.md`.
Permanent agent rules belong in `AGENTS.md`.
Historical changes belong in Git.

## Template Conventions

Incomplete content uses exactly one reserved marker:

```text
{{TBD: description}}
```

No other placeholder syntax is permitted. `{{TBD:` must not appear in an approved
specification.

Keep all numbered top-level headings. Mechanical checks address them by name, so a
deleted heading breaks the check rather than simplifying the file.

Conditional sections declare applicability:

```text
**Applicability:** YES
```

or:

```text
**Applicability:** N/A
```

When a section is `N/A`, remove its subsections and placeholder content but keep the
top-level heading and the applicability line.

---

## 1. Project Controls

**Status:** DRAFT
**Spec revision:** 0
**Entry:** {{TBD: NEW or ADOPT}}
**Rigor:** {{TBD: LEAN, STANDARD, or STRICT}}
**Monthly budget USD:** 0.00

### Status

- `DRAFT` — the specification is being created or changed.
- `APPROVED` — the current specification is authorized for implementation.

Do not begin substantial implementation while `Status` is `DRAFT`.

### Spec Revision

`Spec revision` identifies an approved version of project truth.

- A new project begins at revision `0` while `DRAFT`.
- Each transition from `DRAFT` to `APPROVED` increments the revision by exactly `1`.
- Editing while `DRAFT` does not increment the revision.
- Returning an approved specification to `DRAFT` neither increments nor decrements
  it.
- `TODO.md` records the revision each phase began under and completed under.

```text
DRAFT rev 0
    │ approve
    ▼
APPROVED rev 1
    │ material change begins
    ▼
DRAFT rev 1
    │ approve
    ▼
APPROVED rev 2
```

### Material Changes

Materiality is defined mechanically. A change is material if and only if it changes:

- §3 Requirements
- §4 Acceptance Criteria
- §7 Architecture
- §10 External Services and Dependencies
- `Monthly budget USD` in §1

No other section change affects approval state.

A material change to an `APPROVED` specification requires:

1. set `Status` to `DRAFT` before making the change
2. complete the specification change
3. run `bash scripts/check-spec.sh`
4. proceed only when it exits `0`
5. obtain human approval
6. increment `Spec revision` by exactly `1`
7. set `Status` to `APPROVED`

While `Status` is `DRAFT`, a non-zero result from `check-spec.sh` means only that the
specification is not ready for approval yet. Do not treat it as a project validation
failure.

Execution consequences for an in-progress AUTO phase are defined in `AGENTS.md`.

### Phase Revision Semantics

A planned phase has no revision until work begins:

```text
**Defined against:** —
```

When a phase moves to `In Progress`:

1. `SPEC.md` must be `APPROVED`
2. record the current revision as `Defined against: Spec revision N`
3. freeze that value permanently

`Defined against` must never be rewritten. Do not erase a mismatch by updating it.

Phase completion does not manually assign a revision. The completion procedure reads
the current approved `Spec revision` and records:

```text
**Completed against:** Spec revision M
```

The completion revision is derived from `SPEC.md`, not chosen by the agent.

If `N != M`, the intervening specification changes must be reviewed before completion
is allowed. A mismatch is evidence to inspect, not automatic invalidation.

### Work While the Specification Is DRAFT

No new phase may move to `In Progress` while `SPEC.md` is `DRAFT`.

An already-running `AUTO` phase stops according to `AGENTS.md`.

An already-running `MANUAL` phase may continue only when the human explicitly
confirms that the pending specification change does not affect that phase. Otherwise
it stops until the specification is re-approved.

This holds regardless of which section is being changed. An agent does not decide
whether a pending change is unrelated enough.

### Entry

- `NEW` — build a new project from this specification.
- `ADOPT` — bring an existing repository under the framework while preserving useful
  existing structure and behavior.

### Rigor

- `LEAN` — critical-path verification with minimal ceremony.
- `STANDARD` — automated tests, review, CI, and core integration/E2E verification.
- `STRICT` — stronger security, deterministic validation, critical E2E coverage, and
  operational/recovery requirements.

Rigor changes verification depth, not architecture complexity.

### Execution Mode

Execution mode does not live in this file. `TODO.md` declares `MANUAL` or `AUTO` per
phase. AUTO behavior, immutable boundaries, and stop conditions are defined in
`AGENTS.md`.

---

## 2. Product

### Problem

{{TBD: problem being solved}}

### Outcome

{{TBD: what must be true when the project succeeds}}

### Users

{{TBD: intended users}}

### Primary Use Cases

1. {{TBD: primary use case}}
2. {{TBD: primary use case}}

Keep this section focused on product outcomes rather than implementation.

---

## 3. Requirements

Requirements define observable behavior the finished system must provide.

### Functional Requirements

- `REQ-001` — {{TBD: functional requirement}}
- `REQ-002` — {{TBD: functional requirement}}

### Non-Functional Requirements

A non-functional requirement must be measurable or observable enough to have
acceptance criteria.

- `NFR-001` — {{TBD: measurable non-functional requirement}}

If a condition cannot be expressed as observable system behavior, it belongs in §6
Constraints instead.

Every requirement must be specific enough to determine whether it passed. Do not
create requirements for hypothetical future needs.

---

## 4. Acceptance Criteria

Acceptance criteria define observable pass/fail conditions.

Every `REQ-*` and every `NFR-*` must be covered by at least one `AC-*`. One
acceptance criterion may cover multiple requirements.

### AC-001 — {{TBD: criterion name}}

**Satisfies:** `REQ-001`

Given:
- {{TBD: starting condition}}

When:
- {{TBD: action}}

Then:
- {{TBD: observable result}}

### AC-002 — {{TBD: criterion name}}

**Satisfies:** `REQ-002`, `NFR-001`

Given:
- {{TBD: starting condition}}

When:
- {{TBD: action or measurement}}

Then:
- {{TBD: observable result or threshold}}

Every acceptance criterion must produce a clear pass or fail. AUTO eligibility is
defined in `AGENTS.md`.

---

## 5. Out of Scope

Explicitly exclude plausible work that is not part of the project.

- {{TBD: excluded capability}}
- {{TBD: excluded capability}}

Absence from this section does not create a requirement. Only §3 defines
requirements.

---

## 6. Constraints

Constraints are fixed boundaries on implementation choices.

Whether something is a requirement or a constraint depends on what it describes, not
whether it happens to be testable.

- Observable behavior the finished system must satisfy → §3 Requirement
- A boundary within which implementation must operate → §6 Constraint

Example:

```text
"Deployment must use the client's existing AWS account."
→ Constraint

"User data must never be stored outside the EU."
→ NFR with acceptance coverage
```

### Technical

- {{TBD: constraint}}

### Platform / Environment

- {{TBD: constraint}}

### Compatibility

- {{TBD: constraint}}

### Security / Privacy

- {{TBD: constraint}}

### Operational

- {{TBD: constraint}}

Remove subsections that do not apply. Do not add hypothetical constraints.

---

## 7. Architecture

Describe the smallest architecture that satisfies the requirements.

### System Shape

```text
{{TBD: user}}
   │
   ▼
{{TBD: frontend}}
   │
   ▼
{{TBD: backend or API}}
   │
   ├── {{TBD: database if applicable}}
   └── {{TBD: external service if applicable}}
```

### Components

| Component | Responsibility |
|---|---|
| {{TBD: component}} | {{TBD: single responsibility}} |

### Data Flow

1. {{TBD: step}}
2. {{TBD: step}}

### Boundaries

Document boundaries that affect implementation. Examples: client vs server, trusted
vs untrusted input, authentication boundary, persistence boundary, external-service
boundary.

- {{TBD: boundary}}

---

## 8. Repository Shape

Describe repository structure only to the level required to prevent architectural
drift.

```text
{{TBD: project-name}}/
├── {{TBD: directory}}/
├── {{TBD: directory}}/
└── ...
```

For `ADOPT`, document the useful existing structure. Do not force an adopted
repository to match the template. Do not list every file.

---

## 9. Data and State

**Applicability:** {{TBD: YES or N/A}}

`N/A` asserts that the project stores no meaningful state.

### Entities

| Entity | Purpose |
|---|---|
| {{TBD: entity}} | {{TBD: purpose}} |

### Ownership

{{TBD: who owns or may access each important class of data}}

### Persistence

{{TBD: where state is stored}}

### Lifecycle

{{TBD: creation, retention, deletion, or archival rules}}

Do not turn this section into a complete database schema unless the schema itself is
an architectural constraint.

---

## 10. External Services and Dependencies

**Applicability:** {{TBD: YES or N/A}}

`N/A` asserts that the project relies on no externally managed service, hosted API,
SaaS dependency, or externally operated data store. If any such dependency appears in
§7 Architecture, this section must be `YES`.

| Service | Need | Free Tier / Limit | Estimated Monthly Cost USD | Variable-Cost Risk | Pricing Notes | Alternative |
|---|---|---|---:|---|---|---|
| {{TBD: service}} | {{TBD: need}} | {{TBD: limit}} | 0.00 | LOW | {{TBD: pricing notes}} | {{TBD: alternative}} |

Every service present in an `APPROVED` specification is approved for use.

Before adding a service, establish:

1. why it is required
2. free or included limits
3. expected monthly cost
4. variable-cost exposure
5. a cheaper or free alternative
6. total expected monthly project cost

Adding, replacing, or removing a service is a material change under §1.

### Cost Fields

`Monthly budget USD` and every `Estimated Monthly Cost USD` must use exactly two
decimal places.

Valid: `0.00`, `5.00`, `12.50`
Invalid: `0`, `12.5`, `$5.00`, `~12.00`, `free`, `$0.002/request`

`Variable-Cost Risk` must be exactly one of `LOW`, `MEDIUM`, or `HIGH`.

For `MEDIUM` or `HIGH`, `Pricing Notes` must be non-empty and describe the exposure,
including the unit price, threshold, or condition that can increase cost.

**A numeric estimate of `0.00` does not imply zero financial risk.** A service inside
a free tier today with metered pricing beyond it is `MEDIUM` or `HIGH` at `0.00`.

### Budget

The authoritative budget is `Monthly budget USD` in §1. Do not restate its value
here.

The summed `Estimated Monthly Cost USD` of all services in this section must not
exceed that value.

Existing personal subscriptions count as dependencies when the project relies on
them.

---

## 11. UX / Design

**Applicability:** {{TBD: YES or N/A}}

`N/A` asserts that the project has no meaningful user-facing experience.

Include only decisions that constrain implementation.

### Experience

- {{TBD: interaction requirement}}
- {{TBD: navigation or responsive requirement}}

### Visual Direction

- {{TBD: design direction}}

### Accessibility

- {{TBD: accessibility requirement}}

### Required States

User-visible states the product must handle:

- loading
- empty
- error
- success
- disabled
- unauthorized

Remove states that do not apply. Do not use this section as a design diary.

---

## 12. Security

**Applicability:** {{TBD: YES or N/A}}

`N/A` asserts that the project has no project-specific security decisions. Permanent
security rules in `AGENTS.md` still apply.

### Authentication

{{TBD: method or none}}

### Authorization

{{TBD: who may do what}}

### Sensitive Data

{{TBD: sensitive data or none}}

### Untrusted Inputs

{{TBD: inputs crossing trust boundaries}}

### Required Protections

- {{TBD: project-specific protection}}

Only project-specific security truth belongs here.

---

## 13. Deployment and Operations

**Applicability:** {{TBD: YES or N/A}}

`N/A` asserts that deployment and operational behavior are outside project scope.

### Environments

- Local — {{TBD: purpose}}
- Preview / Staging — {{TBD: purpose}}
- Production — {{TBD: purpose}}

Remove environments that do not exist.

### Deployment Target

{{TBD: target}}

### Runtime Requirements

{{TBD: runtime requirements}}

### Observability

{{TBD: logs, metrics, health checks, or alerts}}

### Recovery

{{TBD: backup, rollback, or recovery requirements}}

Do not invent production infrastructure for a project that does not require it.

---

## 14. Important Decisions

Store decisions that still explain or constrain the current project.

| Decision | Current Choice | Alternatives Rejected | Reason |
|---|---|---|---|
| {{TBD: decision}} | {{TBD: choice}} | {{TBD: rejected alternatives}} | {{TBD: reason}} |

Keep rejected alternatives concise but sufficient to prevent needless relitigation.

When a decision changes:

- update `Current Choice`
- update `Alternatives Rejected`
- update `Reason`
- apply the §1 material-change rules when the decision alters §3, §4, §7, §10, or the
  budget

Git preserves chronology.

---

## 15. Open Questions

Only unresolved questions that block or affect the specification belong here.

- [ ] {{TBD: unresolved question}}

Before approval, all blocking questions must be resolved.

When a question is resolved:

1. move the resulting project truth into its authoritative section
2. when meaningful alternatives were considered, add the decision and rejected
   alternatives to §14
3. remove the resolved question from this section

Resolved questions do not remain here.

---

## Approval

Approval has two gates.

### Mechanical Approval Gate

`bash scripts/check-spec.sh` answers one question:

> Is the current `SPEC.md` mechanically ready to be approved?

It may be run at any time while `Status: DRAFT`. A non-zero exit while drafting is
expected until all mechanical conditions are satisfied — it is information, not a
build failure.

A zero exit is required immediately before the human approval gate.

When `Status: APPROVED`, `bash scripts/validate.sh` invokes this check
automatically, and a failure then is a project validation failure.

The check must fail when:

- any `{{TBD:` marker remains
- `Spec revision` is not a non-negative integer
- any required top-level heading is missing
- a conditional section has neither `Applicability: YES` nor `Applicability: N/A`
- a section marked `N/A` still contains template subsection content
- any unchecked question remains in §15
- any `REQ-*` lacks `AC-*` coverage
- any `NFR-*` lacks `AC-*` coverage
- any `AC-*` references no requirement
- any `AC-*` references an ID that does not exist
- any applicable service row lacks a required field
- any cost value does not match `^[0-9]+\.[0-9]{2}$`
- any `Variable-Cost Risk` is not `LOW`, `MEDIUM`, or `HIGH`
- any `MEDIUM` or `HIGH` row has empty `Pricing Notes`
- the summed service cost exceeds `Monthly budget USD`

### Human / Engineering Gate

After `bash scripts/check-spec.sh` exits `0`, confirm:

- requirements represent the intended product
- architecture can satisfy those requirements
- constraints reflect actual project boundaries
- §7 and §10 agree about external dependencies
- every `MEDIUM` or `HIGH` variable-cost exposure is acceptable
- service alternatives and rejected options are understood
- important unresolved decisions are closed

Then:

1. increment `Spec revision` by exactly `1`
2. set `Status: APPROVED`

`APPROVED` means implementation may rely on that revision as current project truth.

Execution consequences of specification changes are governed by `AGENTS.md`.
