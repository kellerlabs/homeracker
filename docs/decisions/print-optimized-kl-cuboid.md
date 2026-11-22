# 📋 Build cuboids with the print-optimized kl_cuboid

## 📌 Status

**Accepted**: 2026-11-21

## 🤔 Context

- Combining roundings and chamfers on one cuboid gives broken results with BOSL2: `cuboid` refuses both at once, and a chamfer mask on a rounded `cuboid` cuts a square outline over the rounded corners. See the [comparison render](../../models/essentials/README.md#-cuboid).
- The clean result takes an `offset_sweep`, plus growing and clipping the outline whenever only some sides get chamfered. That is too much code to repeat in every model.
- FDM printers leave a bulge on sharp vertical corners: the toolhead slows into the corner while the nozzle keeps extruding. A 15 mm test cube measures 15.13 mm with sharp corners, 15.05 mm with a 1 mm rounding and 14.95 mm with a 2 mm rounding; a chamfered support segment measures 15.08 mm, a rounded one 14.98 mm. See the [measurements](../../models/essentials/README.md#-cuboid).
- A rounding on a horizontal edge prints as visible layer steps, depending on the layer height.

## 🔧 Decision

- [`models/essentials/lib/kl_cuboid.scad`](../../models/essentials/lib/kl_cuboid.scad) provides `kl_cuboid`, the preferred way to build a cuboid.
- **Opinionated:** roundings on the edges along one axis, chamfers on the edges of the two faces across it. With that axis pointing up on the print bed, the roundings reduce corner bulges and the chamfers avoid layer steps.
- **Axis from the edges:** all rounding edges run along one axis and name it; without roundings a whole-face chamfer does; otherwise it's Z. The caller writes edges in the part's own frame.
- **Chain rule:** a rounded edge joins its two sides into a chain. Chamfering one edge of a chain chamfers the whole chain on that face, so the chamfer follows the rounding.
- **Geometry:** the cuboid is built with the axis turned to Z and turned back. One `offset_sweep` per face chamfers the outline, with every unchamfered side grown outward first; an intersection with the plain extrusion clips the grown sides back to sharp edges.
- **Interface:** BOSL2 attachable with `size`, `rounding` + `rounding_edges`, `chamfer` + `chamfer_edges`; assertions reject edges outside the rule. `kl_cuboid_axis` exposes the inferred axis.
- **Location:** [essentials](../../models/essentials/README.md), KellerLab's generic utilities, with the `kl_` prefix.
- Masks and plain BOSL2 shapes stay available for geometry outside the rule.

Alternatives rejected:

| Alternative | Reason |
|---|---|
| BOSL2 `cuboid` with edge masks | A chamfer mask on a rounded `cuboid` leaves a square outline over the rounded corners |
| `offset_sweep` at every call site | Chamfers the whole outline only; per-side chamfers need the grow-and-clip step each time |
| Rounding and chamfer on any edge | Horizontal roundings print as layer steps and break the single-sweep construction |
| Roundings on Z only, turned with `orient` | Callers have to write every edge in the turned frame |
| An explicit axis parameter | The rounding edges already name the axis; a parameter repeats them |
| `models/core/lib/` with `hr_` prefix | Core holds the HomeRacker building system; the cuboid is a generic utility |

## 📊 Consequences

- ✅ One call gives roundings and chamfers that follow them, in any print orientation.
- ⚠️ When all rounding edges share a wrong axis, the axis switches silently; mixed axes still fail.
- ✅ The chain rule is a pure function, covered by asserts in [`models/essentials/test/kl_cuboid.scad`](../../models/essentials/test/kl_cuboid.scad).
- ⚠️ Renders slower than `cuboid`: two sweeps and an intersection per body.
- ⚠️ A chamfer wider than the rounding radius turns the rounded corner sharp on that face.
- ✅ Rounded vertical edges print within 0.05 mm of nominal, where sharp corners bulge by up to 0.13 mm.
- ⚠️ The evidence is five single pieces from one H2C, with an X1C matching by eye only; other printer brands may behave differently.
