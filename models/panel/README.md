# 🖼️ Panel

## 📌 What

A plain mounting panel that fits into the HomeRacker scaffold system. Panels attach to vertical and horizontal supports via lockpin holes and can be used as-is (blank panels) or as a base for custom cutouts (keystone jacks, switches, displays, etc.).

## 🤔 Why

- **Universal base**: A generic panel module that any specialized panel (keystone, frontpanel, side panel) can build upon — no distinction between front/side at the lib level.
- **Two integration types**:
  - **Inter-Fit**: Inset panel for a flush fit between support bars. Each panel can be removed independently.
  - **Full Cover**: Overlap panel covering supports and connectors for a clean aesthetic. Must be integrated during scaffold assembly.
- **Scalable**: Supports arbitrary grid sizes (min 2×2 units). Panels larger than 2 units automatically get additional wall mounts for rigidity.

## 🔧 How

Open `parts/panel.scad` in OpenSCAD and use the **Customizer** panel.

| Parameter | Default | Range | Description |
|-----------|---------|-------|-------------|
| `panel_type` | 1 (Inter-Fit) | 1–2 | Panel integration type |
| `units_x` | 4 | 2–16 | Panel width in HR units |
| `units_y` | 2 | 2–16 | Panel height in HR units |
| `panel_clearance` | 0.0 | 0–0.4 | Full Cover only — gap between adjacent panels (mm) |
| `support_contact_x` | false | — | Add protrusions on horizontal supports (only when units_x > 2) |
| `support_contact_y` | false | — | Add protrusions on vertical supports (only when units_y > 2) |
| `debug_colors` | false | — | Show distinct colors per section for debugging |
| `chamfer_enabled` | true | — | Apply chamfers to edges |

## 📸 Catalog

| Part | Preview |
|------|---------|
| Panel | ![Panel](parts/renders/panel.png) |
| Rack Panel (10") | ![Rack Panel 10"](parts/renders/rackpanel_default_1u_10inch.png) |
| Rack Panel (19") | ![Rack Panel 19"](parts/renders/rackpanel_default_1u_19inch.png) |

To generate or refresh previews:

```sh
scadm export-png models/panel/parts/panel.scad
scadm export-png models/panel/parts/rackpanel.scad
```

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
