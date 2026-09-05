import { describe, expect, test } from "vitest";
import { buildModel } from "../src/engine/model";
import { closeFace, closeOpenings, closeReason, edgeConnectors, openings, panelAt, panelPins, panelSize, togglePanel } from "../src/engine/panels";
import type { PanelSpec } from "../src/engine/types";
import { exampleA, stepped, twoColumns, uShape } from "./fixtures";

const spec = (face: PanelSpec["face"], at: number, index: number, type: PanelSpec["type"] = "interfit"): PanelSpec => ({
  face,
  at,
  index,
  type,
});

describe("panelSize", () => {
  test("a panel fills the opening bounded by the supports", () => {
    expect(panelSize(6, 5)).toEqual({ unitsX: 6, unitsY: 5 });
  });
});

describe("panelPins", () => {
  test("counts one pin per mount plate hole on large panels", () => {
    expect(panelPins(6, 5)).toEqual({ standard: 2 * 4 + 2 * 3, extended: 0 });
  });

  test("adds four extended pins for corner mounts on small panels", () => {
    expect(panelPins(6, 3)).toEqual({ standard: 2 * 4 + 2 * 1, extended: 4 });
    expect(panelPins(2, 2)).toEqual({ standard: 0, extended: 4 });
  });
});

describe("openings", () => {
  test("front and back have one opening per column per row", () => {
    const front = openings(twoColumns).filter((o) => o.face === "front");
    expect(front.map((o) => [o.at, o.index, o.length, o.height, o.origin])).toEqual([
      [0, 0, 4, 5, [0, 0, 0]],
      [0, 1, 4, 5, [5, 0, 0]],
    ]);
    const back = openings(exampleA).filter((o) => o.face === "back");
    expect(back.map((o) => o.origin)).toEqual([
      [0, 7, 0],
      [0, 7, 6],
    ]);
  });

  test("left and right have one opening per row at the edge of that row", () => {
    const right = openings(stepped).filter((o) => o.face === "right");
    expect(right.map((o) => [o.at, o.length, o.height, o.origin])).toEqual([
      [0, 4, 3, [8, 0, 0]],
      [1, 4, 3, [4, 0, 4]],
    ]);
  });

  test("every frame has horizontal openings between its nodes: bottom, shelves, top", () => {
    const horizontal = openings(stepped).filter((o) => o.face === "horizontal");
    expect(horizontal.map((o) => [o.at, o.index, o.length, o.height, o.origin, o.normal])).toEqual([
      [0, 0, 3, 4, [0, 0, 0], "-z"],
      [0, 1, 3, 4, [4, 0, 0], "-z"],
      [1, 0, 3, 4, [0, 0, 4], "+z"],
      [1, 1, 3, 4, [4, 0, 4], "+z"],
      [2, 0, 3, 4, [0, 0, 8], "+z"],
    ]);
  });

  test("openings have stable ids", () => {
    expect(openings(exampleA).map((o) => o.id)).toContain("front:1:0");
    expect(openings(exampleA).map((o) => o.id)).toContain("horizontal:2:0");
  });

  test("a gap has no bay, so no front or back opening", () => {
    const front = openings(uShape).filter((o) => o.face === "front" && o.at === 1);
    expect(front.map((o) => [o.index, o.length, o.origin])).toEqual([
      [0, 6, [0, 0, 6]],
      [2, 6, [18, 0, 6]],
    ]);
  });

  test("each segment of a row gets its own left and right opening", () => {
    const sides = openings(uShape).filter((o) => (o.face === "left" || o.face === "right") && o.at === 1);
    expect(sides.map((o) => [o.face, o.index, o.length, o.height, o.origin])).toEqual([
      ["left", 0, 6, 4, [0, 0, 6]],
      ["right", 0, 6, 4, [7, 0, 6]],
      ["left", 1, 6, 4, [18, 0, 6]],
      ["right", 1, 6, 4, [25, 0, 6]],
    ]);
  });

  test("a row without gaps keeps left and right at index 0", () => {
    const sides = openings(exampleA).filter((o) => o.face === "left" || o.face === "right");
    expect(sides.map((o) => o.index)).toEqual([0, 0, 0, 0]);
  });

  test("a frame span with no beam has no horizontal opening, and the others keep their index", () => {
    const top = openings(uShape).filter((o) => o.face === "horizontal" && o.at === 2);
    expect(top.map((o) => [o.index, o.length, o.origin])).toEqual([
      [0, 6, [0, 0, 11]],
      [2, 6, [18, 0, 11]],
    ]);
  });
});

