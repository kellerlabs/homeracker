import { AXIS_INDEX, dirVector, type Axis, type Dir, type RackModel, type RackPanel, type Vec3 } from "./types";

const AXES = ["x", "y", "z"] as const;

/**
 * Axis a lock pin follows when nothing else decides it. Supports are exported with holes across
 * both axes (`x_holes=true` in models/core/lib/support.scad), so either hole of a cell is open;
 * this is the one that reads naturally, vertical through a beam and front to back through a post.
 */
export const HOLE_AXIS: Record<Axis, Axis> = { x: "z", y: "z", z: "y" };

/** Which end of a lock pin is extended, one per panel hanging on it. */
export type PinExtension = "none" | "neck" | "tail" | "both";

/** `neck_extension` of models/core/parts/lockpin.scad. */
export const NECK_EXTENSION: Record<PinExtension, number> = { none: 0, neck: 1, both: 2, tail: 3 };

/** A lock pin of the frame: one per connector arm, in the outermost hole of the support there. */
export interface FramePin {
  /** Cell of the support the pin goes through. */
  cell: Vec3;
  /** Axis the pin runs along, the hole axis of that support. */
  axis: Axis;
  /** Which way along that axis the grip points, the side the pin is pushed in from. */
  grip: 1 | -1;
  extension: PinExtension;
}

/** A panel corner bracket bolted to a support, on the lock pin hole it shares with the frame. */
export interface PanelCorner {
  cell: Vec3;
  axis: Axis;
  /** Which way along that axis the bracket lies on the support, towards the opening. */
  side: 1 | -1;
}

const holeKey = (cell: Vec3, axis: Axis) => `${cell[0]},${cell[1]},${cell[2]}:${axis}`;

/**
 * The corner brackets of a panel, two per corner. Each one lies on the face a bounding support
 * turns towards the opening, in the outermost cell of that support, where its hole falls on the
 * same hole of the support that the connector arm beside it uses (mount_corner in panel.scad).
 */
export function panelCorners(panel: RackPanel): PanelCorner[] {
  const n = AXIS_INDEX[panel.normal[1] as Axis];
  const [l, h] = ([0, 1, 2] as const).filter((i) => i !== n) as [number, number];
  const corners: PanelCorner[] = [];
  // Once per edge direction: the supports that bound the opening across it carry the brackets.
  for (const [along, across, ends, width] of [
    [l, h, panel.unitsX, panel.unitsY],
    [h, l, panel.unitsY, panel.unitsX],
  ] as const) {
    for (const [at, side] of [
      [panel.origin[across]!, 1],
      [panel.origin[across]! + width + 1, -1],
    ] as const) {
      for (const end of [panel.origin[along]! + 1, panel.origin[along]! + ends]) {
        const cell: [number, number, number] = [0, 0, 0];
        cell[n] = panel.origin[n]!;
        cell[along] = end;
        cell[across] = at;
        corners.push({ cell, axis: AXES[across]!, side });
      }
    }
  }
  return corners;
}

/** Every lock pin hole in the rack a panel corner bracket hangs on, and from which side. */
export function cornerSides(panels: readonly RackPanel[]): Map<string, Set<number>> {
  const sides = new Map<string, Set<number>>();
  for (const panel of panels) {
    for (const corner of panelCorners(panel)) {
      const key = holeKey(corner.cell, corner.axis);
      const at = sides.get(key) ?? new Set<number>();
      at.add(corner.side);
      sides.set(key, at);
    }
  }
  return sides;
}

/**
 * Every lock pin of the frame, one per connector arm, feet included: a foot plugs into the arm like
 * a support and is locked the same way (models/foot/README.md). A pin follows the hole axis of the support in that arm and is pushed
 * in from the inside of the rack, so its grip stays out of the way of panels and of whatever stands
 * next to the rack. Where a panel corner bracket shares the hole the pin has to reach through it:
 * the neck when the bracket is on the side the pin goes in from, the tail when it is on the far
 * side, both when a panel hangs on either side (models/panel/README.md, "When to use corner mounts").
 */
export function framePins(model: RackModel): FramePin[] {
  const sides = cornerSides(model.panels);
  const centre = [model.extent[0] / 2, model.extent[1] / 2, model.extent[2] / 2];
  const pins: FramePin[] = [];
  for (const node of model.nodes) {
    for (const arm of node.arms) {
      const step = dirVector(arm);
      const cell: Vec3 = [node.pos[0] + step[0], node.pos[1] + step[1], node.pos[2] + step[2]];
      const support = arm[1] as Axis;
      const preferred = HOLE_AXIS[support];
      const options = [preferred, ...AXES.filter((a) => a !== support && a !== preferred)].map((axis) => {
        const i = AXIS_INDEX[axis];
        const grip = -(Math.sign(cell[i] + 0.5 - centre[i]!) || 1) as 1 | -1;
        const at = sides.get(holeKey(cell, axis));
        const neck = at?.has(grip) ?? false;
        const tail = at?.has(-grip) ?? false;
        const extension: PinExtension = neck && tail ? "both" : neck ? "neck" : tail ? "tail" : "none";
        return { pin: { cell, axis, grip, extension }, holds: (neck ? 1 : 0) + (tail ? 1 : 0) };
      });
      // The two holes of a cell cross in its middle, so only one of them can take a pin: give it to
      // the one that holds the most panel brackets, and otherwise leave it where it reads naturally.
      pins.push(options.reduce((best, option) => (option.holds > best.holds ? option : best)).pin);
    }
  }
  return pins;
}

/** Direction a lock pin's grip points. */
export function gripDir(pin: FramePin): Dir {
  return `${pin.grip > 0 ? "+" : "-"}${pin.axis}` as Dir;
}

/** Name of a lock pin in the exported part library. */
export function lockpinPart(extension: PinExtension): string {
  return extension === "none" ? "lockpin" : `lockpin-${extension}`;
}
