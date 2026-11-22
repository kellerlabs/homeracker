# 📋 Space rackmount adapter holes per EIA-310 and scale the 19" geometry to any width

## 📌 Status

**Accepted**: 2026-11-22

## 🤔 Context

- The [rackmount adapter](../../models/rackmount_adapter/README.md) replaces the rack rail, so its cage nut holes have to line up with standard rack equipment.
- Version 1, the [10"](https://makerworld.com/en/models/1353730-modular-10-server-rack#profileId-1396918) and [19"](https://makerworld.com/en/models/1503491-modular-19-server-rack#profileId-1573137) adapters on MakerWorld, and the first draft of this one centered each hole on the 0.625" (15.875 mm) mount surface. That spaces the holes width − 0.625": 466.725 mm on 19", 238.125 mm on 10".
- EIA-310 sets the 19" hole spacing to 18.312" (465.1 mm). [IBM's EIA-310-D requirements](https://www.ibm.com/docs/en/n-series?topic=specifications-requirements) allow 465 mm, +0.8 mm. Centered holes sat 1.6 mm wider, outside that.
- 10" has no formal standard. Vendors scale the 19" rail and use 9.312" (236.525 mm) between holes ([Project MINI RACK](https://mini-rack.jeffgeerling.com/), [Micropolis](https://www.micropolis.com/support/kb/rack-mounting-faq)). Centered holes sat 1.6 mm wider here too.
- The standard puts each hole 0.344" from the panel edge, 0.031" off the center of the 0.625" rail.

## 🔧 Decision

- Each hole center sits `STD_RACK_BORE_EDGE_DISTANCE_X` = (19" − 18.312") / 2 = 8.7376 mm in from the panel edge, for every width. The spacing becomes width − 0.688": 465.125 mm on 19", 236.525 mm on 10".
- Any other width scales the same 19" geometry: 0.625" rails, a width − 1.25" opening, the EIA-310 vertical pattern (1U = 44.45 mm, ½"-⅝"-⅝").
- The cage nut hook pocket narrows from 13.4 to 12.6 mm, so the wall to the rail's inner edge stays at two perimeters (0.84 mm) after the move. A print test with a fully tightened M6 screw held.
- The details and sources live in [rack standards](../../models/rackmount_adapter/rack-standards.md).

Alternatives rejected:

| Alternative | Reason |
|---|---|
| Center the holes on the mount surface | 1.6 mm wider than EIA-310 and the 10" convention, outside the 19" tolerance |
| Move the holes outward within tolerance for a thicker wall | Two perimeters only fit outside the +0.8 mm tolerance |
| Western Electric 23" pattern | Holes on 1" vertical centers, incompatible with the EIA-310 unit pattern |
| ETSI ETS 300 119 | A separate metric system with 25 mm hole spacing |

## 📊 Consequences

- ✅ 19" matches EIA-310 and IEC 60297-3-100; 10" matches what vendors build.
- ✅ One constant covers every width, so the any-inch claim rests on a single scaling rule.
- ⚠️ Widths other than 10" and 19" follow that rule, not a standard; no rack vendor guarantees them.
- ⚠️ Western Electric 23" and ETSI racks don't fit.
- ⚠️ The narrower pocket compresses the cage nut hooks about 0.5 mm per side; tested with one cage nut brand.
