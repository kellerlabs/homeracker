import { describe, expect, test } from "vitest";
import { faceDiagrams } from "../src/engine/diagrams";
import type { RackConfig } from "../src/engine/types";
import { exampleA, stepped, uShape } from "./fixtures";

const byId = (id: string) => faceDiagrams(stepped).find((d) => d.id === id)!;

describe("faceDiagrams", () => {
  test("lists elevations first, then one plan per frame from the top down", () => {
    expect(faceDiagrams(stepped).map((d) => d.id)).toEqual([
      "front",
      "back",
      "left",
      "right",
      "horizontal:2",
      "horizontal:1",
      "horizontal:0",
    ]);
    expect(faceDiagrams(stepped).map((d) => d.title)).toEqual([
      "Front",
      "Back",
      "Left side",
      "Right side",
      "Top of row 2",
      "Top of row 1",
      "Bottom",
    ]);
  });

  test("the front elevation draws every bay at its real position, y down from the top", () => {
    const front = byId("front");
    expect([front.width, front.height]).toEqual([9, 9]);
    // stepped: bottom row bays 3+3 (rows 3 high), top row one bay of 3 flush left; extent z = 9
    expect(front.cells.map((c) => [c.opening.id, c.x, c.y, c.w, c.h])).toEqual([
      ["front:0:0", 1, 5, 3, 3],
      ["front:0:1", 5, 5, 3, 3],
      ["front:1:0", 1, 1, 3, 3],
    ]);
  });

  test("the back elevation is mirrored so left and right match the viewer standing behind", () => {
    const back = byId("back");
    expect(back.cells.map((c) => [c.opening.id, c.x])).toEqual([
      ["back:0:0", 5],
      ["back:0:1", 1],
      ["back:1:0", 5],
    ]);
  });

  test("side elevations span the depth, with the front edge where the viewer sees it", () => {
    const right = byId("right");
    expect([right.width, right.height]).toEqual([6, 9]);
    expect(right.cells.map((c) => [c.opening.id, c.x, c.y, c.w, c.h])).toEqual([
      ["right:0:0", 1, 5, 4, 3],
      ["right:1:0", 1, 1, 4, 3],
    ]);
    const left = byId("left");
    expect(left.cells.map((c) => c.x)).toEqual([1, 1]);
  });

  test("plan views draw spans along x and the depth downwards, front at the bottom", () => {
    const shelf = byId("horizontal:1");
    expect([shelf.width, shelf.height]).toEqual([9, 6]);
    expect(shelf.cells.map((c) => [c.opening.id, c.x, c.y, c.w, c.h])).toEqual([
      ["horizontal:1:0", 1, 1, 3, 4],
      ["horizontal:1:1", 5, 1, 3, 4],
    ]);
  });

  test("plans above a row are titled with that row's name", () => {
    const named = { ...stepped, rows: [{ ...stepped.rows[0]!, name: "Storage" }, { ...stepped.rows[1]!, name: "Servers" }] };
    expect(faceDiagrams(named).find((d) => d.id === "horizontal:1")?.title).toBe("Top of Storage");
    expect(faceDiagrams(named).find((d) => d.id === "horizontal:2")?.title).toBe("Top of Servers");
  });

  test("a single-row rack has no shelf diagrams", () => {
    const ids = faceDiagrams({ ...exampleA, rows: [exampleA.rows[0]!] }).map((d) => d.id);
    expect(ids).toEqual(["front", "back", "left", "right", "horizontal:1", "horizontal:0"]);
  });

  test("the side elevations show only the outer faces of the rack", () => {
    const left = faceDiagrams(uShape).find((d) => d.id === "left")!;
    const right = faceDiagrams(uShape).find((d) => d.id === "right")!;
    expect(left.cells.map((c) => c.opening.id)).toEqual(["left:0:0", "left:1:0"]);
    expect(right.cells.map((c) => c.opening.id)).toEqual(["right:0:0", "right:1:1"]);
  });

  test("each gap gets a figure with the two walls it exposes", () => {
    expect(faceDiagrams(uShape).map((d) => d.id)).toEqual(["front", "back", "left", "right", "gap:1:1", "horizontal:2", "horizontal:1", "horizontal:0"]);
    const gap = faceDiagrams(uShape).find((d) => d.id === "gap:1:1")!;
    expect(gap.title).toBe("Gap in row 2");
    expect([gap.width, gap.height]).toEqual([16, 12]);
    expect(gap.cells.map((c) => [c.opening.id, c.x, c.y, c.w, c.h])).toEqual([
      ["right:1:0", 1, 1, 6, 4],
      ["left:1:1", 9, 1, 6, 4],
    ]);
  });

  test("a rack without gaps has no gap figure", () => {
    expect(faceDiagrams(exampleA).some((d) => d.id.startsWith("gap:"))).toBe(false);
  });

  test("numbers figures from the ones actually drawn, not the gap columns", () => {
    // A leading gap has no wall to its left, so it draws no figure; only the second gap does,
    // and it should read as the row's only figure rather than "Gap 2".
    const config: RackConfig = { depth: 6, rows: [{ height: 4, columns: [-6, 6, -8, 6], shift: 0, through: false }], feet: false, panels: [] };
    const gapDiagrams = faceDiagrams(config).filter((d) => d.id.startsWith("gap:"));
    expect(gapDiagrams).toHaveLength(1);
    expect(gapDiagrams[0]?.title).toBe("Gap in row 1");
  });
});
