# WORKFLOW.md

Reusable multi-step procedures.

Permanent rules belong in `AGENTS.md`.
Project truth belongs in `SPEC.md`.
Execution state belongs in `TODO.md`.
Verification truth belongs in `EVIDENCE.md`.
Deterministic enforcement belongs in `scripts/` and `.framework/`.

This file defines **how** lifecycle work is performed. It does not duplicate
permanent rules already owned by `AGENTS.md`.

---

## Canonical Lifecycle

```text
INTAKE
  -> SPECIFICATION
  -> SEMANTIC CONSISTENCY REVIEW
  -> HUMAN APPROVAL
  -> PHASE PLANNING
  -> EXECUTION
  -> VALIDATION
  -> REVIEW
  -> COMPLETION
  -> COMMIT
  -> NEXT PHASE
  -> FINAL PROJECT CERTIFICATION
```

Do not skip directly from implementation to `Done`.

---

## Start or Resume Work

At the beginning of a session:

1. read `AGENTS.md`
2. read `SPEC.md`
3. read `TODO.md`
4. read the relevant rows in `EVIDENCE.md`
5. identify the active phase/task
6. inspect only relevant code, tests, interfaces, configuration, and current failure evidence

Use Git history only for historical evidence. Do not reconstruct current project
truth from old chats when authoritative files already define it.

---

## Intake and Context Normalization

Intake has two explicit modes.

### Discovery mode

Invoked with no requirement bundle:

```text
/intake
```

State briefly that no requirements were supplied, begin discovery, and mention that
`/intake <requirements>` can normalize an existing requirement dump.

### Normalization mode

Invoked with requirements/context already supplied:

```text
/intake <requirements/context>
```

Treat typed requirements, files, screenshots, existing-repository evidence, and
other supplied material as one context bundle.

### Normalize

Produce a compact working model of:

1. product problem, users, outcomes, and use cases
2. functional and measurable non-functional requirements
3. constraints and compatibility requirements
4. existing confirmed technical decisions
5. data/state and entity ownership classes
6. external services, deterministic test-provider strategy, cost, and required final integration state
7. authentication and network-exposure boundary
8. runtime/toolchain requirements
9. out-of-scope items
10. contradictions or unresolved questions

Populate `SPEC.md` as `DRAFT`. Use only `{{TBD: ...}}` for unresolved content.
Do not create application code during intake.

---

## Specification Procedure

For `Entry: NEW`, define the smallest architecture that satisfies the requirements.
For `Entry: ADOPT`, inspect the repository before changing its shape and normalize
existing useful behavior into the SPEC.

Before approval ensure:

- every REQ/NFR has AC coverage
- each AC declares its required proof class
- data entities are classified rather than blindly treated as user-owned
- important runtime versions are pinned when version matters
- nondeterministic/credentialed external services have a deterministic automated-test strategy
- each external integration declares its required final state: IMPLEMENTED, TESTED, or LIVE VERIFIED
- unauthenticated applications explicitly define network exposure
- Important Decisions contain concrete confirmed choices only
- Open Questions accurately distinguishes unresolved/proposed defaults from confirmed truth

---

## Semantic Consistency Review

Mechanical parsing cannot prove semantic agreement. Before human approval, and again
after any MANUAL decision that changes implementation/proof strategy, reconcile:

```text
Product Outcome
<-> Requirements / NFRs
<-> Acceptance Criteria + proof classes
<-> Constraints
<-> Architecture
<-> Data / Ownership
<-> External Services
<-> Security / Network Exposure
<-> Deployment / Runtime
<-> Important Decisions
<-> Open Questions
```

Look specifically for contradictions such as:

- credential-free outcome vs mandatory credentialed provider
- optional service vs mandatory AC
- out-of-scope behavior referenced by an AC
- confirmed decision expressed only as an example
- a MANUAL proof decision that contradicts AC wording
- runtime pin in SPEC but a different runtime in project tooling

