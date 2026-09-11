# Global Claude Code Preferences - Example

**This file is not loaded from this repository.** It is a distributable example of a
*personal* Claude Code memory file. Nothing here applies to this project unless you
copy it into your own home directory:

```bash
mkdir -p ~/.claude
cp GLOBAL_CLAUDE.example.md ~/.claude/CLAUDE.md
```

Claude Code loads `CLAUDE.md` from your working directory and every directory above
it, plus `~/.claude/CLAUDE.md` as user-scope memory. A file sitting in a project
under this name is just a text file until you install it.

Keep personal preferences here. Project requirements, architecture, and status belong
in `SPEC.md` and `TODO.md`; agent policy belongs in `AGENTS.md`.

---

## Work style

- Keep solutions simple, incremental, and scoped to the actual requirement.
- Understand the problem before editing code.
- Search existing code and reuse established patterns before creating new ones.
- Avoid unnecessary abstractions, dependencies, files, services, and complexity.
- Validate each meaningful increment before moving on.
- Do not claim completion without evidence that the result works.

## Debugging

- Reproduce the problem before fixing it.
- Identify and prove the root cause. Do not guess.
- Do not treat a single old issue thread or forum post as proof.
- Prefer the smallest correct fix over a workaround.
- Add regression protection for behavioral bugs when practical.
- Verify that the original failure no longer occurs.
- Take a Git snapshot before a deep investigation.
- For a long or uncertain investigation, a temporary `DEBUG.md` may record evidence,
 hypotheses, ruled-out causes, root cause, fix, and verification. Remove it when the
 investigation is over.

## Python

Use `uv` by default for dependency and environment management.

- Prefer `uv add <package>` over `pip install`.
- Prefer `uv run <command>` for Python commands and project tools.
- Prefer `uv sync` for restoring project dependencies.
- Do not introduce a second Python package manager where `uv` is established.
- Preserve an existing project's deliberate toolchain unless asked to migrate it.

## Terminal and automation

- Prefer reliable automation over repetitive manual copy-paste when it makes the task
 safer and simpler.
- For substantial terminal or debugging work, prefer one coherent script with
 validation, checks, and clear failure handling.
- Never print, expose, or commit secrets unnecessarily.

## Current documentation

When library, framework, SDK, API, or platform behavior is version-sensitive, verify
against current documentation rather than relying on model memory.
