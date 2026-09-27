import { expect, hasParts, test, yellowShare } from "./fixtures";
import type { Page } from "@playwright/test";

/** Two rows, the top one's posts continuing, one inter-fit panel on the front of the bottom bay. */
const SHARED = "#v=4&d=4&r=3:4.4_3:9*&f=0&pn=f0.0i";

/** Parts list as "qty | label | note" lines, group headings included. */
function partsList(page: Page): Promise<string[]> {
  return page.locator(".cfg-bom tr").evaluateAll((rows) =>
    rows.map((row) => [...row.children].map((cell) => cell.textContent?.trim() ?? "").join(" | ")),
  );
}

async function open(page: Page, hash = ""): Promise<void> {
  await page.goto(`configurator/${hash}`);
  await expect(page.locator(".cfg-canvas")).toHaveAttribute("data-render", /.+/);
}

const total = (page: Page) => page.locator(".cfg-bom tr.total .qty");
const issues = (page: Page) => page.locator("#issues");
const row = (page: Page, n: number) => page.locator(`.cfg-row[data-index="${n - 1}"]`);

/** Row cards start collapsed; open one to reach its fields. */
async function expand(page: Page, n: number): Promise<void> {
  const toggle = row(page, n).getByRole("button", { name: "Expand row" });
  if (await toggle.isVisible()) await toggle.click();
}

