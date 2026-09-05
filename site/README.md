# 🌐 Site

## 📌 What

The homeracker.org website: an Astro static site that renders the repository's own markdown (the root `README.md`, `models/README.md`, and every `models/*/README.md`) into a themed site, with the [configurator](../configurator/README.md) mounted at `/configurator/`.

## 🤔 Why

The README stays the single source of truth. The site adds navigation, a model catalog with the tracked render PNGs, a live preview of the system on the home page, and a visual identity built from HomeRacker's own constants: the 15 mm unit as a lattice, the brand yellow as the one accent.

## 🔧 How

```sh
cd site
npm ci
npm run dev      # local dev server with live reload
npm run check    # astro check + vitest
npm run build    # static site in dist/
```

`npm run build` first runs `scripts/export-parts.mjs`, which needs OpenSCAD (`scadm install` puts it in `bin/openscad/`, or set `OPENSCAD`). Without it the script warns, the build continues, and the hero shows the schematic rack instead. CI sets `PARTS_REQUIRED=1` so a missing OpenSCAD fails the build there.

Astro caches rendered markdown in `.astro/`. After changing the rehype transforms in `src/lib/`, run `npx astro build --force` so cached README renders are regenerated.

### Structure

| Path | Purpose |
|---|---|
| `src/content.config.ts` | Content collections: `docs` (root + models index) and `models` (one entry per `models/*/README.md`) |
| `src/lib/links.ts` | Rewrites relative markdown links to site routes, or to GitHub when the site has no page for the target |
| `src/lib/sections.ts` | Wraps each heading block in a `<section>` so the theme can lay out README sections; drops the GitHub table of contents |
| `src/lib/catalog.ts` | Builds catalog cards from `models/README.md` |
| `src/lib/hero.ts` | Home page hero: the exploded 3D3W cube (8 connectors, 12 supports, 24 lock pins) built from real part meshes, assembling and coming apart in a loop; still exploded view under reduced motion |
| `src/lib/rack.ts` | Fallback hero when no part meshes are present: the default configurator rack as schematic boxes |
| `scripts/export-parts.mjs` | Exports the part library with OpenSCAD into `public/parts/` (gitignored): every connector type and pull-through variant, supports from 1 to 50 units, the lock pin, the foot, and the panel kit (support mount plates for 3 to 50 units and corner brackets, both panel types) from `scripts/scad/panel_kit.scad`. Used by the hero and by the configurator preview |
| `src/pages/` | `index.astro` (README), `models/index.astro` (catalog), `models/[slug].astro` (model pages), `configurator.astro` (mounts the configurator app) |
| `src/styles/global.css` | Design tokens, the type system from [docs/styleguide.md](../docs/styleguide.md) (Orbitron Black for headings, Source Code Pro for everything else) and markdown styling |

### Writing docs that render well

- Relative links between READMEs (`../core/README.md`, `models/panel/README.md`) become site links automatically. Links to anything else in the repo go to GitHub.
- Relative images under `parts/renders/` are optimized by Astro at build time. Images from `kellerlabs/assets` are loaded as-is.
- Model pages take their table of contents from the `##` headings.

### Deploy

`.github/workflows/pages.yml` installs both packages, builds this site (which bundles the configurator page), and deploys `site/dist` with `actions/deploy-pages`. The repository's Pages source must be set to **GitHub Actions**; the custom domain comes from `public/CNAME`.

## 📚 References

- [astro-site-replaces-jekyll](../docs/decisions/astro-site-replaces-jekyll.md) — decision record
- [web-configurator-on-github-pages](../docs/decisions/web-configurator-on-github-pages.md)
- [Astro content collections](https://docs.astro.build/en/guides/content-collections/)
