# 🔄 Inception — HomeRacker Meta

## 📌 What

Models for organizing HomeRacker parts *within* the HomeRacker ecosystem. Uses Gridfinity-compatible bin bases to store overshoot supports, connectors, and other bits.

## 🤔 Why

For the completely insane people who want to store their leftover HomeRacker parts in an organized fashion — on a HomeRacker shelf, in Gridfinity bins, of course.

## 🔧 How

### Support Bin

A Gridfinity bin with a pocket grid that holds HomeRacker support pieces upright. Open any file in `lib/` with OpenSCAD and use the **Customizer** panel:

| Parameter | Default | Range | Description |
|-----------|---------|-------|-------------|
| `grid_x` | 2 | 1–17 | Gridfinity units in X (×42mm) |
| `grid_y` | 2 | 1–10 | Gridfinity units in Y (×42mm) |
| `divider_strength` | 1.2 | 1.0–3.0 | Divider wall thickness (mm) |
| `grid_style` | Riser | Riser / Full | Cross-shaped ridges vs solid walls |
| `height` | 15 | 5–15 | Pocket grid height (mm) |

**Grid styles:**
- **Riser** — Cross-shaped ridges with 45° slopes, minimal material and easier fitting
- **Full** — Solid walls with rectangular pockets, maximum rigidity

## 📚 References

- [Gridfinity library](../gridfinity/README.md)
- [HomeRacker core](../core/README.md)
