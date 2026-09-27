---
paths: ["site/src/**", "site/e2e/**", "configurator/src/**", "configurator/index.html"]
---

# 🧪 E2E Test Guidelines

The Playwright suite in `site/e2e/` is the only check that renders a page. See [e2e-test-site-and-configurator-with-playwright](../../docs/decisions/e2e-test-site-and-configurator-with-playwright.md).

## When to Change It

- A user-visible change needs a new or updated journey in `site/e2e/configurator.spec.ts` that **asserts the effect** (parts list, URL hash, visible message), not just the click.
- A new control fails `inventory.spec.ts` until a test uses it. Only exempt a control in `EXEMPT` with a reason a reviewer can accept.
- A new error path (invalid input, missing asset, bad link) gets a test under `error paths`.
- A new page is smoke-tested automatically. Add a journey only if it has behaviour beyond static content.

## Writing Tests

- Import `test` and `expect` from `./fixtures`, never from `@playwright/test`, so the health checks and the inventory recorder run.
- Locate by role and label (`getByRole`, `getByLabel`). Use a CSS selector only where no accessible name exists.
- Web-first assertions only (`await expect(...)`). No `waitForTimeout`.
- Navigate with relative paths (`configurator/`, not `/configurator/`), so the preview subpath run works.
- A test that expects a same-origin request to fail sets `test.use({ allowedFailures: [...] })`.

## Running

```bash
cd site
npm run build                         # needs OpenSCAD for real part meshes, see README.md
npm run e2e
SITE_BASE=/preview/pr-0/ npm run build:site && SITE_BASE=/preview/pr-0/ npm run e2e
```

Run the full suite before pushing. The inventory test only counts the tests that ran.
