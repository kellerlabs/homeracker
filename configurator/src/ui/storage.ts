import type { RackConfig } from "../engine/types";
import { decodeConfig, encodeConfig } from "../engine/url";
import { DEFAULT_BED, type PrinterBed } from "../engine/printer";

/**
 * What the browser remembers, and for how long.
 *
 * Everything here is `sessionStorage`, and deliberately so: it lives for the life of the tab and
 * nothing longer. Leave the page and come back and your work is still there; open a new tab and
 * you start clean. Nothing identifies anyone, nothing outlives the tab, and nothing is sent
 * anywhere. Do not reach for `localStorage` or cookies here. Every read and write is guarded,
 * because storage throws rather than returning null when a browser is set to block it.
 */

const BED_KEY = "homeracker.printerBed";
const RACK_KEY = "homeracker.rack";

/**
 * Delete what earlier builds left in `localStorage`. Those builds kept the print volume there, so
 * it would otherwise sit on the machine for good; this clears it on the next visit. Removal only,
 * and safe to keep long after the last such build is forgotten.
 */
export function forgetPersistentStorage(): void {
  try {
    localStorage.removeItem(BED_KEY);
  } catch {
    // Nothing to do: a browser that blocks storage has nothing of ours to remove.
  }
}

export function loadBed(): PrinterBed {
  try {
    const raw = sessionStorage.getItem(BED_KEY);
    if (!raw) return { ...DEFAULT_BED };
    const parsed = JSON.parse(raw) as Partial<PrinterBed>;
    const ok = (v: unknown) => typeof v === "number" && Number.isFinite(v) && v >= 50;
    return ok(parsed.x) && ok(parsed.y) && ok(parsed.z) ? { x: parsed.x!, y: parsed.y!, z: parsed.z! } : { ...DEFAULT_BED };
  } catch {
    return { ...DEFAULT_BED };
  }
}

export function saveBed(bed: PrinterBed): void {
  try {
    sessionStorage.setItem(BED_KEY, JSON.stringify(bed));
  } catch {
    // Storage may be unavailable (private mode); the bed then lives for this page only.
  }
}

/**
 * The rack as last edited in this tab, or null when there is none to restore. Stored in the same
 * form as the link, so an entry written by an older build still opens through the version handling
 * in `decodeConfig`, and anything unreadable simply falls back to the default rack.
 */
export function loadRack(): RackConfig | null {
  try {
    const raw = sessionStorage.getItem(RACK_KEY);
    return raw ? decodeConfig(raw) : null;
  } catch {
    return null;
  }
}

export function saveRack(config: RackConfig): void {
  try {
    sessionStorage.setItem(RACK_KEY, encodeConfig(config));
  } catch {
    // Nothing to fall back to: the rack still lives in the address bar.
  }
}
