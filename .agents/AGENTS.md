# Homeracker Rules

## Pre-commit Hooks on Windows
When committing on a local Windows environment, DO NOT bypass all pre-commit hooks using `--no-verify`. This skips critical formatting checks (like `end-of-file-fixer` and `trailing-whitespace`) and causes CI failures.
Instead, ensure `pre-commit` is installed and explicitly skip only the hooks that are known to fail on Windows due to bash/path incompatibilities by using the `SKIP` environment variable:
`$env:SKIP="flatten-validate,shell-lint,scadm-tests"; git commit -m "..."`

## MakerWorld Parametric Source Files
- The flattened `.scad` files for MakerWorld (parametric sources) must NOT instantiate the module directly with top-level geometry.
- They must wrap the module calls in MakerWorld-specific wrappers like `module mw_assembly_view()` and `module mw_plate_1()`.
- They must include a section header for the customizer (e.g., `/* [General] */`), otherwise MakerWorld will drop the parameters.
- Ensure the source file and flattened file are completely in sync before pushing to avoid `flatten-validate` CI failures.

## MakerWorld Descriptions
- Do not use GitHub-style Markdown admonitions (like `> [!TIP]`) in MakerWorld descriptions, as they are not supported by the `md-to-mw.py` export script. Use standard blockquotes with emojis (like `> 💡`) instead.
