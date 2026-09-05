import { AXIS_INDEX, type Axis, type Dir } from "./types";

/** Canonical arm sets of every connector type, in the order of CONNECTOR_CONFIGS in connector.scad. */
export const CANONICAL_ARMS = {
  "1D1W": ["+z"],
  "1D2W": ["+z", "-z"],
  "2D2W": ["+z", "+x"],
  "2D3W": ["+z", "-z", "+x"],
  "2D4W": ["+z", "-z", "+x", "-x"],
  "3D3W": ["+z", "+x", "+y"],
  "3D4W": ["+z", "-z", "+x", "+y"],
  "3D5W": ["+z", "-z", "+x", "-x", "+y"],
  "3D6W": ["+z", "-z", "+x", "-x", "+y", "-y"],
} as const satisfies Record<string, readonly Dir[]>;

export type ConnectorLabel = keyof typeof CANONICAL_ARMS;

/** 3x3 rotation matrix, row major. Entries are -1, 0 or 1. */
export type Rotation = readonly (readonly number[])[];

const AXES: Axis[] = ["x", "y", "z"];

function vectorOf(dir: Dir): number[] {
  const v = [0, 0, 0];
  v[AXIS_INDEX[dir[1] as Axis]] = dir[0] === "+" ? 1 : -1;
  return v;
}

function dirOf(v: number[]): Dir {
  const i = v.findIndex((c) => c !== 0);
  return `${v[i]! > 0 ? "+" : "-"}${AXES[i]}` as Dir;
}

export function applyRotation(r: Rotation, dir: Dir): Dir {
  const v = vectorOf(dir);
  return dirOf(r.map((row) => row[0]! * v[0]! + row[1]! * v[1]! + row[2]! * v[2]!));
}

/** The 24 rotations of a cube: signed permutation matrices with determinant +1. */
function cubeRotations(): Rotation[] {
  const perms = [
    [0, 1, 2],
    [0, 2, 1],
    [1, 0, 2],
    [1, 2, 0],
    [2, 0, 1],
    [2, 1, 0],
  ];
  const out: Rotation[] = [];
  for (const p of perms) {
    for (const s0 of [1, -1]) {
      for (const s1 of [1, -1]) {
        for (const s2 of [1, -1]) {
          const m = [0, 1, 2].map((row) => {
            const line = [0, 0, 0];
            line[p[row]!] = [s0, s1, s2][row]!;
            return line;
          });
          const det =
            m[0]![0]! * (m[1]![1]! * m[2]![2]! - m[1]![2]! * m[2]![1]!) -
            m[0]![1]! * (m[1]![0]! * m[2]![2]! - m[1]![2]! * m[2]![0]!) +
            m[0]![2]! * (m[1]![0]! * m[2]![1]! - m[1]![1]! * m[2]![0]!);
          if (det === 1) out.push(m);
        }
      }
    }
  }
  return out;
}

const ROTATIONS = cubeRotations();

export function connectorLabelOf(arms: ReadonlySet<Dir>): ConnectorLabel {
  const dims = new Set([...arms].map((d) => d[1])).size;
  return `${dims}D${arms.size}W` as ConnectorLabel;
}

/** Canonical pull-through axes a connector type can be exported with: every axis that has both arms. */
export function canonicalPullAxes(label: ConnectorLabel): Axis[] {
  const arms = new Set<Dir>(CANONICAL_ARMS[label]);
  return AXES.filter((a) => arms.has(`+${a}`) && arms.has(`-${a}`));
}

export interface ConnectorOrientation {
  rotation: Rotation;
  /** Pull-through axis of the canonical mesh to use, before rotation. */
  variant: Axis | "none";
}

const orientCache = new Map<string, ConnectorOrientation>();

/** Rotation (and mesh variant) that maps the canonical connector onto a node's arms and pull-through axis. */
export function orientConnector(arms: ReadonlySet<Dir>, pull: Axis | "none"): ConnectorOrientation {
  const sorted = [...arms].sort();
  const cacheKey = `${sorted.join(",")}:${pull}`;
  const cached = orientCache.get(cacheKey);
  if (cached) return cached;
  const label = connectorLabelOf(arms);
  const canonical = CANONICAL_ARMS[label];
  if (!canonical) throw new Error(`no connector for arms ${sorted.join(",")}`);
  const variants: (Axis | "none")[] = pull === "none" ? ["none"] : canonicalPullAxes(label);
  for (const rotation of ROTATIONS) {
    const rotated = new Set(canonical.map((d) => applyRotation(rotation, d)));
    if (rotated.size !== arms.size || [...arms].some((d) => !rotated.has(d))) continue;
    for (const variant of variants) {
      if (variant === "none" || applyRotation(rotation, `+${variant}`)[1] === pull) {
        const result = { rotation, variant };
        orientCache.set(cacheKey, result);
        return result;
      }
    }
  }
  throw new Error(`no rotation maps ${label} onto ${sorted.join(",")} with pull-through ${pull}`);
}

export function rotationFor(arms: ReadonlySet<Dir>, pull: Axis | "none"): Rotation {
  return orientConnector(arms, pull).rotation;
}
