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

## Testing

- Use `unittest` or `pytest` for unit tests.
- Tests live alongside the package they test (e.g., `cmd/scadm/tests/`).
- Run tests with `python -m pytest` from the package directory.
