import { LIMITS } from "./constants";
import { frames, isGap, rowBoundaries } from "./lattice";
import { buildPanels, openings } from "./panels";
import { AXIS_INDEX, type Axis, type Dir, type RackConfig, type RackModel, type RackNode, type RackProblem, type RackSupport, type Vec3 } from "./types";

export function nodeId(pos: Vec3): string {
  return `n:${pos[0]},${pos[1]},${pos[2]}`;
}

function shifted(pos: Vec3, axis: Axis, value: number): Vec3 {
  const next: [number, number, number] = [pos[0], pos[1], pos[2]];
  next[AXIS_INDEX[axis]] = value;
  return next;
}

class Lattice {
  readonly nodes = new Map<string, RackNode>();
  supports: RackSupport[] = [];

  node(pos: Vec3): RackNode {
    const id = nodeId(pos);
    let node = this.nodes.get(id);
    if (!node) {
      node = { id, pos, arms: new Set<Dir>(), pullThrough: "none", foot: false };
      this.nodes.set(id, node);
    }
    return node;
  }

  /** Add a support between the nodes at coordinates `a` and `b` along `axis`, through `base`. */
  support(axis: Axis, base: Vec3, a: number, b: number): void {
    const lower = this.node(shifted(base, axis, a));
    const upper = this.node(shifted(base, axis, b));
    lower.arms.add(`+${axis}`);
    upper.arms.add(`-${axis}`);
    const from = shifted(base, axis, a + 1);
    this.supports.push({ id: `s:${axis}:${from.join(",")}`, axis, from, length: b - a - 1, nodeIds: [lower.id, upper.id] });
  }

  /** Merge chained supports along `axis` wherever `passes(z)` allows it; nodes passed become pull-through. */
  mergeColumns(axis: Axis, passes: (coordinate: number) => boolean): void {
    const index = AXIS_INDEX[axis];
    const lineKey = (s: RackSupport) => s.from.filter((_, i) => i !== index).join(",");
    const lines = new Map<string, RackSupport[]>();
    for (const s of this.supports) {
      if (s.axis !== axis) continue;
      const list = lines.get(lineKey(s)) ?? [];
      list.push(s);
      lines.set(lineKey(s), list);
    }
    const merged: RackSupport[] = this.supports.filter((s) => s.axis !== axis);
    for (const chain of lines.values()) {
      chain.sort((a, b) => a.from[index] - b.from[index]);
      const groups: RackSupport[][] = [];
      for (const s of chain) {
        const last = groups[groups.length - 1];
        const prev = last?.[last.length - 1];
        const junction = prev ? prev.from[index] + prev.length : -1;
        if (prev && junction + 1 === s.from[index] && passes(junction)) last.push(s);
        else groups.push([s]);
      }
      for (const group of groups) {
        const first = group[0]!;
        const last = group[group.length - 1]!;
        const nodeIds = [...new Set(group.flatMap((s) => s.nodeIds))];
        for (const id of nodeIds.slice(1, -1)) this.nodes.get(id)!.pullThrough = axis;
        merged.push({ ...first, length: last.from[index] + last.length - first.from[index], nodeIds });
      }
    }
    this.supports = merged;
  }
}

/**
 * A rack is one piece. A gap with nothing spanning under it leaves the parts on either side
 * standing free, which is two racks rather than one; say so instead of shipping a parts list for it.
 */
function disconnectedProblems(config: RackConfig, nodes: RackNode[], supports: RackSupport[]): RackProblem[] {
  if (nodes.length === 0) return [];
  const parent = new Map(nodes.map((n) => [n.id, n.id]));
  const find = (start: string): string => {
    let root = start;
    while (parent.get(root) !== root) root = parent.get(root)!;
    for (let id = start; parent.get(id) !== root; ) {
      const next = parent.get(id)!;
      parent.set(id, root);
      id = next;
    }
    return root;
  };
  for (const s of supports) {
    const [first, ...rest] = s.nodeIds;
    if (!first) continue;
    for (const id of rest) parent.set(find(id), find(first));
  }
  const parts = new Set(nodes.map((n) => find(n.id))).size;
  if (parts < 2) return [];
  return [
    {
      message: `the rack falls into ${parts} separate parts; nothing joins them`,
      rows: config.rows.flatMap((row, i) => (row.columns.some(isGap) ? [i] : [])),
      supportIds: [],
    },
  ];
}

