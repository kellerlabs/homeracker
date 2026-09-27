# 📋 E2E-test the site and configurator with Playwright on every web PR

## 📌 Status

**Accepted**: 2026-09-27

## 🤔 Context

- npm updates to `site/` and `configurator/` are not automerged beyond a patch allow-list, because no check renders a page: a runtime break passes eslint, tsc, Vitest and the build.
- Checking each Renovate preview by hand is slow and misses things.
- Typical runtime breaks: an uncaught error on load, a chunk or asset that 404s (worse under the `/preview/pr-<n>/` subpath), a broken `STLLoader` or parts manifest, a blank WebGL canvas, broken clipboard or share links.
- An E2E suite only helps while it keeps up with the UI. A feature that ships without a journey is a blind spot nobody notices.

## 🔧 Decision

**Framework: Playwright (`@playwright/test`) in `site/e2e/`.**

- Open source, actively maintained, built-in runner with retries, traces and request stubbing. The npm version pins the browser, so Renovate bumps both together.
- One package: the site mounts the configurator, so testing the site build covers both apps.
- Alternatives rejected:
  - Cypress: no real WebKit, heavier, parallel runs need the paid Cloud.
  - WebdriverIO: its strength is real mobile devices, which this project does not need.
  - Vitest browser mode: suits component tests, not journeys through the built site.
  - Visual snapshot services (Argos, Percy, Chromatic): CI renders WebGL in software, and three.js bumps change pixels legitimately, so baselines would churn.

**Environment: the built site on the CI runner, not the Pages preview.**

- The `site` job in [`web.yml`](../../.github/workflows/web.yml) builds `dist/` with the real part meshes, serves it with `astro preview` on localhost, and runs headless Chromium against it. A second build with `SITE_BASE=/preview/pr-0/` runs the suite again under a subpath.
- This gates the PR before merge, including Renovate PRs, is the same for every run of a commit, works for forks, and does not depend on the shared `pages` concurrency group.
- Alternative deferred: a smoke test against the deployed preview. It would add coverage of Pages itself (redirects, the real domain) at the cost of a slow, coupled job. Revisit if Pages serving ever breaks.

**What is tested.**

- 🩺 A fixture fails every test on an uncaught page error, a console error, or a same-origin request that fails or returns 4xx/5xx.
- 🗺️ Every page in `dist/` gets a smoke test (status, title, one `h1`, every internal link resolves). The list comes from the build, so a new page is covered automatically. Also runs at a mobile viewport.
- 🧊 The canvases carry `data-render="parts"` or `"schematic"`, and a screenshot must contain HomeRacker yellow, proving WebGL drew the rack.
- 🧭 Configurator journeys: default rack, a shared link with an exact parts list, footprint and row editing, panels (click, keyboard, shortcuts), copy link and Markdown, session restore, and error paths (unparsable input, out-of-range values, malformed links, printbed overflow, missing part meshes).

**Reporting failures.**

- 💬 A failing run posts one PR comment, edited in place: each failing test with its error, a link to the report artifact (screenshots, traces) and the run. It flips to ✅ when the suite passes and is never created for a PR that never failed. A separate job holds `pull-requests: write`; the build and tests keep read-only access. Fork PRs get the job summary only.
- 🧪 The `e2e-probe-failure` label makes one probe test fail on purpose, so the report pipeline can be checked on any PR. Label changes rerun only the `site` job.
- 🖼️ Screenshots stay in the workflow artifact (7-day retention). Inline images would need committing them to a repository, which grows its history for good.

**Keeping the suite current: deterministic gates first, guidance second.**

- 🔒 Control inventory ([`inventory.spec.ts`](../../site/e2e/inventory.spec.ts)): every configurator control rendered in any test must be used by at least one test, or CI fails. Exemptions are listed in the spec with a reason.
- 🔒 Page inventory: automatic, because the smoke test enumerates `dist/`.
- 📜 The path-scoped rule [`.claude/rules/e2e.md`](../../.claude/rules/e2e.md) loads for agents editing `site/` or `configurator/`, and the PR template asks for the E2E change.
- Alternatives rejected:
  - An agent skill alone: nothing enforces it for humans or agents that skip it.
  - Failing a PR that changes `src/` without touching `e2e/`: refactors trip it constantly and an override label becomes a reflex.
- Deferred: a coverage gate on the lines each PR changes (V8 coverage from Chromium), once the suite has been stable for a few weeks.

## 📊 Consequences

- ✅ Dependency PRs get a runtime check, so Renovate automerge can widen from patches to minors once the suite has stayed green for a few weeks.
- ✅ A new page or control fails CI until a test covers it.
- ❌ The inventory gate proves a control was used, not that its effect was asserted. Review still has to check the assertion.
- ❌ The `site` job grows by a few minutes (browser install, second build, two runs).
- ❌ Pages-specific serving behaviour is not covered.
