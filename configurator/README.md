# 🧮 Configurator

## 📌 What

Browser-only rack configurator published at <https://homeracker.org/configurator/>. Define a rack as a stack of rows (each with an optional name, its own height, column widths and whether its posts continue from the row below), set depth and feet, close individual openings with panels (in to-scale face drawings or by clicking them in the 3D view), preview it, and get the parts list to print. The config lives in the URL hash, so a link is a saved rack; the Copy link button puts it on the clipboard. A printer section holds your print volume (default 256 mm cubed, kept in the browser, not in the link); parts that do not fit it are marked in the parts list and drawn red in the 3D view, without blocking anything else.

## 🤔 Why

The README's first assembly tip is "make a parts list". This does the counting, and it encodes the geometry rules once, next to the models they mirror.

## 🔧 How

```sh
cd configurator
npm ci
npm run dev      # local dev server
npm run check    # eslint + tsc + vitest
npm run build    # static bundle in dist/, served under /configurator/
```

### Structure

| Path | Purpose |
|---|---|
| `src/engine/` | Pure geometry + parts list. No DOM, no Three.js (enforced by `tsconfig.engine.json` and eslint) |
| `src/engine/orientation.ts` | Finds which of the 24 cube rotations maps a canonical connector mesh onto a node (pure, tested) |
| `src/engine/printer.ts` | Print bed check: every parts-list line carries the bounding box of one part in mm; `unprintable()` lists the lines that fit no axis-aligned orientation of the bed |
| `src/render/` | `meshes.ts` draws real part meshes from the exported library (connectors per type and pull-through axis, supports per length, lock pins, feet); `layout.ts` + `build.ts` are the schematic box fallback; `scene.ts` picks one; `viewcube.ts` + `viewcubeGeometry.ts` (both pure and tested) + `viewcubeGizmo.ts` are the orientation cube |
| `src/app.ts` | `mountConfigurator(root)`: builds the controls, stage and parts list inside any element |
| `src/configurator.css` | Component styles; reads the site design tokens, falls back to matching values standalone |
| `src/engine/diagrams.ts` | To-scale elevations and plans of every face and frame for the panel drawings (pure, tested) |
| `src/ui/` | Row editor (height, shift, column widths with negative widths for gaps, posts continue from below), panel drawings (click a rectangle to cycle open, inter-fit, full cover; one figure per face plus one per gap; the three squares next to a drawing set all of its openings; hover syncs with the 3D view), parts-list table, URL hash sync |
| `tests/` | Vitest; `fixtures.ts` holds the worked examples |

### Geometry rules

- 1 unit = 15 mm (`BASE_UNIT`). Connector cores are 1 unit; a support between nodes `a < b` has length `b - a - 1`.
- A rack is a stack of rows, bottom to top. Each row has a height (its vertical support length), a list of column widths (bay support lengths, left to right; each divider between bays is one unit of connector core), a shift (units to the right of x = 0) and a `through` flag: when set, the posts of the row below continue through the frame under this row (pull-through connectors there, one long support) instead of ending in a standard connector. Depth is shared.
- A column width may be written negative: that is a **gap**, taking the same space as a bay of that width but carrying no beam above it. It is what builds a U — a row of `6, 10, 6` under a row of `6, -10, 6` gives two towers with the space between them open to the top. The posts on both flanks of a gap stand as they would for a bay, and a beam under a gap survives when a bay of the row below spans the same place. The beam above a gap never comes back: stacking another row on the U leaves the gap open and that row keeps its own top beam, so a gap cannot be bridged from above. A gap has no bay, so no front or back panel; the walls it exposes become the left and right openings of the row's segments (the runs of bays on either side), drawn in their own `Gap in <row>` figure. Because those openings are indexed by segment ordinal, editing a gap into an existing row can move a left or right panel to a different wall (a saved link has no gap, so its indices never shift under it). A gap may sit anywhere in a row, including at either end, where it takes away the beam above its own columns and nothing else; a gap at the end exposes one wall rather than a facing pair, so it gets no figure of its own and that wall shows in the side elevation instead. A rack whose parts end up joined by nothing — a U standing on the floor, with no row spanning under its gap — is reported under the rows, without blocking anything else.
- Frames sit between rows and get a connector at every column boundary of the row below and the row above; beams are split there, so a divider that stops ends in a T connector. Vertical posts run at every column boundary of their own row. Rows can differ in width and position (stepped racks).
- Two connectors need at least 2 units of support between them, because each connector arm wraps one unit of the support. Depth, row heights and column widths are therefore 2..50, and a frame beam shorter than 2 units (dividers of neighbouring rows landing 2 units apart) is reported under the rows, drawn red in the 3D view and marked in the parts list, without blocking the rack.
- Outer size is the widest row by `depth + 2` by the sum of `height + 1` over rows, plus 1.
- Connector type = (axes used, arm count) as in `CONNECTOR_CONFIGS`. A through junction makes its nodes z pull-through.
- One lock pin per occupied arm. Feet plug into the `-z` arm of every floor node.
- Panels close openings. Every row has front and back openings per column and one left and one right opening per segment; every frame (bottom, each shelf between rows, top) has one horizontal opening per span between its nodes, so exposed roofs of a wider lower row and shelves inside the rack can be panelled too. A panel fills its opening exactly: `units_x = support length` (from the inter-fit deduction in `panel.scad`). Openings need at least 2 units per side to take a panel (the model asserts that); the upper bound is the support length. A front or back bay whose top or bottom edge carries a connector between its corners (the divider of a neighbouring row ending in a T there) cannot take a standard panel either: the panel model runs its mount plates and contour walls along the whole edge, and a connector core stands 2.1 mm proud of the support into that space. Such openings are hatched in the drawings and skipped by the whole-face shortcuts. A panel that still lands on an opening no standard part fits (from an older link, or after a row was resized) never blocks the rack: it is drawn in the warning colour in the drawing, the parts list and the 3D view, and a click on it removes it. Panels beyond the Customizer slider range of 16 units get a note in the parts list: type the units into the Customizer or print them split. Panel lock pins are an estimate (one per mount plate hole, plus four extended pins for corner mounts on panels 3 units or smaller) and are listed separately.
- URL hash: `v=4&d=<depth>&r=<height>:<w>.<w>[~shift][*]_<row>...&f=<feet>&pn=<f|b|l|r|h><at>.<index><i|f>_...&n<row>=<name>` where a negative `<w>` is a gap, `*` marks a row whose posts continue from below, `at` is the row index (vertical faces) or frame index (horizontal), and `n0`, `n1`, ... carry optional row names (up to 40 characters). Version 3 links (one post mode for the whole rack), version 2 links (one panel type per face) and version 1 links (single column, level positions) still open.

