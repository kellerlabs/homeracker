import { describe, expect, test } from "vitest";
import { buildModel } from "../src/engine/model";
import type { RackModel, RackNode } from "../src/engine/types";
import { bottomU, exampleA, exampleB, invariantRack, mixedPosts, shortBeam, smallestRack, stepped, twoColumns, uShape } from "./fixtures";

const sorted = (node: RackNode) => [...node.arms].sort().join(",");
const nodesAtZ = (model: RackModel, z: number) => model.nodes.filter((n) => n.pos[2] === z);
const node = (model: RackModel, id: string) => model.nodes.find((n) => n.id === id);
const lengths = (model: RackModel, axis: "x" | "y" | "z") =>
  model.supports
    .filter((s) => s.axis === axis)
    .map((s) => s.length)
    .sort((a, b) => a - b);

describe("buildModel frame", () => {
  test("places a node at every corner of every frame", () => {
    const model = buildModel(exampleA);
    expect(model.nodes).toHaveLength(12);
    expect(nodesAtZ(model, 0)).toHaveLength(4);
    expect(nodesAtZ(model, 6)).toHaveLength(4);
    expect(nodesAtZ(model, 11)).toHaveLength(4);
  });

  test("reports the outer extent in units", () => {
    expect(buildModel(exampleA).extent).toEqual([8, 8, 12]);
  });

  test("creates horizontal supports of the column width on every frame", () => {
    const model = buildModel(exampleA);
    expect(lengths(model, "x")).toEqual([6, 6, 6, 6, 6, 6]);
    expect(lengths(model, "y")).toEqual([6, 6, 6, 6, 6, 6]);
  });

  test("segmented posts are one support per row", () => {
    expect(lengths(buildModel(exampleA), "z")).toEqual([4, 4, 4, 4, 5, 5, 5, 5]);
  });

  test("posts run through a junction the row above lets them through", () => {
    expect(lengths(buildModel(exampleB), "z")).toEqual([10, 10, 10, 10]);
  });

  test("posts merge only across junctions marked through", () => {
    // rows of 3: bottom junction through, top junction split -> posts of 7 and 3 units
    expect(lengths(buildModel(mixedPosts), "z")).toEqual([3, 3, 3, 3, 7, 7, 7, 7]);
    const model = buildModel(mixedPosts);
    expect(nodesAtZ(model, 4).every((n) => n.pullThrough === "z")).toBe(true);
    expect(nodesAtZ(model, 8).every((n) => n.pullThrough === "none")).toBe(true);
  });

  test("a continuous post occupies the arms of the nodes it passes through", () => {
    const post = buildModel(exampleB).supports.find((s) => s.axis === "z" && s.from[0] === 0 && s.from[1] === 0);
    expect(post?.nodeIds.sort()).toEqual(["n:0,0,0", "n:0,0,11", "n:0,0,6"].sort());
  });

  test("the 105 mm invariant: 3 + connector + 3 between two frames", () => {
    const model = buildModel(invariantRack);
    expect(lengths(model, "z")).toEqual([3, 3, 3, 3, 3, 3, 3, 3]);
    expect(model.extent[2]).toBe(9);
  });

  test("the smallest rack has eight nodes and two-unit supports", () => {
    const model = buildModel(smallestRack);
    expect(model.nodes).toHaveLength(8);
    expect(model.supports.every((s) => s.length === 2)).toBe(true);
    expect(model.problems).toEqual([]);
  });

  test("a beam shorter than two units between two connectors is reported with the rows involved", () => {
    const model = buildModel(shortBeam);
    expect(model.problems).toHaveLength(1);
    expect(model.problems[0]?.message).toMatch(/Top of Semme.*1-unit.*11.*13.*Semme.*Leberkas/);
    expect(model.problems[0]?.supportIds).toHaveLength(2);
    expect(model.problems[0]?.rows).toEqual([0, 1]);
  });

  test("a gap leaves the frame above it open and the flanking nodes as corners", () => {
    const model = buildModel(uShape);
    expect(model.nodes).toHaveLength(24);
    expect(lengths(model, "x")).toEqual([6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 10, 10, 10, 10]);
    // Top frame: the post and the depth support stay, the beam over the gap is gone.
    expect(sorted(node(model, "n:7,0,11")!)).toBe("+y,-x,-z");
    // Shelf under the gap: the row below spans it, so the node keeps both beams.
    expect(sorted(node(model, "n:7,0,6")!)).toBe("+x,+y,+z,-x,-z");
  });
});

