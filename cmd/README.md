# 🔧 OpenSCAD Installation and Testing

This directory contains tooling scripts for OpenSCAD models.

For installation, use the **scadm** package (see `cmd/scadm/`).

## 📦 Quick Start

```bash
# Install scadm from local source
pip install -e cmd/scadm

# Install OpenSCAD + dependencies from scadm.json
scadm install

# Check if updates are available
scadm install --check

# Render a single model (validates syntax + geometry)
scadm render models/core/parts/connector.scad

# Discover and render all models (test/ + makerworld/ dirs)
./cmd/test/test-models.sh

# Flatten include trees for single-file platforms (e.g. MakerWorld)
scadm flatten --all
```

## 🤖 Automatic Updates

OpenSCAD versions are managed by Renovate Bot in `cmd/scadm/scadm/constants.py`. When new releases are available, Renovate creates a PR to update the versions.

## 📦 Dependency Management

Dependencies are defined in `scadm.json` at the repository root. The installer supports both Git commit hashes (SHAs) and SemVer tags.

### Configuration Format (`scadm.json`)

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
      "version": "homeracker-v1.3.1",
      "source": "github"
    },
    {
      "name": "example",
      "repository": "example/repo",
      "version": "v1.2.3",
      "source": "github"
    }
  ]
}
```

### Renovate Integration

To enable Renovate to update these dependencies, extend the configuration from this repository in your `renovate.json`:

> **Note**: Use `github>...` for external repositories. Internally, this repository uses `local>...`.

```json
{
  "extends": [
    "github>kellerlabs/homeracker:renovate-dependencies.json"
  ]
}
```

The preset supports:
- Git commit hashes (40-character hex strings)
- HomeRacker tags (`homeracker-vX.Y.Z` for `kellerlabs/homeracker`)
- SemVer tags (`vX.Y.Z` or `X.Y.Z` for other repositories)
