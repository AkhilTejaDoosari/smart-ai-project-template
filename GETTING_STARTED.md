# Getting Started

This is the narrated walkthrough for Smart AI Project Template v2.3.0.
`README.md` is the denser architecture reference.

---

## 1. The files you actually live in

```text
SPEC.md      = what the project must be
TODO.md      = what work is being executed now
EVIDENCE.md  = what has actually been proven
```

Everything else either defines policy/procedure or mechanically keeps those files
honest.

```text
AGENTS.md                    permanent agent rules and authority boundaries
WORKFLOW.md                  lifecycle procedures
CLAUDE.md                    Claude-specific capability/executor adapter
.framework/validation.conf   normal-validation surface registry
.framework/smoke.conf        expensive packaging/deployment smoke gates
scripts/                     deterministic checks and state transitions
tests/framework/run.sh       tests the framework itself
```

---

## 2. Start with intake

Two modes are explicit.

### No requirements yet

```text
/intake
```

Claude should say that no requirements were supplied and begin discovery. It should
also mention that `/intake <requirements>` can normalize an existing dump.

### Requirements already exist

```text
/intake I want to build ...
```

Claude normalizes the supplied context into `SPEC.md`. It should not begin application
code yet.

During intake, important decisions include runtime versions, data ownership classes,
external providers/test providers, network exposure, costs, and unresolved questions.

---

## 3. Review the DRAFT SPEC

Read `SPEC.md` yourself.

Check that:

- the requirements match what you meant
- acceptance criteria are binary and observable
- each AC has the right proof class (`NORMAL`, `SMOKE`, `LIVE`, `MANUAL`)
- global/reference data is not incorrectly treated as user-owned
- unauthenticated apps define localhost/LAN/public exposure explicitly
- external AI/services have deterministic automated-test providers where appropriate
- runtime versions are concrete when version matters
- Important Decisions contain actual choices, not `e.g.` examples
- Open Questions truthfully reflects what still needs confirmation

Then run:

```bash
bash scripts/check-spec.sh
```

While the SPEC is DRAFT, a non-zero exit means “not ready for approval yet,” not
“project build failed.”

---

## 4. Approve the SPEC

Mechanical readiness is only half the gate. Claude/human review must also check that
Product, Requirements, ACs, Constraints, Architecture, Data, Services, Security, and
Deployment do not contradict one another.

When that semantic review is complete:

```bash
bash scripts/approve-spec.sh
```

Do not manually edit `Status` and `Spec revision` to approve. The script atomically
changes:

```text
DRAFT rev N -> APPROVED rev N+1
```

---

## 5. Plan phases

Choose one planning default once:

```text
CONSERVATIVE  mostly MANUAL
HYBRID        selected AUTO phases
AUTONOMOUS    routine implementation phases default AUTO
CUSTOM        explicit per-phase choices
```

That choice helps planning; each phase's `Mode` is still authoritative.

Each phase records:

```text
Status
Mode
Depends on
Defined against
Completed against
AUTO executor
AUTO iteration budget
```

AUTO has two different meanings now:

```text
Mode: AUTO + AUTO executor: NONE
  -> policy-only AUTO
  -> Claude may continue safe in-scope work without intermediate approval
  -> no durable iteration count is claimed

Mode: AUTO + AUTO executor: <executor>
  -> persistent autonomous executor selected
  -> positive iteration budget required
  -> scripts/auto-state.sh records durable cumulative attempts
```

Run:

```bash
bash scripts/check-todo.sh
bash scripts/check-evidence.sh
```

---

## 6. Register project validation as soon as code surfaces exist

A fresh template intentionally returns:

```text
FRAMEWORK: PASS
PROJECT SURFACES: NONE DETECTED
PROJECT VALIDATION: NOT CONFIGURED
OVERALL: PRE-SCAFFOLD
```

with exit code `2` from:

```bash
bash scripts/validate.sh
```

That is **not** a passing build.

When a backend/frontend/worker/infra surface appears, add one line to:

```text
.framework/validation.conf
```

Format:

```text
name|path|runtime_check|lint|typecheck|test|build
```

Example:

