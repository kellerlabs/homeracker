import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { afterEach, expect, test } from "vitest";
import { MARKER, report } from "../scripts/e2e-report.mjs";

let dir = "";
afterEach(() => fs.rmSync(dir, { recursive: true, force: true }));

function results(runs: Record<string, object>): string {
  dir = fs.mkdtempSync(path.join(os.tmpdir(), "e2e-report-"));
  for (const [run, json] of Object.entries(runs)) fs.writeFileSync(path.join(dir, `${run}.json`), JSON.stringify(json));
  return dir;
}

const spec = (title: string, status: string, message?: string) => ({
  title,
  file: "configurator.spec.ts",
  line: 7,
  tests: [{ projectName: "desktop", status, results: [{ status: "failed", errors: message ? [{ message }] : [] }] }],
});

test("no results means no report", () => {
  expect(report(results({}))).toBe("");
});

test("a green run reports the pass count per run", () => {
  const green = { stats: { expected: 46, unexpected: 0, flaky: 0 }, suites: [] };
  const body = report(results({ root: green, "preview-subpath": green }), { SHA: "7eabc24abcdef" });
  expect(body.split("\n")[0]).toBe(MARKER);
  expect(body).toContain("✅ **E2E:** 92 passed (preview subpath, site root) · 7eabc24");
});

test("a failure lists the test with its describe path, error and report link", () => {
  const red = {
    stats: { expected: 45, unexpected: 1, flaky: 0 },
    suites: [
      {
        title: "configurator.spec.ts",
        specs: [],
        suites: [{ title: "happy paths", specs: [spec("row editing", "unexpected", "\u001b[31mpage error: boom\u001b[39m"), spec("ok", "expected")] }],
      },
    ],
  };
  const body = report(results({ root: red }), { REPORT_URL: "https://example.test/artifact", RUN_URL: "https://example.test/run" });
  expect(body).toContain("❌ **E2E:** 1 failed, 45 passed");
  expect(body).toContain("<b>happy paths › row editing</b> (desktop, site root)");
  expect(body).toContain("`configurator.spec.ts:7`");
  expect(body).toContain("page error: boom");
  expect(body).not.toContain("\u001b[");
  expect(body).toContain("[playwright-report](https://example.test/artifact) · [workflow run](https://example.test/run)");
});

test("a run without results makes the report incomplete, not green", () => {
  const green = { stats: { expected: 47, unexpected: 0, flaky: 0 }, suites: [] };
  const body = report(results({ root: green }), { E2E_RUNS: "root preview-subpath" });
  expect(body).toContain("❌ **E2E:** 47 passed, incomplete");
  expect(body).toContain("⚠️ No results for preview subpath");
});

test("no results at all while runs are expected still reports", () => {
  expect(report(results({}), { E2E_RUNS: "root" })).toContain("No results for site root");
});
