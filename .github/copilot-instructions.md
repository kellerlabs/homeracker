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
  - **Unit tests**: run via pre-commit hooks (fast, mocked). Always run before commit.
  - **Integration tests**: run via CI workflow on ubuntu + windows (`integration-tests.yml`). Update when adding/modifying CLI commands or config schema. See `TESTING.md`.
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
- **Assets Policy**: All manually-created images (photos, diagrams, logos, MakerWorld description images) are hosted in [`kellerlabs/assets`](https://github.com/kellerlabs/assets). Push directly to its `main` branch. Reference via `https://raw.githubusercontent.com/kellerlabs/assets/main/<repo>/<path>`. Only auto-generated render PNGs (`**/renders/*.png`) are tracked in source repos. See [ADR-001](docs/decisions/ADR-001-image-hosting-assets-repo.md).
- **Architecture Decision Records (ADRs)**:
  - When the user makes an architectural or design decision during a session, create an ADR in `docs/decisions/`.
  - Format: `ADR-NNN-<slug>.md`, numbered sequentially.
  - Cross-link the ADR from related docs (READMEs, instructions, other ADRs) where viable.
- **Commits**: Use [Conventional Commits](https://www.conventionalcommits.org/) format
  - Types: `feat`, `fix`, `docs`, `chore`, `refactor`, `test`
  - Format: `type(scope): description` or `type: description`
  - Breaking changes: Add `!` (e.g., `feat!: change base unit`)
  - **NEVER amend commits** (`--amend`). PRs are squash-merged, so extra commits are fine.

## Terminal Session Setup
Before terminal operations, consider running these steps (use best judgement):
1. `git fetch origin && git rebase origin/main` — sync with latest main
2. `source .venv/Scripts/activate` (Windows) or `source .venv/bin/activate` (Linux/macOS) — activate venv

> **Note**: `scadm` upgrade and `scadm install` run automatically via a `SessionStart` hook (see `.github/hooks/`).

## **MANDATORY** Workflow
> [!IMPORTANT]
> **On errors**: Step back, check docs, ask user if stuck—don't iterate blindly

1. **Check repo patterns** first for consistency
1. **Consult online docs** (especially BOSL2: https://github.com/BelfrySCAD/BOSL2/wiki). Use Context7 MCP Server for quick access to docs and codebase where applicable.
1. **Ask before proceeding** if requirements conflict with best practices or patterns in the repo
1. **Provide outline** before implementation for confirmation
1. **Make the change** and immediately test it - do NOT announce completion before testing
1. **Update** existing documentation (.md files) and create new ones where applicable
1. **Run pre-commit hooks** to catch formatting/linting issues before commit. Fix any issues found (no ignores allowed).
1. **Code review**: When done implementing review ALL changes made from a holistic perspective — check for consistency, missed edge cases, and unintended side effects before presenting to the user.
1. **Creating PRs**: Use the **GitHub MCP Server** (never `gh` CLI). Read `.github/pull_request_template.md` and fill in every section. Keep it brief per project conventions.

## Technology-Specific Guidelines
- Documentation: See .github/instructions/markdown.instructions.md
- OpenSCAD: See .github/instructions/openscad.instructions.md
- Python: See .github/instructions/python.instructions.md
- Renovate: See .github/instructions/renovate.instructions.md
