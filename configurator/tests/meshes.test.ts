import { expect, test } from "vitest";
import { BASE_STRENGTH, BASE_UNIT, TOLERANCE } from "../src/engine/constants";
import { panelPlateBottom } from "../src/render/meshes";

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
