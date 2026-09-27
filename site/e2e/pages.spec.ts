import { expect, hasParts, routes, test, yellowShare } from "./fixtures";

// Every page the build produces, so a new page is smoke-tested without touching this file.
for (const route of routes()) {
  test(`page /${route} loads and its links resolve`, async ({ page, baseURL }) => {
    const response = await page.goto(route);
    expect(response?.status()).toBe(200);
    await expect(page).toHaveTitle(/HomeRacker/);
    await expect(page.locator("h1")).toHaveCount(1);

    const origin = new URL(baseURL!).origin;
    const hrefs = await page.locator("a[href]").evaluateAll((links) => links.map((a) => (a as HTMLAnchorElement).href));
    const internal = [...new Set(hrefs.map((h) => h.split("#")[0]!).filter((h) => h.startsWith(origin)))];
    for (const href of internal) {
      const link = await page.request.get(href);
      expect(link.status(), `link ${href} on /${route}`).toBe(200);
    }
  });
}

test("hero draws the rack", async ({ page }) => {
  await page.goto("");
  const hero = page.locator("#hero-rack");
  await expect(hero).toHaveAttribute("data-render", hasParts() ? "parts" : "schematic");
  expect(await yellowShare(page, hero)).toBeGreaterThan(0.005);
});
