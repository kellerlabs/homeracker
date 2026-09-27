// Markdown report of the Playwright JSON results in e2e-results/, for the job summary and the PR
// comment. Prints nothing when there are no results and none are expected.
// Env: E2E_RUNS (space-separated runs that must have results), SHA, RUN_URL, REPORT_URL (all optional).
import fs from "node:fs";
import path from "node:path";

export const MARKER = "<!-- e2e-report -->";
const MAX_ERROR_LINES = 20;
const RUN_LABEL = { root: "site root", "preview-subpath": "preview subpath" };

const stripAnsi = (text) => text.replace(/\u001b\[[0-9;]*m/g, "");

/** Every test of a Playwright JSON report, with its describe titles. */
function* tests(suite, titles = []) {
  const here = suite.title && !suite.title.endsWith(".ts") ? [...titles, suite.title] : titles;
  for (const spec of suite.specs ?? []) {
    for (const test of spec.tests) yield { file: spec.file, line: spec.line, title: [...here, spec.title].join(" › "), test };
  }
  for (const child of suite.suites ?? []) yield* tests(child, here);
}

export function report(dir, env = {}) {
  const files = fs.existsSync(dir) ? fs.readdirSync(dir).filter((f) => f.endsWith(".json")).sort() : [];
  // A run without results never finished (an earlier step failed), so it cannot count as passing.
  const missing = (env.E2E_RUNS ?? "")
    .split(/\s+/)
    .filter((run) => run && !files.includes(`${run}.json`))
    .map((run) => RUN_LABEL[run] ?? run);
  if (files.length === 0 && missing.length === 0) return "";

  const runs = [];
  const failures = [];
  let passed = 0;
  let flaky = 0;
  for (const file of files) {
    const run = path.basename(file, ".json");
    runs.push(RUN_LABEL[run] ?? run);
    const results = JSON.parse(fs.readFileSync(path.join(dir, file), "utf8"));
    passed += results.stats.expected;
    flaky += results.stats.flaky;
    for (const suite of results.suites) {
      for (const { file: spec, line, title, test } of tests(suite)) {
        if (test.status !== "unexpected") continue;
        const last = test.results.at(-1);
        const error = stripAnsi(last?.errors?.map((e) => e.message).join("\n\n") ?? last?.error?.message ?? "no error message");
        failures.push({ run: RUN_LABEL[run] ?? run, project: test.projectName, where: `${spec}:${line}`, title, error });
      }
    }
  }

  const sha = env.SHA ? ` · ${env.SHA.slice(0, 7)}` : "";
  const links = [
    env.REPORT_URL && `📸 Screenshots and traces: [playwright-report](${env.REPORT_URL})`,
    env.RUN_URL && `[workflow run](${env.RUN_URL})`,
  ].filter(Boolean);
  const out = [MARKER];
  if (failures.length === 0 && missing.length === 0) {
    out.push(`✅ **E2E:** ${passed} passed (${runs.join(", ")})${sha}`);
    if (flaky > 0) out.push("", `⚠️ ${flaky} flaky: passed only on retry, see the workflow run.`);
    if (env.RUN_URL) out.push("", `[workflow run](${env.RUN_URL})`);
    return out.join("\n");
  }

  const counts = [failures.length > 0 && `${failures.length} failed`, `${passed} passed`, missing.length > 0 && "incomplete"];
  out.push(`❌ **E2E:** ${counts.filter(Boolean).join(", ")}${sha}`, "");
  if (missing.length > 0) out.push(`⚠️ No results for ${missing.join(", ")}: an earlier step failed, see the workflow run.`, "");
  for (const f of failures) {
    const lines = f.error.split("\n");
    const shown = lines.slice(0, MAX_ERROR_LINES).join("\n") + (lines.length > MAX_ERROR_LINES ? "\n…" : "");
    out.push(
      `<details><summary><b>${f.title}</b> (${f.project}, ${f.run})</summary>`,
      "",
      `\`${f.where}\``,
      "",
      "```",
      shown,
      "```",
      "</details>",
    );
  }
  if (links.length > 0) out.push("", links.join(" · "));
  return out.join("\n");
}

if (import.meta.url === `file://${process.argv[1]}`) {
  process.stdout.write(report("e2e-results", process.env));
}
