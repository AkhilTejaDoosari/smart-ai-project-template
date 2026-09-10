# WORKFLOW.md

Reusable procedures and prompt sequences.

Permanent rules belong in `AGENTS.md`.
Project truth belongs in `SPEC.md`.
Current execution state belongs in `TODO.md`.
Deterministic validation belongs in `scripts/`.

This file explains **how** recurring work is performed.
It does not redefine rules already owned by `AGENTS.md`.

---

## 1. Start or Resume Work

At the beginning of a new session:

1. read `AGENTS.md`
2. read `SPEC.md`
3. read `TODO.md`
4. identify the phase or task being worked
5. inspect only the code, tests, interfaces, and configuration relevant to that work

Use Git history only when historical evidence is needed.

Do not reconstruct current project truth from old chats when `SPEC.md` and `TODO.md`
already define it.

---

## 2. Intake and Context Normalization

Intake may begin from one or more sources:

- typed requirements
- PDFs
- client documents
- email or pasted email
- notes
- screenshots
- readable project documentation
- an existing repository

Treat all supplied material as one context bundle.

### Normalize

Produce a compact working understanding:

1. short project overview
2. users and primary outcomes
3. functional requirements
4. measurable non-functional requirements
5. constraints
6. technical choices already made
7. budget and external-service implications
8. explicit out-of-scope items
9. conflicts or contradictions
10. unresolved questions that materially affect the project

Do not repeat source documents verbatim.

Spend context on ambiguity and decisions, not repetition.

### Intake Result

Populate `SPEC.md` with:

```text
Status: DRAFT
Spec revision: 0 or current revision
Entry: NEW or ADOPT
Rigor: LEAN, STANDARD, or STRICT
```

Then fill only applicable sections.

Use `{{TBD: ...}}` for unresolved content.

Do not mark the specification `APPROVED` during normalization.

---

## 3. NEW Project Procedure

Use when `Entry: NEW`.

1. normalize the context bundle
2. define the product and requirements in `SPEC.md`
3. define REQ → AC traceability
4. define constraints
5. choose the smallest architecture that satisfies the requirements
6. record external services, cost, and alternatives
7. record important decisions and rejected alternatives
8. resolve blocking open questions
9. plan phases in `TODO.md`
10. run the specification approval procedure (§5)
11. start the first eligible phase (§7)

Do not create application code before the specification is approved.

---

## 4. ADOPT Existing Repository Procedure

Use when `Entry: ADOPT`.

Before changing structure:

1. inspect repository layout
2. inspect package manifests and dependency files
3. identify application entrypoints
4. identify tests and current validation commands
5. identify build and deployment paths
6. identify data stores and external services
7. identify existing security and environment conventions
8. inspect representative code for established project patterns

Then:

1. normalize existing behavior into `SPEC.md`
2. record the existing useful repository shape
3. identify drift between documentation and implementation
4. preserve working behavior unless the specification changes it
5. add only framework files or changes that the project actually needs
6. plan adoption work in `TODO.md`
7. approve the specification before starting a new phase

Do not force an adopted project to resemble the template.

---

## 5. Specification Approval Procedure

`bash scripts/check-spec.sh` answers:

> Is the current `SPEC.md` mechanically ready to be approved?

While `Status: DRAFT`, a non-zero exit is readiness information, not a build failure.

### Mechanical Gate

Run:

```bash
bash scripts/check-spec.sh
```

Continue only when it exits `0`.

### Human / Engineering Gate

Review the human gate defined in the `Approval` section of `SPEC.md`.

If approved:

1. increment `Spec revision` by exactly `1`
2. change `Status` to `APPROVED`
3. save the file
4. run:

```bash
bash scripts/check-spec.sh
```

The approval transition depends on specification integrity, not on the current code,
test, or build state. A red implementation may be the reason the newly approved
specification exists.

Project validation remains required for implementation completion, not for approving
project truth.

---

## 6. Planning Phases

Planning may occur while `SPEC.md` is `DRAFT`.

Use the simple phase pattern already defined in `TODO.md`:

```text
Phase N
  state block
  Agenda
  Acceptance Coverage
  To-do list
  Blocker
```

For each phase:

1. give it one coherent objective
2. reference the `AC-*` IDs it owns
3. break the objective into concrete tasks
4. choose `MANUAL` or `AUTO`
5. define dependencies
6. set the AUTO iteration budget
7. leave both revision fields as `—`

### Phase Design

Prefer phases that can be verified independently.

Independent phases may run in parallel.

Use `Depends on` only when a real ordering dependency exists.

Every `AC-*` in an approved `SPEC.md` must be owned by at least one phase before
implementation begins.

---

## 7. Start Phase Procedure

A phase may start only when the start rules in `AGENTS.md` are satisfied.

Before starting:

1. confirm `SPEC.md` is `APPROVED`
2. run:

```bash
bash scripts/check-todo.sh
```

