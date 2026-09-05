import { describe, expect, test } from "vitest";
import { cameraPositionFor, FACE_DIRECTION, FACE_LABEL, gizmoBox, gizmoNdc } from "../src/render/viewcube";

describe("FACE_DIRECTION", () => {
  test("follows the rack's axes: z up, the front face looks along -y", () => {
    expect(FACE_DIRECTION.front).toEqual([0, -1, 0]);
    expect(FACE_DIRECTION.back).toEqual([0, 1, 0]);
    expect(FACE_DIRECTION.left).toEqual([-1, 0, 0]);
    expect(FACE_DIRECTION.right).toEqual([1, 0, 0]);
    expect(FACE_DIRECTION.top).toEqual([0, 0, 1]);
    expect(FACE_DIRECTION.bottom).toEqual([0, 0, -1]);
  });

  test("labels match the names the face drawings use", () => {
    expect(FACE_LABEL.front).toBe("FRONT");
    expect(FACE_LABEL.bottom).toBe("BOTTOM");
  });
});

describe("cameraPositionFor", () => {
  test("stands the camera one distance away along the direction", () => {
    expect(cameraPositionFor(FACE_DIRECTION.front, [10, 4, 6], 20)).toEqual([10, -16, 6]);
    expect(cameraPositionFor(FACE_DIRECTION.back, [10, 4, 6], 20)).toEqual([10, 24, 6]);
    expect(cameraPositionFor(FACE_DIRECTION.right, [10, 4, 6], 20)).toEqual([30, 4, 6]);
    expect(cameraPositionFor(FACE_DIRECTION.left, [10, 4, 6], 20)).toEqual([-10, 4, 6]);
  });

  test("tips the top and bottom views a hair to the front, so the orbit azimuth stays defined", () => {
    const [x, y, z] = cameraPositionFor(FACE_DIRECTION.top, [0, 0, 0], 10);
    expect(x).toBe(0);
    expect(Math.hypot(x, y, z)).toBeCloseTo(10, 6);
    expect(y).toBeLessThan(0);
    expect(y).toBeGreaterThan(-1);
    expect(z).toBeGreaterThan(9.9);

    const below = cameraPositionFor(FACE_DIRECTION.bottom, [0, 0, 0], 10);
    expect(below[2]).toBeLessThan(-9.9);
    expect(below[1]).toBeLessThan(0);
  });

  test("a corner needs no tilt: it is already off both poles", () => {
    const p = cameraPositionFor([1, -1, 1], [0, 0, 0], 12);
    const leg = 12 / Math.sqrt(3);
    expect(p[0]).toBeCloseTo(leg, 6);
    expect(p[1]).toBeCloseTo(-leg, 6);
    expect(p[2]).toBeCloseTo(leg, 6);
  });

  test("keeps the distance exact for every face and corner", () => {
    const target: [number, number, number] = [3, -2, 7];
    const directions = [...Object.values(FACE_DIRECTION), [1, -1, 1], [-1, 1, -1]] as [number, number, number][];
    for (const direction of directions) {
      const p = cameraPositionFor(direction, target, 12);
      expect(Math.hypot(p[0] - target[0], p[1] - target[1], p[2] - target[2])).toBeCloseTo(12, 6);
    }
  });
});

describe("gizmoBox", () => {
  test("sits inset from the top right corner", () => {
    expect(gizmoBox(800)).toEqual({ x: 800 - 96 - 12, y: 12, size: 96 });
  });

  test("shrinks on a narrow canvas", () => {
    expect(gizmoBox(320).size).toBe(72);
  });
});

describe("gizmoNdc", () => {
  const box = { x: 100, y: 10, size: 100 };

  test("maps a point in the box to normalised device coordinates, y up", () => {
    expect(gizmoNdc(box, 150, 60)).toEqual([0, 0]);
    expect(gizmoNdc(box, 100, 10)).toEqual([-1, 1]);
    expect(gizmoNdc(box, 200, 110)).toEqual([1, -1]);
  });

  test("is null outside the box", () => {
    expect(gizmoNdc(box, 50, 60)).toBeNull();
    expect(gizmoNdc(box, 150, 200)).toBeNull();
  });
});
