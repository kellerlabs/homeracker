import { describe, expect, test } from "vitest";
import { CANONICAL_ARMS, applyRotation, rotationFor, type Rotation } from "../src/engine/orientation";
import type { Dir } from "../src/engine/types";

const arms = (...dirs: Dir[]) => new Set<Dir>(dirs);
const rotate = (r: Rotation, dirs: readonly Dir[]) => new Set(dirs.map((d) => applyRotation(r, d)));

describe("CANONICAL_ARMS", () => {
  test("mirrors CONNECTOR_CONFIGS from connector.scad", () => {
    expect(CANONICAL_ARMS["3D4W"]).toEqual(["+z", "-z", "+x", "+y"]);
    expect(CANONICAL_ARMS["2D2W"]).toEqual(["+z", "+x"]);
    expect(Object.keys(CANONICAL_ARMS)).toHaveLength(9);
  });
});

describe("applyRotation", () => {
  test("identity keeps a direction", () => {
    const r = rotationFor(arms("+z", "+x", "+y"), "none");
    expect(applyRotation(r, "+x")).toBe("+x");
  });
});

describe("rotationFor", () => {
  test("returns the identity for canonical arms", () => {
    expect(rotationFor(arms("+z", "-z", "+x", "+y"), "none")).toEqual([
      [1, 0, 0],
      [0, 1, 0],
      [0, 0, 1],
    ]);
  });

  test("maps the canonical arms onto rotated arm sets", () => {
    const cases: Dir[][] = [
      ["-z", "-x", "-y"],
      ["+x", "-x", "+y"],
      ["+y", "-y", "+z", "-x"],
      ["+x", "-x", "+y", "-y", "-z"],
      ["-z"],
      ["+y", "-y"],
    ];
    for (const target of cases) {
      const r = rotationFor(arms(...target), "none");
      const label = `${new Set(target.map((d) => d[1])).size}D${target.length}W` as keyof typeof CANONICAL_ARMS;
      expect(rotate(r, CANONICAL_ARMS[label])).toEqual(new Set(target));
    }
  });

  test("keeps the pull-through axis aligned", () => {
    const r = rotationFor(arms("+x", "-x", "+y", "+z"), "x");
    expect(rotate(r, CANONICAL_ARMS["3D4W"])).toEqual(arms("+x", "-x", "+y", "+z"));
    expect(new Set([applyRotation(r, "+z"), applyRotation(r, "-z")])).toEqual(arms("+x", "-x"));
  });

  test("is a proper rotation, never a mirror", () => {
    const r = rotationFor(arms("-x", "+y", "+z"), "none");
    const det =
      r[0]![0]! * (r[1]![1]! * r[2]![2]! - r[1]![2]! * r[2]![1]!) -
      r[0]![1]! * (r[1]![0]! * r[2]![2]! - r[1]![2]! * r[2]![0]!) +
      r[0]![2]! * (r[1]![0]! * r[2]![1]! - r[1]![1]! * r[2]![0]!);
    expect(det).toBe(1);
  });

  test("throws when no rotation fits", () => {
    expect(() => rotationFor(arms("+z", "-z", "+x", "+y"), "x")).toThrow(/rotation/);
  });
});
