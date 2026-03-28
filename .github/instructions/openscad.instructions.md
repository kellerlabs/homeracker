---
applyTo: "**/*.scad"
---

# OpenSCAD Guidelines

## BOSL2 Library

- Use [BOSL2](https://github.com/BelfrySCAD/BOSL2/wiki) for complex geometry operations (prefer attach/align over OpenSCAD's translate/rotate).
- Consult the BOSL2 wiki for available modules before writing custom geometry.

## Quality Settings

- Set `$fn=100` for production renders.
- Use lower `$fn` values (e.g., 32) during development for faster previews.

## Customizer Parameters

- Group parameters with `/* [Section] */` comment markers.
- Use `/* [Hidden] */` for internal constants that shouldn't appear in the Customizer UI.
- Include sanity checks (assertions) for critical parameters.
- Test parameter ranges for edge cases — especially min/max and boundary values.

## File Organization

- **Parts**: Printable models go in `models/<type>/parts/`.
- **Libraries**: Shared modules/functions go in `models/<type>/lib/` or `models/core/lib/`.
- **Tests**: Test files go in `models/<type>/test/`.
- **Flattened exports**: Auto-generated via `scadm flatten` into `models/<type>/flattened/` — never edit these manually.

## Include Conventions

- Use `include <BOSL2/std.scad>` for BOSL2 (resolved by OpenSCAD library path).
- Use `include <homeracker/...>` for cross-model library includes (resolved by scadm).
- Use relative paths (`include <../lib/foo.scad>`) for same-model includes.

## Preview PNGs

- When adding or modifying a parts file, **generate a preview PNG** with `cmd/export/export-png.sh`.
- PNGs are stored next to their source `.scad` file (e.g., `parts/foo.scad` → `parts/foo.png`).
- Update the model's README 📸 Catalog table and the `models/README.md` index accordingly.
