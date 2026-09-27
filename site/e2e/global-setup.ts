import fs from "node:fs";
import { DIST, hasParts, INVENTORY_DIR } from "./fixtures";

export default function globalSetup(): void {
  if (!fs.existsSync(`${DIST}/index.html`)) throw new Error("site/dist is missing: run `npm run build` first");
  if (process.env.PARTS_REQUIRED && !hasParts()) {
    throw new Error("PARTS_REQUIRED is set but dist/parts/manifest.json is missing: run `npm run parts` before the build");
  }
  fs.rmSync(INVENTORY_DIR, { recursive: true, force: true });
}
