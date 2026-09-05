import { LIMITS } from "./constants";
import type { RackConfig, RackRow } from "./types";

/** A column is a gap when its width is negative: the same space as a bay, with no beam above it. */
export function isGap(width: number): boolean {
  return width < 0;
}

/** x coordinates of the nodes bounding a row's bays: one per column boundary. A gap takes its magnitude. */
export function rowBoundaries(row: RackRow): number[] {
  const xs = [row.shift];
  let x = row.shift;
  for (const width of row.columns) {
    x += Math.abs(width) + 1;
    xs.push(x);
  }
  return xs;
}

/** Outer width of a row in units, including its bounding nodes. */
export function rowWidth(row: RackRow): number {
  return row.columns.reduce((n, w) => n + Math.abs(w), 0) + row.columns.length + 1;
}

/** A run of neighbouring bays: the parts of a row a gap leaves standing. */
export interface RowSegment {
  /** First and last column index of the run. */
  from: number;
  to: number;
  /** x of the boundary on each side of the run. */
  left: number;
  right: number;
}

/** Maximal runs of bays, left to right. A row without gaps has exactly one segment. */
export function rowSegments(row: RackRow): RowSegment[] {
  const xs = rowBoundaries(row);
  const list: RowSegment[] = [];
  let start = -1;
  row.columns.forEach((width, i) => {
    if (!isGap(width)) {
      if (start < 0) start = i;
      return;
    }
    if (start >= 0) list.push({ from: start, to: i - 1, left: xs[start]!, right: xs[i]! });
    start = -1;
  });
  if (start >= 0) list.push({ from: start, to: row.columns.length - 1, left: xs[start]!, right: xs[row.columns.length]! });
  return list;
}

export interface Frame {
  /** z coordinate of the frame's nodes. */
  z: number;
  /** x coordinates of the frame's nodes: the boundaries of the rows below and above, merged. */
  xs: number[];
  /** Neighbouring pairs of `xs` that carry an x beam, at the front and the back face. */
  beams: [number, number][];
}

type Cover = "bay" | "gap" | "none";

/** How a row covers the span between two frame nodes: the column holding it is a bay, a gap, or the row is elsewhere. */
function coverage(row: RackRow | undefined, a: number, b: number): Cover {
  if (!row) return "none";
  const xs = rowBoundaries(row);
  for (let i = 0; i < row.columns.length; i++) {
    if (xs[i]! <= a && xs[i + 1]! >= b) return isGap(row.columns[i]!) ? "gap" : "bay";
  }
  return "none";
}

/** Whether a row has a bar-forced column covering the span [a, b]. */
function hasBar(row: RackRow | undefined, a: number, b: number): boolean {
  if (!row?.bars?.length) return false;
  const xs = rowBoundaries(row);
  for (const i of row.bars) {
    if (xs[i] !== undefined && xs[i + 1] !== undefined && xs[i]! <= a && xs[i + 1]! >= b) return true;
  }
  return false;
}

/**
 * Resolve a `?` column: compute the auto-fill width so the row's right edge matches the row below.
 * Returns null when the auto cannot be resolved (computed width out of range, multiple autos).
 */
export function resolveAuto(columns: (number | null)[], shift: number, below: RackRow): number[] | null {
  const autoIdx = columns.indexOf(null);
  if (autoIdx < 0) return columns as number[];
  if (columns.indexOf(null, autoIdx + 1) >= 0) return null;
  const targetRight = rowBoundaries(below).at(-1)!;
  let leftOfAuto = shift;
  for (let i = 0; i < autoIdx; i++) leftOfAuto += Math.abs(columns[i]!) + 1;
  let rightPart = 0;
  for (let i = autoIdx + 1; i < columns.length; i++) rightPart += Math.abs(columns[i]!) + 1;
  const width = targetRight - leftOfAuto - 1 - rightPart;
  if (width < LIMITS.span.min || width > LIMITS.span.max) return null;
  const resolved = [...columns];
  resolved[autoIdx] = width;
  return resolved as number[];
}

/** Resolve all `?` (auto) columns in a config. Returns null if any auto cannot be resolved. */
export function resolveConfigAutos(config: RackConfig): RackConfig | null {
  const rows: RackRow[] = [];
  for (let i = 0; i < config.rows.length; i++) {
    const row = config.rows[i]!;
    if (!row.autos?.length) { rows.push(row); continue; }
    if (i === 0) return null;
    const cols = row.columns.map((w, j) => (row.autos!.includes(j) ? null : w));
    const resolved = resolveAuto(cols, row.shift, rows[i - 1]!);
    if (!resolved) return null;
    rows.push({ ...row, columns: resolved });
  }
  return { ...config, rows };
}

/** Frames from the floor to the top: one below the first row, one between rows, one above the last. */
export function frames(config: RackConfig): Frame[] {
  const list: Frame[] = [];
  let z = 0;
  for (let k = 0; k <= config.rows.length; k++) {
    const below = config.rows[k - 1];
    const above = config.rows[k];
    const set = new Set<number>();
    if (below) for (const x of rowBoundaries(below)) set.add(x);
    if (above) for (const x of rowBoundaries(above)) set.add(x);
    const xs = [...set].sort((a, b) => a - b);
    const beams: [number, number][] = [];
    for (let i = 0; i + 1 < xs.length; i++) {
      const span: [number, number] = [xs[i]!, xs[i + 1]!];
      const under = coverage(below, ...span);
      const over = coverage(above, ...span);
      // A gap stays open to the sky unless the row above forces a bottom bar on the column there.
      if (under === "gap" && !hasBar(above, ...span)) continue;
      // Under a gap the beam survives only where a bay of the row below spans the same place.
      if (over === "gap" && under !== "bay" && below) continue;
      // Where neither row reaches, the beam stays: it is what bridges rows standing side by side.
      beams.push(span);
    }
    list.push({ z, xs, beams });
    if (above) z += above.height + 1;
  }
  return list;
}
