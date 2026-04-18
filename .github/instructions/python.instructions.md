---
applyTo: "**/*.py"
---

# Python Guidelines

## Docstrings

Use [Google style](https://google.github.io/styleguide/pyguide.html#38-comments-and-docstrings) for all functions:

- Brief summary on first line.
- `Args:` section describing each parameter.
- `Returns:` section describing return value.
- `Raises:` section for exceptions (if applicable).

Example: See `cmd/scadm/scadm/flatten.py` for reference.

## Code Style

- Keep code self-documenting with clear variable names.
- Add inline comments only for complex regex patterns or non-obvious logic.
- Line length: 121 characters max (enforced by `black`).

## Pylint

- **No unresolved pylint warnings.** Either fix the root cause or suppress with justification.
- When suppressing, **always add a comment explaining why** the rule doesn't apply:
  ```python
  # pylint: disable-next=too-many-branches  # Stateful parser for 3 types; splitting scatters the state machine
  def _parse_definitions(...):
  ```
- Prefer `disable-next` (single line) over inline `# pylint: disable=...` when possible.
- Common legitimate suppressions: data classes with no methods (`too-few-public-methods`), parsers (`too-many-branches`).
- Never suppress without fixing first — if the code *can* be refactored to resolve the warning, do that instead.

## Testing

- Use `unittest` or `pytest` for unit tests.
- Tests live alongside the package they test (e.g., `cmd/scadm/tests/`).
- Run tests with `python -m pytest` from the package directory.

### Unit vs Integration Tests

- **Unit tests** (`test_*.py` without markers): fast, no network, mocked dependencies. Run via pre-commit hooks.
- **Integration tests** (`test_cli_integration.py`, marked `@pytest.mark.integration`): exercise real CLI commands against temp workspaces. Run via CI workflow (`.github/workflows/integration-tests.yml`) on ubuntu + windows matrix.
  - **Slow tests** (`@pytest.mark.slow`): download binaries from the network. Subset of integration tests.
  - Non-`slow` integration tests may still make lightweight network calls (e.g., version resolution) but avoid large downloads.

### Running Integration Tests

```bash
# All integration tests (fast + slow)
python -m pytest tests/ -m integration -v

# Fast only (no downloads)
python -m pytest tests/ -m "integration and not slow" -v
```

### When to Add/Update Integration Tests

- Adding or modifying a CLI subcommand → add/update integration test.
- Changing `scadm.json` config schema → update config-dependent tests.
- Changing installer/resolver behavior → update relevant slow tests.
