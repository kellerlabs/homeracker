# Testing Guide

## General Testing Principles

Always test changes before committing:
- **Use existing test scripts** in `cmd/test/` when available
- **Write simple tests** if none exist (bash scripts, Python tests, or manual verification steps)
- **Document test steps** in commit messages or PR descriptions

## Site and Configurator E2E Tests

Playwright drives the built site in Chromium: every page, the hero canvas, and configurator journeys including error paths. The `site` job in [`web.yml`](.github/workflows/web.yml) runs it on every PR touching `site/` or `configurator/`, once at the root and once under a preview subpath.

```bash
cd site
npx playwright install --only-shell chromium   # once per Playwright version
npm run build
npm run e2e
```

A test fails on any page error, console error or failing same-origin request. `inventory.spec.ts` fails when a configurator control is not used by any test, so a new control needs a journey. Without OpenSCAD the build has no part meshes and the tests expect the schematic fallback; CI sets `PARTS_REQUIRED=1`. On failure, CI uploads the HTML report with screenshots and traces as the `playwright-report` artifact, and a PR comment lists each failing test with its error and a link to that artifact. The comment is created on the first failure and updated in place, back to ✅ once the suite passes. Fork PRs get the job summary only.

To check the failure report end to end, add the `e2e-probe-failure` label to the PR: `probe.spec.ts` then fails on purpose. Remove the label to go green again.

See [e2e.md](.claude/rules/e2e.md) for how to write tests and [e2e-test-site-and-configurator-with-playwright](docs/decisions/e2e-test-site-and-configurator-with-playwright.md) for why.

## scadfmt Tests

### Unit Tests

Unit tests cover every formatting rule, the CLI and the VS Code setup, and format every `.scad` file in the repo twice to prove the output is stable. The `scadfmt-unit-tests` pre-commit hook runs them on Linux when a commit touches `cmd/scadfmt/`, with a branch coverage gate in `cmd/scadfmt/pyproject.toml`. [Mutation testing](#mutation-testing) covers scadfmt like scadm. The `unit tests (windows)` job in [`scadfmt-tests.yml`](.github/workflows/scadfmt-tests.yml) runs them on Windows.

```bash
cd cmd/scadfmt
python -m pytest tests/ -q --cov
```

### Integration Tests (Canary)

The canary in `cmd/scadfmt/tests/canary/` uses every OpenSCAD construct. `check.sh` asserts that the pinned OpenSCAD parses it, that scadfmt turns it into `canary.expected.scad` and leaves that file unchanged, and that OpenSCAD's `.ast` output is identical before and after formatting. The `integration tests (OpenSCAD canary)` job runs it when `cmd/scadfmt/` or the OpenSCAD pin in `scadm.json` changes. Locally it needs `scadm install` first:

```bash
cmd/scadfmt/tests/canary/check.sh
```

A new language construct goes into `canary.scad`, then regenerate the expected file with `scadfmt format - < canary.scad > canary.expected.scad` and review the diff.

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

### Code Coverage

The `scadm-tests` hook runs the unit tests with `--cov`. It fails when branch coverage drops below `fail_under` in [`cmd/scadm/pyproject.toml`](cmd/scadm/pyproject.toml). It also sets `PYTHONWARNDEFAULTENCODING=1`, so text I/O without an explicit `encoding=` fails the tests (it breaks on Windows with a non-UTF-8 locale).

```bash
cd cmd/scadm
PYTHONWARNDEFAULTENCODING=1 python -m pytest tests/ -m "not integration" --cov                    # enforce the gate
PYTHONWARNDEFAULTENCODING=1 python -m pytest tests/ -m "not integration" --cov --cov-report=html  # browse htmlcov/index.html
```

When your change lifts coverage well past the gate, raise `fail_under` in the same PR. Never lower it.

### Mutation Testing

`mutmut` changes the `scadm` and `scadfmt` sources one small edit at a time and reruns the unit tests. A **survived** mutant means no test noticed the change, so a test is missing or its assertion is too weak. Linux and macOS only (Windows: use WSL).

On a PR, [`mutation-tests.yml`](.github/workflows/mutation-tests.yml) mutates only the functions the PR changed, per package, and edits one PR comment with a section per package listing the survivors (fork PRs: job summary only). Kill each survivor with a test, or mark a true equivalent with `# pragma: no mutate`. Log calls, argparse help text and exception messages are skipped by `do_not_mutate_patterns`. The run stops after 5 minutes and never fails the PR. Release-please PRs skip it. A weekly full run per package posts its stats to Discord `#homeracker-ci` and refreshes that package's badge.

```bash
cd cmd/scadm   # or cmd/scadfmt
export PYTHONWARNDEFAULTENCODING=1 PYTHONWARNINGS=ignore::EncodingWarning  # checks the package's I/O, not mutmut's
mutmut run                                        # full run, ~2 min (scadfmt ~1 min)
mutmut run "scadm.flatten.x_flatten_all__mutmut_*"  # one function, as a PR run does (scadm)
mutmut run "scadfmt.formatter.x__role__mutmut_*"    # the same for scadfmt
mutmut results                                    # list surviving mutants
mutmut show <mutant-name>                         # diff of one mutant
```

Known equivalents that survive: `encoding="UTF-8"` for `"utf-8"`, dropping `open()`'s default `"r"` mode, `None` in place of `False`.

See [gate-scadm-coverage-and-mutation-test-changed-functions](docs/decisions/gate-scadm-coverage-and-mutation-test-changed-functions.md) for why.

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
