# Testing Guide

## General Testing Principles

Always test changes before committing:
- **Use existing test scripts** in `cmd/test/` when available
- **Write simple tests** if none exist (bash scripts, Python tests, or manual verification steps)
- **Document test steps** in commit messages or PR descriptions

## scadm Tests

### Unit Tests

Fast, mocked tests. The `scadm-tests` pre-commit hook runs them when a commit touches `cmd/scadm/`, so a commit elsewhere in the repo will not exercise them. Run them by hand after changing anything scadm depends on.

```bash
cd cmd/scadm
python -m pytest tests/ -m "not integration" -v
```

### Integration Tests

CLI integration tests exercise real `scadm` commands against temporary workspaces. Run via CI workflow (`.github/workflows/integration-tests.yml`) on **ubuntu + windows** matrix.

| Marker | What | Network | Speed |
|--------|------|---------|-------|
| `integration` (no `slow`) | Config parsing, `--info`, `--check`, vscode settings, cache | ⚡ version resolution only | ~5s |
| `integration` + `slow` | Binary download, library install | ✅ | ~60s |

#### Running Locally

```bash
cd cmd/scadm

# All integration tests
python -m pytest tests/test_cli_integration.py -m integration -v

# Fast only (no downloads)
python -m pytest tests/test_cli_integration.py -m "integration and not slow" -v
```

> **Prerequisite**: Install scadm in editable mode first: `pip install -e cmd/scadm`

#### When to Update

- Adding or modifying a CLI subcommand → add/update integration test
- Changing `scadm.json` config schema → update config-dependent tests
- Changing installer/resolver behavior → update relevant slow tests

## Code Coverage

Coverage is enforced via `pytest-cov` with a ratcheting threshold stored in `cmd/scadm/.coverage-threshold`.

### Running Locally

```bash
# Enforce threshold (fails if coverage drops below stored value)
./cmd/test/test-coverage.sh

# Generate HTML report only (no threshold check)
./cmd/test/test-coverage.sh --report
```

On success the threshold file is updated to the actual coverage value — subsequent runs can only increase, never decrease.

### CI

`.github/workflows/coverage.yml` runs on PRs and main pushes (scoped to `cmd/scadm/**`).

## Mutation Testing

Mutation testing uses `mutmut` to validate test quality by introducing code mutations and checking that tests catch them.

### Running Locally

```bash
# Full mutation run
./cmd/test/test-mutmut.sh

# Show results from last run
./cmd/test/test-mutmut.sh --results
```

### CI

`.github/workflows/mutation-tests.yml` runs weekly (Monday 03:00 UTC) and on manual dispatch.

> ⚠️ Mutation testing is CPU-intensive — expect runs to take several minutes.

## Renovate Configuration Testing

When modifying `renovate.json5`, always test changes before merging to prevent incorrect PRs.

### Workflow

1. **Create feature branch**
   ```bash
   git checkout -b fix/renovate-<description>
   ```

2. **Make changes and commit**
   ```bash
   git add renovate.json5
   git commit -m "fix(renovate): <description>"
   ```

3. **Push to remote** (required for testing)
   ```bash
   git push -u origin fix/renovate-<description>
   ```

4. **Test locally**
   ```bash
   ./cmd/test/test-renovate-local.sh
   ```

5. **Validate output**
   - Check that dependencies are detected correctly
   - Verify version extraction matches expected format
   - Confirm updates are grouped as intended

### What to Check in the Output

**OpenSCAD version extraction**, which uses a separate datasource per platform:
- `OpenSCAD-Windows`: version without `.ai` suffix
- `OpenSCAD-Linux`: version with `.ai` suffix preserved

**Grouping and automerge**, for any rule in `renovate.json5` carrying a `groupSlug`:
- A **single branch** `renovate/<groupSlug>` holding every dependency in the group
- Major and minor updates combined in that one branch where the rule sets `separateMajorMinor: false`, with no separate `renovate/major-<groupSlug>` branch
- `"automerge": true` in the branch configuration where the rule enables it

### Why Remote Push is Required

Renovate test fetches from GitHub, so changes must exist remotely before testing validates them.
