# Getting Started

A step-by-step walkthrough for someone using this template for the first time. If
you already know the framework, `README.md` is the faster reference; this file is
the slower, narrated version.

---

## 1. What's in this folder

```text
smart-ai-project-template/
│
├── README.md                 Architecture reference. Dense; read after this file.
├── GETTING_STARTED.md         This file.
├── CLAUDE.md                  Tells Claude Code which installed capability handles
│                               each kind of work. You will not edit this.
├── GLOBAL_CLAUDE.example.md   Not part of this project. A copyable example for your
│                               personal ~/.claude/CLAUDE.md. Ignore it for now.
│
├── AGENTS.md                  The rulebook. What any agent must / must never do.
│                               You will rarely open this, never edit it.
├── SPEC.md                    THE PLAN. What you're building, how you'll know it's
│                               right. You will read and edit this a lot, especially
│                               at the start of a project.
├── TODO.md                    THE DIARY. What phase you're on right now, today.
│                               You will read this often, edit it occasionally.
├── WORKFLOW.md                The instruction manual an agent follows to perform
│                               each step correctly. You will rarely open this.
│
├── TEMPLATE_VERSION            One line: which version of this template you're on.
├── .gitignore                  Keeps secrets and junk out of Git.
├── .env.example                Safe placeholder env vars. Copy to .env.local and
│                               fill in real values there — .env.local is never
│                               committed.
│
├── .claude/
│   └── settings.json           Permission rules. Blocks reading secret files
│                               outright; makes Claude ask before destructive
│                               commands (force-push, terraform destroy, etc).
│
└── scripts/                    Things you RUN, not things you edit (except one).
    ├── check-spec.sh           Is SPEC.md ready to approve?
    ├── check-todo.sh           Is TODO.md internally consistent?
    ├── complete-phase.sh       The only way a phase is allowed to become "Done".
    └── validate.sh             Runs your project's real lint/test/build commands.
                                 Starts empty — YOU fill this in once, early on.
```

The one-sentence version: **`SPEC.md` and `TODO.md` are the files you live in.
Everything else is machinery that keeps those two files honest.**

---

## 2. The five files, in plain words

**`SPEC.md`** - the plan. What the project is, what "done" means for each piece of
it, what it's allowed to cost, what architecture it uses. Starts as a template full
of `{{TBD: ...}}` placeholders. Nothing real gets built until this file is filled in
and approved.

**`TODO.md`** - the diary. Broken into phases (Phase 1, Phase 2, ...). Each phase
has a status (`Not Started`, `In Progress`, `Blocked`, `Done`), a mode (`MANUAL` or
`AUTO`), and a checklist of tasks. This is where "what are we doing right now" lives.

**`AGENTS.md`** - the rulebook. Permanent rules an agent must follow: how to size a
task, when to write tests, what counts as a destructive action needing your
approval. You don't maintain this; it ships with the template.

**`WORKFLOW.md`** - the instruction manual. Step-by-step procedures for each kind
of work: how to run intake, how to start a phase, how to complete one. `AGENTS.md`
says the *rules*; `WORKFLOW.md` says the *steps*.

**`scripts/`** - the referee. Four small programs that check things mechanically
instead of trusting a claim. A phase cannot become `Done` by an agent saying so; it
becomes `Done` by `complete-phase.sh` agreeing.

---

## 3. The commands you'll actually type

All of these run from inside the project folder, in Claude Code's own built-in
terminal (you don't need to switch to a separate Mac Terminal or VS Code terminal
window - Claude Code has one). `cd` into the project first if you aren't already
there.

Check whether `SPEC.md` is ready to be approved:

```bash
bash scripts/check-spec.sh
```

