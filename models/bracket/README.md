# 🗜️ Bracket

## 📌 What

A clamp that wraps a device from above or below and hangs it in a HomeRacker frame. A shell grips the device, mount wings on both flanks cap the vertical supports and take a lock pin each.

![Bracket](parts/renders/bracket.png)

## 🤔 Why

Devices come in arbitrary sizes, HomeRacker supports sit on a 15mm grid. The wings absorb the difference: each one widens by half of what the device width misses on the grid, so the lock pin holes land on a support whatever the device measures. Nothing below/above the device, so airflow and cabling stay clear.

## 🔧 How

Open `parts/bracket.scad` in OpenSCAD and use the **Customizer** panel.

| Parameter | Default | Range | Description |
|-----------|---------|-------|-------------|
| `device_width` | 100 | 15-390 | Device width in mm |
| `device_depth` | 99 | 15-400 | Device depth in mm |
| `device_height` | 25.5 | 9.4-250 | Device height in mm |
| `strength_top` | 7.5 | 2-50 | How far the top plate reaches inward over the device |
| `strength_sides` | 7.5 | 2-50 | How far the side walls reach down the device |
| `mount_columns` | 0 | 0-2 | Wing columns, 0 picks 1 or 2 automatically |
| `mount_offset_y` | 0 | 0 to `device_depth - 15` | Pushes the wings back from the front edge |
| `debug_colors` | false | bool | Color-code geometry for debugging |
| `disable_chamfer` | false | bool | Remove chamfers (useful for debugging fit) |

Measure the device itself, not a gap. The standard 0.2mm `TOLERANCE` is added internally.

The 50mm ceiling on both strengths is a Customizer slider bound, not a limit of the model. Through the library or a `-D` override they take any value from 2mm up and clamp as described under ⚠️ Limits, which is what the `strength_sides=200` render command below does.

**Library usage**, include in your own model:

```scad
include <../bracket/lib/bracket.scad>

bracket(device_width=100, device_depth=99, device_height=25.5);
```

Implemented as a [BOSL2 attachable](https://github.com/BelfrySCAD/BOSL2/wiki/Tutorial-Attachments). `bracket_shell()`, `bracket_mount()` and `bracket_mount_pair()` are exposed for composing the halves separately. An optional `color` parameter overrides the default yellow.

## ⚠️ Limits

Five inputs are refused outright, with an assertion naming the value that would work.

| Limit | Value | Why |
|-------|-------|-----|
| `device_height` | at least 9.4mm | The bridge skeleton cutout is rounded by half a unit, and the rounding has to fit between the bridge floor and its chamfered top |
| `device_depth` | at least 15mm | Shallower leaves no room for even one column of wings |
| `mount_offset_y` | at most `device_depth - 15` | Beyond that the wings hang off the back of the shell instead of gripping the supports |
| `mount_columns = 2` | needs `device_depth >= 45 + mount_offset_y` | Two columns any closer would merge into one block |
| `strength_top`, `strength_sides` | at least 2mm | One wall thickness is the thinnest shell that holds a device at all |

Three inputs are silently clamped at the top end rather than refused, because the clamped result is still the part you asked for:

- `strength_top` caps at half the smaller device dimension, where the top plate closes over entirely.
- `strength_sides` caps at `device_height - 2mm`.
- `mount_columns = 0` picks two columns from a device depth of `45 + mount_offset_y`, one below that.

One thing to know before composing with the module: **the attachable bounding box covers the shell only**. The wings reach past it on all three axes, outward in X by a wing width each side, down in Z by roughly the device height plus a support unit, and in Y wherever `mount_offset_y` puts them. Anchor against the shell, then place anything near the wings by hand.

## 📸 Catalog

| Part | Preview |
|------|---------|
| Bracket | ![Bracket](parts/renders/bracket.png) |

### Variants

Each of these shows one behavior the module applies on its own.

| Single column (shallow device) | Forced single column | Wide wings (width near a grid line) |
|--------------------------------|----------------------|--------------------------------------|
| ![Single column](parts/renders/bracket_single_column.png) | ![Forced single column](parts/renders/bracket_forced_single.png) | ![Wide wings](parts/renders/bracket_wide_wings.png) |
| `device_depth` of 30 is under the two-column threshold, so one column per side | 200mm deep but pinned to one column, which saves material on a light device | A 90mm device sits just past a grid line, so each wing grows to 22.4mm to reach the support. The lock pin hole stays on the grid |

| Mount offset | Closed top plate | Deep side walls |
|--------------|------------------|-----------------|
| ![Mount offset](parts/renders/bracket_mount_offset.png) | ![Closed top](parts/renders/bracket_closed_top.png) | ![Deep sides](parts/renders/bracket_deep_sides.png) |
| `mount_offset_y` of 34 pushes both columns back, which is how a bracket clears a front panel | `strength_top` of 50 hits the cap on a 99mm device, closing the window and dropping its chamfer | `strength_sides` of 200 clamps to `device_height - 2`, wrapping a 120mm device almost to the bottom |

| Minimum strengths |
|-------------------|
| ![Minimum strengths](parts/renders/bracket_min_strength.png) |
| Both strengths at their 2mm floor, the thinnest shell the module will build |

To generate or refresh the renders (full F6 renders via `scadm export-png`):

```sh
scadm export-png models/bracket/parts/bracket.scad
scadm export-png models/bracket/parts/bracket.scad -D device_depth=30 --output models/bracket/parts/renders/bracket_single_column.png
scadm export-png models/bracket/parts/bracket.scad -D device_depth=200 -D mount_columns=1 --output models/bracket/parts/renders/bracket_forced_single.png
scadm export-png models/bracket/parts/bracket.scad -D device_width=90 --output models/bracket/parts/renders/bracket_wide_wings.png
scadm export-png models/bracket/parts/bracket.scad -D device_depth=200 -D mount_offset_y=34 --output models/bracket/parts/renders/bracket_mount_offset.png
scadm export-png models/bracket/parts/bracket.scad -D strength_top=50 --output models/bracket/parts/renders/bracket_closed_top.png
scadm export-png models/bracket/parts/bracket.scad -D strength_top=2 -D strength_sides=2 --output models/bracket/parts/renders/bracket_min_strength.png
scadm export-png models/bracket/parts/bracket.scad -D device_height=120 -D strength_sides=200 --output models/bracket/parts/renders/bracket_deep_sides.png
```

## 📚 References

- [HomeRacker core](../core/README.md): base constants, lock pins and supports
- [Sleeve](../sleeve/README.md): the other reusable way to attach to a support
- [Return the bracket to the open-source catalog](../../docs/decisions/return-bracket-to-open-source-catalog.md): why the module lives here
