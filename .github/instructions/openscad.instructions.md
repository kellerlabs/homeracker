---
applyTo: "**/*.scad"
---

# OpenSCAD Guidelines

## BOSL2 Library

- Use [BOSL2](https://github.com/BelfrySCAD/BOSL2/wiki) for complex geometry operations (prefer attach/align over OpenSCAD's translate/rotate).
- Consult the BOSL2 wiki for available modules before writing custom geometry.

## Composing Geometry (attach/align vs union/diff)

- **Position with anchors, not offsets.** Prefer `attach`/`align`/`position` + `left`/`right`/`fwd`/`back` over raw `translate`/`rotate` with hand-computed centre math. `union()` is for merging separate solids, never for positioning.
- **`diff()` is tag-based.** Kept (untagged) geometry and `remove`-tagged cutters coexist in one `diff()`; cutters only subtract where they overlap. A part welded on after the bores belongs *inside* the same `diff()` as an untagged child — do **not** wrap it in `union()` to "shield" it.
- **Isolate a child's own `diff()`/`edge_mask` with `tag_scope()`.** A nested chamfer (edge_mask applies a `remove` tag) leaks into an enclosing `diff()` and gets cancelled. Wrap the inner part in `tag_scope()` at the call site to contain its tags.
- **Edge breaks in one pass.** Chamfer/fillet an assembly's outer edge with `edge_mask` on the bounding-box edges, not per-member — per-piece chamfers leave nubs at junctions.
- **Keep sub-parts ignorant of the parent.** A reusable part (e.g. a back brace) should take its own size and attach to a face; splitting/clipping belongs in the parent, not duplicated inside the part.

## Naming

- **Use descriptive variable names.** Spell out intent: `usable_width`, `seam_edge`, `row_center` — not `uw`, `se`, `rc`. The only exception is loop counters (`i`, `j`, `k`) and BOSL2/OpenSCAD idioms (`$fn`, `$idx`).
- Local variables in functions/modules carry a leading underscore by convention (`_usable_width`); keep the descriptive name after it.


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

## Catalog Render PNGs

- When adding or modifying a parts file, **regenerate its render PNG** with `scadm export-png`.
- `scadm export-png` always passes `--render`, so catalog images are **full F6 renders**, not OpenCSG previews. Always recreate them this way — preview screenshots show triangulation seams on coplanar/coincident faces that full renders avoid.
- If a full render still shows a diagonal seam on a flat face, the geometry has two coplanar coincident faces. Fix it in the model (e.g. overlap unioned boxes by `HR_EPSILON`) rather than re-rendering.
- PNGs are stored in a `renders/` subfolder next to their source (e.g., `parts/foo.scad` → `parts/renders/foo.png`).
- Update the model's README 📸 Catalog table and the `models/README.md` index accordingly.
- **Dark models** (e.g., `HR_CHARCOAL` primary color): use `--colorscheme Metallic` for better contrast. The default `BeforeDawn` has a dark background that makes charcoal/black models invisible.
- **Repo-wide regeneration** — recreate every default catalog PNG (one per non-`_` `parts/*.scad`):
  ```bash
  find models -path '*/parts/*.scad' -not -name '_*' -exec scadm export-png {} \;
  ```
  Variant PNGs (those built with `-D`/`--output`) are listed per model in that model's `README.md` — re-run those commands too.

## Self-Test Renders

For quick geometry verification during development:

1. Create a temporary preset JSON in `parts/` with `_test_` prefix:
   ```json
   { "parameterSets": { "my_test": { "param": "value" } } }
   ```
2. Prefer `scadm export-png` when available, fall back to direct OpenSCAD:
   ```bash
   # Preferred (when scadm export-png is available):
   scadm export-png models/<type>/parts/<file>.scad -p _test_preset.json -P my_test

   # Fallback (direct OpenSCAD — use openscad.com on Windows, openscad on Linux/macOS):
   bin/openscad/openscad.com models/<type>/parts/<file>.scad \
     -o models/<type>/parts/_test_output.png --render \
     --imgsize=1200,900 --colorscheme BeforeDawn --viewall --autocenter \
     -p models/<type>/parts/_test_preset.json -P my_test
   ```
3. **Render multiple angles** — a single view can miss geometry issues:
   - Default (`--viewall --autocenter`): overall shape
   - Front: `--camera=0,0,0,90,0,0,0`
   - Side: `--camera=0,0,0,90,0,90,0`
   - Close-up of changed area: `--camera=x,y,z,rx,ry,rz,dist`
4. Use `debug_colors=true` and low `$fn` (32) for fast iteration.
5. **Clean up** all `_test_*` files after verification.
