# Smart AI Project Template v2.1.3

A compact, agent-friendly project framework for turning requirements into controlled, verifiable implementation without turning the repository into a documentation maze.

The template separates **project truth**, **execution state**, **agent policy**, **procedures**, and **tool-specific adapters** so every kind of information has one clear home.

## Repository map

```text
smart-ai-project-template/
│
├── README.md                 ← Human orientation. Explains the template and where information belongs.
├── CLAUDE.md                 ← Project Claude Code adapter, loaded automatically because it sits at the repository root. Imports AGENTS.md and maps its portable capability needs to installed Claude Code capabilities.
├── GLOBAL_CLAUDE.example.md  ← Example of a personal `~/.claude/CLAUDE.md`. Not loaded from this repository; copy it to your home directory if you want it.
├── AGENTS.md                 ← Portable operating policy for coding agents: rules, safety, routing, AUTO/MANUAL behavior, review, validation, and Definition of Done.
├── SPEC.md                   ← Current approved project truth: requirements, acceptance criteria, architecture, constraints, services, security, deployment, and important decisions.
├── TODO.md                   ← Current execution truth: phases, Mode, dependencies, revision state, acceptance coverage, tasks, blockers, and AUTO iteration budget.
├── WORKFLOW.md               ← Reusable multi-step procedures: intake, planning, phase start, MANUAL/AUTO execution, blocking/resume, replanning, completion, and adoption.
├── TEMPLATE_VERSION          ← Template release number. This release is 2.1.3.
│
├── .gitignore                ← Prevents local secrets, credentials, editor noise, dependencies, and build output from being committed.
├── .env.example              ← Safe environment-variable names and placeholders that may be committed. Never contains real secrets.
│
├── .claude/
│   └── settings.json         ← Permission policy. `deny` blocks secret reads outright; `ask` forces a human prompt for the destructive operations AGENTS.md gates.
│
└── scripts/                  ← Deterministic framework mechanics. These scripts check or transition framework state; they are not project business logic.
    ├── check-spec.sh         ← Checks SPEC.md structure and approval readiness/integrity.
    ├── check-todo.sh         ← Checks TODO.md structure and cross-file phase/acceptance/dependency integrity.
    ├── complete-phase.sh     ← Controlled phase state transition from In Progress to Done after required gates pass.
    └── validate.sh           ← Single project validation entrypoint. Configure it with the real project's lint/typecheck/test/build commands.
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

Claude Code loads `CLAUDE.md` from the working directory and every directory above
it, so the project adapter must stay at the repository root. Moving it to
`.claude/CLAUDE.md` would stop it loading — that path is only read for directories
added with `--add-dir` — and the failure is silent, so nothing would tell you the
capability mapping had disappeared.

## Where information goes

| Information | Authoritative home |
|---|---|
| What are we building? | `SPEC.md` |
| What behavior must be accepted? | `SPEC.md` acceptance criteria |
| What architecture/constraints/services are approved? | `SPEC.md` |
| What phase is being worked on now? | `TODO.md` |
| Is a phase MANUAL or AUTO? | `TODO.md` |
| What is blocked, done, or still pending? | `TODO.md` |
| What must an agent always/must never do? | `AGENTS.md` |
| How do we perform a recurring multi-step process? | `WORKFLOW.md` |
| How should Claude Code adapt to this project? | `CLAUDE.md` |
| What is the deterministic validation command? | `scripts/validate.sh` |
| What happened historically? | Git history |
| What should a human read first to understand the template? | `README.md` |

The rule is simple: **one fact, one authoritative home**. `README.md` explains the system but does not become a second copy of project requirements or status.

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

For an AUTO phase, Claude Code may use Ralph Loop as the execution engine when available:

```text
TODO.md: Mode = AUTO
        ↓
AGENTS.md policy + safety boundaries
        ↓
Claude capability selected for the work
        ↓
ralph-loop (optional executor)
        ↓
attempt → validate/verify → inspect → decide → repeat
        ↓
stop on success, budget exhaustion, repeated failure, blocker, hard gate, or protected-boundary change
```

Ralph Loop does **not** define AUTO and does not override the framework. AUTO is the portable policy; Ralph Loop is only one Claude-specific way to execute bounded autonomous iterations.

## Optional additions — only when earned

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
External request / Jira / GitHub issue / user idea
                    ↓
                  intake
                    ↓
                 SPEC.md
                    ↓
                 TODO.md
                    ↓
        AGENTS.md chooses constraints/routing
                    ↓
             implementation capability
                    ↓
       code + tests + project validation
                    ↓
         review + acceptance verification
                    ↓
          complete-phase.sh → Done
```

External trackers are useful inputs and collaboration systems, but `SPEC.md` and `TODO.md` remain the repository's current authoritative truth.

## First checks

```bash
bash scripts/check-spec.sh
bash scripts/check-todo.sh
bash scripts/validate.sh
```

A fresh template intentionally has an unfinished `SPEC.md`, and `validate.sh` intentionally warns until real project validation commands are configured. A phase must not be claimed complete until the real project has a deterministic validation gate.

### Permission policy

`.claude/settings.json` encodes the `AGENTS.md` §6 safety model in the two primitives
Claude Code actually provides:

```text
deny  → the operation can never happen
ask   → STOP, a human confirms, then it may proceed
```

A hard human gate is an `ask`, not a `deny`. Rules are evaluated deny → ask → allow
and the first match wins regardless of specificity, so a broad deny cannot carry an
allowlist exception — denying `Bash(aws *)` would also block `aws s3 ls` during
ordinary debugging, with no way to authorize it from inside a session. Only secret
reads and edits are denied outright; destructive infrastructure, publish, and history
operations are `ask`.

Explicit `ask` rules prompt even in permission modes that would otherwise auto-approve,
which is what makes them usable as gates during an AUTO phase.

`Read` and `Edit` patterns use gitignore syntax, where `*` matches within a single
path segment. `Read(.env.*)` would therefore also match `.env.example` and lock the
template out of the one env file that is meant to be readable, so the denies name the
secret-bearing files individually. For the same reason `~/.aws/` and `~/.ssh/` are not
denied wholesale — that would block harmless config and `known_hosts` during ordinary
work — only the credential and private-key paths inside them.

Three caveats worth knowing before you trust a rule:

- **Bash argument patterns are guidance, not a boundary.** A pattern matching on flags
  or URLs fails on reordered options, variables, or extra spaces, and a deny rule does
  not match the same program invoked as `/bin/rm` or inside `sh -c`. Treat these rules
  as a speed bump; `AGENTS.md` and the completion gates remain the real control.
- **`Write(path)` rules are silently ignored** — file-permission checks only consult
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
