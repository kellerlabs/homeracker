# 🖼️ Panel

## 📌 What

A plain mounting panel that fits into the HomeRacker scaffold system. Panels attach to vertical and horizontal supports via lockpin holes and can be used as-is (blank panels) or as a base for custom cutouts (keystone jacks, switches, displays, etc.).

## 🤔 Why

- **Universal base**: A generic panel module that any specialized panel (keystone, frontpanel, side panel) can build upon — no distinction between front/side at the lib level.
- **Two integration types**:
  - **Inter-Fit**: Inset panel for a flush fit between support bars. Each panel can be removed independently.
  - **Full Cover**: Overlap panel covering supports and connectors for a clean aesthetic. Must be integrated during scaffold assembly.
- **Scalable**: Supports arbitrary grid sizes (min 2×2 units). Panels larger than 2 units automatically get additional mount surfaces for rigidity.
- **Per-side control**: Each edge's mount surface can be enabled/disabled independently (north/south/east/west), and corner mounts can be toggled between full-height lockpin engagement and contour-only mode.

## 🔧 How

Open `parts/panel.scad` in OpenSCAD and use the **Customizer** panel.

| Parameter | Default | Range | Description |
|-----------|---------|-------|-------------|
| `panel_type` | 1 (Inter-Fit) | 1–2 | Panel integration type |
| `units_x` | 4 | 2–16 | Panel width in HR units |
| `units_y` | 3 | 2–16 | Panel height in HR units |
| `panel_clearance` | 0.0 | 0–0.4 | Full Cover only — gap between adjacent panels (mm). Default 0.0 works for most printers; increase slightly if panels are too tight |
| `corner_mounts` | true | — | Full-height corner mounts with lockpin holes (false = contour only) |
| `mount_north` | true | — | Mount plate on north (back) edge (only effective when units_x > 2) |
| `mount_south` | true | — | Mount plate on south (front) edge (only effective when units_x > 2) |
| `mount_east` | true | — | Mount plate on east (right) edge (only effective when units_y > 2) |
| `mount_west` | true | — | Mount plate on west (left) edge (only effective when units_y > 2) |
| `debug_colors` | false | — | Show distinct colors per section for debugging |
| `chamfer_enabled` | true | — | Apply chamfers to edges |

## 📸 Catalog

| Part | Preview |
|------|---------|
| Panel (Inter-Fit) | ![Panel Inter-Fit](parts/renders/panel_interfit_default.png) |
| Panel (Full Cover) | ![Panel Full Cover](parts/renders/panel_fullcover_default.png) |
| Rack Panel (10") | ![Rack Panel 10"](parts/renders/rackpanel_default_1u_10inch.png) |
| Rack Panel (19") | ![Rack Panel 19"](parts/renders/rackpanel_default_1u_19inch.png) |

To generate or refresh previews:

```sh
scadm export-png models/panel/parts/panel.scad
scadm export-png models/panel/parts/rackpanel.scad
```

### Panel Variants

#### Default (all mounts enabled)

| Inter-Fit | Full Cover |
|-----------|------------|
| ![Inter-Fit Default](parts/renders/panel_interfit_default.png) | ![Full Cover Default](parts/renders/panel_fullcover_default.png) |

#### Contour Corners (corner_mounts = false)

Wherever a mount surface is disabled (corners or edges), the panel shows a contour instead — a short wall at BASE_STRENGTH height without lockpin holes. The contour provides added stability and keeps the panel opaque (no gaps), while staying short enough to not block any attachments on the HR scaffold.

**When to use corner mounts:**

Corner mounts occupy the lockpin holes normally used by supports and connectors. This matters when two panels share a 90° edge of the rack — one panel's corner mount blocks the lockpin hole needed by the other. For panels > 3×3 units, leaving corners disabled (contour only) is recommended as the mount surfaces alone provide sufficient engagement and it's easier to first build the scaffold and afterwards add panels to it.

