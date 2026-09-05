// Export the HomeRacker core parts used by the site (hero) and the configurator preview from
// their OpenSCAD sources into site/public/parts/ (gitignored), plus a manifest.
// Skips with a warning when OpenSCAD is not installed, unless PARTS_REQUIRED=1; the pages then
// fall back to schematic boxes.
import { spawn, spawnSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";

const here = path.dirname(fileURLToPath(import.meta.url));
const repo = path.resolve(here, "../..");
const binDir = path.join(repo, "bin", "openscad");
const outDir = path.join(here, "..", "public", "parts");
const DETAIL = "$fn=24";
const MAX_SUPPORT = 50;
const JOBS = Math.max(2, Math.min(os.cpus().length, 6));

/** Connector types (dimensions, ways) and the axes that may be pull-through for each. */
const CONNECTORS = [
  [1, 1, []],
  [1, 2, ["z"]],
  [2, 2, []],
  [2, 3, ["z"]],
  [2, 4, ["z", "x"]],
  [3, 3, []],
  [3, 4, ["z"]],
  [3, 5, ["z", "x"]],
  [3, 6, ["z", "x", "y"]],
];

function parts() {
  const list = [];
  for (const [dimensions, ways, pulls] of CONNECTORS) {
    for (const pull of ["none", ...pulls]) {
      const name = `connector-${dimensions}d${ways}w${pull === "none" ? "" : `-${pull}`}`;
      list.push({
        name,
        file: "models/core/parts/connector.scad",
        defines: [`dimensions=${dimensions}`, `directions=${ways}`, `pull_through_axis="${pull}"`, "optimal_orientation=false"],
      });
    }
  }
  for (let units = 1; units <= MAX_SUPPORT; units++) {
    list.push({ name: `support-${units}`, file: "models/core/parts/support.scad", defines: [`units=${units}`] });
  }
  list.push({ name: "lockpin", file: "models/core/parts/lockpin.scad", defines: [] });
  list.push({ name: "foot", file: "models/foot/parts/foot.scad", defines: [] });
  // Panel kit: panels are assembled in the browser from their mount plates and corner brackets.
  const kit = "site/scripts/scad/panel_kit.scad";
  for (const [code, type] of [["i", 1], ["f", 2]]) {
    list.push({ name: `panel-corner-${code}`, file: kit, defines: ['part="mount_corner"', `panel_type=${type}`] });
    for (let units = 3; units <= MAX_SUPPORT; units++) {
      list.push({ name: `panel-mount-${code}-${units}`, file: kit, defines: ['part="mount_plate"', `panel_type=${type}`, `units=${units}`] });
    }
  }
  return list;
}

function onPath(name) {
  const probe = spawnSync(os.platform() === "win32" ? "where" : "which", [name], { encoding: "utf8" });
  return probe.status === 0 ? probe.stdout.split(/\r?\n/)[0].trim() : null;
}

function findOpenscad() {
  if (process.env.OPENSCAD) return process.env.OPENSCAD;
  if (fs.existsSync(binDir)) {
    const names = fs.readdirSync(binDir).filter((n) => /^openscad(\.exe)?$|^openscad-nightly$|^OpenSCAD.*\.AppImage$/i.test(n));
    for (const n of names) {
      const candidate = path.join(binDir, n);
      if (fs.statSync(candidate).isFile()) return candidate;
    }
  }
  return onPath("openscad") ?? onPath("openscad-nightly");
}

function exportPart(openscad, env, runner, part) {
  const target = path.join(outDir, `${part.name}.stl`);
  const args = ["-o", target, "--export-format", "binstl"];
  for (const define of [...part.defines, DETAIL]) args.push("-D", define);
  args.push(path.join(repo, part.file));
  const [cmd, ...cmdArgs] = runner.length ? [...runner, openscad, ...args] : [openscad, ...args];
  return new Promise((resolve) => {
    const child = spawn(cmd, cmdArgs, { env });
    let stderr = "";
    child.stderr.on("data", (d) => (stderr += d));
    child.on("close", (code) => {
      if (code !== 0 || !fs.existsSync(target)) {
        resolve({ part, error: stderr || `exit ${code}` });
        return;
      }
      resolve({ part, triangles: Math.round((fs.statSync(target).size - 84) / 50) });
    });
  });
}

async function main() {
  const openscad = findOpenscad();
  if (!openscad) {
    const message = "OpenSCAD not found (run `scadm install` or set OPENSCAD); parts not exported";
    if (process.env.PARTS_REQUIRED === "1") {
      console.error(message);
      process.exit(1);
    }
    console.warn(message);
    return;
  }

  const env = { ...process.env };
  const libraries = path.join(binDir, "libraries");
  if (fs.existsSync(libraries)) env.OPENSCADPATH = libraries;
  const runner = os.platform() === "linux" && onPath("xvfb-run") ? ["xvfb-run", "-a"] : [];

  fs.mkdirSync(outDir, { recursive: true });
  const queue = parts();
  const manifest = { generated: new Date().toISOString(), unit: 15, parts: {} };
  let failed = false;

  const worker = async () => {
    for (let part = queue.shift(); part; part = queue.shift()) {
      const result = await exportPart(openscad, env, runner, part);
      if (result.error) {
        failed = true;
        console.error(`export failed for ${part.name}\n${result.error}`);
      } else {
        manifest.parts[part.name] = { file: `${part.name}.stl`, triangles: result.triangles };
      }
    }
  };
  const started = Date.now();
  await Promise.all(Array.from({ length: JOBS }, worker));
  if (failed) process.exit(1);

  fs.writeFileSync(path.join(outDir, "manifest.json"), JSON.stringify(manifest, null, 2));
  const count = Object.keys(manifest.parts).length;
  console.log(`exported ${count} parts in ${Math.round((Date.now() - started) / 1000)}s -> ${path.relative(repo, outDir)}`);
}

await main();
