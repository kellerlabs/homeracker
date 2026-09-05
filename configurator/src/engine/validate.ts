import { LIMITS } from "./constants";
import type { RackConfig, ValidationIssue } from "./types";

export const MAX_ROWS = 24;
export const MAX_COLUMNS = 12;

/** Depth, heights and widths are supports between two connectors, so they follow the span limits. */
function isSupportLength(value: number): boolean {
  return Number.isInteger(value) && value >= LIMITS.span.min && value <= LIMITS.span.max;
}

/** A column is a bay, or a gap written as the negative of its width. Both follow the span limits. */
function isColumnWidth(value: number): boolean {
  return isSupportLength(Math.abs(value));
}

function rowIssue(config: RackConfig): ValidationIssue | null {
  const range = `between ${LIMITS.span.min} and ${LIMITS.span.max} units`;
  if (config.rows.length === 0) return { field: "rows", message: "add at least one row" };
  if (config.rows.length > MAX_ROWS) return { field: "rows", message: `at most ${MAX_ROWS} rows` };
  for (const [i, row] of config.rows.entries()) {
    const name = `row ${i + 1}`;
    if (!isSupportLength(row.height)) return { field: "rows", message: `${name}: height must be a whole number ${range}` };
    if (row.columns.length === 0) return { field: "rows", message: `${name}: add at least one column width` };
    if (row.columns.length > MAX_COLUMNS) return { field: "rows", message: `${name}: at most ${MAX_COLUMNS} columns` };
    if (!row.columns.every(isColumnWidth)) {
      return { field: "rows", message: `${name}: every column width must be a whole number ${range}, or its negative for a gap (e.g. -10)` };
    }
    if (!Number.isInteger(row.shift) || row.shift < 0 || row.shift > LIMITS.support.max) {
      return { field: "rows", message: `${name}: shift must be a whole number between 0 and ${LIMITS.support.max} units` };
    }
  }
  return null;
}

export function validate(config: RackConfig): ValidationIssue[] {
  const issues: ValidationIssue[] = [];
  if (!isSupportLength(config.depth)) {
    issues.push({
      field: "depth",
      message: `depth must be a whole number between ${LIMITS.span.min} and ${LIMITS.span.max} units`,
    });
  }
  const rows = rowIssue(config);
  if (rows) issues.push(rows);
  // Panels never invalidate a rack: one that fits no standard part is kept, marked in the drawings,
  // the parts list and the 3D view, so the problem shows where it was configured.
  return issues;
}
