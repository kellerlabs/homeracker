import type { Vec3 } from "../engine/types";

/** The six faces of the orientation cube, named as the face drawings name them. */
export type CubeFace = "front" | "back" | "left" | "right" | "top" | "bottom";

/** Outward normal of each face in rack coordinates: z is up and the front of a rack looks along -y. */
export const FACE_DIRECTION: Record<CubeFace, Vec3> = {
  front: [0, -1, 0],
  back: [0, 1, 0],
  left: [-1, 0, 0],
  right: [1, 0, 0],
  top: [0, 0, 1],
  bottom: [0, 0, -1],
};

export const FACE_LABEL: Record<CubeFace, string> = {
  front: "FRONT",
  back: "BACK",
  left: "LEFT",
  right: "RIGHT",
  top: "TOP",
  bottom: "BOTTOM",
};

/** A clickable region of the cube: one face, or a corner where three of them meet. */
export interface CubeZone {
  /** The faces that meet here: one for a face, three for a corner. */
  faces: CubeFace[];
  /** Which way to look from, each component -1, 0 or 1. */
  direction: Vec3;
  id: string;
}

/** Side of the gizmo in css pixels, and how far it sits from the corner. */
export const GIZMO_SIZE = 96;
export const GIZMO_SIZE_NARROW = 72;
export const GIZMO_INSET = 12;
/** Below this canvas width the gizmo takes its smaller size. */
export const NARROW_CANVAS = 480;

/** Where the gizmo sits on the canvas, in css pixels from the top left. */
export interface GizmoBox {
  x: number;
  y: number;
  size: number;
}

export function gizmoBox(width: number): GizmoBox {
  const size = width < NARROW_CANVAS ? GIZMO_SIZE_NARROW : GIZMO_SIZE;
  return { x: width - size - GIZMO_INSET, y: GIZMO_INSET, size };
}

/** A pointer inside the gizmo in normalised device coordinates (y up); null when it is outside. */
export function gizmoNdc(box: GizmoBox, px: number, py: number): [number, number] | null {
  const u = (px - box.x) / box.size;
  const v = (py - box.y) / box.size;
  if (u < 0 || u > 1 || v < 0 || v > 1) return null;
  return [u * 2 - 1, 1 - v * 2];
}

/**
 * Looking straight down the up axis leaves an orbit camera's azimuth undefined, so the top and
 * bottom views are tipped a hair towards the front. A corner is already off both poles.
 */
const POLE_TILT = 0.02;

/** Where the camera stands to look at `target` from `direction`, keeping `distance`. */
export function cameraPositionFor(direction: Vec3, target: Vec3, distance: number): Vec3 {
  const [dx, dy, dz] = direction;
  const y = dx === 0 && dy === 0 ? dy - POLE_TILT : dy;
  const length = Math.hypot(dx, y, dz);
  return [target[0] + (dx / length) * distance, target[1] + (y / length) * distance, target[2] + (dz / length) * distance];
}
