import { LIMITS } from "./constants";
import { frames, isGap, rowBoundaries, rowSegments } from "./lattice";
import type { FaceGroup, Opening, PanelSpec, PanelType, RackConfig, RackPanel } from "./types";

/**
 * Panel units for an opening bounded by supports of `length` x `height` units.
 * models/panel/lib/panel.scad: inter-fit width = units_x * BASE_UNIT - (2 * BASE_STRENGTH + TOLERANCE),
 * i.e. a panel drops into an opening of exactly units_x units. Verify once against a real render.
 */
export function panelSize(length: number, height: number): { unitsX: number; unitsY: number } {
  return { unitsX: length, unitsY: height };
}

/**
 * Lock pins to fasten a panel: one per mount-plate hole (units - 2 per edge, only when > 2),
 * plus four extended pins for corner mounts when a side is 3 units or shorter
 * (models/panel/README.md, "When to use corner mounts").
 */
export function panelPins(length: number, height: number): { standard: number; extended: number } {
  const standard = 2 * Math.max(length - 2, 0) + 2 * Math.max(height - 2, 0);
  const extended = Math.min(length, height) <= 3 ? 4 : 0;
  return { standard, extended };
}

export function openingId(face: PanelSpec["face"], at: number, index: number): string {
  return `${face}:${at}:${index}`;
}

/**
 * Every opening of the rack: per row the bays it has at the front and the back and the sides of
 * each of its segments, per frame the spans that carry a beam.
 */
export function openings(config: RackConfig): Opening[] {
  const list: Opening[] = [];
  const levels = frames(config);
  const yFar = config.depth + 1;

  config.rows.forEach((row, r) => {
    const z = levels[r]?.z ?? 0;
    const xs = rowBoundaries(row);
    row.columns.forEach((width, i) => {
      // A gap has no beam above it, so nothing bounds a bay there.
      if (isGap(width)) return;
      const x = xs[i] ?? 0;
      list.push({ id: openingId("front", r, i), face: "front", at: r, index: i, length: width, height: row.height, origin: [x, 0, z], normal: "-y" });
      list.push({ id: openingId("back", r, i), face: "back", at: r, index: i, length: width, height: row.height, origin: [x, yFar, z], normal: "+y" });
    });
    rowSegments(row).forEach((segment, s) => {
      list.push({ id: openingId("left", r, s), face: "left", at: r, index: s, length: config.depth, height: row.height, origin: [segment.left, 0, z], normal: "-x" });
      list.push({ id: openingId("right", r, s), face: "right", at: r, index: s, length: config.depth, height: row.height, origin: [segment.right, 0, z], normal: "+x" });
    });
  });

  levels.forEach((frame, k) => {
    for (let i = 0; i + 1 < frame.xs.length; i++) {
      const a = frame.xs[i]!;
      const b = frame.xs[i + 1]!;
      // The index stays the ordinal of the pair, so the spans that remain keep the ids they had.
      if (!frame.beams.some(([from, to]) => from === a && to === b)) continue;
      list.push({
        id: openingId("horizontal", k, i),
        face: "horizontal",
        at: k,
        index: i,
        length: b - a - 1,
        height: config.depth,
        origin: [a, 0, frame.z],
        normal: k === 0 ? "-z" : "+z",
      });
    }
  });

  return list;
}

/** Openings belonging to a face group; shelves are the horizontal frames between rows. */
export function groupOpenings(config: RackConfig, group: FaceGroup): Opening[] {
  const all = openings(config);
  const top = config.rows.length;
  switch (group) {
    case "top":
      return all.filter((o) => o.face === "horizontal" && o.at === top);
    case "bottom":
      return all.filter((o) => o.face === "horizontal" && o.at === 0);
    case "shelves":
      return all.filter((o) => o.face === "horizontal" && o.at > 0 && o.at < top);
    default:
      return all.filter((o) => o.face === group);
  }
}

