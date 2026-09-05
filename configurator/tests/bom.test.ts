import { describe, expect, test } from "vitest";
import { computeBom } from "../src/engine/bom";
import { buildModel } from "../src/engine/model";
import { closeFace } from "../src/engine/panels";
import type { Bom, RackConfig } from "../src/engine/types";
import { exampleA, exampleB, invariantRack, shortBeam, smallestRack, stepped, twoColumns } from "./fixtures";

const bomOf = (config: RackConfig): Bom => computeBom(buildModel(config));
const qty = (bom: Bom, key: string) => bom.lines.find((l) => l.key === key)?.qty ?? 0;
const keys = (bom: Bom, kind: string) => bom.lines.filter((l) => l.kind === kind).map((l) => l.key);

describe("computeBom example A (segmented)", () => {
  const bom = bomOf(exampleA);

  test("supports by length", () => {
    expect(qty(bom, "support:6")).toBe(12);
    expect(qty(bom, "support:5")).toBe(4);
    expect(qty(bom, "support:4")).toBe(4);
    expect(bom.totals.supports).toBe(20);
    expect(bom.totals.supportUnits).toBe(108);
  });

  test("connectors by type", () => {
    expect(qty(bom, "connector:3D4W:none")).toBe(8);
    expect(qty(bom, "connector:3D3W:none")).toBe(4);
    expect(bom.totals.connectors).toBe(12);
  });

  test("one lock pin per occupied arm", () => {
    expect(qty(bom, "lockpin:frame")).toBe(44);
    expect(bom.totals.lockPins).toBe(44);
  });

  test("feet and outer size", () => {
    expect(qty(bom, "foot")).toBe(4);
    expect(bom.totals.feet).toBe(4);
    expect(bom.outerMm).toEqual([120, 120, 180]);
  });
});

describe("computeBom example B (posts through the middle junction)", () => {
  const bom = bomOf(exampleB);

  test("posts run the full height", () => {
    expect(qty(bom, "support:6")).toBe(12);
    expect(qty(bom, "support:10")).toBe(4);
    expect(bom.totals.supports).toBe(16);
  });

  test("intermediate connectors are pull-through", () => {
    expect(qty(bom, "connector:3D4W:none")).toBe(4);
    expect(qty(bom, "connector:3D4W:z")).toBe(4);
    expect(qty(bom, "connector:3D3W:none")).toBe(4);
  });

  test("pass-through arms still take a pin each", () => {
    expect(qty(bom, "lockpin:frame")).toBe(44);
  });
});

describe("computeBom panels", () => {
  const bom = bomOf(closeFace(closeFace(closeFace(exampleA, "front", "interfit"), "back", "interfit"), "top", "fullcover"));

  test("aggregates panels by size and type", () => {
    expect(qty(bom, "panel:6x5:interfit")).toBe(2);
    expect(qty(bom, "panel:6x4:interfit")).toBe(2);
    expect(qty(bom, "panel:6x6:fullcover")).toBe(1);
    expect(bom.totals.panels).toBe(5);
  });

  test("lists panel pins separately from frame pins", () => {
    // 6x5: 8+6=14, 6x4: 8+4=12, 6x6: 8+8=16, twice for the pairs => 2*14 + 2*12 + 16
    expect(qty(bom, "lockpin:panel")).toBe(68);
    expect(qty(bom, "lockpin:panel-extended")).toBe(0);
    expect(bom.totals.lockPins).toBe(44 + 68);
  });

  test("small panels need extended pins for their corner mounts", () => {
    const small = bomOf(closeFace({ ...smallestRack, depth: 3, rows: [{ height: 3, columns: [3], shift: 0, through: false }] }, "front", "interfit"));
    expect(qty(small, "lockpin:panel-extended")).toBe(4);
  });
});

describe("computeBom oversize panels", () => {
  test("flags panels beyond the Customizer slider range", () => {
    const wide = bomOf(closeFace({ ...exampleA, rows: [{ height: 5, columns: [20], shift: 0, through: false }] }, "front", "interfit"));
    expect(wide.lines.find((l) => l.key === "panel:20x5:interfit")?.note).toMatch(/Customizer slider \(16\)/);
    expect(bomOf(closeFace(exampleA, "front", "interfit")).lines.find((l) => l.kind === "panel")?.note).toBeUndefined();
  });
});

describe("computeBom short beams", () => {
  test("marks 1-unit supports as impossible to assemble", () => {
    const bom = bomOf(shortBeam);
    expect(bom.lines.find((l) => l.key === "support:1")?.note).toMatch(/at least 2 units/);
    expect(bomOf(exampleA).lines.find((l) => l.kind === "support")?.note).toBeUndefined();
  });
});

