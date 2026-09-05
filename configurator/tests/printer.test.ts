import { describe, expect, test } from "vitest";
import { computeBom } from "../src/engine/bom";
import { buildModel } from "../src/engine/model";
import { closeFace } from "../src/engine/panels";
import { DEFAULT_BED, fitsBed, unprintable } from "../src/engine/printer";
import { exampleA, exampleB } from "./fixtures";

describe("fitsBed", () => {
  test("accepts a part in any axis-aligned orientation", () => {
    expect(fitsBed([15, 15, 240], { x: 256, y: 256, z: 256 })).toBe(true);
    expect(fitsBed([240, 15, 15], { x: 100, y: 100, z: 250 })).toBe(true);
  });

  test("rejects a part longer than the longest bed axis", () => {
    expect(fitsBed([15, 15, 300], DEFAULT_BED)).toBe(false);
    expect(fitsBed([257, 100, 10], DEFAULT_BED)).toBe(false);
  });

  test("the default bed is 256 mm cubed", () => {
    expect(DEFAULT_BED).toEqual({ x: 256, y: 256, z: 256 });
  });
});

describe("bill of materials part sizes", () => {
  const bom = computeBom(buildModel(closeFace(exampleB, "front", "fullcover")));
  const size = (key: string) => bom.lines.find((l) => l.key === key)?.size;

  test("supports are one unit square by their length", () => {
    expect(size("support:10")).toEqual([15, 15, 150]);
  });

  test("connectors span their arms", () => {
    // 3D3W: one arm per axis -> 9.6 + 22.5 on every axis
    expect(size("connector:3D3W:none")).toEqual([32.1, 32.1, 32.1]);
    // 3D4W with both z arms: 45 on z
    expect(size("connector:3D4W:none")).toEqual([32.1, 32.1, 45]);
  });

  test("lock pins, feet and panels have their model sizes", () => {
    expect(size("lockpin:frame")).toEqual([8, 22.1, 3.8]);
    expect(size("foot")).toEqual([19.2, 19.2, 17.1]);
    // full cover 6x5: plate (6*15+15) x (5*15+15), height 2 + 17.2
    expect(size("panel:6x5:fullcover")).toEqual([105, 90, 19.2]);
  });

  test("inter-fit panels are smaller than their opening", () => {
    const interfit = computeBom(buildModel(closeFace(exampleA, "front", "interfit")));
    expect(interfit.lines.find((l) => l.key === "panel:6x5:interfit")?.size).toEqual([85.8, 70.8, 17.2]);
  });
});

describe("unprintable", () => {
  test("lists the keys of parts that do not fit the bed", () => {
    const wide = buildModel({ ...exampleA, rows: [{ height: 5, columns: [20], shift: 0, through: false }] });
    const bom = computeBom(wide);
    expect(unprintable(bom, DEFAULT_BED)).toEqual(new Set(["support:20"]));
    expect(unprintable(bom, { x: 300, y: 300, z: 300 })).toEqual(new Set());
  });

  test("the default rack fits the default bed", () => {
    expect(unprintable(computeBom(buildModel(exampleA)), DEFAULT_BED).size).toBe(0);
  });
});