### Preview

An orientation cube sits in the top right corner of the stage, the way CAD software shows one. It turns with the model so the face you are looking at is always named, using the same names as the face drawings: `FRONT` is -y, `RIGHT` is +x, `TOP` is +z. Its corners are chamfered off, so it is fourteen real facets: six labelled octagons and eight corner triangles, one per view it offers. That makes the corners visible as targets from any angle, including head on to a face, and it makes the hit test exact — the ray reports the facet it struck, with no guessing from how close to an edge it landed. Hovering lights that one facet, and clicking swings the camera to its view, keeping the current target and distance, so a corner gives the usual 3/4 isometric. The top and bottom views are tipped a hair towards the front, because looking exactly down the up axis leaves an orbit camera's azimuth undefined. The cube is drawn in a scissored corner of the same WebGL canvas, so it costs no second context and cannot drift out of step with the camera.

The 3D preview uses the part meshes exported by `site/scripts/export-parts.mjs` (served under `/parts/`; the standalone app serves `../site/public` too). Every connector is placed with the rotation from `orientation.ts`, lock pins sit in every occupied arm, feet plug into the floor arms. Panels are parametric in two dimensions, so each one is assembled the way `panel()` in `panel.scad` assembles it: a plate (inset and flush for inter-fit, overlapping the supports by half a unit for full cover) plus real exported meshes of the support mount plate for that edge length and the corner bracket, placed with the same spins as the OpenSCAD module. The kit is exported from `site/scripts/scad/panel_kit.scad`. Without the mesh library the preview falls back to schematic boxes.

Worked example (defaults): depth 6, rows 5 and 4 high with one 6-unit column, feet on, segmented posts gives 12 x 6u + 4 x 5u + 4 x 4u supports, 8 x 3D4W + 4 x 3D3W connectors, 44 lock pins, 4 feet. Splitting the bottom row into two 4-unit columns adds a post, two T connectors (3D5W and 3D4W) and two feet.

> ⚠️ The panel sizing rule is derived from the library source, not yet verified on a print. If a panel is off by one unit, fix `panelSize()` in `src/engine/panels.ts` and its test.

### Deploy

The [site](../site/README.md) mounts this app on its `/configurator/` page by importing `src/app.ts` and `src/configurator.css` directly, so the deployed configurator shares the site's navigation, fonts and colours. `npm run build` here still produces a standalone bundle for local use; `index.html` is that shell.

## 📚 References

- [web-configurator-on-github-pages](../docs/decisions/web-configurator-on-github-pages.md) — decision record
- [HomeRacker core](../models/core/README.md) — supports, connectors, lock pins
- [Panels](../models/panel/README.md), [Feet](../models/foot/README.md)
