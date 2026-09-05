# 📋 Web Configurator on GitHub Pages

## 📌 Status

**Accepted** — 2026-09-02

## 🤔 Context

The README asks builders to "make a parts list" by hand: supports per length, connectors per type, lock pins. Nothing in the repo does that math, and the only site is the README rendered by the classic Jekyll Pages build at `homeracker.org`.

A configurator needs a place to live, a toolchain, a way to publish, and a preview strategy.

### Alternatives Considered

| Approach | Verdict | Reason |
|---|---|---|
| Separate `homeracker-configurator` repo | ❌ Rejected | Geometry rules drift from the `.scad` sources; second release train |
| Plain ES modules without a build step | ❌ Rejected | No type checking, no unit tests for the parts-list math |
| UI framework (React/Svelte) | ❌ Rejected | Form + table + canvas does not justify the dependency weight |
| Real part meshes rendered in CI | ⏳ Deferred | Heavy asset pipeline before anything is usable; schematic boxes are enough to sanity-check a layout |
| Commit built `dist/` to keep branch-based Pages | ❌ Rejected | Generated code in git, noisy PRs |

## 🔧 Decision

- **Location**: `configurator/` in this repo, published at `https://homeracker.org/configurator/`.
- **Stack**: Vite + TypeScript + Three.js, Vitest for tests, no UI framework.
- **Engine/render split**: `src/engine/` is pure (no DOM, no Three.js) and holds every geometry rule and the bill of materials; enforced by a separate `tsconfig.engine.json` and an eslint import restriction. `src/render/` and `src/ui/` are thin.
- **Preview**: real part meshes exported from the OpenSCAD sources at site build time (connectors per type and pull-through axis, supports per length, lock pins, feet), placed with a rotation solver that mirrors `CONNECTOR_CONFIGS`; schematic unit boxes remain as the fallback when the mesh library is not served. Panels stay schematic. (Updated 2026-09-02; the first version drew boxes only.)
- **Sharing**: the config is encoded in the URL hash (`#v=4&d=6&r=5:6_4:6&f=1`); no backend.
- **Deploy**: `pages.yml` builds the site and the Vite app and deploys both with `actions/deploy-pages`; the app lands under `/configurator/`. Pages source must be set to **GitHub Actions** once. (Superseded detail: the first version kept the Jekyll README build; see [astro-site-replaces-jekyll](astro-site-replaces-jekyll.md).)
- **CI**: the `Web` workflow (`web.yml`) lints, tests and builds on PRs touching `configurator/**`; a local pre-commit hook runs the same `npm run check`.

### Geometry rules encoded

- Nodes on an integer lattice; a support between nodes `a < b` has length `b - a - 1`, so `3 + connector + 3 = 7 units`.
- A rack is a stack of rows, each with its own height, column widths and horizontal shift; frames between rows carry the column boundaries of both neighbouring rows, so dividers that stop end in T connectors (added 2026-09-02 after the level editor proved unintuitive).
- Connector type = (axes used, arm count), matching `CONNECTOR_CONFIGS`. A row whose posts continue from the row below turns that junction into z pull-through connectors and one long support (per junction since 2026-09-02; before that one switch for the whole rack).
- One lock pin per occupied arm; feet occupy the `-z` arm of every floor node.
- A panel fills the opening bounded by its supports (`units_x = support length`), derived from `panel.scad`'s inter-fit deduction. Panels are configured per opening (front/back bays per row, sides per row, spans of every frame including shelves), in to-scale face drawings (front, back, sides, and a plan per frame) or by clicking the opening in the 3D view, with hover synced both ways; each drawing has all-open/inter-fit/full-cover shortcuts. Panel geometry in the preview is assembled from exported mount plates and corner brackets around a plate, mirroring `panel()`, because exporting every panel size would take an hour per build. Panel pins are an estimate and listed separately. (Per-opening panels added 2026-09-02; before that one panel type applied to a whole face.)

## 📊 Consequences

- **Positive**: parts list is computed, testable and shareable by link; geometry rules live next to the models they mirror
- **Positive**: README site is unchanged; the configurator is an additive path
- **Negative**: first JS toolchain in the repo (Node in CI and pre-commit, Renovate npm updates)
- **Negative**: Pages source setting must be flipped by an admin; until then the deploy job fails
- **Next**: per-part STL export in the browser via openscad-wasm from `models/*/flattened/*.scad`

## 📚 References

- [configurator/README.md](../../configurator/README.md)
- [models/core/lib/connector.scad](../../models/core/lib/connector.scad) — `CONNECTOR_CONFIGS`
- [models/panel/lib/panel.scad](../../models/panel/lib/panel.scad) — inter-fit deduction
- [image-hosting-assets-repo](image-hosting-assets-repo.md) — why the app ships no image files
