# scadm - OpenSCAD Dependency Manager

**scadm** is a lightweight, python-based dependency manager for OpenSCAD projects. It simplifies installing OpenSCAD (nightly or stable) and managing library dependencies through a simple `scadm.json` file.

## Features

- 🚀 **Install OpenSCAD**: Automatically downloads and installs OpenSCAD (nightly or stable builds)
- 📦 **Manage Libraries**: Install OpenSCAD libraries (BOSL2, MCAD, custom libraries) from GitHub
- 🔄 **Version Tracking**: Keeps dependencies in sync with your project
- 📋 **Simple Config**: Define dependencies in a single `scadm.json` file

## Installation

**Requirements:** Python 3.11 or newer

```bash
pip install scadm
```

## Quick Start

### 1. Create `scadm.json` in your project root

```json
{
  "dependencies": [
    {
      "name": "BOSL2",
      "repository": "BelfrySCAD/BOSL2",
      "version": "266792b2a4bbf7514e73225dfadb92da95f2afe1",
      "source": "github"
    }
  ]
}
```

### 2. Install OpenSCAD and dependencies

```bash
scadm install
```

This will:
- Download and install OpenSCAD to `bin/openscad/`
- Install all libraries defined in `scadm.json` to `bin/openscad/libraries/`

## Usage

### Check version

```bash
scadm --version
```

### Install everything (OpenSCAD + libraries)

```bash
scadm install                # Install nightly build (default - RECOMMENDED)
scadm install --stable       # Install stable release (2021.01)
```

> [!NOTE]
> Nightly builds are installed by default since the stable release (2021.01) is outdated and missing modern features. All nightly versions pass rendering tests before being published to ensure quality.

### Check installation status

```bash
scadm install --check
```

### Force reinstall

```bash
scadm install --force
```

### Install only OpenSCAD

```bash
scadm install --openscad-only
```

### Install only libraries

```bash
scadm install --libs-only
```

### Flatten .scad files

Flatten include trees into single files — useful for platforms that require single-file uploads (e.g. MakerWorld Customizer).

```bash
# Single file
scadm flatten models/core/parts/connector.scad -o out/connector.scad

# Batch-flatten all files configured in scadm.json
scadm flatten --all

# Compute transitive dependency checksum (for caching)
scadm flatten --checksum models/core/parts/connector.scad
```

Batch mode reads `"flatten"` entries from `scadm.json`:

```json
{
  "flatten": [
    {"src": "models/core/parts", "dest": "models/core/flattened"}
  ]
}
```

Unchanged files are skipped via SHA256 checksums stored in `models/.flatten-checksums` (gitignored; cached in CI).

#### File structure conventions

The flattener expects source `.scad` files to follow OpenSCAD Customizer conventions:

**Root files** (the files being flattened):

1. **Parameter sections** — `/* [SectionName] */` blocks with customizable variables
2. **Hidden section** — `/* [Hidden] */` with constants/variables hidden from the Customizer UI
3. **Main code** — module/function calls that generate geometry

Variable placement rules:

- Variables inside `/* [SectionName] */` blocks → preserved in their respective sections
- Variables in `/* [Hidden] */` section → included in the Hidden section
- In **root files**, place top-level variables inside a section block (`/* [Hidden] */` or named) so they are preserved reliably during flattening
- In **library files**, variables may appear anywhere — the flattener collects them regardless of position

**Library files** (resolved via `include <...>`):

- May contain module/function definitions, constants, and variables in any order
- Section markers (`/* [SectionName] */`) in library files are silently ignored — only root file sections are preserved in the output
- Only **effectively used** definitions (modules, functions, variables) from the dependency chain are included — unused code is omitted
- Library variables appear in the Hidden section with an origin comment (e.g. `// --- from constants.scad ---`)

### Render .scad files

Validate .scad files by rendering them through the bundled OpenSCAD binary.
"Rendering" means compiling the .scad source into a binary STL — this validates syntax,
geometry, and that all includes resolve correctly. A non-zero exit code means something is broken.

```bash
# Explicit files
scadm render models/core/parts/connector.scad
scadm render file1.scad file2.scad

# Render flattened output files (from scadm.json flatten dest dirs)
scadm render --flattened

# Render source files that feed into flatten (from scadm.json flatten src dirs)
scadm render --source

# Both at once
scadm render --source --flattened
```

The `--source` and `--flattened` flags discover files from `scadm.json` `"flatten"` entries automatically. They cannot be combined with explicit file arguments.

### Configure VS Code extensions

These are opinionated QoL improvements to install nifty VSCode extensions which improve DevEx.

```bash
scadm vscode --openscad   # Install and configure OpenSCAD extension
scadm vscode --python     # Install and configure Python extension
```

**OpenSCAD extension** will:
- Install the `Leathong.openscad-language-support` extension
- Configure VS Code settings with correct OpenSCAD paths
- Merge with existing settings (preserves unrelated configurations)

**Python extension** will:
- Install the `ms-python.python` extension
- Configure default interpreter path to `${workspaceFolder}/.venv` (eliminates need to manually source venv when opening project)

> [!NOTE]
> Settings are opinionated defaults designed to streamline development experience. They're configured in `.vscode/settings.json` (workspace-level), not globally.

> [!IMPORTANT]
> Requires VS Code CLI (`code` command) to be available in PATH. If not found, you'll receive installation instructions.

## Configuration

### `scadm.json` Schema

```json
{
  "dependencies": [
    {
      "name": "BOSL2",
      "repository": "BelfrySCAD/BOSL2",
      "version": "266792b2a4bbf7514e73225dfadb92da95f2afe1",
      "source": "github"
    },
    {
      "name": "homeracker",
      "repository": "kellerlabs/homeracker",
      "version": "homeracker-v1.7.3",
      "source": "github"
    }
  ]
}
```

**Fields:**
- `name`: Library name (creates `bin/openscad/libraries/{name}/`)
- `repository`: GitHub repository in `owner/repo` format
- `version`: Git tag, commit SHA, or branch name
- `source`: Currently only `"github"` is supported

## Directory Structure

After running `scadm`, your project will have:

```
your-project/
├── scadm.json
├── models/
│   └── your_model.scad
└── bin/openscad/
    ├── openscad.exe (or openscad appimage)
    └── libraries/
        ├── BOSL2/
        └── homeracker/
```

## Use in OpenSCAD Files

```openscad
include <BOSL2/std.scad>
include <homeracker/core/lib/connector.scad>

// Your code here
```

## Renovate Integration

Keep your `scadm.json` dependencies automatically updated with [Renovate](https://docs.renovatebot.com/):

Add this preset to your `renovate.json`:

```json
{
  "extends": [
    "github>kellerlabs/homeracker:renovate-dependencies"
  ]
}
```

This preset enables automatic updates for:
- Git commit SHAs (for tracking main/master branches)
- Semantic version tags (v1.2.3)

## License

MIT

## Contributing

Issues and pull requests are welcome at [kellerlabs/homeracker](https://github.com/kellerlabs/homeracker).
