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

- `DRAFT` - the specification is being created or changed.
- `APPROVED` - the current specification is authorized for implementation.

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

A change is material when it affects what, how, or where the project must be built
or operated - any change with semantic effect on implementation, not just changes
to a fixed list of sections. A pure typo, wording clarification, or formatting fix
with no semantic effect is not material.

Sections most likely to be material: §3 Requirements, §4 Acceptance Criteria, §7
Architecture, §9 Data and State, §10 External Services and Dependencies, §12
Security, §13 Deployment and Operations, and `Monthly budget USD` in §1. This list
names where material changes usually occur; it does not exempt any other section.
Changing §12 Security from `N/A` to `YES` and adding real security requirements is
material, for example, even though Security is not one of the five sections a
narrower rule once singled out.

**Known limitation:** `check-spec.sh` cannot detect materiality by itself. It has
no memory of what the spec said before this edit, so it cannot tell a material
rewrite of Security from a typo fix in the same section. Determining materiality is
a human judgment call at the approval gate (§1's Human/Engineering Gate), not a
mechanical check - the mechanical gate can enforce structure, not intent.

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

- `NEW` - build a new project from this specification.
- `ADOPT` - bring an existing repository under the framework while preserving useful
 existing structure and behavior.

### Rigor

- `LEAN` - critical-path verification with minimal ceremony.
- `STANDARD` - automated tests, review, CI, and core integration/E2E verification.
- `STRICT` - stronger security, deterministic validation, critical E2E coverage, and
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

- `REQ-001` - {{TBD: functional requirement}}
- `REQ-002` - {{TBD: functional requirement}}

### Non-Functional Requirements

A non-functional requirement must be measurable or observable enough to have
acceptance criteria.

- `NFR-001` - {{TBD: measurable non-functional requirement}}

If a condition cannot be expressed as observable system behavior, it belongs in §6
Constraints instead.

Every requirement must be specific enough to determine whether it passed. Do not
create requirements for hypothetical future needs.

---

## 4. Acceptance Criteria

Acceptance criteria define observable pass/fail conditions.

Every `REQ-*` and every `NFR-*` must be covered by at least one `AC-*`. One
acceptance criterion may cover multiple requirements.

### AC-001 - {{TBD: criterion name}}

**Satisfies:** `REQ-001`
**Required proof:** {{TBD: NORMAL, SMOKE, LIVE, MANUAL, or comma-separated combination}}

Given:
- {{TBD: starting condition}}

When:
- {{TBD: action}}

Then:
- {{TBD: observable result}}

### AC-002 - {{TBD: criterion name}}

**Satisfies:** `REQ-002`, `NFR-001`
**Required proof:** {{TBD: NORMAL, SMOKE, LIVE, MANUAL, or comma-separated combination}}

Given:
- {{TBD: starting condition}}

When:
- {{TBD: action or measurement}}

Then:
- {{TBD: observable result or threshold}}

Every acceptance criterion must produce a clear pass or fail. `Required proof`
defines the class of evidence needed to prove it:

- `NORMAL` - routine deterministic project validation
- `SMOKE` - packaging/deployment/runtime smoke verification
- `LIVE` - real external-provider verification
- `MANUAL` - human-observed evidence that cannot reasonably be automated

Use comma-separated combinations when more than one class is genuinely required.
AUTO eligibility is defined in `AGENTS.md`.

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

Classify every important entity before assigning ownership fields.

| Entity | Class | Purpose | Owner / Authority |
|---|---|---|---|
| {{TBD: entity}} | {{TBD: USER_OWNED, GLOBAL_REFERENCE, DERIVED_RUNTIME, or EXTERNAL}} | {{TBD: purpose}} | {{TBD: user, project, runtime, or external authority}} |

Entity classes mean:

- `USER_OWNED` - belongs to a specific project user; user ownership identifiers may be required.
- `GLOBAL_REFERENCE` - shared reference/catalog data; do not add user ownership merely by convention.
- `DERIVED_RUNTIME` - computed, cached, transient, or runtime-generated state.
- `EXTERNAL` - authoritative state lives outside this project.

### Ownership and Access

{{TBD: who may create, read, modify, or delete each important class of data}}

### Persistence

{{TBD: where state is stored}}

### Lifecycle

{{TBD: creation, retention, deletion, or archival rules}}

Do not turn this section into a complete database schema unless the schema itself is
an architectural constraint.

## 10. External Services and Dependencies

**Applicability:** {{TBD: YES or N/A}}

`N/A` asserts that the project relies on no externally managed service, hosted API,
SaaS dependency, or externally operated data store. If any such dependency appears
in §7 Architecture, this section must be `YES`.

| Service | Need | Production Provider | Automated Test Provider | Required Final State | Free Tier / Limit | Estimated Monthly Cost USD | Variable-Cost Risk | Pricing Notes | Alternative |
|---|---|---|---|---|---|---:|---|---|---|
| {{TBD: service}} | {{TBD: need}} | {{TBD: real configured provider/path}} | {{TBD: deterministic fake/stub/sandbox, or N/A}} | {{TBD: IMPLEMENTED, TESTED, or LIVE VERIFIED}} | {{TBD: limit}} | 0.00 | LOW | {{TBD: pricing notes}} | {{TBD: alternative}} |

For nondeterministic or credentialed AI/external services, automated project tests
must not depend on network availability, real credentials, token spend, or unstable
responses. Define a deterministic test provider unless the integration genuinely
cannot be tested that way; document the exception explicitly.

Integration states are cumulative:

```text
IMPLEMENTED -> TESTED -> LIVE VERIFIED
```

- `IMPLEMENTED` means the real adapter/configuration path exists.
- `TESTED` means deterministic automated evidence exercises the integration contract.
- `LIVE VERIFIED` means the actual target provider was contacted through its real
  credential/configuration path and expected behavior was observed.

Mocks, deterministic stubs, fallback behavior, or adapter existence never count as
`LIVE VERIFIED`. Achieved states and evidence live in `EVIDENCE.md`.

Every service present in an `APPROVED` specification is approved for use. Before
adding a service, establish why it is required, expected cost, variable-cost risk,
and a cheaper/free alternative. Adding, replacing, or removing a service is a
material change under §1.

### Cost Fields

`Monthly budget USD` and every `Estimated Monthly Cost USD` must use exactly two
decimal places.

Valid: `0.00`, `5.00`, `12.50`
Invalid: `0`, `12.5`, `$5.00`, `~12.00`, `free`, `$0.002/request`

`Variable-Cost Risk` must be exactly one of `LOW`, `MEDIUM`, or `HIGH`.

For `MEDIUM` or `HIGH`, `Pricing Notes` must be non-empty and describe the exposure,
including the unit price, threshold, or condition that can increase cost.

A numeric estimate of `0.00` does not imply zero financial risk.

### Budget

The authoritative budget is `Monthly budget USD` in §1. The summed
`Estimated Monthly Cost USD` of all services in this section must not exceed it.
Existing personal subscriptions count as dependencies when the project relies on them.

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

If authentication is `None`, explicitly define the network-exposure boundary below.
Unauthenticated local applications default to localhost-only exposure unless broader
access is an approved requirement.

### Network Exposure

- Intended exposure: {{TBD: LOCALHOST_ONLY, LAN, or PUBLIC}}
- Bind interface: {{TBD: e.g. 127.0.0.1, 0.0.0.0, or platform equivalent}}
- Container port publication: {{TBD: localhost-only, LAN/public, or N/A}}

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

- Local - {{TBD: purpose}}
- Preview / Staging - {{TBD: purpose}}
- Production - {{TBD: purpose}}

Remove environments that do not exist.

### Deployment Target

{{TBD: target}}

### Runtime Requirements

Pin important runtimes when implementation or support depends on a specific version.
Validation must verify the actual runtime before project checks run.

| Runtime | Required Version | Project Pin / Source |
|---|---|---|
| {{TBD: runtime}} | {{TBD: exact or explicitly allowed version range}} | {{TBD: pyproject, .python-version, package.json engines, toolchain file, etc.}} |

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

`Current Choice` must be a concrete confirmed decision, not an example or a proposed
default. Phrases such as `e.g.`, `such as`, `something like`, or `a framework like`
do not belong in `Current Choice`. If confirmation is still required, keep the item
in §15 instead.

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

**State:** {{TBD: OPEN or CLEAR}}

Only unresolved questions or proposed defaults awaiting confirmation belong here.

When `State: OPEN`, list each unresolved item:

- [ ] {{TBD: unresolved question or proposed default awaiting confirmation}}

Before approval, `State` must be `CLEAR` and no unchecked question may remain.
Do not write narrative such as "no unresolved questions remain" while keeping items
that still require confirmation.

When a question is resolved:

1. move the resulting project truth into its authoritative section
2. when meaningful alternatives were considered, record the confirmed decision in §14
3. remove the resolved question from this section
4. set `State: CLEAR` only when nothing remains unresolved

## Approval

Approval has two gates.

### Mechanical Approval Gate

`bash scripts/check-spec.sh` answers one question:

> Is the current `SPEC.md` mechanically ready to be approved?

It may be run at any time while `Status: DRAFT`. A non-zero exit while drafting is
expected until all mechanical conditions are satisfied - it is information, not a
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
- `Entry` is not `NEW` or `ADOPT`
- `Rigor` is not `LEAN`, `STANDARD`, or `STRICT`
- `Status` is `APPROVED` while `Spec revision` is `0` (approval was not
 incremented; use `scripts/approve-spec.sh` rather than a manual edit)

### Human / Engineering Gate

After `bash scripts/check-spec.sh` exits `0`, perform a semantic consistency review
across Product, Requirements, Acceptance Criteria, Constraints, Architecture, Data,
External Services, Security, Deployment, Important Decisions, and Open Questions.
Mechanical parsing cannot prove that those sections agree semantically.

Then confirm:

- requirements represent the intended product
- architecture can satisfy those requirements
- constraints reflect actual project boundaries
- §7 and §10 agree about external dependencies
- every `MEDIUM` or `HIGH` variable-cost exposure is acceptable
- service alternatives and rejected options are understood
- important unresolved decisions are closed

Then run:

```bash
bash scripts/approve-spec.sh
```

Running that script is the only documented DRAFT -> APPROVED transition. It
re-checks mechanical readiness and atomically increments `Spec revision` by exactly
`1` while setting `Status: APPROVED`. Do not hand-edit those two fields to approve.

`APPROVED` means implementation may rely on that revision as current project truth.
Execution consequences of specification changes are governed by `AGENTS.md`.