3. read the current `Spec revision`
4. confirm all dependencies are `Done`
5. confirm every referenced `AC-*` exists
6. confirm phase mode and iteration-budget fields are valid
7. confirm:

```text
Defined against: —
Completed against: —
```

Then update the phase in one edit:

```text
Status: In Progress
Defined against: Spec revision N
```

where `N` is the current approved revision.

After first start, `Defined against` is frozen.

Do not change `Completed against`.

---

## 8. MANUAL Phase Execution

For a MANUAL phase:

1. read the phase Agenda and Acceptance Coverage
2. work through the To-do list
3. update task checkboxes as work becomes true
4. run focused checks during implementation as needed
5. use `Blocker` when progress cannot continue
6. stop at human gates defined by `AGENTS.md`
7. perform required review
8. run the completion procedure (§13)

MANUAL means supervised decision boundaries, not step-by-step permission for every
safe edit.

---

## 9. AUTO Phase Execution

AUTO executes safe, in-scope work without intermediate approval.

### Autonomous Run

At the start of a human-authorized autonomous run:

1. read the phase Agenda, Acceptance Coverage, and To-do list
2. read the phase AUTO iteration budget
3. set the run-local iteration counter to `0`
4. continue through safe tasks while remaining inside the approved phase boundaries

The iteration budget limits one uninterrupted autonomous run.

A human-authorized resume begins a new autonomous run and resets the run-local
counter. An AUTO agent may not authorize or perform its own resume after a stop
condition.

### Iteration

One iteration is the cycle defined in `AGENTS.md`:

```text
attempt → validate or verify relevant work → inspect the result → decide the next action
```

Increment the run-local counter once after every completed cycle, whether the result
succeeds or fails.

When the counter reaches the phase budget, stop before beginning another cycle.

Stop immediately when any other AUTO stop condition in `AGENTS.md` fires.

### Allowed TODO Updates During AUTO

AUTO may:

- check completed tasks
- write `Blocker`
- move `In Progress` → `Blocked`

Clearing `Blocker` and moving `Blocked` → `In Progress` occur only as part of a
human-authorized resume (§11).

AUTO may not perform the `Done` transition.

---

## 10. Block Phase Procedure

When progress cannot continue:

1. set:

```text
Status: Blocked
```

2. replace `Blocker: None` with a concise description of:
   - what prevents progress
   - what decision, credential, dependency, condition, or external event is required
3. report the stop condition

If the blocker is AUTO iteration-budget exhaustion or another AUTO stop condition,
state that human authorization is required before resume. Do not self-resume.

Do not change:

- `Mode`
- `Depends on`
- `Defined against`
- `Completed against`
- Acceptance Coverage
- phase deliverables
- AUTO iteration budget

---

## 11. Resume Blocked Phase

A blocked phase resumes only after human authorization.

For AUTO, the agent may not authorize or perform its own resume, including after
iteration-budget exhaustion.

When the blocker is resolved and resume is authorized:

1. confirm no immutable phase field needs to change
2. clear the Blocker back to:

```text
None
```

3. change:

```text
Status: Blocked
```

to:

```text
Status: In Progress
```

This is a resume, not a new phase start.

Do not rewrite `Defined against`.

For AUTO, the human-authorized resume begins a new autonomous run and resets the
run-local iteration counter to `0`.

---

## 12. Replan or Remove an Active Phase

Any active phase being replanned must remain `Status: Blocked` while replanning is
in progress. The schema has no separate stopped or replanning status.

### AUTO

An AUTO phase is never replanned in place.

If scope, mode, dependencies, acceptance coverage, deliverables, or iteration budget
must change:

1. move the phase to `Blocked`
2. stop AUTO execution
3. report why the phase cannot continue as defined
4. human reviews the required change
5. if project truth must change, follow the specification-change procedure (§15)
6. edit the phase only outside AUTO execution while it remains `Blocked`
7. resume only through the human-authorized resume procedure (§11)

### MANUAL

A MANUAL phase that requires replanning also moves to `Blocked` first.

After human authorization, edit it while blocked and resume through §11.

`Defined against` remains frozen even when the phase is replanned.

`Completed against` remains untouched until completion.

### Remove an Unneeded Phase

The framework does not add an `Abandoned` status.

Abandonment means replanning the phase out of the current execution plan.

A phase may be removed only with human authorization and only when it is not `Done`.

Before removal:

1. if it is `In Progress`, move it to `Blocked`
2. reassign every owned `AC-*` to another phase, or remove that AC through the
   approved specification-change procedure when the requirement itself no longer
   exists
3. update every phase that depends on the removed phase
4. confirm `check-todo.sh` passes after the edit
5. remove the phase from `TODO.md`

Do not renumber remaining phases merely to close a numbering gap.

Git preserves the historical existence of the removed phase.

---

## 13. Complete Phase Procedure

A phase becomes `Done` only through this procedure.

### A. Human / Engineering Completion Gate

Before invoking the script, confirm:

