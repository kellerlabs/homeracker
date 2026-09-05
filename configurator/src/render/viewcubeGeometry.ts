import type { Vec3 } from "../engine/types";
import type { CubeFace, CubeZone } from "./viewcube";

/** One flat surface of the cube: a labelled octagon, or a triangle where a corner was cut off. */
export interface CubeFacet extends CubeZone {
  /** Triangle corners in the cube's own space, three numbers per vertex. */
  positions: number[];
  /** Texture coordinates, two per vertex. Corner facets carry no label, but keep the array aligned. */
  uvs: number[];
  /** True for the six labelled faces, false for the eight corners. */
  labelled: boolean;
}

/**
 * In-plane axes of each face, chosen so a label drawn on it reads upright when that face is
 * viewed head on with z up. Each pair is right handed with the outward normal, so listing a
 * polygon anticlockwise in (u, v) also winds it outwards.
 */
const FACES: { face: CubeFace; normal: Vec3; u: Vec3; v: Vec3 }[] = [
  { face: "front", normal: [0, -1, 0], u: [1, 0, 0], v: [0, 0, 1] },
  { face: "back", normal: [0, 1, 0], u: [-1, 0, 0], v: [0, 0, 1] },
  { face: "right", normal: [1, 0, 0], u: [0, 1, 0], v: [0, 0, 1] },
  { face: "left", normal: [-1, 0, 0], u: [0, -1, 0], v: [0, 0, 1] },
  { face: "top", normal: [0, 0, 1], u: [1, 0, 0], v: [0, 1, 0] },
  { face: "bottom", normal: [0, 0, -1], u: [1, 0, 0], v: [0, -1, 0] },
];

const axisFace = (sign: number, negative: CubeFace, positive: CubeFace): CubeFace => (sign > 0 ? positive : negative);

/**
 * A cube with its eight corners cut off: six octagonal faces and eight corner triangles,
 * fourteen facets for the fourteen views the gizmo offers. `chamfer` is how far the cut
 * reaches back along each edge from a corner.
 */
export function chamferedCube(half: number, chamfer: number): CubeFacet[] {
  const inner = half - chamfer;
  const facets: CubeFacet[] = [];

  for (const { face, normal, u, v } of FACES) {
    // The octagon, anticlockwise in (u, v): a square with its four corners cut back to `inner`.
    const ring: [number, number][] = [
      [inner, half],
      [-inner, half],
      [-half, inner],
      [-half, -inner],
      [-inner, -half],
      [inner, -half],
      [half, -inner],
      [half, inner],
    ];
    const at = (i: number): Vec3 => {
      const [du, dv] = ring[i]!;
      return [
        normal[0] * half + u[0] * du + v[0] * dv,
        normal[1] * half + u[1] * du + v[1] * dv,
        normal[2] * half + u[2] * du + v[2] * dv,
      ];
    };
    const uvAt = (i: number): [number, number] => {
      const [du, dv] = ring[i]!;
      return [(du + half) / (2 * half), (dv + half) / (2 * half)];
    };
    const positions: number[] = [];
    const uvs: number[] = [];
    // Fan from the first vertex: six triangles cover the octagon.
    for (let i = 1; i + 1 < ring.length; i++) {
      for (const index of [0, i, i + 1]) {
        positions.push(...at(index));
        uvs.push(...uvAt(index));
      }
    }
    facets.push({ faces: [face], direction: normal, id: face, positions, uvs, labelled: true });
  }

  for (const sx of [1, -1]) {
    for (const sy of [1, -1]) {
      for (const sz of [1, -1]) {
        const a: Vec3 = [sx * inner, sy * half, sz * half];
        const b: Vec3 = [sx * half, sy * inner, sz * half];
        const c: Vec3 = [sx * half, sy * half, sz * inner];
        // Wind the triangle so its normal points away from the middle of the cube.
        const corners = sx * sy * sz > 0 ? [a, b, c] : [a, c, b];
        const faces: CubeFace[] = [axisFace(sx, "left", "right"), axisFace(sy, "front", "back"), axisFace(sz, "bottom", "top")];
        facets.push({
          faces,
          direction: [sx, sy, sz],
          id: faces.join("+"),
          positions: corners.flat(),
          uvs: [0.5, 0.5, 0.5, 0.5, 0.5, 0.5],
          labelled: false,
        });
      }
    }
  }

  return facets;
}
