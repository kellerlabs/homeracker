import { describe, expect, test } from "vitest";
import { SCALE_REFERENCE_UNITS, sweptReference } from "../src/render/scaleReference";

const RINGS = 28;
const SIDES = 14;
const LENGTH = SCALE_REFERENCE_UNITS;
const shape = sweptReference(LENGTH, RINGS, SIDES);

const vertex = (i: number) => [shape.positions[i * 3]!, shape.positions[i * 3 + 1]!, shape.positions[i * 3 + 2]!];
const ring = (i: number) => Array.from({ length: SIDES }, (_, j) => vertex(i * SIDES + j));

describe("sweptReference", () => {
  test("is 12 units long, which is 180 mm at 15 mm per unit", () => {
    expect(SCALE_REFERENCE_UNITS).toBe(12);
    const xs = shape.positions.filter((_, i) => i % 3 === 0);
    expect(Math.min(...xs)).toBeCloseTo(-LENGTH / 2, 9);
    expect(Math.max(...xs)).toBeCloseTo(LENGTH / 2, 9);
  });

  test("builds one ring per step and two triangles per quad", () => {
    expect(shape.positions.length / 3).toBe(RINGS * SIDES);
    expect(shape.indices.length).toBe((RINGS - 1) * SIDES * 6);
    expect(Math.max(...shape.indices)).toBeLessThan(RINGS * SIDES);
  });

  test("tapers to a point at both tips", () => {
    for (const end of [ring(0), ring(RINGS - 1)]) {
      const [first] = end;
      for (const point of end) {
        expect(point[0]).toBeCloseTo(first![0]!, 9);
        expect(point[1]).toBeCloseTo(first![1]!, 9);
        expect(point[2]).toBeCloseTo(first![2]!, 9);
      }
    }
  });

  test("is fattest in the middle", () => {
    const spread = (i: number) => {
      const ys = ring(i).map((p) => p[1]!);
      return Math.max(...ys) - Math.min(...ys);
    };
    const middle = spread(Math.floor(RINGS / 2));
    expect(middle).toBeGreaterThan(spread(3));
    expect(spread(3)).toBeGreaterThan(spread(0));
  });

  test("dips in the middle and lifts at the ends, and never sinks below what it rests on", () => {
    const zs = shape.positions.filter((_, i) => i % 3 === 2);
    expect(Math.min(...zs)).toBeGreaterThanOrEqual(-1e-9);
    const middleZ = ring(Math.floor(RINGS / 2)).map((p) => p[2]!);
    const endZ = ring(0).map((p) => p[2]!);
    expect(Math.min(...middleZ)).toBeLessThan(Math.min(...endZ));
  });

  test("scales with the length it is asked for", () => {
    const big = sweptReference(LENGTH * 2, RINGS, SIDES);
    const xs = big.positions.filter((_, i) => i % 3 === 0);
    expect(Math.max(...xs) - Math.min(...xs)).toBeCloseTo(LENGTH * 2, 9);
  });
});
