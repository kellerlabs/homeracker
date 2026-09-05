import { describe, expect, test } from "vitest";
import { axisOf, classifyConnector, connectorLabel } from "../src/engine/connector";
import type { Dir } from "../src/engine/types";

const arms = (...dirs: Dir[]) => new Set<Dir>(dirs);

describe("classifyConnector", () => {
  test.each<[string, Dir[], number, number]>([
    ["1D1W", ["+z"], 1, 1],
    ["1D2W", ["+z", "-z"], 1, 2],
    ["2D2W", ["+z", "+x"], 2, 2],
    ["2D3W", ["+z", "-z", "+x"], 2, 3],
    ["2D4W", ["+z", "-z", "+x", "-x"], 2, 4],
    ["3D3W", ["+z", "+x", "+y"], 3, 3],
    ["3D4W", ["+z", "-z", "+x", "+y"], 3, 4],
    ["3D5W", ["+z", "-z", "+x", "-x", "+y"], 3, 5],
    ["3D6W", ["+z", "-z", "+x", "-x", "+y", "-y"], 3, 6],
  ])("%s from canonical arms", (_label, dirs, dimensions, ways) => {
    expect(classifyConnector(arms(...dirs), "none")).toEqual({ dimensions, ways, pullThrough: "none" });
  });

  test("rotated arm sets map to the same connector", () => {
    expect(classifyConnector(arms("-z", "-x", "-y"), "none")).toEqual({ dimensions: 3, ways: 3, pullThrough: "none" });
    expect(classifyConnector(arms("+x", "-x", "+y"), "none")).toEqual({ dimensions: 2, ways: 3, pullThrough: "none" });
  });

  test("keeps the pull-through axis", () => {
    expect(classifyConnector(arms("+z", "-z", "+x", "+y"), "z")).toEqual({ dimensions: 3, ways: 4, pullThrough: "z" });
  });

  test("rejects an empty arm set", () => {
    expect(() => classifyConnector(arms(), "none")).toThrow(/at least one arm/);
  });

  test("rejects pull-through without both arms on that axis", () => {
    expect(() => classifyConnector(arms("+z", "+x", "+y"), "z")).toThrow(/pull-through/);
  });
});

describe("connectorLabel", () => {
  test("formats dimensions and ways", () => {
    expect(connectorLabel({ dimensions: 3, ways: 4, pullThrough: "none" })).toBe("3D4W");
  });

  test("appends the pull-through axis", () => {
    expect(connectorLabel({ dimensions: 3, ways: 4, pullThrough: "z" })).toBe("3D4W pull-through Z");
  });
});

describe("axisOf", () => {
  test("strips the sign", () => {
    expect(axisOf("-y")).toBe("y");
  });
});
