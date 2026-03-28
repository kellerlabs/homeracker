# 🔄 Inception — HomeRacker Meta

## 📌 What

Models for organizing HomeRacker parts *within* the HomeRacker ecosystem. Includes Gridfinity-compatible bins and frame-mounted grids for storing supports and other bits.

## 🤔 Why

For the completely insane people who want to store their leftover HomeRacker parts in an organized fashion — on a HomeRacker shelf, in Gridfinity bins, of course.

## 🔧 How

Open any file in `parts/` with OpenSCAD and use the **Customizer** panel.

### Support Bin

A Gridfinity bin with a pocket grid that holds HomeRacker supports upright. Uses a standard Gridfinity bin base.

| Parameter | Default | Range | Description |
|-----------|---------|-------|-------------|
| `grid_x` | 2 | 1–17 | Gridfinity units in X (×42 mm) |
| `grid_y` | 2 | 1–10 | Gridfinity units in Y (×42 mm) |
| `divider_strength` | 1.2 | 1.0–3.0 | Divider wall thickness (mm) |
| `grid_style` | Riser | Riser / Full | Cross-shaped ridges vs solid walls |
| `height` | 15 | 5–15 | Pocket grid height (mm) |

**Grid styles:**

- **Riser** — Cross-shaped ridges with 45° slopes; minimal material, easier fitting
- **Full** — Solid walls with rectangular pockets; maximum rigidity

### Support Grid

A frame-mounted pocket grid that clips directly into a HomeRacker rack opening via mounting ears with lock pins. No Gridfinity base needed.

| Parameter | Default | Range | Description |
|-----------|---------|-------|-------------|
| `hr_width` | 11 | 15–17 | Frame width in HR units (×15 mm) |
| `hr_height` | 3 | 3–10 | Frame height in HR units (×15 mm) |
| `end_piece` | false | true/false | Add backstop to prevent supports sliding through |
| `funnel_strength` | 3 | 3.3–5.0 | Divider wall thickness (mm) |
| `grid_depth` | 1 | 1–5 | Grid depth in HR units (longer = more stable) |
| `mounting_axis` | Vertical | Vertical / Horizontal / Both | Where to place the mounting ears |

**Mounting axis options:**

- **Vertical** — Ears on the left/right sides of the grid
- **Horizontal** — Ears on the top/bottom
- **Both** — Ears on all four sides

## 📸 Catalog

| Part | Preview |
|------|---------|
| Support Bin | ![Support Bin](parts/supportbin.png) |
| Support Grid | ![Support Grid](parts/supportgrid.png) |

To generate or refresh previews:

```sh
./cmd/export/export-png.sh models/inception/parts/<part>.scad
```

## 📚 References

- [Gridfinity library](../gridfinity/README.md)
- [HomeRacker core](../core/README.md)
