# Smart AI Project Template v2.4.0

**New to this template? Start with [`GETTING_STARTED.md`](./GETTING_STARTED.md)** -
a narrated, step-by-step walkthrough. This file is the denser architecture
reference.

A compact, agent-friendly project framework for turning requirements into controlled, verifiable implementation without turning the repository into a documentation maze.

The template separates **project truth**, **execution state**, **agent policy**, **procedures**, and **tool-specific adapters** so every kind of information has one clear home.

## Repository map

```text
smart-ai-project-template/
│
├── README.md
├── GETTING_STARTED.md
├── CLAUDE.md
├── GLOBAL_CLAUDE.example.md
├── AGENTS.md
├── WORKFLOW.md
├── SPEC.md
├── TODO.md
├── EVIDENCE.md              ← current verification truth
├── TEMPLATE_VERSION         ← 2.3.0
│
├── .framework/
│   ├── validation.conf      ← registered normal-validation surfaces + runtime checks
│   ├── validation-ignore.txt
│   ├── smoke.conf           ← packaging/deployment smoke gates
│   └── auto/                ← local durable AUTO executor state (ignored by Git)
│
├── scripts/
│   ├── check-spec.sh
│   ├── check-todo.sh
│   ├── check-evidence.sh
│   ├── check-validation-surfaces.sh
│   ├── check-framework.sh
│   ├── approve-spec.sh
│   ├── auto-state.sh
│   ├── complete-phase.sh
│   ├── validate.sh
│   ├── smoke.sh
│   └── certify-project.sh
│
└── tests/framework/
    └── run.sh               ← framework lifecycle/self-tests
```

The central separation is:

```text
SPEC.md      = what must be true
TODO.md      = what work is being executed
EVIDENCE.md  = what has actually been proven
AGENTS.md    = authority and permanent rules
WORKFLOW.md  = lifecycle procedures
scripts/     = deterministic enforcement/state transitions
```

### Local-only file

```text
.env.local                    ← Real local environment values/secrets. Ignored by Git. Never commit it. Not shipped in the template.
```

### Three files named CLAUDE, three different jobs

```text
CLAUDE.md                     ← in this repository, at the root
                                 How Claude works with THIS project.
                                 Loaded automatically at session start.
                                 Committed and shared with the team.

~/.claude/CLAUDE.md           ← on your machine, outside any repository
                                 How YOU prefer Claude to work across all projects.
                                 Personal; never committed here.

GLOBAL_CLAUDE.example.md      ← in this repository, at the root
                                 A distributable example of the file above.
                                 Loaded by nothing. Copy it to ~/.claude/CLAUDE.md
                                 to use it, then edit it there.
```

Current Claude Code docs confirm a project CLAUDE.md may live at either `./CLAUDE.md`
or `./.claude/CLAUDE.md` - both load automatically. This template keeps it at the
repository root as a convention (visible immediately, no reason to hide it in
`.claude/`), not because the other location is broken. If you move it, run
`/context` in a session to confirm it still appears under **Memory files**.

## Where information goes

| Information | Authoritative home |
|---|---|
| What are we building? | `SPEC.md` |
| What behavior must be accepted? | `SPEC.md` acceptance criteria |
| What proof class is required? | `SPEC.md` acceptance criteria |
| What phase is active / blocked / done? | `TODO.md` |
| Is a phase MANUAL or AUTO? | `TODO.md` |
| Is AUTO policy-only or executor-backed? | `TODO.md` |
| What evidence actually passed? | `EVIDENCE.md` |
| Has an external integration only been implemented, tested, or live verified? | `EVIDENCE.md` |
| What must an agent always/must never do? | `AGENTS.md` |
| How does a lifecycle procedure run? | `WORKFLOW.md` |
| What is normal validation? | `scripts/validate.sh` + `.framework/validation.conf` |
| What is packaging/deployment smoke? | `scripts/smoke.sh` + `.framework/smoke.conf` |
| What happened historically? | Git |

One fact should still have one authoritative home.


## Human Terminal

This template ships a shared Claude Code output style at
`.claude/output-styles/human-terminal.md`.

Human Terminal is designed for fast engineering work:

- routine success is compressed
- failures, blockers, and important decisions are expanded
- SPEC, TODO, EVIDENCE, validation, AUTO, cost, and security state are easy to scan
- genuine human gates are visually obvious
- `/intake` remains the public project-entry command
- internal skill, plugin, and capability-routing details stay out of normal user-facing output

The committed `.claude/settings.json` selects `Human Terminal` as the shared
project default.

Users can still override presentation preferences locally without changing the
framework or the repository.


## Claude Code layer

`AGENTS.md` states *what capability is needed*; `CLAUDE.md` resolves each need to an
installed Claude Code capability. No plugin name appears in `AGENTS.md`, so another
coding agent supplies its own adapter and the policy stays portable.

```text
Claude Code
    ↓
CLAUDE.md                    ← Claude-specific adapter
    ↓ imports
AGENTS.md                    ← portable policy
    ↓
SPEC.md + TODO.md            ← current project + execution truth
    ↓
WORKFLOW.md                  ← procedures when a multi-step workflow is needed
```

AUTO now has two explicit layers:

```text
AUTO POLICY
  = authority boundaries + stop conditions

AUTO EXECUTOR (optional)
  = persistent attempt -> validate -> inspect -> decide orchestration
```

`Mode: AUTO` alone does not claim persistent autonomous execution.

- `AUTO executor: NONE` = policy-only AUTO; no durable iteration count is claimed.
- an adapter-defined executor such as `ralph-loop` = durable executor-backed AUTO;
  `scripts/auto-state.sh` accounts attempts mechanically and cumulatively.

Human resume never resets consumed executor iterations. `auto-state.sh resume`
reactivates the existing ledger after human authorization; a human-approved budget
increase uses `auto-state.sh rebudget` and preserves consumed iterations. The executor
cannot rewrite its own acceptance criteria, budget, scope, or completion state.

## Lifecycle skills - shipped with the template

```text
.claude/
└── skills/
    └── intake/
        └── SKILL.md          ← /intake -- thin wrapper over WORKFLOW.md's Intake
                                  and Context Normalization procedure.
```

These give Claude Code a shortcut for framework operations that already exist in
`WORKFLOW.md`. A lifecycle skill contains no logic of its own -- it names the
`WORKFLOW.md` procedure to run and passes along whatever you typed after the
command. If you edit how intake behaves, edit `WORKFLOW.md`, not this file; the
skill's whole job is pointing at the one place that behavior is actually defined.

`disable-model-invocation: true` means Claude runs it only when you type `/intake`
-- never on
its own initiative. Other lifecycle skills (`/project-plan`, `/phase-review`, and
the phase state-transition commands) are intentionally not built yet. Build one
only once you've felt the friction of typing the equivalent request in full
sentences -- `/intake` is the exception, since it's the one command guaranteed to
run on day one of every project, so there was no friction to wait for.

## Optional additions - only when earned

These are **not** part of the base template. Add them only when a real project needs them.

```text
.claude/
└── skills/
    └── <project-specific-skill>/
        └── SKILL.md          ← Specialized project knowledge or a repeatable project-specific capability.

DEBUG.md                     ← Temporary investigation artifact for a difficult, context-heavy bug; remove when no longer useful.
```

Examples of good project-local skills: a company API integration, a project-specific deployment procedure, or a specialized model/provider recipe. Do not create empty skill folders or generic skills just for ceremony.

**Why project-local skills are allowed at all.** An earlier version of this template
ruled that skills live only in `~/.claude/` and are never vendored per repository,
because copying generic engineering skills into every project is duplication. That
still holds for generic skills. Project-*specific* expertise is different: it is
project state, it travels with the repository, and it is useless outside it. The rule
is therefore: generic skills global, project-specific skills local, nothing created
for ceremony.

## Personal Claude preferences live outside the repository

Your personal defaults should not pollute a reusable project template.

```text
~/.claude/
└── CLAUDE.md                ← User-level preferences applied across your Claude Code projects.
```

Good examples: use `uv` for Python projects, work incrementally, diagnose root cause before fixing, avoid overengineering, or other personal workflow preferences.

Do not place project requirements, project status, or project architecture in the global file.

## Working model