If a decision changes project truth or how an AC must be interpreted, reconcile the
SPEC **before implementation continues**. Do not defer the contradiction until phase completion.

---

## Specification Approval Procedure

Mechanical readiness:

```bash
bash scripts/check-spec.sh
```

While DRAFT, non-zero means NOT READY FOR APPROVAL; it is not a project build failure.

Then complete the semantic/human gate. If approved, run exactly:

```bash
bash scripts/approve-spec.sh
```

Running this script is the approval action. It atomically increments the revision and
sets `Status: APPROVED`. Do not hand-edit those fields to approve.

Framework implementation self-tests separately prove that the approval transition
works; `check-spec.sh` only validates SPEC state/readiness.

---

## Phase Planning Procedure

Plan phases after the SPEC is approved. If planning exposes a specification defect,
return the SPEC to DRAFT rather than silently compensating in TODO.

Choose one planning default once:

- `CONSERVATIVE` - mostly MANUAL
- `HYBRID` - selected AUTO phases
- `AUTONOMOUS` - routine implementation phases default AUTO with human gates intact
- `CUSTOM` - explicit per-phase choices

Record it in `TODO.md`. It is not an authority grant; each phase `Mode` remains authoritative.

For each phase:

1. define one coherent objective
2. own specific `AC-*` IDs
3. define concrete tasks
4. define real dependencies
5. choose `MANUAL` or `AUTO`
6. if AUTO, choose `AUTO executor: NONE` for policy-only AUTO or an adapter-defined executor
7. require a positive iteration budget only for executor-backed AUTO
8. leave `Defined against` and `Completed against` as `—`
9. ensure required evidence rows exist in `EVIDENCE.md`

Run:

```bash
bash scripts/check-todo.sh
bash scripts/check-evidence.sh
```

---

## Start Phase Procedure

Before first start:

1. SPEC is APPROVED
2. `check-todo.sh` passes
3. all dependencies are Done
4. referenced AC IDs exist
5. MANUAL/AUTO/executor fields are valid
6. `Defined against: —`
7. `Completed against: —`

Then atomically conceptually transition the phase to:

```text
Status: In Progress
Defined against: Spec revision N
```

`Defined against` is frozen after first start.

If executor-backed AUTO is selected, initialize durable state once:

```bash
bash scripts/auto-state.sh init <phase> <executor> <budget>
```

Never reinitialize an existing phase ledger to reset consumed iterations.

---

## MANUAL Phase Execution

1. read Agenda, AC ownership, and required evidence classes
2. resolve architecture/proof decisions before implementing them
3. when a decision changes SPEC truth, stop and use the specification-change procedure
4. implement incrementally
5. update task checkboxes only when true
6. update `EVIDENCE.md` as proof is actually obtained
7. use Blocker when progress cannot continue
8. run normal validation and any applicable focused checks
9. complete review
10. use the Complete Phase Procedure

MANUAL means supervised decision boundaries, not permission prompts for every safe edit.

---

## AUTO Policy Execution

For `Mode: AUTO`, work may continue without intermediate approval only inside the
approved phase boundary.

### Policy-only AUTO

```text
AUTO executor: NONE
AUTO iteration budget: —
```

There is no durable iteration count. Do not invent one in conversation or TODO.
The current session may continue until an AUTO stop condition fires.

### Executor-backed AUTO

A real executor performs cycles:

```text
attempt -> relevant validation/verification -> inspect -> decide
```

After each genuine cycle record it mechanically:

```bash
bash scripts/auto-state.sh consume <phase> <PASS|FAIL> <fingerprint> <reason>
```

The ledger is durable and cumulative across session/process restarts. Human resume
does not reset it. Reads, reporting, planning, and housekeeping do not consume an iteration.

The executor stops on:

- budget exhaustion
- three identical failed attempts
- protected-boundary change
- hard human gate
- phase-scope exit
- unresolved drift/blocker