```text
backend|backend|python -c 'import sys; assert sys.version_info[:2] == (3,13)'|ruff check .||pytest|
```

Every registered surface must have a runtime check **and** at least one real project
check from lint/typecheck/test/build. If a new executable surface is detected but not
registered or explicitly ignored, validation fails.

This prevents a project from adding a frontend while still validating only the backend,
or approving Python 3.13 while silently testing on Python 3.14.

---

## 7. Keep normal validation separate from packaging smoke

Normal fast validation:

```bash
bash scripts/validate.sh
```

Packaging/deployment smoke:

```bash
bash scripts/smoke.sh
```

Configure smoke gates in:

```text
.framework/smoke.conf
```

Use smoke for things like real Docker build/start, packaged CLI execution, restart
persistence, or deployment verification. Do not make every normal validation cycle
pay that cost unless the project deliberately requires it.

---

## 8. Record evidence as you prove things

`EVIDENCE.md` is not a diary. It is current verification truth.

For each AC, record:

```text
Required proof
Result: NOT VERIFIED | PASS | FAIL
Evidence
```

External integrations use cumulative states:

```text
IMPLEMENTED -> TESTED -> LIVE VERIFIED
```

A mock, deterministic stub, adapter, or no-credential fallback can never produce
`LIVE VERIFIED`.

If the SPEC requires `LIVE VERIFIED`, real provider contact through the real configured
credential path must be observed and recorded.

---

## 9. Complete a phase

Before completion:

- all phase tasks are actually done
- review is complete when required
- all ACs owned by the phase are `PASS` in `EVIDENCE.md`
- required smoke/live/manual evidence has been obtained
- `scripts/validate.sh` exits `0`

Then run:

```bash
bash scripts/complete-phase.sh 1
```

The script atomically writes:

```text
Status: Done
Completed against: Spec revision N
```

It does not commit Git.

Afterward inspect the diff and create a phase checkpoint commit when appropriate.

---

## 10. Executor-backed AUTO

If a phase selected a real executor, initialize its durable ledger once:

```bash
bash scripts/auto-state.sh init 2 ralph-loop 10
```

After each genuine attempt/verify/inspect cycle:

```bash
bash scripts/auto-state.sh consume 2 PASS result-id "implemented and verified slice"
```

or:

```bash
bash scripts/auto-state.sh consume 2 FAIL failure-id "same failing validation"
```

The count persists across sessions. Reinitializing an existing ledger is rejected.
After an executor stop condition, a human-authorized resume reactivates the existing
ledger without resetting consumed iterations:

```bash
bash scripts/auto-state.sh resume 2 "reviewed blocker and authorized retry"
```

If the iteration budget is exhausted, ordinary resume is rejected. Keep the phase
Blocked, human-replan the budget, update TODO, and mechanically preserve prior usage:

```bash
bash scripts/auto-state.sh rebudget 2 15 "approved additional attempts"
bash scripts/auto-state.sh resume 2 "resume after approved rebudget"
```

Reads, planning, reporting, and housekeeping are not iterations.

---

## 11. Finish the whole project

When all phases are Done:

1. all AC evidence must be PASS
2. integrations must meet their SPEC-required final state
3. normal validation must pass
4. required smoke gates must pass
5. `Final Certification Notes` in `EVIDENCE.md` must be exactly `None`

Then run:

```bash
bash scripts/certify-project.sh
```

Certification is read-only. It does not repair missing state or invent evidence.

---

## 12. Test the template itself

If you are maintaining the Smart AI Project Template, run:

```bash
bash tests/framework/run.sh
```

These tests exercise the framework machinery itself: phase parsing, approval,
completion, validation-surface discovery, runtime mismatch, AUTO accounting and
human resume/rebudget, evidence proof contracts, smoke separation, and both successful
and rejected final certification paths.

Template CI should run this suite on both macOS and Linux.

---

## 13. The important mental model

```text
SPEC says what must be true.
TODO says what we are doing.
EVIDENCE says what we proved.

AUTO policy grants authority.
AUTO executor performs persistent orchestration.
They are not the same thing.

Normal validation proves routine project correctness.
Smoke proves the shipping artifact/deployment path.
Live verification proves the real external provider.
They are not the same thing either.
```
