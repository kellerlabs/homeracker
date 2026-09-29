# 🎨 scadfmt

[![PyPI](https://img.shields.io/pypi/v/scadfmt)](https://pypi.org/project/scadfmt/)
[![Pre-commit](https://github.com/kellerlabs/homeracker/actions/workflows/pre-commit.yml/badge.svg?branch=main)](https://github.com/kellerlabs/homeracker/actions/workflows/pre-commit.yml?query=branch%3Amain)
[![Coverage](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fkellerlabs%2Fhomeracker%2Fbadges%2Fscadfmt-coverage.json)](https://github.com/kellerlabs/homeracker/actions/workflows/coverage-badge.yml?query=branch%3Amain)
[![Mutation score](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fkellerlabs%2Fhomeracker%2Fbadges%2Fscadfmt-mutation.json)](https://github.com/kellerlabs/homeracker/actions/workflows/mutation-tests.yml?query=event%3Aschedule)

## 📌 What

An opinionated formatter for OpenSCAD code. It fixes indentation and spacing, puts blocks and statements on their own lines, and never joins lines or changes what the code does.

## 🤔 Why

Community contributions need one code style without style debates in review. Existing formatters rewrite code they do not understand (dropping operators, breaking `include` paths) or join hand-wrapped lines into very long ones. scadfmt only needs to know OpenSCAD's tokens, so new syntax rarely affects it, and it refuses to write output whose tokens differ from the input. See [build-own-openscad-formatter-scadfmt](../../docs/decisions/build-own-openscad-formatter-scadfmt.md).

## 🔧 How

### 📦 Install

Requires Python 3.11 or newer, no other dependencies.

```bash
pip install scadfmt           # from PyPI
pip install -e cmd/scadfmt    # from this repo
```

### ▶️ Usage

```bash
scadfmt format models/                  # format files in place, directories recursively
scadfmt format --check models/          # write nothing, exit 1 if a file would change
scadfmt format --diff part.scad         # write nothing, print a diff
scadfmt format - < in.scad > out.scad   # stdin to stdout
```

Exit codes: `0` clean, `1` files would change (`--check`), `2` error. On an error (unknown character, unbalanced brackets) the file stays untouched.

### 👀 Before and After

```openscad
include<BOSL2/std.scad>
wall=2;// wall strength
height_units=3; // rack units
/**
 * Bracket holding a device of the given size.
 * center: centers the body on the origin
 */
module bracket(width=10,depth=20,center=false){
    size=[width,depth,wall*height_units];
    if(center){translate(-size/2)cube(size);}else{cube(size);}
    for(i=[0:2:width])
    translate([i,0,0])
    rotate([0,0,-90])
    #cylinder(h=wall,r=1);
}
```

becomes

```openscad
include <BOSL2/std.scad>

wall = 2;          // wall strength
height_units = 3;  // rack units

/**
 * Bracket holding a device of the given size.
 * center: centers the body on the origin
 */
module bracket(width = 10, depth = 20, center = false) {
  size = [width, depth, wall * height_units];
  if (center) {
    translate(-size / 2) cube(size);
  } else {
    cube(size);
  }
  for (i = [0:2:width])
    translate([i, 0, 0])
      rotate([0, 0, -90])
        #cylinder(h = wall, r = 1);
}
```

### 📏 Rules

| Rule | Example |
|---|---|
| 2 spaces per open `{ ( [`, one level per line that opens them | `cube([`↵`  1,`↵`]);` |
| A line continuing a module call nests one level further | `translate(v)`↵`  cube();` |
| A line continuing an expression is one level in | `x =`↵`  a +`↵`  b;` |
| Spaces around every binary operator and every `=` | `cube(size = w * 2, center = true);` |
| Tight unary operators, modifiers, calls, indexing | `-x`, `!a`, `#cube()`, `f(a)[0]` |
| Tight range colons, spaced ternary colons | `[0:2:10]`, `a ? b : c` |
| `if`, `for`, `intersection_for`, `function` get a space before `(` | `for (i = [0:2])` |
| Space after commas, none inside brackets | `f(a, [1, 2])` |
| Block contents on their own lines, `}` on its own line except `} else`, empty `{}` stays | `if (a) {`↵`  b();`↵`} else {` |
| One statement per line (`;` inside `for (...)` excepted) | `a();`↵`b();` |
| Exactly one blank line before and after each `module` and `function` definition, none next to a brace | `x = 1;`↵↵`module m() {` |
| Imports form one block without blank lines, followed by exactly one blank line | `include <a.scad>`↵`use <b.scad>`↵↵`x = 1;` |
| Trailing comments on consecutive lines share one column, a lone one gets 2 spaces | `x = 1;  // note` |
| At most 2 blank lines at top level, 1 inside blocks | |
| Keeps the file's line endings (LF or CRLF, judged by the first one), no trailing whitespace, one final newline | |

Comments (`//` or `/* */`) directly above a line belong to it, so a blank line added before that line goes above its comments. Lines are never joined and line length is never limited.

### 🙈 Opting Out

Lines between `// fmt: off` and `// fmt: on` stay as written, for example a hand-aligned matrix:

```openscad
// fmt: off
identity = [
  1, 0, 0,
  0, 1, 0,
];
// fmt: on
```

### 🪝 Pre-commit

In another repository, install scadfmt from PyPI through a local hook:

```yaml
- repo: local
  hooks:
    - id: scadfmt
      name: scadfmt
      entry: scadfmt format
      language: python
      additional_dependencies: [scadfmt==0.1.0]
      files: \.scad$
```

### 🖥️ VS Code

```bash
scadfmt vscode
```

Installs the [Custom Local Formatters](https://marketplace.visualstudio.com/items?itemName=jkillian.custom-local-formatters) extension and makes scadfmt the default formatter for `.scad` files in `.vscode/settings.json` (of `--workspace <folder>`, default `.`), so **Format Document** (`Shift+Alt+F`) runs it.

⚠️ In a multi-root workspace, VS Code ignores the formatter list in a folder's `.vscode/settings.json`. Pass the `.code-workspace` file to `--workspace` there, so the settings go into it instead:

```bash
scadfmt vscode --workspace                        # asks about the nearest .code-workspace file in . or above
scadfmt vscode --workspace ../my.code-workspace   # no prompt
```

Declining the offered file, or having none, asks for a workspace file or folder.

It refuses to touch a settings file with comments; add the settings by hand then (in a `.code-workspace` file, inside its `"settings"` block):

```jsonc
"customLocalFormatters.formatters": [{ "command": "\"/path/to/python\" -m scadfmt format -", "languages": ["scad"] }],
"[scad]": { "editor.defaultFormatter": "jkillian.custom-local-formatters" }
```

For formatting on save, add `"editor.formatOnSave": true` to the `[scad]` block.

### 🔄 Keeping Up with OpenSCAD

HomeRacker pins OpenSCAD nightly. When a weekly nightly bump changes OpenSCAD's grammar, a Claude agent adapts scadfmt and its canary on the Renovate PR, and a maintainer approves the result. See [agent-adapts-scadfmt-to-openscad-nightly](../../docs/decisions/agent-adapts-scadfmt-to-openscad-nightly.md). To do the same by hand, follow the [`scadfmt-adapt`](../../.claude/skills/scadfmt-adapt/SKILL.md) skill.

### 🧪 Tests

See [TESTING.md](../../TESTING.md#scadfmt-tests). `tests/canary/` holds a file using every OpenSCAD construct and its expected output; `check.sh` checks both against the pinned OpenSCAD. `tests/ast_check.sh` proves that formatting-only changes in a PR keep OpenSCAD's AST.

## 📚 References

- [#177](https://github.com/kellerlabs/homeracker/issues/177): introduce an OpenSCAD formatter
- [build-own-openscad-formatter-scadfmt](../../docs/decisions/build-own-openscad-formatter-scadfmt.md): why scadfmt exists and how it works
- [agent-adapts-scadfmt-to-openscad-nightly](../../docs/decisions/agent-adapts-scadfmt-to-openscad-nightly.md): how scadfmt follows new OpenSCAD nightlies
- [OpenSCAD language reference](https://en.wikibooks.org/wiki/OpenSCAD_User_Manual/The_OpenSCAD_Language)
