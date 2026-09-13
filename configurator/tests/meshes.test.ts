import { expect, test } from "vitest";
import { BASE_STRENGTH, BASE_UNIT, TOLERANCE } from "../src/engine/constants";
import { panelStandoff } from "../src/render/meshes";

const PLATE = BASE_STRENGTH / BASE_UNIT;
/** How far a connector arm stands proud of the support it wraps (connector_outer_side_length). */
const CONNECTOR_PROUD = (BASE_STRENGTH + TOLERANCE / 2) / BASE_UNIT;

test("an inter-fit panel is flush with the plane of the opening", () => {
  expect(panelStandoff("interfit")).toBe(0);
});

test("a full cover panel covers the connector arms instead of clashing with them", () => {
  const inner = panelStandoff("fullcover") - PLATE;
  expect(inner).toBeGreaterThan(0);
  expect(panelStandoff("fullcover")).toBeGreaterThan(CONNECTOR_PROUD);
});