describe("buildModel arms", () => {
  test("bottom corners with feet have four arms including -z", () => {
    const n = node(buildModel(exampleA), "n:0,0,0");
    expect(sorted(n!)).toBe("+x,+y,+z,-z");
    expect(n?.foot).toBe(true);
  });

  test("bottom corners without feet have three arms", () => {
    const n = node(buildModel({ ...exampleA, feet: false }), "n:7,7,0");
    expect(sorted(n!)).toBe("+z,-x,-y");
    expect(n?.foot).toBe(false);
  });

  test("intermediate corners have four arms", () => {
    const n = node(buildModel(exampleA), "n:7,0,6");
    expect(sorted(n!)).toBe("+y,+z,-x,-z");
    expect(n?.pullThrough).toBe("none");
  });

  test("top corners have three arms", () => {
    expect(sorted(node(buildModel(exampleA), "n:0,7,11")!)).toBe("+x,-y,-z");
  });

  test("through junctions make their nodes z pull-through", () => {
    const model = buildModel(exampleB);
    expect(nodesAtZ(model, 6).every((n) => n.pullThrough === "z")).toBe(true);
    expect(nodesAtZ(model, 0).every((n) => n.pullThrough === "none")).toBe(true);
  });

  test("supports start one cell past their lower node", () => {
    const beam = buildModel(exampleA).supports.find((s) => s.axis === "x" && s.from[1] === 0 && s.from[2] === 0);
    expect(beam?.from).toEqual([1, 0, 0]);
    expect(beam?.nodeIds.sort()).toEqual(["n:0,0,0", "n:7,0,0"]);
  });
});

describe("buildModel columns", () => {
  test("a divider adds a post and splits the frame beams", () => {
    const model = buildModel(twoColumns);
    expect(model.nodes).toHaveLength(12);
    expect(lengths(model, "x")).toEqual([4, 4, 4, 4, 4, 4, 4, 4]);
    expect(lengths(model, "y")).toEqual([6, 6, 6, 6, 6, 6]);
    expect(lengths(model, "z")).toEqual([5, 5, 5, 5, 5, 5]);
  });

  test("divider nodes are T junctions", () => {
    const model = buildModel(twoColumns);
    expect(sorted(node(model, "n:5,0,0")!)).toBe("+x,+y,+z,-x,-z");
    expect(sorted(node(model, "n:5,7,6")!)).toBe("+x,-x,-y,-z");
  });

  test("a stepped rack keeps a node where the lower divider meets the frame", () => {
    const model = buildModel(stepped);
    expect(model.extent).toEqual([9, 6, 9]);
    expect(sorted(node(model, "n:8,0,4")!)).toBe("+y,-x,-z");
    expect(node(model, "n:8,0,8")).toBeUndefined();
    expect(lengths(model, "z")).toEqual([3, 3, 3, 3, 3, 3, 3, 3, 3, 3]);
  });

  test("a shifted row starts at its shift", () => {
    const model = buildModel({ ...stepped, rows: [stepped.rows[0]!, { height: 3, columns: [3], shift: 2, through: false }] });
    expect(nodesAtZ(model, 8).map((n) => n.pos[0]).sort((a, b) => a - b)).toEqual([2, 2, 6, 6]);
    expect(sorted(node(model, "n:2,0,4")!)).toBe("+x,+y,+z,-x");
  });
});

describe("disconnected racks", () => {
  test("a U standing on the floor is one connected rack", () => {
    expect(buildModel(bottomU).problems).toEqual([]);
  });

  test("a U carried by a row that spans its gap is one rack", () => {
    expect(buildModel(uShape).problems).toEqual([]);
  });

  test("an ordinary rack reports nothing", () => {
    expect(buildModel(stepped).problems).toEqual([]);
  });
});
