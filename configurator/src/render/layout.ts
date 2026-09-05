import { AXIS_INDEX, dirVector, type Axis, type RackModel, type RackPanel, type Vec3 } from "../engine/types";

export type BoxKind = "support" | "core" | "core-pullthrough" | "arm" | "foot" | "panel";

export interface Box {
  kind: BoxKind;
  center: Vec3;
  size: Vec3;
  /** Parts-list key of the part this box belongs to, when it maps to one line. */
  key?: string;
}

const ARM_INSET = 0.9;
const PANEL_THICKNESS = 0.15;
const FOOT_SIZE: Vec3 = [1.3, 1.3, 0.2];

function cellCenter(pos: Vec3): Vec3 {
  return [pos[0] + 0.5, pos[1] + 0.5, pos[2] + 0.5];
}

function panelBox(panel: RackPanel): Box {
  const normal = dirVector(panel.normal);
  const axis = AXIS_INDEX[panel.normal[1] as Axis];
  const sign = normal[axis];
  const plane = sign > 0 ? panel.origin[axis] + 1 : panel.origin[axis];
  const offset = (panel.type === "interfit" ? -sign : sign) * (PANEL_THICKNESS / 2);
  const center: [number, number, number] = [0, 0, 0];
  const size: [number, number, number] = [0, 0, 0];
  center[axis] = plane + offset;
  size[axis] = PANEL_THICKNESS;
  const inPlane = ([0, 1, 2] as const).filter((i) => i !== axis);
  const spans = [panel.unitsX, panel.unitsY];
  inPlane.forEach((i, k) => {
    const span = spans[k] ?? 0;
    center[i] = panel.origin[i] + 1 + span / 2;
    size[i] = span;
  });
  const key = panel.blocked
    ? `panel:${panel.unitsX}x${panel.unitsY}:${panel.type}:blocked`
    : `panel:${panel.unitsX}x${panel.unitsY}:${panel.type}`;
  return { kind: "panel", center, size, key };
}

export function rackBoxes(model: RackModel): Box[] {
  const boxes: Box[] = [];

  for (const s of model.supports) {
    const center = cellCenter(s.from) as [number, number, number];
    const size: [number, number, number] = [1, 1, 1];
    const i = AXIS_INDEX[s.axis];
    center[i] = s.from[i] + s.length / 2;
    size[i] = s.length;
    boxes.push({ kind: "support", center, size, key: `support:${s.length}` });
  }

  for (const n of model.nodes) {
    const core = cellCenter(n.pos);
    boxes.push({ kind: n.pullThrough === "none" ? "core" : "core-pullthrough", center: core, size: [1, 1, 1] });
    for (const arm of n.arms) {
      const v = dirVector(arm);
      boxes.push({
        kind: "arm",
        center: [core[0] + v[0], core[1] + v[1], core[2] + v[2]],
        size: [ARM_INSET, ARM_INSET, ARM_INSET],
      });
    }
    if (n.foot) {
      boxes.push({ kind: "foot", center: [core[0], core[1], n.pos[2] - 1 - FOOT_SIZE[2] / 2], size: FOOT_SIZE });
    }
  }

  for (const p of model.panels) boxes.push(panelBox(p));
  return boxes;
}