describe("computeBom blocked panels", () => {
  test("notes panels whose opening has a connector inside an edge", () => {
    const offset = { ...exampleA, rows: [{ height: 5, columns: [9, 10], shift: 0, through: false }, { height: 4, columns: [20], shift: 0, through: false }] };
    const bom = bomOf({ ...offset, panels: [{ face: "front", at: 1, index: 0, type: "interfit" }] });
    expect(bom.lines.find((l) => l.kind === "panel")?.note).toMatch(/connector inside the bottom edge/);
  });
});

describe("computeBom shape", () => {
  test("orders lines by kind and supports by length descending", () => {
    const bom = bomOf(closeFace(exampleA, "top", "interfit"));
    expect(bom.lines.map((l) => l.kind)).toEqual([
      "support", "support", "support",
      "connector", "connector",
      "lockpin", "lockpin",
      "foot",
      "panel",
    ]);
    expect(keys(bom, "support")).toEqual(["support:6", "support:5", "support:4"]);
  });

  test("labels carry human readable sizes", () => {
    const bom = bomOf(exampleB);
    expect(bom.lines.find((l) => l.key === "support:10")?.label).toBe("Support 10 units (150 mm)");
    expect(bom.lines.find((l) => l.key === "connector:3D4W:z")?.label).toBe("Connector 3D4W pull-through Z");
  });

  test("carries OpenSCAD parameters for every printable line", () => {
    const bom = bomOf(closeFace(exampleB, "top", "fullcover"));
    expect(bom.lines.find((l) => l.key === "support:10")?.scad).toEqual({ part: "core/support", params: { units: 10 } });
    expect(bom.lines.find((l) => l.key === "connector:3D4W:z")?.scad).toEqual({
      part: "core/connector",
      params: { dimensions: 3, directions: 4, pull_through_axis: "z" },
    });
    expect(bom.lines.find((l) => l.key === "panel:6x6:fullcover")?.scad).toEqual({
      part: "panel/panel",
      params: { panel_type: 2, units_x: 6, units_y: 6 },
    });
  });

  test("omits empty groups", () => {
    const bom = bomOf(smallestRack);
    expect(keys(bom, "foot")).toEqual([]);
    expect(keys(bom, "panel")).toEqual([]);
    expect(qty(bom, "lockpin:frame")).toBe(24);
  });
});

describe("computeBom columns", () => {
  test("a divider adds T connectors, posts and feet", () => {
    const bom = bomOf(twoColumns);
    expect(qty(bom, "support:4")).toBe(8);
    expect(qty(bom, "support:6")).toBe(6);
    expect(qty(bom, "support:5")).toBe(6);
    expect(qty(bom, "connector:3D4W:none")).toBe(6);
    expect(qty(bom, "connector:3D5W:none")).toBe(2);
    expect(qty(bom, "connector:3D3W:none")).toBe(4);
    expect(qty(bom, "lockpin:frame")).toBe(46);
    expect(qty(bom, "foot")).toBe(6);
  });

  test("a stepped rack ends the lower divider in a plain corner on the middle frame", () => {
    const bom = bomOf(stepped);
    // 4 floor corners, 2 stub ends of the lower divider on the middle frame, 4 corners of the top frame
    expect(bom.totals.connectors).toBe(16);
    expect(qty(bom, "connector:3D3W:none")).toBe(10);
    expect(qty(bom, "connector:3D5W:none")).toBe(2);
    expect(bom.outerMm).toEqual([135, 90, 135]);
  });
});

describe("computeBom invariants", () => {
  const configs: RackConfig[] = [];
  const rowSets = [
    [[9, [4]]],
    [[3, [4]], [5, [4]]],
    [[2, [2, 2]], [3, [5]], [2, [1, 1, 1]]],
    [[4, [4, 4]], [4, [4]]],
  ] as const;
  for (const through of [false, true]) {
    for (const feet of [true, false]) {
      for (const rows of rowSets) {
        configs.push({
          depth: 7,
          rows: rows.map(([height, columns], i) => ({ height, columns: [...columns], shift: 0, through: through && i > 0 })),
          feet,
          panels: [],
        });
      }
    }
  }

  test.each(configs.map((c) => [c.rows.some((r) => r.through) ? "through" : "split", c.feet, c.rows.length, c] as const))(
    "frame pins equal 2 per support end plus pass-throughs plus feet (%s, feet %s, %s rows)",
    (_p, _f, _r, config) => {
      const model = buildModel(config);
      const bom = computeBom(model);
      const passThroughs = model.nodes.filter((n) => n.pullThrough !== "none").length;
      const feet = model.nodes.filter((n) => n.foot).length;
      expect(bom.totals.lockPins).toBe(2 * model.supports.length + 2 * passThroughs + feet);
      expect(bom.totals.connectors).toBe(model.nodes.length);
    },
  );

  test("the invariant rack is 135 mm tall", () => {
    expect(bomOf(invariantRack).outerMm[2]).toBe(135);
  });
});
