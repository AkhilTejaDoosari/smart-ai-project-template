@AGENTS.md

# Claude Code Adapter

The imported `AGENTS.md` is the authoritative agent policy for this repository.
Do not copy or restate its engineering rules here.

This file does one job: resolve the portable capability needs in `AGENTS.md` §4 to
the capabilities installed in this Claude Code environment.

## Capability mapping

| Need (`AGENTS.md` §4) | Claude Code capability |
|---|---|
| specification-driven development | `agent-skills:spec-driven-development` |
| structured brainstorming | `superpowers:brainstorming` |
| plan writing | `superpowers:writing-plans` |
| feature development workflow | `feature-dev` |
| plan execution | `superpowers:executing-plans` |
| incremental implementation | `agent-skills:incremental-implementation` |
| test-driven development | `superpowers:test-driven-development` |
| API and interface design | `agent-skills:api-and-interface-design` |
| frontend UI engineering | `agent-skills:frontend-ui-engineering` |
| frontend design | `frontend-design` |
| systematic root-cause debugging | `superpowers:systematic-debugging` |
| current documentation lookup | `context7` |
| browser automation | `playwright` |
| security guidance | `security-guidance` |
| security and hardening review | `agent-skills:security-and-hardening` |
| code review | `code-review` |
| simplification | `code-simplifier` |
| verification before completion | `superpowers:verification-before-completion` |

If a mapped capability is unavailable in this session, say which one is missing, use
the closest available equivalent, and do not skip the underlying engineering or
verification work.

## AUTO execution

- When a `TODO.md` phase has `Mode: AUTO`, `ralph-loop` may be used as the Claude
 Code execution engine when available and appropriate.
- Ralph Loop remains bounded by that phase's `AUTO iteration budget` and every AUTO
 stop condition and hard human gate in `AGENTS.md`.
- Ralph Loop cannot authorize its own resume, change protected AUTO fields, bypass
 validation, or mark a phase `Done` outside the required completion procedure.

AUTO is portable policy defined in `AGENTS.md`. Ralph Loop is only one Claude-specific
way to execute bounded autonomous iterations.

## Project-local skills

Add specialized project knowledge under `.claude/skills/<skill>/SKILL.md` only when
the project genuinely needs it. Generic engineering skills stay installed globally
and are not vendored into this repository.

Project requirements, architecture, constraints, execution state, and progress belong
in their authoritative files defined by `AGENTS.md`, not in this adapter.
