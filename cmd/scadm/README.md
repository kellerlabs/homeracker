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

```bash
pip install scadm    # Install scadm
scadm install        # Install OpenSCAD + libraries (BOSL2, etc.)
```

That's it. Now open any `.scad` file using the **project-local** OpenSCAD:

```bash
./bin/openscad/openscad models/core/main.scad
```

> [!IMPORTANT]
> You must use the project-local OpenSCAD at `bin/openscad/openscad` (not a system-installed `openscad`).
> The project-local binary knows where to find the installed libraries. If you use a system OpenSCAD,
> you'll get errors about missing dependencies (e.g. BOSL2).
>
> Alternatively, point any OpenSCAD at the libraries manually:
> ```bash
> OPENSCADPATH=./bin/openscad/libraries openscad models/core/main.scad
> ```

### Setting up a new project

#### 1. Create `scadm.json` in your project root

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

#### 2. Install OpenSCAD and dependencies

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