1. every `AC-*` owned by the phase passes against the current implementation
2. required review under `AGENTS.md` is complete
3. unresolved review findings do not invalidate the phase outcome

If:

```text
Defined against != current Spec revision
```

re-verify every AC in the phase against its **current wording**.

Confirming that the AC ID still exists is not sufficient.

### B. Mechanical Completion Gate

Run:

```bash
bash scripts/complete-phase.sh <phase-number>
```

The script must verify deterministic completion preconditions, including:

- SPEC is `APPROVED`
- phase is `In Progress`
- all tasks are checked
- referenced AC IDs exist
- no dependency currently has `Status: Not Started`
- `Defined against` is populated
- `Completed against` is `—`
- `bash scripts/validate.sh` exits `0`
- TODO structural integrity passes

### C. State Transition

On success, `complete-phase.sh` performs one atomic update:

```text
Status: Done
Completed against: Spec revision N
```

where `N` is read from the current approved `SPEC.md`.

The script writes both fields or neither.

Re-running it on an already-valid `Done` phase is a successful no-op.

If an already-Done phase is malformed, the script fails rather than silently
repairing state.

`complete-phase.sh` is a state-transition helper.

It must never be called by `scripts/validate.sh`.

---

## 14. Review and Verification Procedure

For work requiring review under `AGENTS.md`:

1. finish implementation
2. run the mapped review capability
3. resolve findings that affect correctness, security, maintainability, or scope
4. simplify unnecessary complexity when behavior remains unchanged
5. run:

```bash
bash scripts/validate.sh
```

6. verify required browser/E2E behavior when acceptance criteria require runtime
   evidence
7. retain concise completion evidence

Do not substitute review for validation or validation for acceptance verification.

---

## 15. Change an Approved Specification

When an approved specification requires a material change:

1. change `Status` from `APPROVED` to `DRAFT` before editing the material section
2. stop in-progress AUTO phases according to `AGENTS.md`
3. do not start new phases
4. edit the specification
5. update planned phases when needed
6. run:

```bash
bash scripts/check-spec.sh
```

7. complete the human approval gate
8. increment `Spec revision`
9. restore:

```text
Status: APPROVED
```

10. run:

```bash
bash scripts/check-spec.sh
```

Specification re-approval is not gated on the current code, test, or build state.

Already-running MANUAL work follows the DRAFT rules in `SPEC.md`.

Completed phases are not automatically invalidated by a new revision.

Revision mismatch is a re-verification trigger at completion.

---

## 16. Validation Procedures

### Normal Validation

Use:

```bash
bash scripts/validate.sh
```

This is the only validation entrypoint for humans, agents, and CI.

It may delegate to deterministic helpers such as:

```text
scripts/check-spec.sh
scripts/check-todo.sh
```

It must never invoke state-transition helpers.

### Spec Readiness

Use directly while drafting:

```bash
bash scripts/check-spec.sh
```

A non-zero result while DRAFT means:

```text
NOT READY FOR APPROVAL
```

not:

```text
PROJECT BUILD FAILED
```

### TODO Integrity

Use:

```bash
bash scripts/check-todo.sh
```

to inspect TODO structure and cross-file state invariants.

---

## 17. Context Reset Procedure

When a session becomes large, stale, or unfocused:

1. preserve the current task and unresolved blocker
2. preserve active requirements and constraints
3. preserve the current error or validation evidence
4. discard failed exploratory paths once their conclusion is known
5. restart from:
   - `AGENTS.md`
   - `SPEC.md`
   - `TODO.md`
   - relevant code only

Do not carry entire prior conversations forward as project state.

---

## 18. Reusable Prompt Sequences

These are starting instructions, not additional rules.

### Intake

```text
Normalize the supplied context into the existing SPEC.md structure.
Resolve conflicts where evidence permits, surface unresolved conflicts, and use
{{TBD: ...}} only where project truth is genuinely unknown. Do not implement code.
```

### Plan

```text
Using the current SPEC.md, create or update TODO.md using the existing
Phase N → Agenda → Acceptance Coverage → To-do list pattern. Ensure every AC is owned
by at least one phase, choose per-phase MANUAL/AUTO mode, and add only real
dependencies. Do not start a phase.
```

### Execute Phase

```text
Execute the selected phase under AGENTS.md and WORKFLOW.md. Work only inside its
approved scope, update task state as work becomes true, validate incrementally, and
stop when a human gate, blocker, or AUTO stop condition is reached.
```

### Review

```text
Review the completed implementation against the phase Acceptance Coverage,
AGENTS.md engineering rules, and the current approved SPEC.md. Report only findings
that materially affect correctness, security, maintainability, scope, or completion.
```

### Verify Completion

```text
Verify the phase against the current wording of every AC it owns. If the phase's
Defined against revision differs from the current SPEC revision, re-verify every
owned AC. Run required validation and review, then use the authorized completion
procedure. Do not edit Status: Done or Completed against manually.
```