The executor cannot authorize its own resume or increase its budget.

---

## Block / Resume / Replan

When execution cannot continue:

```text
Status: Blocked
Blocker: <specific condition + what is required>
```

Do not alter protected phase fields merely to escape a blocker.

Resume requires human authorization. Clear the blocker and restore `In Progress`.
For executor-backed AUTO, continue using the existing durable ledger; do not reset it.
Reactivate a stopped ledger only as part of that human-authorized resume:

```bash
bash scripts/auto-state.sh resume <phase> <reason>
```

If the executor budget must increase, keep the phase Blocked, perform the human
replanning, update the TODO budget, then update the durable ledger without erasing
consumed iterations:

```bash
bash scripts/auto-state.sh rebudget <phase> <new-budget> <reason>
```

The executor remains stopped after rebudgeting until the human-authorized `resume`
operation runs. If scope, AC ownership, mode, dependencies, executor, or deliverables
must change, keep the phase Blocked while replanning. If project truth changes, return
SPEC to DRAFT and reapprove it first.

---

## Validation Procedure

### Normal fast validation

```bash
bash scripts/validate.sh
```

Meaning:

- `0` = configured validation PASS
- `1` = FAIL
- `2` = PRE-SCAFFOLD / NOT CONFIGURED because no executable surface exists yet

Exit 2 never counts as a passing build and never completes a phase.

`.framework/validation.conf` registers every executable/testable surface. Each record
includes a runtime preflight plus at least one real project check from
lint/typecheck/test/build. `scripts/check-validation-surfaces.sh` discovers common
executable surfaces and fails when a new one is neither registered nor explicitly
ignored, or when a registered surface has only a runtime preflight and no project
behavior check.

### Packaging / deployment smoke

```bash
bash scripts/smoke.sh
```

Use this for expensive shipping-artifact proof such as Docker build/start, restart
persistence, packaged execution, or deployment smoke. Keep it separate from normal
validation unless the project deliberately chooses otherwise.

### Live external-provider verification

Run only when SPEC requires LIVE VERIFIED and credentials/network/cost are authorized.
Mocks and deterministic stubs may prove TESTED, never LIVE VERIFIED.

Record achieved proof in `EVIDENCE.md`.

---

## Review and Verification Procedure

For MEDIUM/LARGE behavioral work:

1. finish the smallest coherent implementation
2. run the mapped review capability
3. resolve correctness/security/maintainability findings
4. simplify unnecessary complexity without changing behavior
5. run `scripts/validate.sh`
6. run required SMOKE/LIVE/MANUAL proof separately
7. update `EVIDENCE.md`
8. re-run semantic reconciliation when MANUAL decisions changed how an AC is proven

Review, validation, and acceptance evidence are different gates.

---

## Complete Phase Procedure

A phase becomes `Done` only through this procedure.

### Human / engineering gate

Confirm:

- every owned AC is actually satisfied against current wording
- review is complete
- required NORMAL/SMOKE/LIVE/MANUAL evidence has been obtained
- `EVIDENCE.md` reports owned ACs as `PASS`
- revision drift, if any, was explicitly re-verified

### Mechanical gate and transition

```bash
bash scripts/complete-phase.sh <phase-number>
```

The script verifies:

- SPEC APPROVED
- phase In Progress
- all tasks checked
- TODO/framework integrity
- owned AC evidence is PASS
- executor ledger matches TODO when executor-backed AUTO is used
- normal validation exits 0
- SPEC status/revision did not change during validation

On success it atomically writes:

```text
Status: Done
Completed against: Spec revision N
```

It reports durable AUTO iterations consumed when applicable. It never commits Git.

---

## Commit Procedure

After phase completion:

1. inspect `git status` and the complete diff
2. confirm only intended changes are present
3. create a phase checkpoint commit when the repository uses Git
4. do not combine unrelated work merely to force one commit

