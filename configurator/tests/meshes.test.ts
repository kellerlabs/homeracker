import { expect, test, vi } from "vitest";
import { BASE_STRENGTH, BASE_UNIT, TOLERANCE } from "../src/engine/constants";
import { buildModel } from "../src/engine/model";
import { createMaterials } from "../src/render/materials";
import { buildRealRack, panelPlateBottom, PartLibrary } from "../src/render/meshes";

const PLATE = BASE_STRENGTH / BASE_UNIT;
/** How far a connector arm stands proud of the support it wraps (connector_outer_side_length). */
const CONNECTOR_PROUD = (BASE_STRENGTH + TOLERANCE / 2) / BASE_UNIT;

test("an inter-fit panel reaches back out to the plane of the opening", () => {
  const mountHeight = (BASE_UNIT + TOLERANCE) / BASE_UNIT;
  expect(panelPlateBottom("interfit") + PLATE + mountHeight).toBeCloseTo(0);
});

test("a full cover panel covers the connector arms instead of clashing with them", () => {
  expect(-panelPlateBottom("fullcover")).toBeGreaterThan(CONNECTOR_PROUD);
});

test("a support the part library does not hold is drawn as a block instead of failing the rack", async () => {
  vi.stubGlobal("fetch", async () => new Response(JSON.stringify({ parts: {} })));
  const library = await PartLibrary.load("parts/");
  vi.unstubAllGlobals();
  // Dividers of the two rows one unit apart leave a 0-unit beam between them.
  const model = buildModel({
    depth: 4,
    rows: [
      { height: 3, columns: [4, 4], shift: 0, through: false },
      { height: 3, columns: [8], shift: 0, through: true },
    ],
    feet: false,
    panels: [],
  });
  expect(model.supports.some((s) => s.length === 0)).toBe(true);
  const group = await buildRealRack(model, library!, createMaterials());
  expect(group.children).toHaveLength(model.supports.length);
});
