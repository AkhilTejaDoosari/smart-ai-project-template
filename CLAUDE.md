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

<!-- CLAUDE-FRONTEND-ADAPTER:BEGIN -->
## Frontend capability routing

For user-facing UI work:

- Visual direction, typography, composition, color, hierarchy, interaction quality → `frontend-design`
- Standard product primitives and registry search → `shadcn` MCP
- Premium/reference component discovery → `21st` MCP
- Browser rendering, responsive inspection, interaction checks, screenshots → `playwright`
- Current framework/library behavior → `context7`

Execution order for substantial frontend work:

1. Establish one coherent visual direction with `frontend-design`.
2. Inspect existing tokens and components.
3. Reuse existing components where possible.
4. Search shadcn for standard primitives.
5. Search 21st only when a stronger reference/component materially improves the result.
6. Adapt selected components to the project's own design system.
7. Implement the smallest coherent screen or flow.
8. Render with Playwright at desktop and mobile widths.
9. Fix hierarchy, typography, spacing, contrast, overflow, responsiveness, interaction, and accessibility defects.
10. Re-render before declaring completion.

Do not add Motion or another component library merely because it is available. Add a visual dependency only when the approved design direction requires it.
<!-- CLAUDE-FRONTEND-ADAPTER:END -->
