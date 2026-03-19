# 🧲 Wall Mount

## 📌 What

A wall-mountable bracket that attaches HomeRacker supports to a wall using screws.
Accepts a support beam via the standard connector interface and secures it with lock pins.

## 🤔 Why

Not every setup sits on a desk — this lets you mount HomeRacker racks directly to walls or vertical surfaces (or even the ceiling).

## 🔧 How

Open `parts/wallmount.scad` in OpenSCAD Customizer:

- **Base**: `bore_type` (flathead or countersunk), `bore_shaft_diameter`, `bore_head_diameter`
- **Finetuning**: `countersunk_angle`, `bore_tolerance`

Mount with appropriate wall anchors. The connector slot accepts a standard HomeRacker support beam.

## 📸 Catalog

| Part | Preview |
|------|---------|
| Wall Mount | ![Wall Mount](parts/wallmount.png) |

To generate or refresh previews:

```bash
./cmd/export/export-png.sh models/wallmount/parts/wallmount.scad
```

## 📚 References

- [HomeRacker Core](../core/README.md)