/**
 * Beams shorter than two units between two connectors cannot be assembled (each arm needs a unit).
 * They arise when the dividers of neighbouring rows land close together on the frame between them.
 */
function shortBeamProblems(config: RackConfig, supports: RackSupport[]): RackProblem[] {
  const levels = frames(config);
  const rowName = (i: number) => config.rows[i]?.name?.trim() || `row ${i + 1}`;
  const frameTitle = (k: number) => (k === 0 ? "Bottom" : `Top of ${rowName(k - 1)}`);
  const byPair = new Map<string, RackProblem>();
  for (const s of supports) {
    if (s.length >= LIMITS.span.min) continue;
    if (s.axis !== "x") {
      byPair.set(s.id, {
        message: `${s.axis === "z" ? "Posts" : "Depth supports"} of ${s.length} unit cannot be assembled: two connectors need at least ${LIMITS.span.min} units between them`,
        rows: [],
        supportIds: [s.id],
      });
      continue;
    }
    const k = levels.findIndex((f) => f.z === s.from[2]);
    const a = s.from[0] - 1;
    const b = s.from[0] + s.length;
    const key = `${k}:${a}:${b}`;
    const existing = byPair.get(key);
    if (existing) {
      existing.supportIds.push(s.id);
      continue;
    }
    const owners = [k - 1, k].filter((i) => {
      const row = config.rows[i];
      if (!row) return false;
      const xs = rowBoundaries(row);
      return xs.includes(a) || xs.includes(b);
    });
    const names = [...new Set(owners.map(rowName))].join(" and ");
    byPair.set(key, {
      message: `${frameTitle(k)}: a ${s.length}-unit beam between x=${a} and x=${b}; the dividers of ${names} are too close, two connectors need at least ${LIMITS.span.min} units between them`,
      rows: owners,
      supportIds: [s.id],
    });
  }
  return [...byPair.values()];
}

export function buildModel(config: RackConfig): RackModel {
  const lattice = new Lattice();
  const ys = [0, config.depth + 1];
  const levels = frames(config);

  for (const frame of levels) {
    for (const y of ys) {
      for (const [a, b] of frame.beams) lattice.support("x", [0, y, frame.z], a, b);
    }
    for (const x of frame.xs) lattice.support("y", [x, 0, frame.z], 0, config.depth + 1);
  }

  config.rows.forEach((row, i) => {
    const bottom = levels[i]!.z;
    const top = levels[i + 1]!.z;
    for (const x of rowBoundaries(row)) for (const y of ys) lattice.support("z", [x, y, 0], bottom, top);
  });

  const throughZ = new Set(config.rows.flatMap((row, i) => (i > 0 && row.through ? [levels[i]!.z] : [])));
  if (throughZ.size > 0) lattice.mergeColumns("z", (z) => throughZ.has(z));

  if (config.feet) {
    for (const node of lattice.nodes.values()) {
      if (node.pos[2] === 0) {
        node.arms.add("-z");
        node.foot = true;
      }
    }
  }

  const maxX = Math.max(...levels.flatMap((f) => f.xs));
  const all = openings(config);
  const nodes = [...lattice.nodes.values()];
  return {
    config,
    nodes,
    supports: lattice.supports,
    openings: all,
    panels: buildPanels(config, all),
    problems: [...shortBeamProblems(config, lattice.supports), ...disconnectedProblems(config, nodes, lattice.supports)],
    extent: [maxX + 1, config.depth + 2, (levels[levels.length - 1]?.z ?? 0) + 1],
  };
}
