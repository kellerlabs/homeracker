# 📋 Stiffen rack panels with a generic truss grid

## 📌 Status

**Accepted** — 2026-06-19

## 🤔 Context

Large rack panels (19", multi-U) flex under load. We needed a way to add stiffness
without a wholesale redesign, and had to decide *how* to add it:

- FDM panels print **face-down**, so panel depth is the vertical (Z) print direction.
  Increasing `panel_depth` adds volume that the slicer fills with sparse gyroid infill —
  cheap broad bending resistance (a sandwich/I-beam), but stiffness depends on the user's
  infill settings and gyroid resists **torsion/racking** poorly.
- Split panels already grow knuckles to a back depth of `HR_SPLIT_KNUCKLE_STRENGTH_SLIM`
  (8.8mm). Any structure that stays within that envelope is "free" — it adds no bounding
  footprint beyond what the connector already claims.

We also had to decide whether the stiffener should be panel-specific or reusable, and how
it should behave on split panels (where a centerline connector interrupts the back face).

## 🔧 Decision

Add an **optional back-side truss stiffener** built from a new **generic, dimension-driven**
module `models/panel/lib/truss.scad` (`truss_grid`):

- `truss_grid` knows nothing about panels, bores, or splits — it takes `size`, `rows`, and
  `rib` and produces a framed, triangulated lattice (frame and diagonals are always on). It is
  **row-driven**: `rows` sets the number of horizontal bands and columns auto-size for ~square
  cells, so every cell is full-length (no clipped partial cells). Each cell's diagonal
  **alternates direction in a checkerboard** (a Warren/zigzag lattice) so the grid resists
  racking/shear equally in both directions rather than favouring one handedness. The chamfer
  (`chamfer_enabled`) is applied **only to the outer back (+Y) perimeter edge** — the face that
  shows on an assembled panel; interior ribs stay square. Kept generic for reuse by future
  models.
- `rackpanel` orchestrates: the brace attaches at the panel **back** face and protrudes to the
  knuckle back plane (`RP_BRACE_DEPTH = 8.8mm` from the front), so it sits **flush with split
  connectors**, its depth shrinks automatically as `panel_depth` grows, and it never touches
  the front face or its chamfer. It is skipped when less than a rib's depth of protrusion
  remains (`RP_BRACE_DEPTH - panel_depth < BASE_STRENGTH`).
- Each panel/half attaches its **own** brace to its back face via `attach(BACK, FRONT)`
  (`_naked_panel` itself stays brace-free, so the clippable building block is never cut
  through a truss). In split mode each half attaches a margin-trimmed field flush to the
  centerline cut, the right one **mirrored** about the centerline for a symmetric panel,
  leaving a connector gap between them; in full mode, one centered field spans the back.
  All leave a `RP_BRACE_SIDE_MARGIN` (16mm) strip each side to clear the mount surfaces
  and bore columns.
- Density preset (`back_brace_density`) scales bands with panel height so triangle size stays
  consistent: `regular` = 1 band/unit, `dense` = 2 bands/unit. Ribs stay `BASE_STRENGTH`.

Alternatives considered:

- **Solid/deeper panel only** — rejected as the *sole* mechanism: infill-dependent and weak
  in torsion. Kept as a complementary option (`panel_depth`); the two combine.
- **A wider (`strong`, full `BASE_UNIT`) split connector for seam stiffness** — added as an option
  first, then **removed**. A four-panel print test (19" 1U, Bambu X1C, HomeRacker defaults:
  3 walls, Arachne, 15 % gyroid, Bambu PLA Matte Charcoal) hand-loaded in shear and bending showed
  the wider knuckle flexed *more* along the seam and cost extra filament for no gain — stiffness
  came from `panel_depth` and `back_brace`, not connector width. So `split_connector_strength` /
  `connector_strength` and the `HR_SPLIT_KNUCKLE_STRENGTH_BASE` / `knuckle_strength` plumbing were
  dropped; the slim knuckle is the only connector. See the README's
  [real-world print test](../../models/panel/README.md#-stiffening-depth-vs-back-brace).
- **All diagonals one direction** (initial draft) — rejected: asymmetric racking stiffness and
  it left clipped partial cells along one edge from the 45° clip. The row-based alternating
  pattern fixes both.
- **Spacing-driven grid** (initial draft) — rejected: a fixed pitch left ragged partial cells.
  Row count + auto columns gives clean, evenly-spread triangles at any size.
- **Naming it `isogrid`** — rejected. Isogrid implies a fixed equilateral 60° lattice;
  our pattern is a rectangular grid with alternating diagonals, so `truss_grid` is honest.
- **Panel-specific brace module** — rejected in favor of a generic reusable file.

## 📊 Consequences

- ✅ Deterministic, infill-independent stiffness with strong torsion/racking resistance.
- ✅ Flush with the knuckle plane → no extra footprint on split panels; split halves each
  carry a self-contained sub-brace.
- ✅ `truss_grid` is reusable by other models.
- ✅ Composable: `panel_depth` (broad bending) + `back_brace` (torsion) stack;
  `back_brace` + Minimal bores is the lightest stiff combo.
- ✅ One split-connector width to reason about: dropping `strong` removed a trap option that
  hurt seam bending, plus its dead `knuckle_strength` plumbing.
- ⚠️ The full-panel attachable bounding box still reports `panel_depth` and does not include
  the brace protrusion (consistent with how split knuckles already exceed it). Back-face
  child anchoring is therefore approximate on braced full panels.
- ⚠️ The brace's solid ribs cost real plastic: `dense` density on a large panel can exceed
  the material of simply choosing Strong `panel_depth` (which is mostly sparse infill).
  `regular` is the sensible default; reach for `dense` only when extra rigidity is needed.