For smaller panels (≤ 3 units on one axis), corner mounts become valuable: a 3-unit side has only 1 lockpin hole on its mount surface, and panels < 3 units have no mount surfaces at all. Corner mounts (combined with extended lockpins — neck, tail, or both variants) let these panels use connector lockpin positions that would otherwise be inaccessible.

| Inter-Fit | Full Cover |
|-----------|------------|
| ![Inter-Fit No Corners](parts/renders/panel_interfit_no_corners.png) | ![Full Cover No Corners](parts/renders/panel_fullcover_no_corners.png) |

#### Partial Mounts (south + west disabled)

Shows the difference in wall height between panel types when mount surfaces are disabled:
- **Inter-Fit**: disabled sides get full-height walls (same as mount height) to maintain the panel contour.
- **Full Cover**: disabled sides get short 2mm walls only, keeping the area clear for attachments in the HR scaffold.

| Inter-Fit | Full Cover |
|-----------|------------|
| ![Inter-Fit Partial](parts/renders/panel_interfit_partial_mounts.png) | ![Full Cover Partial](parts/renders/panel_fullcover_partial_mounts.png) |

#### Minimal Size (2×2)

The smallest possible panel — only corner mounts, no mount surfaces (they require > 2 units). Disabling `corner_mounts` on a 2×2 panel makes the panel non-mountable.

| Inter-Fit | Full Cover |
|-----------|------------|
| ![Inter-Fit 2×2](parts/renders/panel_interfit_2x2.png) | ![Full Cover 2×2](parts/renders/panel_fullcover_2x2.png) |

## 🔩 Rack Panel

A standard 10"/19" rack-compatible panel with configurable bore patterns. Open `parts/rackpanel.scad` in OpenSCAD.

### Parameters

| Parameter | Default | Range | Description |
|-----------|---------|-------|-------------|
| `panel_width_type` | 1 (10") | 1–2 | Panel width standard (10" or 19") |
| `height_Units` | 1 | 1–8 | Panel height in rack units |
| `bore_mode` | 0 (Default) | 0–2 | Bore hole pattern |
| `debug_colors` | false | — | Show distinct colors per section for debugging |
| `chamfer_enabled` | true | — | Apply chamfers to edges |

### Bore Modes

| Mode | Value | 1U | 2U | 3U+ |
|------|-------|----|----|-----|
| Default | 0 | 2 bores/unit | 1 bore/unit | 1 bore/unit |
| All | 1 | 3 bores/unit | 3 bores/unit | 3 bores/unit |
| Minimal | 2 | 1 bore/unit | 1 bore top + bottom | 1 bore top + bottom, 0 inner |

### Variants

#### Default

| 1U | 2U |
|----|----|
| ![Default 1U](parts/renders/rackpanel_default_1u_10inch.png) | ![Default 2U](parts/renders/rackpanel_default_2u_10inch.png) |

#### All (Full)

| 1U | 2U |
|----|----|
| ![All 1U](parts/renders/rackpanel_all_1u_10inch.png) | ![All 2U](parts/renders/rackpanel_all_2u_10inch.png) |

#### Minimal

| 1U | 2U | 3U |
|----|----|----|
| ![Minimal 1U](parts/renders/rackpanel_minimal_1u_10inch.png) | ![Minimal 2U](parts/renders/rackpanel_minimal_2u_10inch.png) | ![Minimal 3U](parts/renders/rackpanel_minimal_3u_10inch.png) |

### Module Architecture

```text
rackpanel          → orchestrator: bore mode logic, chamfering (edge_mask)
└─ rackpanel_stack → pure stacker: one zcopies of rackpanel_1u
   └─ rackpanel_1u → single 1U body with bore subtraction (no chamfer)
      └─ bores_1u  → 1–3 evenly spaced bores per unit
└─ bores_minimal   → 1–2 bores (top + bottom unit centers) for MINIMAL mode
```

See [lib/rackpanel.scad](lib/rackpanel.scad) for implementation.

## 📚 References

- [HomeRacker core](../core/README.md)
