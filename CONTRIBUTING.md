# Contributing to HomeRacker

Thanks for your interest in contributing! Even getting this far is already worth a ton 🏋

## 📦 Contribution Scope

This repository contains the **HomeRacker Core** system. We accept **bugfixes and improvements to the core model** here.

**New features, modules, and extensions** (e.g. new mount types, adapters, accessories) should be contributed to the [HomeRacker Community Repository](https://github.com/kellerlabs/homeracker-community).

> 💡 Not sure where your contribution belongs? [Open an issue](https://github.com/kellerlabs/homeracker/issues) or [start a discussion](https://github.com/kellerlabs/homeracker/discussions) first — we're happy to help you find the right place.

## 🚀 Quick Start

### Pre-commit Hooks (Required)

This repository uses [pre-commit](https://pre-commit.com/) to enforce code quality checks before commits.

**Prerequisites**: Python 3.x installed on your system

```bash
# Clone and setup
git clone https://github.com/kellerlabs/homeracker.git
cd homeracker

# On Debian/Ubuntu systems, you need to install the python3-venv package before next command
python3 -m venv .venv

# Activate the virtual environment
# Windows (Git Bash/CMD/PowerShell):
source .venv/Scripts/activate
# macOS/Linux:
source .venv/bin/activate

# Install scadm package (openscad dependency manager)
pip install -e cmd/scadm

# Install OpenSCAD (Windows/Linux/macOS) + Dependencies
scadm install

# Optional (Opinionated VSCode Integration)
# see cmd/scadm/README.md for details
scadm vscode --openscad   # For OpenSCAD development
scadm vscode --python     # Install and configure Python extension

# Install pre-commit
pip install pre-commit

# Additional dependencies for OpensCAD and pre-commit (Ubuntu / Debian)
sudo apt install libopengl0 shellcheck

# Verify installation
./cmd/test/openscad-render.sh

# Install the git hooks
pre-commit install --install-hooks -t commit-msg -t pre-commit

# Optional: Skip manual venv activation in VS Code each time you open a terminal
# Run `scadm vscode --python` to auto-configure the Python interpreter
# (see Quick Start section above)
```

Now pre-commit will automatically run on `git commit`. To manually run hooks on all files:

```bash
pre-commit run --all-files
```

The hooks can be found here: [.pre-commit-config.yaml](.pre-commit-config.yaml)

## 📐 HomeRacker Standards

- **Base unit**: 15mm
- **Lock pins**: 4mm square
- **Walls**: 2mm thickness
- **Tolerance**: 0.2mm
- **Quality**: `$fn=100` for production

## 🛠️ Development Guidelines

### Code Standards
- **DRY, KISS, YAGNI** - Keep it simple
- Use [BOSL2](https://github.com/BelfrySCAD/BOSL2/wiki) for complex geometry
- Group parameters with `/* [Section] */` comments
- Add sanity checks: `assert(height % 15 == 0, "Must be multiple of 15mm")`

### Python Code Standards
- **Docstrings**: All functions must use [Google style docstrings](https://google.github.io/styleguide/pyguide.html#38-comments-and-docstrings)
  ```python
  def example_function(param1: str, param2: int) -> bool:
      """Brief one-line summary of what the function does.

      More detailed explanation if needed (optional).

      Args:
          param1: Description of first parameter
          param2: Description of second parameter

      Returns:
          Description of return value

      Raises:
          ValueError: Description of when this exception is raised
      """
  ```
- See `cmd/export/export_makerworld.py` for real examples
- Use type hints for function parameters and return values
- Keep inline comments minimal - code should be self-documenting

### Testing
- Render in OpenSCAD without errors
- Test edge cases (min/max parameter values)
- Export to STL and verify mesh integrity

### MakerWorld Exports
Files in `models/<model_type>/parts/` are automatically exported on commit. See [cmd/export/README.md](cmd/export/README.md) for details.

## 📝 Commit Conventions

This project uses [Conventional Commits](https://www.conventionalcommits.org/) for automated changelog generation and semantic versioning.

### Commit Format

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

### Commit Types

| Type | Description | Version Bump |
|------|-------------|--------------|
| `feat:` | New feature | **minor** (0.x.0) |
| `fix:` | Bug fix | **patch** (0.0.x) |
| `feat!:` or `fix!:` | Breaking change | **major** (x.0.0) |
| `docs:` | Documentation only | **patch** (0.0.x) |
| `chore:` | Maintenance tasks | **patch** (0.0.x) |
| `refactor:` | Code restructuring | **patch** (0.0.x) |
| `test:` | Adding tests | **patch** (0.0.x) |

### Examples

```bash
# Feature (bumps minor version)
feat: add gridfinity adapter module

# Bug fix (bumps patch version)
fix: correct tolerance in wallmount holes

# Breaking change (bumps major version)
feat!: change base unit from 15mm to 20mm

# Documentation (no version bump)
docs: update installation instructions in README

# Maintenance (no version bump)
chore: update OpenSCAD to nightly-2024.11.20

# With scope
feat(wallmount): add cable management clips
fix(core): correct lock pin dimensions
```

### Breaking Changes

> [!IMPORTANT]
> Breaking changes must be aligned with the codeowners beforehand. We should avoid breaking changes as much as possible.

For breaking changes, use `!` after the type or add `BREAKING CHANGE:` in the footer:

```bash
feat!: change base unit from 15mm to 14mm

# or

feat: change base unit from 15mm to 14mm

BREAKING CHANGE: Base unit changed from 15mm to 14mm. All models need regeneration.
```

### Release Process

Releases are automated using Camunda's GitHub actions from [infra-global-github-actions](https://github.com/camunda/infra-global-github-actions):
- Commits following Conventional Commits automatically update the changelog
- Release PRs are created automatically when commits are pushed to `main`
- Scheduled releases run weekly via auto-merge workflow
- Manual releases can be triggered via GitHub Actions workflow dispatch
- PR titles are validated to ensure Conventional Commits compliance

**Note:** The workflows require GitHub App credentials configured as repository secrets.

## 🔄 Pull Request Workflow

1. Create branch or fork: `git checkout -b feature/my-feature`
2. Make changes following standards above
3. Test thoroughly
4. Commit: `git commit -m "feat: add cool feature"`
5. Push: `git push origin feature/my-feature`
6. Create PR with description and screenshots

## 📂 Project Structure

```
models/              # OpenSCAD models
  ├── core/         # Core components (supports, connectors, lock pins)
  ├── gridfinity/   # Gridfinity-compatible baseplates
  ├── wallmount/    # Wall mounting
  ├── flexmount/    # Flexible mounts
  └── rackmount_ears/  # Customizable rack ears
cmd/                # Command-line utilities (setup, test, lib)
```

## 💬 Getting Help

- [Open an issue](https://github.com/kellerlabs/homeracker/issues) for bugs
- [Start a discussion](https://github.com/kellerlabs/homeracker/discussions) for questions
- [Community Repo](https://github.com/kellerlabs/homeracker-community) for new features and extensions
- See [scadm documentation](cmd/scadm/README.md) for dependency manager details

## 🔔 Discord Integration

The repository is integrated with Discord to announce updates:

- **Channel**: `#homeracker-announcements`
- **Webhook Name**: GitHub Releases
- **Events**: Release events
- **Configuration**: Discord GitHub-formatted webhook (`/github` suffix)
- **Status**: Active (last response: 204 OK)

Releases automatically post to the Discord server, keeping the community updated.

## 📜 License

Contributions are licensed under MIT (code) and CC BY-SA 4.0 (models).

---

**Platform**: Windows/Linux/macOS (macOS treated as Linux, untested)
