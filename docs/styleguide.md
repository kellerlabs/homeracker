# 🎨 Style Guide

## 📌 What

The visual rules for everything HomeRacker publishes: the website, the configurator, MakerWorld descriptions and renders. Colours come from the models themselves; type and layout follow from the product.

## 🎨 Colours

The palette is defined once, in [`models/core/lib/constants.scad`](../models/core/lib/constants.scad), and every part render uses it. The site and the configurator read the same values.

| Token | Hex | Use |
|---|---|---|
| `HR_YELLOW` | `#f7b600` | Supports, the brand accent, primary buttons, highlights |
| `HR_BLUE` | `#0056b3` | Connector cores |
| `HR_RED` | `#c41e3a` | Feet, warnings |
| `HR_GREEN` | `#2d7a2e` | Connector arm interiors in renders |
| `HR_CHARCOAL` | `#333333` | Lock pins, print interfaces |
| `HR_WHITE` | `#f0f0f0` | Pull-through connectors |

Web surfaces add a neutral dark scale around the palette:

| Token | Hex | Use |
|---|---|---|
| `--bg` | `#0b0c10` | Page background |
| `--panel` | `#15171c` | Cards, side panes |
| `--panel-2` | `#1c1f26` | Raised elements, inputs on cards |
| `--line` | `#2a2e38` | Borders, rules |
| `--text` | `#e8e6df` | Body text |
| `--muted` | `#a3a49f` | Secondary text, labels |
| `--link` | `#4d95ff` | Links (HR_BLUE lifted for contrast on dark) |
| `--danger` | `#ff4d6a` | Validation errors; parts that do not fit the print bed, in lists and in 3D (HR_RED lifted for contrast on dark) |
| panel plate | `#d9d6cc` | Panels in 3D previews: a matte bone white, distinct from yellow supports and white pull-through cores |

Rules: yellow is the only loud colour on a page. Blue is for links and connector cores, red only for errors and feet. Body text stays at 4.5:1 contrast or better against its background.

## 🔤 Type

| Role | Face | Weight | Notes |
|---|---|---|---|
| Headings, display | **Orbitron** | Black (900) | Uppercase, tight leading. Keep it for titles, section headings and big numbers |
| Everything else | **Source Code Pro** | 400 body, 500/600 labels and buttons | Body text, navigation, labels, tables, code |

Both are open fonts (SIL OFL) and are self-hosted through `@fontsource` packages; no external font requests.

## 📐 Structure

- The 15 mm base unit is a visible motif: pin-hole background lattice, support-beam dividers with a connector core at each end.
- Corners are square. Chamfered buttons (one clipped corner pair) echo the printed parts.
- Diagrams and previews use the part colours above so a support is yellow everywhere it appears.

## 📚 References

- [`models/core/lib/constants.scad`](../models/core/lib/constants.scad) — colour source of truth
- [`site/src/styles/global.css`](../site/src/styles/global.css) — web tokens and type scale
- [`configurator/src/configurator.css`](../configurator/src/configurator.css) — the configurator reads the same tokens
- [homeracker.org](https://homeracker.org) — the site, [MakerWorld](https://makerworld.com/@kellerlab) — model listings
