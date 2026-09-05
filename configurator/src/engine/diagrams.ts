import { frames, isGap, rowSegments } from "./lattice";
import { openings } from "./panels";
import type { Opening, RackConfig } from "./types";

/** One clickable rectangle in a diagram, in rack units; y grows downwards like SVG. */
export interface DiagramCell {
  opening: Opening;
  x: number;
  y: number;
  w: number;
  h: number;
}

/** A to-scale drawing of one face (or one frame seen from above), in rack units. */
export interface Diagram {
  id: string;
  title: string;
  width: number;
  height: number;
  cells: DiagramCell[];
}

/**
 * Elevations of the four vertical faces and a plan view of every frame, top first ("Top of <row>" for every frame above a row).
 * Front/back/left/right are drawn as a viewer standing in front of that face sees them;
 * plans are seen from above with the front edge at the bottom.
 */
export function faceDiagrams(config: RackConfig, all: Opening[] = openings(config)): Diagram[] {
  const levels = frames(config);
  const extentX = Math.max(...levels.flatMap((f) => f.xs)) + 1;
  const extentY = config.depth + 2;
  const extentZ = (levels[levels.length - 1]?.z ?? 0) + 1;

  const elevation = (
    id: Opening["face"],
    title: string,
    width: number,
    x: (o: Opening) => number,
    keep: (o: Opening) => boolean = () => true,
  ): Diagram => ({
    id,
    title,
    width,
    height: extentZ,
    cells: all
      .filter((o) => o.face === id && keep(o))
      .map((o) => ({ opening: o, x: x(o), y: extentZ - (o.origin[2] + 1 + o.height), w: o.length, h: o.height })),
  });

  // A side elevation projects along x, so only the outermost wall of a row can be drawn in it;
  // the walls a gap exposes get their own figure below.
  const lastSegment = (at: number) => rowSegments(config.rows[at]!).length - 1;

  const diagrams: Diagram[] = [
    elevation("front", "Front", extentX, (o) => o.origin[0] + 1),
    elevation("back", "Back", extentX, (o) => extentX - (o.origin[0] + 1 + o.length)),
    elevation("left", "Left side", extentY, (o) => extentY - (o.origin[1] + 1 + o.length), (o) => o.index === 0),
    elevation("right", "Right side", extentY, (o) => o.origin[1] + 1, (o) => o.index === lastSegment(o.at)),
  ];

  // Both walls of a gap, unfolded outwards: each is placed exactly as its own side elevation
  // would place it, the left one in the first half of the figure and the right one in the second.
  config.rows.forEach((row, r) => {
    const segments = rowSegments(row);
    const gaps = row.columns.flatMap((width, i) => (isGap(width) ? [i] : []));
    const name = row.name?.trim() || `row ${r + 1}`;
    // A gap at the edge of a row exposes one wall, not a facing pair, and that wall already
    // appears in its own side elevation. So a figure may not exist for every gap: number the
    // ones that actually get a figure, not the gap columns themselves.
    const figures = gaps.flatMap((column) => {
      const leftWall = all.find((o) => o.face === "right" && o.at === r && o.index === segments.findIndex((s) => s.to === column - 1));
      const rightWall = all.find((o) => o.face === "left" && o.at === r && o.index === segments.findIndex((s) => s.from === column + 1));
      return leftWall && rightWall ? [{ column, leftWall, rightWall }] : [];
    });
    figures.forEach(({ column, leftWall, rightWall }, n) => {
      const cell = (o: Opening, x: number): DiagramCell => ({ opening: o, x, y: extentZ - (o.origin[2] + 1 + o.height), w: o.length, h: o.height });
      diagrams.push({
        id: `gap:${r}:${column}`,
        title: figures.length > 1 ? `Gap ${n + 1} in ${name}` : `Gap in ${name}`,
        width: 2 * extentY,
        height: extentZ,
        cells: [cell(leftWall, leftWall.origin[1] + 1), cell(rightWall, extentY + (extentY - (rightWall.origin[1] + 1 + rightWall.length)))],
      });
    });
  });

  for (let k = levels.length - 1; k >= 0; k--) {
    const below = config.rows[k - 1]?.name?.trim();
    const title = k === 0 ? "Bottom" : `Top of ${below || `row ${k}`}`;
    diagrams.push({
      id: `horizontal:${k}`,
      title,
      width: extentX,
      height: extentY,
      cells: all
        .filter((o) => o.face === "horizontal" && o.at === k)
        .map((o) => ({ opening: o, x: o.origin[0] + 1, y: extentY - (o.origin[1] + 1 + o.height), w: o.length, h: o.height })),
    });
  }
  return diagrams;
}
