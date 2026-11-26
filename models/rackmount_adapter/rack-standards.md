# 📐 Rack Standards

## 📌 What

The [rackmount adapter](README.md) places its mounting holes per EIA-310, the 19" rack standard, and scales the same geometry to any other width. Rack equipment that fits a standard 19" rack fits the 19" adapter; 10" and other widths follow the same rules at their width.

| Width | Status | Defined by |
|---|---|---|
| 19" | Formal standard | EIA-310 (revision D 1992, CEA-310-E 2005), IEC 60297-3-100 (482.6 mm series), DIN 41494 |
| 10" | Industry convention, no formal standard | Vendors scale the 19" rail and keep its unit height. Often called a "half rack". |
| Any other inch | Same scaling, no standard | This adapter's `inches` parameter |

## 🤔 Why

### 📏 Dimensions

Only the overall width changes between sizes; everything else is the 19" geometry.

| Dimension | Rule | 19" | 10" | Source |
|---|---|---|---|---|
| Rack unit (1U) | 1.75" | 44.45 mm | 44.45 mm | EIA-310 |
| Holes per unit | ½"-⅝"-⅝", unit boundary in the middle of the ½" gap | 6.35 / 22.225 / 38.1 mm from the unit edge | same | EIA-310, IBM |
| Panel width | width in inches | 482.6 mm | 254 mm | EIA-310, Micropolis |
| Rail (mount surface) width | 0.625" | 15.875 mm | 15.875 mm | Micropolis |
| Clear opening | width − 1.25" | 450.85 mm | 222.25 mm | IBM, Cisco, Micropolis |
| Hole spacing, center to center | width − 0.688" | 465.125 mm | 236.525 mm | IBM, RackSolutions, Project MINI RACK |
| Panel edge to hole center | 0.344" | 8.74 mm | 8.74 mm | derived from the two above |

- IBM's EIA-310-D requirements give the 19" hole spacing as 18.3", +0.03" (465 mm, +0.8 mm) and the opening as 17.75", +0.03". The adapter's 18.312" and 17.75" sit inside both.
- The unit pattern is vertically symmetric, so equipment also fits upside down.

### 🎯 Hole position

The holes sit 8.74 mm in from the panel edge, not on the center of the 15.875 mm mount surface (7.94 mm). Version 1 of the adapter, the [10"](https://makerworld.com/en/models/1353730-modular-10-server-rack#profileId-1396918) and [19"](https://makerworld.com/en/models/1503491-modular-19-server-rack#profileId-1573137) models on MakerWorld, centered them, which spaces the holes 1.6 mm wider than EIA-310. The [decision record](../../docs/decisions/space-rackmount-adapter-holes-per-eia-310.md) has the details.

### 🔩 Cage nuts

The rail is a printed part with a pocket for each cage nut, which goes in from the back. It takes M6 cage nuts made for the standard 9.5 mm square hole. The hook pocket is 12.6 mm wide, which leaves two perimeters to the rail's inner edge and holds a fully tightened screw in a print test.

### 🚫 What it doesn't follow

- **Western Electric 23"**: holes on 1" vertical centers, incompatible with the EIA-310 unit pattern.
- **ETSI ETS 300 119**: a separate metric system with 535 mm rail-to-rail width and 25 mm hole spacing.

## 🔧 How

- `STD_RACK_BORE_EDGE_DISTANCE_X` in [constants.scad](../core/lib/constants.scad) holds the 8.74 mm, derived from the 19" panel and the 18.312" spacing.
- `get_adapter_gapfill()` fills the space between the HomeRacker frame and the panel edge, so the panel edge, and with it every hole, lands on the standard position for the chosen width.

## 📚 References

- [IBM: Rack specifications, EIA-310-D](https://www.ibm.com/docs/en/n-series?topic=specifications-requirements): hole spacing and opening with tolerances, hole pattern
- [Cisco Firepower 4100 install guide](https://www.cisco.com/c/en/us/td/docs/security/firepower/4100/hw/guide/b_install_guide_4100/mount_and_connect.pdf): 17.75" opening
- [Micropolis Rack Mounting FAQ](https://www.micropolis.com/support/kb/rack-mounting-faq): 10" and 19" panel width, rail width, opening and hole spacing
- [RackSolutions: EIA-310](https://www.racksolutions.com/news/data-center-optimization/eia-310-definition): unit boundary and 18.312" spacing
- [Project MINI RACK](https://mini-rack.jeffgeerling.com/): 10" hole spacing and its missing standard
- [IEC 60297-3-100](https://standards.iteh.ai/catalog/standards/iec/f329c3df-a975-4331-bc72-105e377e9d8a/iec-60297-3-100-2008): the international 482.6 mm series
- [Wikipedia: 19-inch rack](https://en.wikipedia.org/wiki/19-inch_rack): overview, 23" and ETSI formats
