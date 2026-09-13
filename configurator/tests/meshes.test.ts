import { Vector3 } from "three";
import { expect, test } from "vitest";
import { BASE_STRENGTH, BASE_UNIT, TOLERANCE } from "../src/engine/constants";
import { lockpinInsert, panelStandoff } from "../src/render/meshes";

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

test("a post's lock pin follows the front to back holes of the post", () => {
  const rackCenter = new Vector3(3, 3, 3);
  const front = lockpinInsert("+z", new Vector3(0.5, 0.5, 2), rackCenter);
  const back = lockpinInsert("+z", new Vector3(0.5, 5.5, 2), rackCenter);
  expect(front.equals(new Vector3(0, 1, 0))).toBe(true);
  expect(back.equals(new Vector3(0, -1, 0))).toBe(true);
});

test("a beam's lock pin runs vertically and is pushed in from the inside", () => {
  const rackCenter = new Vector3(3, 3, 3);
  const top = lockpinInsert("+x", new Vector3(2, 0.5, 5.5), rackCenter);
  const bottom = lockpinInsert("-y", new Vector3(2, 0.5, 0.5), rackCenter);
  expect(top.equals(new Vector3(0, 0, -1))).toBe(true);
  expect(bottom.equals(new Vector3(0, 0, 1))).toBe(true);
});