```text
intake
  ↓
SPECIFICATION
  ↓
semantic consistency review
  ↓
human approval -> approve-spec.sh
  ↓
phase planning -> TODO.md + EVIDENCE.md obligations
  ↓
execution
  ↓
normal validation / smoke / live verification as required
  ↓
review
  ↓
complete-phase.sh
  ↓
commit checkpoint
  ↓
next phase
  ↓
certify-project.sh
```

Normal validation is deliberately separate from packaging/deployment smoke, and
external integration state is deliberately separate from adapter existence or mocks.

## First checks

```bash
bash scripts/check-spec.sh
bash scripts/check-todo.sh
bash scripts/check-evidence.sh
bash scripts/check-framework.sh
bash scripts/validate.sh
```

A fresh template intentionally returns `2` from `validate.sh`:

```text
FRAMEWORK: PASS
PROJECT SURFACES: NONE DETECTED
PROJECT VALIDATION: NOT CONFIGURED
OVERALL: PRE-SCAFFOLD
```

That is not a project PASS. Once an executable surface appears, it must be registered
in `.framework/validation.conf`; otherwise validation fails. Each registered surface
contains a runtime preflight and at least one real lint/typecheck/test/build command.

Template maintainers also run:

```bash
bash tests/framework/run.sh
```

Those self-tests exercise the lifecycle machinery itself rather than project code.

### Permission policy

`.claude/settings.json` encodes the `AGENTS.md` §6 safety model in the two primitives
Claude Code actually provides:

```text
deny  → the operation can never happen
ask   → STOP, a human confirms, then it may proceed
```

A hard human gate is an `ask`, not a `deny`. Rules are evaluated deny → ask → allow
and the first match wins regardless of specificity, so a broad deny cannot carry an
allowlist exception - denying `Bash(aws *)` would also block `aws s3 ls` during
ordinary debugging, with no way to authorize it from inside a session. Only secret
reads and edits are denied outright; destructive infrastructure, publish, and history
operations are `ask`.

Explicit `ask` rules prompt even in permission modes that would otherwise auto-approve,
which is what makes them usable as gates during an AUTO phase.

`Read` and `Edit` patterns use gitignore syntax, where `*` matches within a single
path segment. `Read(.env.*)` would therefore also match `.env.example` and lock the
template out of the one env file that is meant to be readable, so the denies name the
secret-bearing files individually. For the same reason `~/.aws/` and `~/.ssh/` are not
denied wholesale - that would block harmless config and `known_hosts` during ordinary
work - only the credential and private-key paths inside them.

Three caveats worth knowing before you trust a rule:

- **Bash argument patterns are guidance, not a boundary.** A pattern matching on flags
 or URLs fails on reordered options, variables, or extra spaces, and a deny rule does
 not match the same program invoked as `/bin/rm` or inside `sh -c`. Treat these rules
 as a speed bump; `AGENTS.md` and the completion gates remain the real control.
- **`Write(path)` rules are silently ignored** - file-permission checks only consult
 `Edit(path)` and `Read(path)`. A `Read` deny also covers Edit and Write on the same
 path, but not NotebookEdit, which is why each secret file is listed under both.
- **A trailing `:*` covers the bare command too.** `Bash(npm publish:*)` is equivalent
 to `Bash(npm publish *)` and matches `npm publish` on its own, so one rule per
 operation is enough. This holds only while the trailing wildcard is the rule's only
 wildcard.

Verify these against the current Claude Code permission documentation the first time
you rely on them; the model has changed across releases.

## Design principle

The template should **reduce model context, not consume it**. Keep permanent files small enough to stay useful, add project-specific artifacts only when they earn their place, and prefer stronger decisions and verification over more process.

<!-- FRONTEND-STACK:BEGIN -->
## Frontend capability stack

For projects with a user-facing UI, this template uses a deliberate design workflow rather than one-shot page generation.

- `frontend-design` — visual direction and design judgment.
- shadcn MCP — standard component primitives and registry discovery.
- 21st MCP — premium/reference component discovery.
- Playwright — rendered visual and interaction verification.
- Context7 — current framework and library documentation.

Project MCPs live in `.mcp.json`, so native Claude and the isolated CCR Claude lane use the same project tooling while keeping their user profiles separate.
<!-- FRONTEND-STACK:END -->
