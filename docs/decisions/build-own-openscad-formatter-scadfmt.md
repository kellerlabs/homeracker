# 📋 Build Our Own OpenSCAD Formatter, scadfmt

## 📌 Status

**Accepted**: 2026-09-27

## 🤔 Context

- Community contributions need one common code style ([#177](https://github.com/kellerlabs/homeracker/issues/177)). Today indentation mixes 2 and 4 spaces and operator spacing varies per file.
- The repo pins OpenSCAD nightly, so the formatter must keep up with new syntax, such as the bitwise operators `& | ~ << >>`.
- Existing tools, run against all 74 `.scad` files:

| Tool | Verdict | Reason |
|---|---|---|
| [scadformat](https://github.com/hugheaves/scadformat) (Go, ANTLR) | ❌ Rejected | Rewrites `~5` to `5` with exit code 0; joins hand-wrapped calls into lines up to 479 chars; no config, no check mode; single maintainer, no tagged versions |
| [scad-format](https://pypi.org/project/scad-format/) (clang-format style) | ❌ Rejected | Rewrites `include <BOSL2/std.scad>` to `include < BOSL2 / std . scad >` |
| [openscad-format](https://github.com/Maxattax97/openscad-format) | ❌ Rejected | Unmaintained since 2022, clang-format based |
| openscad-LSP formatter (topiary) | ❌ Rejected | Editor only, no CLI |
| [sca2d](https://gitlab.com/bath_open_instrumentation_group/sca2d) | ❌ Rejected | Linter, not a formatter; cannot resolve BOSL2 or `homeracker/` includes |

## 🔧 Decision

`scadfmt`, a stdlib-only Python package in `cmd/scadfmt/`, separate from scadm.

- **Token based, not a full parser.** It needs to know OpenSCAD's tokens, not its grammar. New syntax made of known tokens needs no change; a new operator is one table entry.
- **Never changes meaning.** The token sequence without whitespace must match before and after, otherwise it aborts. An unknown character is an error, never dropped.
- **Never joins lines.** It only adds breaks: after `{`, around `}` (keeping `} else`), after `;` outside parentheses, after the import block and around definitions.
- **Rules:** 2-space indent, one level per line that opens brackets; one statement per line and block contents on their own lines; imports as one block followed by one blank line; exactly one blank line around each `module` and `function` definition; a continued module call nests one level per line, a continued expression stays one level in; spaces around every binary operator and every `=` (`cube(size = 10)`); space after commas; tight unary operators, modifiers and range colons; consecutive trailing comments aligned to one column (a lone one gets 2 spaces); max 2 blank lines at top level and 1 inside blocks; the file's own line endings and one final newline. Full list in the [scadfmt README](../../cmd/scadfmt/README.md#-rules).
- **CLI conventions:** `format`, `--check`, `--diff`, stdin, exit codes 0/1/2, `// fmt: off` / `// fmt: on`.
- **Linting later** (`scadfmt lint`, naming rules) builds on BelfrySCAD's [openscad-parser](https://github.com/belfryscad/openscad_parser) (by the BOSL2 author, already parses the nightly's bitwise operators). The formatter never depends on it.
- **Tested like scadm:** a branch coverage gate and per-PR mutation testing, see [gate-scadm-coverage-and-mutation-test-changed-functions](gate-scadm-coverage-and-mutation-test-changed-functions.md).
- **Separate from scadm:** scadm manages OpenSCAD and libraries, scadfmt manages style. Released to PyPI on its own (`scadfmt-v*`). `scadfmt vscode` registers it as the VS Code formatter via Custom Local Formatters.

### Alternatives Considered

| Approach | Verdict | Reason |
|---|---|---|
| Own full parser for format and lint | ❌ Rejected | Every grammar change breaks formatting; comment handling on a tree is the hardest part of a formatter |
| tree-sitter + topiary | ❌ Rejected | Depends on `tree-sitter-openscad` (last release 2024), Rust binary |
| Token scanner for lint too | ❌ Rejected | Scope rules turn heuristics into an ad hoc parser |
| Subcommand of scadm | ❌ Rejected | Mixes concerns, couples release cycles, drags an installer into other projects |

## 📊 Consequences

- **Positive**: OpenSCAD drift costs little: tokens change rarely, and the formatter fails loudly instead of corrupting code.
- **Positive**: usable outside HomeRacker via PyPI and a local pre-commit hook.
- **Negative**: we maintain the formatter ourselves; kept in check by the canary and a planned weekly nightly check ([#177](https://github.com/kellerlabs/homeracker/issues/177)).
- **Negative**: `scadfmt vscode` repeats about 60 lines of `scadm vscode` settings handling.
- **Revisable**: no line length limit for now; a lint rule can add one later.
- **Negative**: the first repo-wide format run (a follow-up PR) touches most `.scad` files; its commit goes into `.git-blame-ignore-revs`.
