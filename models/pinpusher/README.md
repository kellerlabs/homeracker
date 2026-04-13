# 🔧 Lockpin Pusher

## 📌 What

A simple tool to push lockpins out of HomeRacker connectors.
The shaft fits through lockpin holes; the grip provides a pinch surface for thumb and index finger.

## 🤔 Why

Lock pins are designed for a tight tension fit — once inserted they're hard to remove by hand.
This tool gives you leverage without damaging the connector, the lockpin or your fingers.

## 🔧 How

Open `parts/pinpusher.scad` in OpenSCAD and export as STL. Print flat — optimized for layer line strength.

## 📸 Catalog

| Part | Preview |
|------|---------|
| Pinpusher | ![Pinpusher](parts/renders/pinpusher.png) |

To generate or refresh previews:

```bash
./cmd/export/export-png.sh models/pinpusher/parts/pinpusher.scad
```

## 📚 References

- [HomeRacker Core](../core/README.md) — the lock pins this tool is designed for
