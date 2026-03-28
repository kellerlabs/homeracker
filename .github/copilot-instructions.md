# HomeRacker Copilot Instructions

## Project Overview
HomeRacker is a modular 3D-printable rack-building system. Core components use parametric OpenSCAD models (BOSL2 library). Licensed: MIT (code), CC BY-SA 4.0 (models).

## Tools & Structure
- **Languages**: OpenSCAD (.scad), Python, Bash
- **Preferred Tooling**: GitHub MCP Server, Context7 MCP Server
- **Key Dirs**: `/models/` (SCAD files), `/bin/` (tools), `/scripts/` (Fusion 360 automation)
- **HomeRacker Standards**: 15mm base unit, 4mm lock pins, 2mm walls, 0.2mm tolerance. See `README.md` for details.
- **Contribution Guide**: See `CONTRIBUTING.md` for setup and workflow instructions.
- **Dependency Manager**: Use `scadm` to install OpenSCAD and libraries
  - Install: `scadm` (installs OpenSCAD + libraries from `scadm.json`)
  - Config: `scadm.json` in project root defines library dependencies
  - Help: `scadm -h` for usage info

## Core Principles
- **Test-Driven Development**: NO change without a test. EVERY change MUST be tested before completion. No exceptions for "simple" changes.
- **DRY, KISS, YAGNI**: Keep it simple, don't over-engineer
- **Be Brief**: All outputs (code, docs, issues, PRs) should be minimal and to-the-point
  - Code: No unnecessary comments, clear variable names speak for themselves
  - Docs: Essential info only - what/why/how in <100 lines when possible
  - GitHub issues/PRs: Clear problem/solution, skip verbose explanations
- **Use Emojis**: Supplement PR descriptions, issue comments, and review comments with emojis for easier reading (e.g. ✅ ❌ 🔧 📦 💡 🚀 ⚠️)
- **Documentation Policy**:
  - Every code change that adds, modifies, or removes functionality **must** include a documentation update.
  - Follow the What / Why / How / References structure defined in the markdown instructions.
  - When renaming or restructuring code, update or rename the associated docs to keep everything tidy.
  - When adding or modifying model parts (`parts/*.scad`), **generate preview PNGs** with `cmd/export/export-png.sh` and update both the model's README 📸 Catalog and the parent `models/README.md` index.
- **Commits**: Use [Conventional Commits](https://www.conventionalcommits.org/) format
  - Types: `feat`, `fix`, `docs`, `chore`, `refactor`, `test`
  - Format: `type(scope): description` or `type: description`
  - Breaking changes: Add `!` (e.g., `feat!: change base unit`)

## Terminal Session Setup
Before terminal operations, consider running these steps (use best judgement):
1. `git fetch origin && git rebase origin/main` — sync with latest main
2. `source .venv/Scripts/activate` (Windows) or `source .venv/bin/activate` (Linux/macOS) — activate venv

> **Note**: `scadm` upgrade and `scadm install` run automatically via a `SessionStart` hook (see `.github/hooks/`).

## **MANDATORY** Workflow
1. **Check repo patterns** first for consistency
2. **Consult online docs** (especially BOSL2: https://github.com/BelfrySCAD/BOSL2/wiki). Use Context7 MCP Server for quick access to docs and codebase where applicable.
3. **Ask before proceeding** if requirements conflict with best practices or patterns in the repo
4. **Provide outline** before implementation for confirmation
5. **Make the change** and immediately test it - do NOT announce completion before testing
6. **Update** existing documentation (.md files) and create new ones where applicable
7. **Run pre-commit hooks** to catch formatting/linting issues before commit. Fix any issues found (no ignores allowed).
8. **Code review**: Review ALL changes made in the session — check for consistency, missed edge cases, and unintended side effects before presenting to the user.
9. **Creating PRs**: Use the **GitHub MCP Server** (never `gh` CLI). Read `.github/pull_request_template.md` and fill in every section. Keep it brief per project conventions.
10. **On errors**: Step back, check docs, ask user if stuck—don't iterate blindly

## Technology-Specific Guidelines
- Documentation: See .github/instructions/markdown.instructions.md
- OpenSCAD: See .github/instructions/openscad.instructions.md
- Python: See .github/instructions/python.instructions.md
- Renovate: See .github/instructions/renovate.instructions.md