Completion and commit are separate concerns. `complete-phase.sh` never runs `git commit`.

---

## Next Phase Procedure

After a completed phase and appropriate checkpoint:

1. identify all `Not Started` phases whose dependencies are Done
2. choose the next phase based on approved plan and current priorities
3. do not renumber phases to close gaps
4. start it through the Start Phase Procedure

Independent phases may run in parallel only when their state transitions cannot overwrite each other.

---

## Final Project Certification

When all planned phases are Done:

1. ensure every AC row in `EVIDENCE.md` is PASS
2. ensure each external integration meets or exceeds its SPEC-required final state
3. run normal validation
4. run required smoke gates
5. set Final Certification Notes to exactly `None` only when no evidence gap remains
6. run:

```bash
bash scripts/certify-project.sh
```

Certification is read-only. It must not repair state or manufacture evidence.

---

## Change Approved Specification Procedure

For a material change:

1. set Status to DRAFT before editing material truth
2. stop affected AUTO work
3. block/reconcile MANUAL work if the pending change affects it
4. edit SPEC
5. update planned TODO/evidence obligations as needed
6. run `check-spec.sh`
7. run semantic consistency review
8. human approves with `approve-spec.sh`
9. re-run TODO/evidence integrity

Completed phases are not automatically invalidated. Revision mismatch is a trigger for re-verification.

---

## Adopt Existing Repository Procedure

For `Entry: ADOPT`, inspect before restructuring:

- repository layout and manifests
- application entrypoints
- tests and current validation commands
- runtime/toolchain pins
- build/deployment paths
- data stores and external services
- security/environment conventions
- representative project patterns

Preserve useful working behavior and structure. Register existing executable surfaces
in `.framework/validation.conf`; do not force the repository to resemble the template.

---

## Framework Self-Test Procedure

The framework must test its own lifecycle machinery separately from project validation:

```bash
bash tests/framework/run.sh
```

Self-tests use disposable fixtures and must cover at least:

- canonical and malformed phase parsing
- zero-phase false-positive prevention
- DRAFT -> APPROVED transition and atomic failure behavior
- phase completion transition and malformed Done rejection
- PRE-SCAFFOLD vs detected-unregistered validation surfaces
- runtime mismatch failure
- AUTO durable iteration accounting across process invocations
- deterministic TESTED vs LIVE VERIFIED state separation
- acceptance-evidence proof-class drift rejection
- final-certification success and failure paths
- human AUTO resume/rebudget without iteration reset
- smoke/normal validation separation and empty smoke-command rejection

Run this suite on macOS and Linux in template CI. Avoid GNU-only shell-tool assumptions.

---

## Context Reset Procedure

When context becomes stale or large, preserve only current task, blockers, requirements,
constraints, current failure evidence, and executor state. Restart from authoritative
files and relevant code. Durable AUTO executor state comes from `.framework/auto/`,
not conversational memory.


<!-- FRONTEND-WORKFLOW:BEGIN -->
## Frontend design loop

### 1. Define
Before coding, establish one design direction: product/audience, reference qualities, type hierarchy, semantic palette, spacing/density, radius/depth, imagery/icon style, and motion rules.

### 2. Reuse before inventing
Inspect the current design system and components. Prefer existing components first, shadcn second, and 21st when a more distinctive reference or component is genuinely useful.

### 3. Build coherently
Use one token system and one component language. Adapt imported code to local conventions rather than mixing raw styles from several libraries.

### 4. Visual QA
Render the actual application. Inspect at least one desktop and one mobile viewport plus important interaction states. Review hierarchy, alignment, whitespace, typography, contrast, overflow, responsive behavior, loading/empty/error states, focus/keyboard behavior, and motion.

### 5. Refine
Fix visible defects and re-render. A passing build is necessary but not sufficient for frontend completion.
<!-- FRONTEND-WORKFLOW:END -->
