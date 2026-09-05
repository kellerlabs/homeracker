/**
 * Geometry for the optional scale reference drawn beside the rack: an object of a length
 * everyone already has a feel for, so the rack's size reads without measuring. Kept as plain
 * arrays here so the shape can be tested without a renderer.
 */

/** 12 units is 180 mm at 15 mm per unit, the length the reference is meant to be. */
export const SCALE_REFERENCE_UNITS = 12;

export interface SweptShape {
  /** Three numbers per vertex. */
  positions: number[];
  /** Three indices per triangle. */
  indices: number[];
}

/** How far the ends rise above the middle, and how fat the middle gets, both relative to length. */
const BOW = 0.15;
const GIRTH = 0.095;
/** Below 1 the taper stays full for longer before pinching; the ends still close to a point. */
const TAPER = 0.55;

/**
 * A tube swept along a shallow arc that dips in the middle and lifts at both ends, tapering to a
 * point at each tip. Built so local z = 0 is the surface it rests on, and it is centred on x.
 */
export function sweptReference(length: number, rings = 28, sides = 14): SweptShape {
  const girth = length * GIRTH;
  const bow = length * BOW;
  const positions: number[] = [];
  const indices: number[] = [];

  for (let i = 0; i < rings; i++) {
    const t = i / (rings - 1);
    const along = 2 * t - 1;
    const centre = [length * (t - 0.5), 0, girth + bow * along * along];
    // Tangent of that curve: d/dt of (length * (t - 0.5), 0, bow * (2t - 1)^2).
    const tangent = [length, 0, bow * 4 * along];
    const scale = Math.hypot(tangent[0]!, tangent[2]!);
    const tx = tangent[0]! / scale;
    const tz = tangent[2]! / scale;
    // The curve stays in the x-z plane, so y is a constant normal and the frame never twists.
    // 4t(1-t) peaks at 1 in the middle and is exactly 0 at both ends, so the tips truly close.
    const radius = girth * (4 * t * (1 - t)) ** TAPER;
    for (let j = 0; j < sides; j++) {
      const angle = (j / sides) * Math.PI * 2;
      const across = Math.cos(angle) * radius;
      const up = Math.sin(angle) * radius;
      // Ring point: centre + across * y + up * (tangent turned a quarter turn in the x-z plane).
      positions.push(centre[0]! + up * -tz, centre[1]! + across, centre[2]! + up * tx);
    }
  }

  for (let i = 0; i + 1 < rings; i++) {
    for (let j = 0; j < sides; j++) {
      const next = (j + 1) % sides;
      const a = i * sides + j;
      const b = i * sides + next;
      const c = (i + 1) * sides + j;
      const d = (i + 1) * sides + next;
      indices.push(a, c, b, b, c, d);
    }
  }

  return { positions, indices };
}
