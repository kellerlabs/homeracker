# 📋 Unify export-png Shell Scripts into scadm CLI

## 📌 Status

**Accepted** — 2026-06-18

## 🤔 Context

Both `homeracker` and `homeracker-exclusive` maintained separate `cmd/export/export-png.sh` scripts for rendering OpenSCAD models to PNG. These scripts:

- Duplicated ~80% of logic (OpenSCAD binary discovery, default camera/color settings, xvfb handling)
- Diverged over time — exclusive added `--projection` support, homeracker didn't
- Required Bash, adding friction on Windows (CI needed Git Bash or WSL)
- Had no tests — regressions could only be caught manually

Meanwhile, `scadm` already handled OpenSCAD binary management and was installed as a Python CLI in all repos.

## 🔧 Decision

Implement `scadm export-png` as a Python module in `cmd/scadm/scadm/export_png.py`, replacing both shell scripts.

### Alternatives Considered

| Approach | Verdict | Reason |
|---|---|---|
| Keep separate shell scripts | ❌ Rejected | Ongoing duplication, no tests, Windows friction |
| Shared shell script via git submodule | ❌ Rejected | Submodule complexity, still no testability |
| Python wrapper calling shell script | ❌ Rejected | Extra indirection without solving test or Windows issues |

### Key Design Choices

- **Moved `find_openscad_exe()`** from `render.py` to `installer.py` for shared use
- **Standardized defaults** (camera, image size, `renders/` output subfolder from homeracker; colorscheme `BeforeDawn` from exclusive — chosen as the unified default)
- **Linux CI**: auto-wraps with `xvfb-run` for headless rendering
- **22 unit tests** + **4 integration tests** (including a slow happy-path that installs OpenSCAD and renders a cube)

## 📊 Consequences

- **Positive**: Single implementation, testable, cross-platform, consistent behavior across repos
- **Positive**: Shell scripts in exclusive (`render-mw-modules.sh`, `visual-test.sh`) now call `scadm export-png` — simpler and shorter
- **Negative**: Requires `scadm` to be installed (already a dependency in all repos via `requirements.txt`)
- **Negative**: Python adds startup overhead vs. direct shell — negligible since OpenSCAD rendering dominates runtime