Check whether `TODO.md` is internally consistent (phases reference real
requirements, dependencies aren't broken, etc.):

```bash
bash scripts/check-todo.sh
```

Run your project's actual tests, lint, and build:

```bash
bash scripts/validate.sh
```

Mark a phase complete - this is the ONLY way `Status: Done` should ever get
written. Replace `1` with the phase number:

```bash
bash scripts/complete-phase.sh 1
```

You can run any of these yourself directly, or just ask Claude to run them - either
way the same script does the same check. Running them yourself costs nothing and
doesn't use up a Claude Code turn, so it's a good habit for quick "where do we
stand" checks.

---

## 4. The real workflow, start to finish

### Step 1 - Describe the project

Type `/intake` followed by your description, however messy:

> /intake I want to build a kanban board app. Users can create boards, add columns,
> drag cards between columns. Needs login. Budget is $0/month.

`/intake` is a shortcut that runs `WORKFLOW.md`'s Intake and Context Normalization
procedure - it's the same result as describing the project in plain language and
asking Claude to run that procedure, just less typing. If you'd rather not use the
shortcut, plain language works exactly the same:

> I want to build a kanban board app. Users can create boards, add columns, drag
> cards between columns. Needs login. Budget is $0/month.

Either way, Claude should turn this into `SPEC.md` - not start writing application
code yet. If it starts writing code immediately, stop it and say "follow the intake
procedure in WORKFLOW.md first."

### Step 2 - You read `SPEC.md` yourself

This is the one step nothing else can substitute for. Open the file. Check the
requirements match what you actually meant. Check the cost table if any external
services are listed.

### Step 3 - Plan phases

While `SPEC.md` is still `DRAFT`, ask Claude to break the work into phases in
`TODO.md`. Planning during DRAFT is intentional - it often surfaces gaps in the
spec itself before you approve it. Each phase gets a mode:

- `MANUAL` - Claude checks in with you at decision points. Use this for anything
 risky, unclear, or security-sensitive (auth, payments, schema changes).
- `AUTO` - Claude works through the phase with less interruption, but it's bounded:
 it can't loop forever, and it can't skip validation. Use this for routine,
 well-defined work (CRUD screens, test coverage).

A phase may be planned this way, but it cannot *start* until SPEC is approved -
that's enforced in the next step.

### Step 4 - Approve the spec

```bash
bash scripts/check-spec.sh
```

The first few times, expect `NOT READY FOR APPROVAL` with a list of what's
incomplete - that's normal, it's telling you exactly what to fix. Once it exits
clean, run:

```bash
bash scripts/approve-spec.sh
```

Running this script IS the approval. It re-checks readiness, then atomically
increments `Spec revision` and sets `Status: APPROVED` in one step - there's no
separate hand-edit to get half-right. If you ever edit `SPEC.md` directly instead,
you must change both `Spec revision` (increment by exactly 1) and `Status` - but
the script exists precisely so you don't have to remember that. Nothing before
this point should touch real code.

### Step 5 - Work a phase

*(Note: the four commands below - `/start-phase`, `/block-phase`, `/resume-phase`,
`/complete-phase` - are planned but not yet built in this copy of the template.
Until they exist, just ask Claude in plain language: "start phase 2", "phase 2 is
blocked because X", "resume phase 2". Only `complete-phase.sh` exists as a real
script today.)*

```bash
bash scripts/complete-phase.sh 2
```

This is the one that matters most: it will refuse if tests fail or tasks are
unchecked, so a phase can't be marked done by mistake or by an agent's optimism.

### Step 6 - Repeat

Keep going phase by phase. If requirements change mid-project, `SPEC.md` goes back
to `DRAFT`, gets fixed, gets re-approved. That re-approval bumps a revision number,
so any phase finished under the old spec can be flagged for a second look.

---

## 5. The one manual thing you must not skip

Early in a real project, once there's something to test, fill in the four blank
lines in `scripts/validate.sh`:

```bash
LINT=""
TYPECHECK=""
TEST=""
BUILD=""
```

You don't write this yourself - ask Claude:

> Look at this project and fill in scripts/validate.sh with the real lint,
> typecheck, test, and build commands.

Claude reads your `package.json` (or equivalent) and fills in the real commands.
Leave a line blank if it doesn't apply to your project (e.g. no typecheck for a
plain JS project) - the script skips blank lines rather than failing on them.
Until this is filled in, `complete-phase.sh` refuses to mark anything done, on
purpose: an empty check is not a passing build.

---

## 6. Installing the capabilities this template expects

`CLAUDE.md` names specific installed capabilities it routes work to - things like
a spec-writing skill, a code-review skill, a browser-automation tool. If those
aren't installed, Claude falls back to doing the work without them and tells you
which one was missing; nothing breaks, but you lose some of the intended quality.

**This section is intentionally incomplete right now.** Claude Code plugins install
in two steps -

```bash
/plugin marketplace add <marketplace-source>
/plugin install <plugin-name>@<marketplace-name>
```

 - but the exact marketplace source for each capability `CLAUDE.md` references
hasn't been verified here, and two of them (`context7`, `playwright`) are actually
MCP servers, installed a different way (`claude mcp add ...`), not plugins. Writing
a single fabricated copy-paste block would mean it fails the first time a teammate
runs it - worse than leaving this blank.

**To finish this section once, correctly:** on the machine where this template
was originally set up, run:

```bash
/plugin list --installed
claude mcp list
```

and paste the output back so this section can be filled in with the exact, working
commands. After that, this becomes the one block every teammate runs after cloning
the repo, and everyone starts with the same capabilities.

---

## 7. What "something's wrong" looks like

- Claude writes application code before `SPEC.md` has real content → stop, redirect
 to intake.
- Claude says a phase is done without you seeing `complete-phase.sh` run and pass →
 don't accept it.
- `check-spec.sh` says `NOT READY FOR APPROVAL` and Claude wants to approve anyway →
 don't; fix what it lists first.
- `validate.sh` prints `WARNING: no validation commands configured` and a phase is
 being marked done anyway → stop; fill in the four blank lines first.