/** Whether a panel exists for this opening: both sides within the panel model limits. */
export function canClose(opening: Pick<Opening, "length" | "height">): boolean {
  const ok = (v: number) => v >= LIMITS.panel.min && v <= LIMITS.panel.max;
  return ok(opening.length) && ok(opening.height);
}

export interface EdgeConnector {
  edge: "bottom" | "top";
  x: number;
}

/**
 * Frame nodes strictly inside the bottom or top edge of a front/back bay: the divider of a
 * neighbouring row ending in a T connector there. The panel model has no room for a connector core
 * between the corners (mount plates and contour walls run the whole edge), so no standard panel fits.
 */
export function edgeConnectors(config: RackConfig, opening: Opening): EdgeConnector[] {
  if (opening.face !== "front" && opening.face !== "back") return [];
  const levels = frames(config);
  const left = opening.origin[0];
  const right = left + opening.length + 1;
  const inside = (xs: number[]) => xs.filter((x) => x > left && x < right);
  return [
    ...inside(levels[opening.at]?.xs ?? []).map((x) => ({ edge: "bottom" as const, x })),
    ...inside(levels[opening.at + 1]?.xs ?? []).map((x) => ({ edge: "top" as const, x })),
  ];
}

/** Why no standard panel fits this opening, or null when one does. */
export function closeReason(config: RackConfig, opening: Opening): string | null {
  if (!canClose(opening)) return `no panel fits (${LIMITS.panel.min} to ${LIMITS.panel.max} units per side)`;
  const hits = edgeConnectors(config, opening);
  if (hits.length === 0) return null;
  const edges = [...new Set(hits.map((h) => h.edge))].join(" and ");
  return `connector inside the ${edges} edge: no standard panel fits; align the dividers of the rows above and below`;
}

function specMatches(spec: PanelSpec, opening: Pick<Opening, "face" | "at" | "index">): boolean {
  return spec.face === opening.face && spec.at === opening.at && spec.index === opening.index;
}

export function panelAt(config: RackConfig, opening: Pick<Opening, "face" | "at" | "index">): PanelType | undefined {
  return config.panels.find((p) => specMatches(p, opening))?.type;
}

/** Close (or, with null, open) the given openings; unclosable ones are skipped, other panels are kept. */
export function closeOpenings(config: RackConfig, targets: Opening[], type: PanelType | null): RackConfig {
  const affected = targets.filter((o) => type === null || closeReason(config, o) === null);
  const rest = config.panels.filter((p) => !affected.some((o) => specMatches(p, o)));
  const added: PanelSpec[] = type ? affected.map((o) => ({ face: o.face, at: o.at, index: o.index, type })) : [];
  return { ...config, panels: [...rest, ...added] };
}

/** Close (or, with null, open) every closable opening of a face group. */
export function closeFace(config: RackConfig, group: FaceGroup, type: PanelType | null): RackConfig {
  return closeOpenings(config, groupOpenings(config, group), type);
}

/** Cycle one opening: open -> inter-fit -> full cover -> open. */
export function togglePanel(config: RackConfig, opening: Pick<Opening, "face" | "at" | "index">): RackConfig {
  const current = panelAt(config, opening);
  const rest = config.panels.filter((p) => !specMatches(p, opening));
  if (current === "fullcover") return { ...config, panels: rest };
  const type: PanelType = current === "interfit" ? "fullcover" : "interfit";
  return { ...config, panels: [...rest, { face: opening.face, at: opening.at, index: opening.index, type }] };
}

/** Panels for every spec that still matches an opening; dangling specs are ignored. */
export function buildPanels(config: RackConfig, all: Opening[] = openings(config)): RackPanel[] {
  const panels: RackPanel[] = [];
  for (const opening of all) {
    const type = panelAt(config, opening);
    if (!type) continue;
    const blocked = closeReason(config, opening);
    panels.push({
      id: `p:${opening.id}`,
      face: opening.face,
      type,
      ...panelSize(opening.length, opening.height),
      origin: opening.origin,
      normal: opening.normal,
      ...(blocked ? { blocked } : {}),
    });
  }
  return panels;
}