test.describe("happy paths", () => {
  test("default rack renders with a parts list", async ({ page }) => {
    await open(page);
    const canvas = page.locator(".cfg-canvas");
    await expect(canvas).toHaveAttribute("data-render", hasParts() ? "parts" : "schematic");
    expect(await yellowShare(page, canvas)).toBeGreaterThan(0.005);
    await expect(total(page)).toHaveText("80");
    await expect(issues(page)).toBeEmpty();
    await expect(page).toHaveURL(/#v=4&d=6&r=5:6_4:6&f=1$/);
  });

  test("a shared link opens the same rack and parts list", async ({ page }) => {
    await open(page, SHARED);
    await expect(page.getByLabel("Depth (units)")).toHaveValue("4");
    await expect(page.getByLabel("Feet")).not.toBeChecked();
    expect(await partsList(page)).toEqual([
      "Supports",
      "2 | Support 9 units (135 mm) | ",
      "4 | Support 7 units (105 mm) | ",
      "16 | Support 4 units (60 mm) | ",
      "2 | Support 3 units (45 mm) | ",
      "Connectors",
      "8 | Connector 3D3W | ",
      "4 | Connector 3D4W | ",
      "4 | Connector 3D4W pull-through Z | ",
      "Lock pins",
      "48 | Lock pin | ",
      "8 | Lock pin, extended neck | holds a panel corner bracket on the outermost hole",
      "6 | Lock pin for panels | one per mount plate hole; estimate",
      "Panels",
      "1 | Panel 4x3 units inter-fit | ",
      "103 | printed parts in total",
    ]);
  });

  test("footprint and structure edits update the parts list and the link", async ({ page }) => {
    await open(page);
    await page.getByLabel("Depth (units)").fill("10");
    await expect(page).toHaveURL(/d=10&/);
    await expect(page.locator(".cfg-bom")).toContainText("Support 10 units (150 mm)");

    await page.getByLabel("Feet").uncheck();
    await expect(page).toHaveURL(/f=0/);
    await expect(page.locator(".cfg-bom")).not.toContainText("Foot insert");
  });

  test("row editing: fields, add, duplicate, move, remove", async ({ page }) => {
    await open(page);
    await expand(page, 2);
    const top = row(page, 2);
    await top.getByLabel("Height").fill("6");
    await top.getByLabel("Shift").fill("1");
    await top.getByLabel("Column widths").fill("3, 2");
    await top.getByLabel("Name of row 2").fill("Shelf");
    await top.getByLabel("Posts continue from the row below").check();
    await expect(page).toHaveURL(/r=5:6_6:3\.2~1\*&f=1&n1=Shelf$/);

    await top.getByRole("button", { name: "Collapse row" }).click();
    await expect(top.getByLabel("Height")).toBeHidden();

    await page.getByRole("button", { name: "Add row on top" }).click();
    await expect(page.locator(".cfg-row")).toHaveCount(3);
    await row(page, 3).getByRole("button", { name: "Duplicate row" }).click();
    await expect(page.locator(".cfg-row")).toHaveCount(4);
    await row(page, 4).getByRole("button", { name: "Remove row" }).click();
    await row(page, 3).getByRole("button", { name: "Remove row" }).click();
    await expect(page.locator(".cfg-row")).toHaveCount(2);

    await row(page, 2).getByRole("button", { name: "Move row down" }).click();
    await expect(page).toHaveURL(/r=6:3\.2~1\*_5:6&/);
    await row(page, 1).getByRole("button", { name: "Move row up" }).click();
    await expect(page).toHaveURL(/r=5:6_6:3\.2~1\*&/);
  });

  test("panels: click a bay, use the shortcuts and the keyboard", async ({ page }) => {
    await open(page);
    await page.locator("summary", { hasText: "Front and back" }).click();
    const bay = page.getByRole("button", { name: /^front, row 1, bay 1: 6x5 units, open$/ });
    await bay.click();
    await expect(page.locator(".cfg-bom")).toContainText("Panel 6x5 units inter-fit");
    await expect(page).toHaveURL(/pn=f0\.0i/);

    await page.getByRole("button", { name: /^front, row 1, bay 1: .*inter-fit$/ }).press("Enter");
    await expect(page.locator(".cfg-bom")).toContainText("Panel 6x5 units full cover");

    await page.getByRole("button", { name: "Front: all full cover" }).click();
    await expect(page.locator(".cfg-bom")).toContainText("Panel 6x4 units full cover");
    await page.getByRole("button", { name: "Front: all inter-fit" }).click();
    await page.getByRole("button", { name: "Front: all open" }).click();
    await expect(page.locator(".cfg-bom")).not.toContainText("Panel");

    for (const group of ["Sides", "Tops and bottom", "Rows, top to bottom", "Panels"]) {
      await page.locator("summary", { hasText: group }).click();
    }
  });

  test("copy link and copy as Markdown", async ({ page, context }) => {
    await context.grantPermissions(["clipboard-read", "clipboard-write"]);
    await open(page, SHARED);
    const clipboard = () => page.evaluate(() => navigator.clipboard.readText());

    await page.getByRole("button", { name: "Copy link" }).click();
    await expect(page.getByRole("button", { name: "Copied" })).toBeVisible();
    expect(await clipboard()).toBe(page.url());

    await page.getByRole("button", { name: "Copy as Markdown" }).click();
    const markdown = await clipboard();
    expect(markdown).toContain("Panel 4x3 units inter-fit");
    expect(markdown).toContain(page.url());
  });

  test("the rack survives leaving and coming back in the same tab", async ({ page }) => {
    await open(page);
    await page.getByLabel("Depth (units)").fill("9");
    await expect(page).toHaveURL(/d=9&/);
    await open(page);
    await expect(page.getByLabel("Depth (units)")).toHaveValue("9");
  });

  test("column syntax help opens and closes", async ({ page }) => {
    await open(page);
    await expand(page, 1);
    const help = page.locator(".cfg-info-tip:visible");
    await row(page, 1).getByRole("button", { name: "Column syntax help" }).click();
    await expect(help).toContainText("auto-fill to match the row below");
    await page.locator("body").click({ position: { x: 5, y: 5 } });
    await expect(help).toHaveCount(0);
  });
});

test.describe("error paths", () => {
  test("unparsable column widths show an issue and keep the last good rack", async ({ page }) => {
    await open(page);
    await expand(page, 1);
    await row(page, 1).getByLabel("Column widths").fill("six");
    await expect(issues(page)).toContainText("column widths must be whole numbers");
    await expect(total(page)).toHaveText("80");
    await expect(page).toHaveURL(/r=5:6_4:6&/);
  });

  test("out-of-range values show a validation issue", async ({ page }) => {
    await open(page);
    await page.getByLabel("Depth (units)").fill("1");
    await expect(issues(page)).toContainText("depth must be a whole number between 2 and 50 units");
    await expect(page).toHaveURL(/d=6&/);
  });

  test("a link with an unresolvable auto-fill falls back to the default rack", async ({ page }) => {
    await open(page, "#v=4&d=6&r=5:?&f=1");
    await expect(total(page)).toHaveText("80");
    await expect(page).toHaveURL(/#v=4&d=6&r=5:6_4:6&f=1$/);
  });

  test("a part too large for the printbed is flagged", async ({ page }) => {
    await open(page);
    for (const axis of ["X", "Y", "Z"]) await page.getByLabel(`${axis} (mm)`).fill("60");
    await expect(page.getByRole("status").filter({ hasText: "do not fit your printbed" })).toBeVisible();
    await expect(page.locator(".cfg-bom .is-unprintable").first()).toBeVisible();
  });

  test("a malformed link falls back to the default rack", async ({ page }) => {
    await open(page, "#v=99&r=nonsense");
    await expect(total(page)).toHaveText("80");
    await expect(page).toHaveURL(/#v=4&d=6&r=5:6_4:6&f=1$/);
  });

  test.describe("without part meshes", () => {
    test.use({ allowedFailures: [/\/parts\/manifest\.json$/] });

    test("the preview falls back to schematic boxes", async ({ page }) => {
      await page.route("**/parts/manifest.json", (route) => route.fulfill({ status: 404, body: "" }));
      await open(page);
      const canvas = page.locator(".cfg-canvas");
      await expect(canvas).toHaveAttribute("data-render", "schematic");
      expect(await yellowShare(page, canvas)).toBeGreaterThan(0.005);
      await expect(total(page)).toHaveText("80");
    });
  });
});
