import type { Bom } from "./types";

/** Usable print volume in millimetres. */
export interface PrinterBed {
  x: number;
  y: number;
  z: number;
}

export const DEFAULT_BED: PrinterBed = { x: 256, y: 256, z: 256 };

/** Whether a part of the given size (mm) fits the bed in some axis-aligned orientation. */
export function fitsBed(size: readonly [number, number, number], bed: PrinterBed): boolean {
  const part = [...size].sort((a, b) => a - b);
  const room = [bed.x, bed.y, bed.z].sort((a, b) => a - b);
  return part.every((v, i) => v <= (room[i] ?? 0));
}

/** Keys of the parts-list lines whose part does not fit the bed. */
export function unprintable(bom: Bom, bed: PrinterBed): Set<string> {
  return new Set(bom.lines.filter((l) => l.size && !fitsBed(l.size, bed)).map((l) => l.key));
}
