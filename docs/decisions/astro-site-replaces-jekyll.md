# 📋 Astro Site Replaces the Jekyll README Page

## 📌 Status

**Accepted** — 2026-09-02

## 🤔 Context

homeracker.org was the root `README.md` rendered by the classic GitHub Pages Jekyll build with the `architect` theme. That gave one long page, GitHub-flavoured, with no navigation, no model catalog, and no way to host the configurator alongside it without workarounds. The goal is one site in a cyberpunk visual identity that still comes entirely from the repository's markdown.

### Alternatives Considered

| Approach | Verdict | Reason |
|---|---|---|
| Keep Jekyll, add a custom theme | ❌ Rejected | Limited theming, slow to iterate, no image pipeline, awkward for a second app |
| Hand-built pages inside the Vite configurator app | ❌ Rejected | Navigation, markdown, and image plumbing would all be hand-rolled |
| Copy docs into a separate content folder | ❌ Rejected | Two sources of truth; READMEs are what contributors edit |
| Astro reading the existing markdown in place | ✅ Accepted | Content collections can point at `../models` and `..`; relative images are optimized; no UI framework needed |

## 🔧 Decision

- `site/` is an Astro static site. Collections load `README.md`, `models/README.md`, and `models/*/README.md` from their real locations; nothing is copied.
- Two rehype transforms keep the READMEs readable on the site: relative links are rewritten to site routes or GitHub, and heading blocks are wrapped in sections so the theme can lay them out. The GitHub table of contents is dropped.
- The home page hero animates the README's exploded assembly drawing in 3D: the three core parts are exported from their OpenSCAD sources at build time (`site/scripts/export-parts.mjs`, generated files are not committed) and assembled into a 3D3W cube; without OpenSCAD the hero falls back to the configurator engine drawing the default rack live; the model catalog is parsed from `models/README.md`; the `/configurator/` page mounts the configurator app (`configurator/src/app.ts`) inside the site layout so it shares navigation and tokens.
- Visual identity: HomeRacker yellow `#f7b600` as the single accent on near-black; Orbitron Black for headings and Source Code Pro for everything else, as set by the project style guide ([docs/styleguide.md](../styleguide.md)); the 15 mm base unit as a visible lattice (pin-hole background, support-beam dividers).
- `pages.yml` builds the site (which bundles the configurator page) and deploys it with `actions/deploy-pages`. `_config.yml` and the root `CNAME` are gone; the domain lives in `site/public/CNAME`.
- The `Web` workflow (`web.yml`) type-checks, tests, and builds both apps on pull requests; a `site-check` pre-commit hook runs when the site or any rendered README changes.

## 📊 Consequences

- **Positive**: one site with navigation, catalog, configurator and docs; READMEs remain the only place content is written
- **Positive**: the build fails when a README links to a missing render, catching broken docs early
- **Negative**: README authors get feedback from the site build, not only from GitHub's renderer; the `site-check` hook needs Node
- **Negative**: the `architect` theme look is gone; GitHub still renders the README as before
- **Follow-up**: the Pages source setting must be switched to GitHub Actions once by an admin

## 📚 References

- [site/README.md](../../site/README.md)
- [web-configurator-on-github-pages](web-configurator-on-github-pages.md)
- [image-hosting-assets-repo](image-hosting-assets-repo.md) — external images stay in `kellerlabs/assets`
