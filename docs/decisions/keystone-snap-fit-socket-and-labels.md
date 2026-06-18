# 📋 Build the keystone module as a measured snap-fit cutter with an original label system

## 📌 Status

**Accepted** — 2026-06-18

## 🤔 Context

HomeRacker panels needed a reusable way to host standard keystone jacks (Ethernet, HDMI,
USB, coax, fiber) without re-deriving snap-fit geometry in every panel model.

- The universal keystone profile is a known quantity, but there was no on-system parametric
  source — only third-party STLs.
- Real panels populate many identical jacks, so render/export cost matters.
- Users print on different printers/filaments, which shrink differently.
- Ports need durable, changeable identification.

## 🔧 Decision

Ship a parametric **cutter** module (`keystone_full()`) that panels subtract in a
`diff("keystone")` context, plus a standalone `label_plate()`.

- **Dimension provenance:** measure the socket profile from Paul Hatcher's CC0
  [Parametric Keystone Connector](https://www.printables.com/model/537480-parametric-keystone-connector).
  That STL printed and fit a wide range of real jacks (e.g. deleyCON CAT.7); the distances
  were measured in the slicer and translated into SCAD. Label dimensions instead derive from
  HomeRacker core constants (`KS_LABEL_HEIGHT = BASE_UNIT`, etc.) to stay on-system.
- **Original label system:** snap-fit retention with a minimal lip overlap (holds against
  vibration without fighting removal), generous top/bottom chamfers for fingernail removal,
  and a double-slit slot so the part bridges support-free and labels print face-down for clean
  multicolor prints. `label_plate_mode = "plate"` lays the plate out print-ready for the
  Parametric Model Maker / MakerWorld build plates.
- **Fit knob:** `additional_tolerance` adds clearance to socket width & height only, default
  `0.0` (perfect on the reference printer). A single-jack sample (`keystone_sample.scad`) lets
  users fit-test cheaply before printing a full panel.
- **Dual geometry backend:** keep both a `native` (BOSL2-free, cache-friendly, fast) and a
  `bosl2` (authored source of truth, per-section debug colors) path behind a `$ks_native`
  toggle. `native` is the default; the native code was AI-transpiled from the BOSL2 source and
  print-tested with no noticeable difference.

**Alternatives considered:**

- *Hard-code keystone geometry per panel* — rejected: duplicates snap-fit math and drifts.
- *Bake labels into the panel* — rejected: labels can't be changed after printing.
- *Ship dust covers / blank fillers / angled / shuttered variants* — rejected as out of scope;
  these exist en masse online. The module covers the standard snap profile only.
- *BOSL2-only geometry* — rejected for production rendering: `attachable`/`diff` defeats
  OpenSCAD's geometry cache and re-evaluates per copy, dominating render time on full panels.
- *Native-only geometry* — rejected: loses the readable authored source and fine debug colors.

## 📊 Consequences

**Positive:**

- Any panel becomes a patch panel by subtracting one module.
- Real jacks fit out of the box; the sample de-risks full-panel prints.
- Labels are durable, changeable, and print cleanly without supports.
- Fast default rendering on populated panels, with a readable fallback for editing/debugging.

**Negative:**

- Two geometry paths must stay in sync; the native path is AI-transpiled, so the `bosl2`
  backend remains the source of truth for correctness.
- `additional_tolerance` values much above `0.2` are untested.
- Only standard keystones are supported; specialty jacks are out of scope.
