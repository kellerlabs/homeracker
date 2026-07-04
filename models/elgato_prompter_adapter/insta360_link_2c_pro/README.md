# 📷 Elgato Prompter Adapter for Insta360 Link 2C Pro

## 📌 What

An adapter to perfectly fit the Insta360 Link 2C Pro webcam into the Elgato Prompter.

## 🤔 Why

The Insta360 Link 2C Pro doesn't fit the standard brackets out of the box. This custom adapter ensures a perfect, flush fit while keeping the camera secure and aligned for teleprompting.

## 🔧 How

Open `adapter.scad` in OpenSCAD and use the **Customizer** panel to adjust parameters if your printer needs different tolerances.

| Parameter | Default | Description |
|-----------|---------|-------------|
| `clearance` | `0.2` | Tolerance to account for print inaccuracy. Increase if the camera is too tight, decrease if it's too loose. |
| `print_demo` | `false` | Set to true to print only a small demo piece to test the fit before printing the whole plate. |

### Usage

```scad
include <lib/adapter.scad>

// Default adapter
elgato_prompter_insta360_link_2c_pro_adapter(clearance=0.2, print_demo=false);
```

## 📸 Catalog

| Part | Preview |
|------|---------|
| Adapter | <img src="https://raw.githubusercontent.com/kellerlabs/assets/main/homeracker/models/elgato_prompter_adapter/insta360_link_2c_pro/adapter_iso.jpg" alt="Adapter ISO View" width="200"> |

## 📝 License

- **Source Code**: MIT License
- **3D Models**: CC BY-SA 4.0

## 📚 References

- [HomeRacker Repository](https://github.com/kellerlabs/homeracker)
