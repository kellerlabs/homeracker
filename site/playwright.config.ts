import { defineConfig, devices } from "@playwright/test";

// Serves the built site (dist/) under the same base path it was built with, so a preview build
// (SITE_BASE=/preview/pr-0/) is tested at its subpath.
const port = 4321;
const base = process.env.SITE_BASE ?? "/";
const url = `http://localhost:${port}${base}`;
/** Names this run's report files, so the root and subpath runs in CI keep both. */
const run = base === "/" ? "root" : "preview-subpath";

export default defineConfig({
  testDir: "e2e",
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 1 : 0,
  reporter: process.env.CI
    ? [
        ["github"],
        ["html", { open: "never", outputFolder: `playwright-report/${run}` }],
        // Read by scripts/e2e-report.mjs for the job summary and the PR comment.
        ["json", { outputFile: `e2e-results/${run}.json` }],
      ]
    : [["list"]],
  globalSetup: "./e2e/global-setup.ts",
  // Software WebGL on CI runners loads and draws the full part library slower than a desktop.
  expect: { timeout: 10_000 },
  use: {
    baseURL: url,
    trace: "on-first-retry",
    screenshot: "only-on-failure",
    reducedMotion: "reduce",
  },
  webServer: {
    // --ignore-lock keeps the server in the foreground, which Astro otherwise skips when run by an agent.
    command: `npx astro preview --port ${port} --ignore-lock`,
    url,
    reuseExistingServer: !process.env.CI,
  },
  projects: [
    { name: "desktop", use: { ...devices["Desktop Chrome"] }, testIgnore: "inventory.spec.ts" },
    { name: "mobile", use: { ...devices["Pixel 7"] }, testMatch: "pages.spec.ts" },
    // Runs after the suites it audits, on what their fixtures recorded.
    { name: "inventory", testMatch: "inventory.spec.ts", dependencies: ["desktop"] },
  ],
});
