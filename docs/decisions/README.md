# 📋 Decision Records

Lightweight records capturing the **why** behind architecture, tooling, and workflow decisions.

## Active Decisions

| Decision | Date | Summary |
|---|---|---|
| [build-own-openscad-formatter-scadfmt](build-own-openscad-formatter-scadfmt.md) | 2026-09-27 | Own token-based formatter `scadfmt` in `cmd/scadfmt`: keeps line breaks, never changes tokens; linting later on `openscad-parser` |
| [gate-prs-with-a-single-check-results-job](gate-prs-with-a-single-check-results-job.md) | 2026-09-27 | One `ci.yml` PR pipeline; `check-results` (plus `validate-title`) are the required checks, so path-filtered jobs are required when they run |
| [e2e-test-site-and-configurator-with-playwright](e2e-test-site-and-configurator-with-playwright.md) | 2026-09-27 | Playwright E2E suite runs against the built site in `web.yml`; control and page inventories fail CI when a feature ships without a test |
| [gate-scadm-coverage-and-mutation-test-changed-functions](gate-scadm-coverage-and-mutation-test-changed-functions.md) | 2026-09-27 | `scadm` unit tests gate on 90% branch coverage; mutmut reports on the functions each PR changes, weekly full run to Discord |
| [return-bracket-to-open-source-catalog](return-bracket-to-open-source-catalog.md) | 2026-09-20 | Bracket comes back into this repo as an open-source part, flexmount retired in its favor |
| [x-hole-supports-by-default](x-hole-supports-by-default.md) | 2026-09-13 | Supports carry lock pin holes on both axes, so panels have a hole to pin to on every edge |
| [astro-site-replaces-jekyll](astro-site-replaces-jekyll.md) | 2026-09-02 | homeracker.org is an Astro site rendering the repo READMEs in place; Jekyll removed |
| [web-configurator-on-github-pages](web-configurator-on-github-pages.md) | 2026-09-02 | Rack configurator + parts list as a Vite app at `/configurator/`, deployed via Pages Actions |
| [rackpanel-usable-frame-helpers](rackpanel-usable-frame-helpers.md) | 2026-06-19 | Expose usable-frame helpers + child passthrough on `rackpanel` |
| [stiffen-rack-panels-with-truss-grid](stiffen-rack-panels-with-truss-grid.md) | 2026-06-19 | Optional back-side truss stiffener via generic `truss_grid` |
| [unify-export-png-into-scadm](unify-export-png-into-scadm.md) | 2026-06-18 | Replace duplicate shell scripts with `scadm export-png` |
| [keystone-snap-fit-socket-and-labels](keystone-snap-fit-socket-and-labels.md) | 2026-06-18 | Measured keystone cutter + original label system + native/bosl2 backend toggle |
| [image-hosting-assets-repo](image-hosting-assets-repo.md) | 2026-04-13 | Host manually-created images in `kellerlabs/assets` repo |
