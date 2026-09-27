import fs from "node:fs";
import path from "node:path";
import { expect, INVENTORY_DIR, test } from "./fixtures";

/** Controls no journey has to use, each with the reason. Keep this list short. */
const EXEMPT: Record<string, string> = {
  link: "links are resolved by the page smoke test in pages.spec.ts",
};

// Every control the configurator rendered in any test must have been used by at least one test,
// so a new button or field fails CI until a journey exercises it.
test("every configurator control is exercised by a test", () => {
  const files = fs.existsSync(INVENTORY_DIR) ? fs.readdirSync(INVENTORY_DIR) : [];
  expect(files.length, "no inventory recorded: run the full suite, not a subset").toBeGreaterThan(0);

  const rendered = new Set<string>();
  const used = new Set<string>();
  for (const file of files) {
    const seen = JSON.parse(fs.readFileSync(path.join(INVENTORY_DIR, file), "utf8")) as { rendered: string[]; used: string[] };
    seen.rendered.forEach((k) => rendered.add(k));
    seen.used.forEach((k) => used.add(k));
  }
  const untested = [...rendered].filter((k) => !used.has(k) && !(k in EXEMPT)).sort();
  expect(untested, "controls no E2E test uses; add a journey in configurator.spec.ts").toEqual([]);
});
