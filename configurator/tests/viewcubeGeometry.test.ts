import { describe, expect, test } from "vitest";
import { chamferedCube } from "../src/render/viewcubeGeometry";

const HALF = 0.5;
const CHAMFER = 0.15;
const facets = chamferedCube(HALF, CHAMFER);

/** Outward normal of one triangle, from three flat position triples. */
function normalOf(p: number[], t: number): [number, number, number] {
  const at = (i: number) => [p[t + i * 3]!, p[t + i * 3 + 1]!, p[t + i * 3 + 2]!] as const;
  const [a, b, c] = [at(0), at(1), at(2)];
  const u = [b[0] - a[0], b[1] - a[1], b[2] - a[2]];
  const v = [c[0] - a[0], c[1] - a[1], c[2] - a[2]];
  return [u[1]! * v[2]! - u[2]! * v[1]!, u[2]! * v[0]! - u[0]! * v[2]!, u[0]! * v[1]! - u[1]! * v[0]!];
}

describe("chamferedCube", () => {
  test("cuts a cube into six labelled faces and eight corners", () => {
    expect(facets).toHaveLength(14);
    expect(facets.filter((f) => f.labelled).map((f) => f.id)).toEqual(["front", "back", "right", "left", "top", "bottom"]);
    expect(facets.filter((f) => !f.labelled)).toHaveLength(8);
  });

  test("every corner facet names the three faces that meet there, and all eight are distinct", () => {
    const corners = facets.filter((f) => !f.labelled);
    for (const corner of corners) expect(corner.faces).toHaveLength(3);
    expect(new Set(corners.map((c) => c.id)).size).toBe(8);
    expect(corners.some((c) => c.id === "right+front+top")).toBe(true);
    expect(corners.some((c) => c.id === "left+back+bottom")).toBe(true);
  });

  test("a face is an octagon drawn as six triangles, a corner is one triangle", () => {
    for (const facet of facets) {
      const vertices = facet.positions.length / 3;
      expect(vertices).toBe(facet.labelled ? 18 : 3);
      expect(facet.uvs.length / 2).toBe(vertices);
    }
  });

  test("every triangle faces outwards", () => {
    for (const facet of facets) {
      for (let t = 0; t < facet.positions.length; t += 9) {
        const n = normalOf(facet.positions, t);
        const dot = n[0] * facet.direction[0] + n[1] * facet.direction[1] + n[2] * facet.direction[2];
        expect(dot).toBeGreaterThan(0);
      }
    }
  });

  test("no vertex escapes the cube, and a face's own axis stays on its plane", () => {
    for (const facet of facets) {
      for (let i = 0; i < facet.positions.length; i += 3) {
        const p = [facet.positions[i]!, facet.positions[i + 1]!, facet.positions[i + 2]!];
        for (const c of p) expect(Math.abs(c)).toBeLessThanOrEqual(HALF + 1e-9);
      }
      if (!facet.labelled) continue;
      const axis = facet.direction.findIndex((d) => d !== 0);
      for (let i = 0; i < facet.positions.length; i += 3) {
        expect(facet.positions[i + axis]).toBeCloseTo(facet.direction[axis]! * HALF, 9);
      }
    }
  });

  test("the label fills the whole square, so the chamfer only clips its corners", () => {
    const front = facets.find((f) => f.id === "front")!;
    const us = front.uvs.filter((_, i) => i % 2 === 0);
    const vs = front.uvs.filter((_, i) => i % 2 === 1);
    expect(Math.min(...us)).toBeCloseTo(0, 9);
    expect(Math.max(...us)).toBeCloseTo(1, 9);
    expect(Math.min(...vs)).toBeCloseTo(0, 9);
    expect(Math.max(...vs)).toBeCloseTo(1, 9);
  });

  test("a bigger chamfer eats further into the faces", () => {
    const small = chamferedCube(HALF, 0.05).find((f) => f.id === "right+front+top")!;
    const big = chamferedCube(HALF, 0.2).find((f) => f.id === "right+front+top")!;
    const spread = (f: { positions: number[] }) => Math.hypot(f.positions[0]! - f.positions[3]!, f.positions[1]! - f.positions[4]!, f.positions[2]! - f.positions[5]!);
    expect(spread(big)).toBeGreaterThan(spread(small));
  });
});
