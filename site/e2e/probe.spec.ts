import { expect, test } from "./fixtures";

// Fails on purpose while the PR carries the `e2e-probe-failure` label, to exercise the failure
// report (PR comment, screenshot, trace) end to end. Remove the label to go green again.
test("probe: fails while the e2e-probe-failure label is set", async ({ page }) => {
  test.skip(process.env.E2E_PROBE_FAILURE !== "true", "label e2e-probe-failure not set");
  await page.goto("configurator/");
  await expect(page.getByRole("heading", { name: "e2e-probe-failure" })).toBeVisible({ timeout: 2_000 });
});