describe("connectors inside a panel edge", () => {
  // Bottom row 9+10 (divider at x=10), row above one 20-wide bay: the divider ends in a T connector
  // inside the upper bay's bottom edge.
  const offset = {
    ...twoColumns,
    rows: [
      { height: 5, columns: [9, 10], shift: 0, through: false },
      { height: 4, columns: [20], shift: 0, through: false },
    ],
  };

  test("edgeConnectors lists frame nodes strictly inside a front or back bay's top and bottom edges", () => {
    const upper = openings(offset).find((o) => o.id === "front:1:0")!;
    expect(edgeConnectors(offset, upper)).toEqual([{ edge: "bottom", x: 10 }]);
    const lowerLeft = openings(offset).find((o) => o.id === "back:0:0")!;
    expect(edgeConnectors(offset, lowerLeft)).toEqual([]);
  });

  test("sides and horizontal openings never have edge connectors", () => {
    const all = openings(offset);
    for (const o of all.filter((o) => o.face === "left" || o.face === "right" || o.face === "horizontal")) {
      expect(edgeConnectors(offset, o)).toEqual([]);
    }
  });

  test("closeReason explains why an opening cannot take a standard panel", () => {
    const all = openings(offset);
    expect(closeReason(offset, all.find((o) => o.id === "front:1:0")!)).toMatch(/connector inside the bottom edge/);
    expect(closeReason(offset, all.find((o) => o.id === "front:0:0")!)).toBeNull();
    const tiny = openings({ ...twoColumns, rows: [{ height: 5, columns: [1, 4], shift: 0, through: false }] });
    expect(closeReason(twoColumns, tiny.find((o) => o.id === "front:0:0")!)).toMatch(/2 to 50/);
  });

  test("whole-face actions skip openings with a connector in an edge", () => {
    const closed = closeFace(offset, "front", "interfit");
    expect(closed.panels.map((p) => `${p.at}:${p.index}`)).toEqual(["0:0", "0:1"]);
  });

  test("a panel placed there anyway is kept but marked", () => {
    const model = buildModel({ ...offset, panels: [spec("front", 1, 0)] });
    expect(model.panels[0]?.blocked).toMatch(/connector inside the bottom edge/);
    const tiny = buildModel({ ...twoColumns, rows: [{ height: 5, columns: [1, 4], shift: 0, through: false }], panels: [spec("front", 0, 0)] });
    expect(tiny.panels[0]?.blocked).toMatch(/2 to 50/);
    expect(buildModel(closeFace(offset, "front", "interfit")).panels.every((p) => !p.blocked)).toBe(true);
  });
});

describe("closeFace and togglePanel", () => {
  test("closeFace covers every opening of a face group", () => {
    const front = closeFace(exampleA, "front", "interfit");
    expect(front.panels).toEqual([spec("front", 0, 0), spec("front", 1, 0)]);
    const top = closeFace(stepped, "top", "fullcover");
    expect(top.panels).toEqual([spec("horizontal", 2, 0, "fullcover")]);
    const bottom = closeFace(stepped, "bottom", "interfit");
    expect(bottom.panels).toEqual([spec("horizontal", 0, 0), spec("horizontal", 0, 1)]);
    const shelves = closeFace(stepped, "shelves", "interfit");
    expect(shelves.panels).toEqual([spec("horizontal", 1, 0), spec("horizontal", 1, 1)]);
  });

  test("closeFace skips openings that are too small or too large for a panel", () => {
    const config = { ...twoColumns, rows: [twoColumns.rows[0]!, { height: 4, columns: [6], shift: 0, through: false }] };
    // The shelf frame has spans of 4, 1 and 2 units; the 1-unit span cannot take a panel.
    expect(closeFace(config, "shelves", "interfit").panels.map((p) => p.index)).toEqual([0, 2]);
    expect(closeFace({ ...twoColumns, rows: [{ height: 5, columns: [51], shift: 0, through: false }] }, "front", "interfit").panels).toEqual([]);
  });

  test("closeFace with null opens the face and keeps other panels", () => {
    const config = closeFace(closeFace(exampleA, "front", "interfit"), "left", "fullcover");
    expect(closeFace(config, "front", null).panels).toEqual([spec("left", 0, 0, "fullcover"), spec("left", 1, 0, "fullcover")]);
  });

  test("closeOpenings sets an explicit list of openings, skipping unclosable ones", () => {
    const all = openings(twoColumns);
    const front = all.filter((o) => o.face === "front");
    const closed = closeOpenings(twoColumns, front, "fullcover");
    expect(closed.panels).toEqual([spec("front", 0, 0, "fullcover"), spec("front", 0, 1, "fullcover")]);
    expect(closeOpenings(closed, front, null).panels).toEqual([]);
  });

  test("togglePanel cycles open, inter-fit, full cover", () => {
    const opening = openings(exampleA).find((o) => o.id === "front:0:0")!;
    const once = togglePanel(exampleA, opening);
    expect(panelAt(once, opening)).toBe("interfit");
    const twice = togglePanel(once, opening);
    expect(panelAt(twice, opening)).toBe("fullcover");
    const thrice = togglePanel(twice, opening);
    expect(panelAt(thrice, opening)).toBeUndefined();
    expect(thrice.panels).toEqual([]);
  });
});

describe("buildModel panels", () => {
  test("no panels by default", () => {
    expect(buildModel(exampleA).panels).toEqual([]);
  });

  test("a closed face gets one panel per opening, sized by its supports", () => {
    const model = buildModel(closeFace(exampleA, "front", "interfit"));
    expect(model.panels.map((p) => [p.unitsX, p.unitsY, p.type, p.normal])).toEqual([
      [6, 5, "interfit", "-y"],
      [6, 4, "interfit", "-y"],
    ]);
  });

  test("a single bay can be closed on its own", () => {
    const model = buildModel({ ...twoColumns, panels: [spec("front", 0, 1, "fullcover")] });
    expect(model.panels.map((p) => [p.origin, p.type])).toEqual([[[5, 0, 0], "fullcover"]]);
  });

  test("panels whose opening no longer exists are ignored", () => {
    const model = buildModel({ ...exampleA, panels: [spec("front", 7, 0)] });
    expect(model.panels).toEqual([]);
  });

  test("the model lists its openings", () => {
    expect(buildModel(twoColumns).openings.filter((o) => o.face === "front")).toHaveLength(2);
  });
});
