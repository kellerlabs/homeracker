# Setup OpenSCAD Action

Composite GitHub Action that installs OpenSCAD, system dependencies, and libraries via [scadm](../../../cmd/scadm/README.md) — with caching.

> ⚠️ Requires `ubuntu` runners (uses `apt` for system dependencies).

## Why

Setting up OpenSCAD in CI requires installing system packages, downloading binaries, and managing library dependencies. This action handles all of that in a single step, with caching for fast subsequent runs.

## Usage

### Cross-repository

```yaml
steps:
  - uses: actions/checkout@v6

  - name: Setup OpenSCAD
    uses: kellerlabs/homeracker/.github/actions/setup-openscad@setup-openscad-v1
```

> Requires a `scadm.json` in the repo root. See [scadm docs](../../../cmd/scadm/README.md) for config format.

### Within homeracker

```yaml
steps:
  - uses: actions/checkout@v6

  - name: Setup OpenSCAD
    uses: ./.github/actions/setup-openscad
    with:
      scadm-source: cmd/scadm
```

## Inputs

| Input | Description | Default |
|---|---|---|
| `scadm-version` | Pinned scadm PyPI version. Also used in the cache key. | See [action.yml](action.yml) |
| `scadm-source` | Local path for editable scadm install. Overrides PyPI version and re-runs `scadm install`. | _(empty)_ |

## What it does

1. Sets up Python 3.x
2. Installs system dependencies (`xvfb`, `libglu1-mesa`, `libfuse2`, `libegl1`, `libxcb-cursor0`)
3. Caches `bin/openscad/` keyed on runner OS, scadm version, `scadm.json`, and local source hash (when `scadm-source` is set)
4. Installs [scadm](../../../cmd/scadm/README.md) — pinned from PyPI, or from a local path if `scadm-source` is set
5. Runs `scadm install` to download OpenSCAD and libraries

## Versioning

This action is independently versioned via [release-please](https://github.com/googleapis/release-please). Use a pinned tag:

```yaml
uses: kellerlabs/homeracker/.github/actions/setup-openscad@setup-openscad-v1.0.0
```
