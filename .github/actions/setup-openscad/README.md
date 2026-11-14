# Setup OpenSCAD Action

Composite GitHub Action that installs OpenSCAD, system dependencies, and libraries via [scadm](../../../cmd/scadm/README.md), with caching.

> ⚠️ Requires `ubuntu` runners (uses `apt` for system dependencies).

## Why

Setting up OpenSCAD in CI requires installing system packages, downloading binaries, and managing library dependencies. This action handles all of that in a single step, with caching for fast subsequent runs.

## Usage

### Cross-repository

```yaml
steps:
  - uses: actions/checkout@v6

  - name: Setup OpenSCAD
    uses: kellerlabs/homeracker/.github/actions/setup-openscad@setup-openscad-v2
    with:
      scadm-requirements: requirements.txt
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
| `scadm-version` | Pinned scadm PyPI version. Takes precedence over `scadm-requirements`. | _(empty)_ |
| `scadm-requirements` | Path to a `requirements.txt` containing a pinned scadm version (e.g. `scadm==0.6.3`). Used when `scadm-version` is not set. | _(empty)_ |
| `scadm-source` | Local path for editable scadm install. Overrides both `scadm-version` and `scadm-requirements`. | _(empty)_ |

> **Priority:** `scadm-source` > `scadm-version` > `scadm-requirements`. At least one must be provided.

## What it does

1. Sets up Python 3.x
2. Installs system dependencies (`xvfb`, `libglu1-mesa`, `libfuse2`, `libegl1`, `libxcb-cursor0`) from cached `.deb` files, see [System package cache](#system-package-cache)
3. Resolves scadm version from inputs (source > explicit version > requirements file)
4. Caches `bin/openscad/` keyed on runner OS, resolved scadm version, `scadm.json`, and `**/constants.py` under `scadm-source` (when set)
5. Installs [scadm](../../../cmd/scadm/README.md), pinned from PyPI, or from a local path if `scadm-source` is set
6. Runs `scadm install` to download OpenSCAD and libraries

## System package cache

The `.deb` files are cached per runner image (distribution, release, architecture) and installed offline, so a run with a warm cache does not depend on the Ubuntu mirrors. [`install-system-deps.sh`](install-system-deps.sh) downloads from the mirrors and saves a new cache entry when:

- no entry exists for the runner image, or the branch cannot read it (a PR reads the entries of its own branch and of the default branch)
- the package list in the script changed
- the cached packages no longer fit the image, for example after an image refresh updated a library they depend on
- a required package is neither on the image nor in the cache, for example after an image refresh dropped one the cache never held

A cached package set stays in use for as long as it installs, so it can trail the mirrors by a few versions.

[`test-install-system-deps.sh`](test-install-system-deps.sh) tests these paths against a real apt. It removes system packages, so run it on a disposable machine only.

## Versioning

This action is independently versioned via [release-please](https://github.com/googleapis/release-please). Use a pinned tag:

```yaml
uses: kellerlabs/homeracker/.github/actions/setup-openscad@setup-openscad-v2.0.0
```
