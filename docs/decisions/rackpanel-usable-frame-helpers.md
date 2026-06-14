# 📋 Expose rack-panel usable-frame helpers and child passthrough

## 📌 Status

**Accepted** — 2026-06-19

## 🤔 Context

Specialized panels (keystone strips/grids, switch/display cutouts) need to add or
subtract geometry on a `rackpanel` face, including its **split** halves. Two problems
blocked building on top of `rackpanel`:

- It did not accept external children — the dispatch called the internal view modules
  (`_naked_panel`, `_panel_left`, `_panel_right`) directly and never propagated
  `children()`. The Full view's `children()` also sat *inside* `tag_scope("rackpanel")`,
  so any `tag("keystone")` cutter would have its remove-tag scoped away and never cut.
- Consumers had no way to know the **cutout-safe band**: the panel face minus the
  rackmount mount-surface columns (and the slide-in clearance), which differs between a
  full panel and a split half (a half has a mount column only on its outer edge).

## 🔧 Decision

Keep the split-distribution logic **out** of the library; expose just enough for a
consumer to drive it:

- **Child passthrough** on the three child-accepting views (Full, Left-half, Right-half)
  via one outer `attachable` that emits `children()` *outside* the internal `tag_scope`,
  so `diff("keystone")` cutters survive. The single active branch is merged with `union()`
  into one shape node; the outer wrapper also applies `anchor/spin/orient` uniformly
  (previously honored only on the Full view). Assembled/exploded views stay preview-only
  and take no children.
- **`get_rackpanel_usable_width(panel_width, split_mode, view_mode)`** — usable band width.
  Full: `panel_width − 2·STD_MOUNT_SURFACE_WIDTH − TOLERANCE`. Split half:
  `panel_width/2 − HR_SPLIT_KNUCKLE_STRENGTH_SLIM/2 − STD_MOUNT_SURFACE_WIDTH − TOLERANCE/2`
  (one outer column; the band stops at the central split-connector knuckle, which stays
  uncovered, so `2·half + knuckle = full`).
- **`get_rackpanel_usable_x(panel_width, split_mode, view_mode)`** — X offset of the band
  centre from the (half-)panel centre. Full: `0`. Left half:
  `+(STD_MOUNT_SURFACE_WIDTH/2 + TOLERANCE/4 − HR_SPLIT_KNUCKLE_STRENGTH_SLIM/4)`, right half
  the negative — each half pins its band's **seam edge on the knuckle boundary** so cutouts
  stay aligned across the joint (a consumer overlaps by `HR_EPSILON` to stay manifold).

Alternatives considered:

- **Library splits content itself** (pass a list of cutouts, it distributes L/R) — rejected:
  couples the panel to consumer semantics (keystone counts, rotations, labels) and bloats
  the parameter surface. The consumer calls `rackpanel` once per half instead.
- **Return a usable bounding box / anchors instead of width+x** — rejected as overkill;
  width + centre offset is the minimum a consumer needs and keeps the helpers pure.
- **Half-unit panels** (a half-height split) were considered for fit-to-frame layouts and
  **deferred**: the split-connector geometry is not designed to be halved that way and
  would need rework not justified for an edge case.

## 📊 Consequences

- ➕ Downstream models (e.g. exclusive keystone rack panels) can `diff()` against full or
  split rackpanels and place cutouts with seam-consistent alignment using two pure helpers.
- ➕ Both helpers `echo()` a warning when called with `split_mode=Half` and a non-half view
  (Assembly/Exploded) — an undefined combination — and fall back to the full-panel band / 0
  rather than failing silently.
- ➕ `anchor/spin/orient` now apply on every child-accepting view, not just Full.
- ➕ Split distribution stays a consumer concern — the library surface stays small.
- ➕ Usage is documented by committed one-scene-per-file demos in `models/panel/demo/`
  (rendered to `demo/renders/*.png` for the README): the usable band is shown as a magenta
  marker on the panel **back** face (so any overlap with a mount column is obvious), and the
  keystone demos cut a real `keystone_full` jack into a strong (4&nbsp;mm) braced panel.
  Functional asserts stay in `models/panel/test/` (CI); the demos are visual reference.
- ➖ Consumers must call `rackpanel` twice for a split assembly and route the correct
  cutouts to each half (the library will not do it for them).
- ➖ `keystone_full()` self-tags its pocket as `"keystone"`, so it must be called **bare**
  inside `diff("keystone")` (an outer `tag("keystone")` would turn the whole jack into a
  hole). Plain cuboid cutters still need the explicit tag — a subtle asymmetry to remember.
- ➖ The helpers assume the standard mount-surface column on outer edges; a future
  custom-mount panel would need its own band math. Unlikely as we're talking standard rackmount panels.
