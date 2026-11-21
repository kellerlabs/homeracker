# 📋 Calculate the longest printable part per print bed in a generic core library

## 📌 Status

**Accepted**: 2026-11-21

## 🤔 Context

- Long parts (supports, 19" rack parts) need a split when they exceed the print bed. Placed diagonally, a part fits far beyond the bed's side length: a 15 mm wide support reaches 29 units on an H2C's left-nozzle area, versus 21 straight.
- Split decisions need that number per printer without guessing, as a foundation for models like the rackmount end cover.

## 🔧 Decision

- [`models/core/lib/print_bed.scad`](../../models/core/lib/print_bed.scad) provides `print_fit(bed, width)` returning `[length, angle]`, `max_print_length(bed, width)`, `print_angle(bed, width, length)` returning the angle a given part fits at (straight preferred) or `undef`, and `bed_size(printer)` over a `PRINT_BEDS` preset table.
- **Generic and unprefixed:** nothing is HomeRacker-specific, so names carry no `hr_` prefix and the library can move to its own repository without renames.
- **Pure usable bed:** presets hold the slicer's printable area. Full-length edge strips are subtracted, corner exclusions are not.
- **Dual nozzle:** the default key holds the area both nozzles reach, which is guaranteed for every print; `*_single` keys hold the left nozzle's larger area.
- **Source:** every size comes from the printer's OrcaSlicer profile (`printable_area`, `bed_exclude_area`, `extruder_printable_area`).
- **Solver:** limits the angle to the range where the width fits, samples it in 360 steps and refines the best one, which covers parts wider than the bed's short side.

Alternatives rejected:

| Alternative | Reason |
|---|---|
| `margin` parameter | YAGNI; callers subtract their own safety margin |
| Corner exclusion zones as polygons | Turns a rectangle-in-rectangle fit into rectangle-in-polygon; the opposite diagonal avoids single-corner zones |
| `models/util/` folder | `models/` is the part catalog; a part-less folder breaks its README conventions |
| Separate library repository | Release and versioning overhead for one function; possible later |
| Raw bed sizes only, or printer names only | Names feed Customizer dropdowns, raw sizes cover unlisted printers; both are needed |
| Closed-form diagonal solve | Fails for parts wider than the bed's short side |

## 📊 Consequences

- ✅ Split decisions become one call, testable with plain asserts in [`models/core/test/print_bed.scad`](../../models/core/test/print_bed.scad).
- ✅ Adding a printer is one line in `PRINT_BEDS`.
- ⚠️ Results touch the bed edges; a brim or skirt needs its own margin.
- ⚠️ Preset sizes go stale when vendors change profiles.
