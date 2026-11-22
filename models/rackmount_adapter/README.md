# 🗄️ Rackmount Adapter

> ⚠️ Work in progress: geometry and parameters still change.

## 📌 What

Connects a vertical HomeRacker front support to a standard rack rail. One adapter per rack side, for racks from 2" to 20" wide (10" and 19" are the common ones) and 1 to 10 rack units tall.

From the HomeRacker side to the rack side, each adapter has:

- **Sleeve**: wraps the vertical front support, secured with a lock pin.
- **Mount bridge with connector covers**: covers the connectors above and below the adapter and rests against their arms, which carries the load into the rack.
- **Gap fill**: widens the adapter so the rack rail lands on the standard rack width.
- **Rack rail**: square cage nut holes for M6 cage nuts, three per rack unit.
- **End cover docks**: pockets at the top and bottom for end covers that close off the adapter.

It succeeds the [10"](https://makerworld.com/en/models/1353730-modular-10-server-rack#profileId-1396918) and [19"](https://makerworld.com/en/models/1503491-modular-19-server-rack#profileId-1573137) adapters on MakerWorld.

## 🤔 Why

### 🔁 Replacing the MakerWorld adapters

- Their building blocks aren't open source, and their Fusion 360 source is hard to maintain.
- They mount on Y-axis supports, which needs pull-through connectors, sticks out two units in front of the rack, and forces a bottom-up build where adjoining adapters share a support.
- They only cover 10" and 19", and leave an unclosed gap between adapters.

This adapter mounts on the vertical front supports instead, so any rack level can be swapped later, not just the top one. It sticks out one HomeRacker unit, which leaves room for the front plate and different cage nut sizes without hitting the connector arms of the horizontal supports.

### 📏 Rack units and HomeRacker units

A rack unit is 44.45 mm (1.75", EIA-310). Three HomeRacker units are 45 mm, so every rack unit adds 0.55 mm of gap to the next adapter above.

The adapter is sized for one device. That puts a gap of one HomeRacker unit between adapters, plus the 0.55 mm per rack unit:

- Supports run directly under each device and carry its load, as long as they print in one piece.
- The gap between devices helps heat dissipation.
- Adapters can also be printed tall enough to mount devices directly on top of each other.

### 🧢 End covers slide in from the back

The end cover docks open to the back. An end cover slides in before the adapter goes onto the rack, and the HomeRacker frame behind it holds it in place once mounted, with no extra locking parts.

## 🔧 How

Open `parts/rackmount_adapter.scad` in OpenSCAD and use the **Customizer** panel.

| Parameter | Default | Range | Description |
|-----------|---------|-------|-------------|
| `inches` | 10 | 2-20 | Rack width in full inches |
| `height_units` | 1 | 1-10 | Height in rack units |
| `side` | left | left, right | Rack side the adapter mounts on |
| `debug_colors` | false | bool | Color-code geometry for debugging |
| `disable_chamfer` | false | bool | Remove chamfers |
| `debug_anchors` | false | bool | Show the BOSL2 anchors |

- ⚠️ Print the right side with `side = right`. Mirroring the part in the slicer mirrors the engraved markings too.
- The markings sit on the side that faces the connectors: an up arrow on the top cover, the inch width and rack units on the bottom cover.

**Library usage**, include in your own model:

```scad
include <../rackmount_adapter/lib/rackmount_adapter.scad>

rackmount_adapter(rackwidth = 10, height_units = 2, side = RIGHT)
  attach("end_cover_top", FRONT) my_end_cover();
```

Implemented as a [BOSL2 attachable](https://github.com/BelfrySCAD/BOSL2/wiki/Tutorial-Attachments) sized to the whole adapter. The named anchors `"end_cover_top"` and `"end_cover_bottom"` sit on each dock's front wall and point back through the pocket.

## 📸 Catalog

| Part | Preview |
|------|---------|
| Rackmount Adapter | ![Rackmount Adapter](parts/renders/rackmount_adapter.png) |

To generate or refresh previews:

```sh
scadm export-png models/rackmount_adapter/parts/rackmount_adapter.scad
```

## 📚 References

- [Sleeve](../sleeve/README.md): wraps the vertical front support
- [Rackmount Ears](../rackmount_ears/README.md): mount devices into a standard rack
- [HomeRacker core](../core/README.md): base constants and measurements
