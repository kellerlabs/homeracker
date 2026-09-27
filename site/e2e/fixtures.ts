import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { test as base, expect, type Locator, type Page } from "@playwright/test";

const here = path.dirname(fileURLToPath(import.meta.url));
export const DIST = path.resolve(here, "..", "dist");
export const INVENTORY_DIR = path.resolve(here, "..", "test-results", "inventory");

/** The build carries the exported part meshes; without OpenSCAD the pages draw schematic boxes. */
export function hasParts(): boolean {
  return fs.existsSync(path.join(DIST, "parts", "manifest.json"));
}

/** Every page of the build as a path relative to the base URL ("" is the home page). */
export function routes(): string[] {
  const out: string[] = [];
  const walk = (dir: string) => {
    for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
      const full = path.join(dir, entry.name);
      if (entry.isDirectory()) walk(full);
      else if (entry.name === "index.html") out.push(path.relative(DIST, dir).split(path.sep).join("/"));
    }
  };
  walk(DIST);
  return out.map((r) => (r ? `${r}/` : "")).sort();
}

/**
 * Stable key of an interactive element, shared by the recorder and the inventory. Keys name the
 * kind of control, not the instance, so "Remove row" on row 1 and row 3 count as one control.
 */
function controlKeyInPage(): void {
  const selector = 'button, input, select, textarea, summary, a[href], [role="button"]';
  const keyOf = (target: Element): string | null => {
    const c = target.closest<HTMLElement>(selector);
    if (!c) return null;
    const d = c.dataset;
    if (d.action) return `action:${d.action}`;
    if (d.all) return `all:${d.all}`;
    if (d.opening) return "opening";
    const name = c.getAttribute("name");
    if (name) return `${c.tagName.toLowerCase()}:${name}`;
    if (c.id) return `#${c.id}`;
    if (c.tagName === "A") return "link";
    const label = c.getAttribute("aria-label") ?? c.textContent ?? "";
    return `${c.tagName.toLowerCase()}:${label.trim()}`;
  };
  const w = window as unknown as { __e2e: { used: Set<string>; keyOf: typeof keyOf; selector: string } };
  w.__e2e = { used: new Set(), keyOf, selector };
  for (const type of ["click", "input", "change", "keydown"]) {
    window.addEventListener(
      type,
      (event) => {
        const target = event.target as Element | null;
        const scope = target?.closest?.("#configurator");
        const key = scope && keyOf(target!);
        if (key) w.__e2e.used.add(key);
      },
      { capture: true },
    );
  }
}

interface Options {
  /** Same-origin URLs a test expects to fail (e.g. a stubbed 404). */
  allowedFailures: RegExp[];
}

/**
 * Every test fails on an uncaught page error, a console error, or a same-origin request that
 * fails or answers 4xx/5xx. It also records which configurator controls it rendered and used.
 */
export const test = base.extend<Options & { health: void; inventory: void }>({
  allowedFailures: [[], { option: true }],

  health: [
    async ({ page, allowedFailures, baseURL }, use) => {
      const origin = new URL(baseURL!).origin;
      const problems: string[] = [];
      const allowed = (url: string) => allowedFailures.some((re) => re.test(url));
      // Without exported parts the pages ask for a manifest that is not there and fall back.
      const optional = (url: string) => !hasParts() && url.endsWith("/parts/manifest.json");
      page.on("pageerror", (error) => problems.push(`page error: ${error.message}`));
      page.on("console", (msg) => {
        if (msg.type() !== "error") return;
        const url = msg.location().url;
        if (url && (allowed(url) || optional(url))) return;
        if (/Failed to load resource/.test(msg.text()) && url && !url.startsWith(origin)) return;
        problems.push(`console error: ${msg.text()}`);
      });
      page.on("requestfailed", (request) => {
        const url = request.url();
        if (url.startsWith(origin) && !allowed(url)) problems.push(`request failed: ${url} (${request.failure()?.errorText})`);
      });
      page.on("response", (response) => {
        const url = response.url();
        if (url.startsWith(origin) && response.status() >= 400 && !allowed(url) && !optional(url)) {
          problems.push(`HTTP ${response.status()}: ${url}`);
        }
      });
      await use();
      expect(problems, "page health").toEqual([]);
    },
    { auto: true },
  ],

  inventory: [
    async ({ page }, use, testInfo) => {
      await page.addInitScript(controlKeyInPage);
      await use();
      const seen = await page
        .evaluate(() => {
          const w = window as unknown as { __e2e?: { used: Set<string>; keyOf: (e: Element) => string | null; selector: string } };
          const root = document.querySelector("#configurator");
          if (!w.__e2e || !root) return null;
          const rendered = [...root.querySelectorAll(w.__e2e.selector)].map((e) => w.__e2e!.keyOf(e)).filter((k): k is string => !!k);
          return { rendered: [...new Set(rendered)], used: [...w.__e2e.used] };
        })
        .catch(() => null);
      if (!seen) return;
      fs.mkdirSync(INVENTORY_DIR, { recursive: true });
      fs.writeFileSync(path.join(INVENTORY_DIR, `${testInfo.testId}.json`), JSON.stringify(seen));
    },
    { auto: true },
  ],
});

export { expect };

/**
 * Share of the element's visible pixels in HomeRacker support yellow (#f7b600), from a screenshot.
 * Non-zero proves WebGL drew the rack, not just an empty canvas or the floor grid.
 */
export async function yellowShare(page: Page, target: Locator): Promise<number> {
  const png = (await target.screenshot()).toString("base64");
  return page.evaluate(async (data) => {
    const image = new Image();
    image.src = `data:image/png;base64,${data}`;
    await image.decode();
    const canvas = new OffscreenCanvas(image.width, image.height);
    const ctx = canvas.getContext("2d")!;
    ctx.drawImage(image, 0, 0);
    const pixels = ctx.getImageData(0, 0, image.width, image.height).data;
    let hits = 0;
    for (let i = 0; i < pixels.length; i += 4) {
      const [r, g, b] = [pixels[i]!, pixels[i + 1]!, pixels[i + 2]!];
      if (r > 150 && g > 90 && b < 80 && r > g) hits++;
    }
    return hits / (pixels.length / 4);
  }, png);
}
