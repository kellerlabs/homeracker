import { describe, expect, test } from "vitest";
import { buildModel } from "../src/engine/model";
import { closeFace } from "../src/engine/panels";
import { rackBoxes, type Box } from "../src/render/layout";
import { exampleA, exampleB, smallestRack } from "./fixtures";

const ofKind = (boxes: Box[], kind: Box["kind"]) => boxes.filter((b) => b.kind === kind);

describe("rackBoxes", () => {
  test("a support box spans its cells", () => {
    const boxes = rackBoxes(buildModel(exampleA));
    const beam = ofKind(boxes, "support").find((b) => b.center[1] === 0.5 && b.center[2] === 0.5 && b.size[0] === 6);
    expect(beam).toEqual({ kind: "support", center: [4, 0.5, 0.5], size: [6, 1, 1], key: "support:6" });
  });

  test("a vertical support is sized along z", () => {
    const boxes = rackBoxes(buildModel(exampleB));
    const post = ofKind(boxes, "support").find((b) => b.size[2] === 10);
    expect(post?.center).toEqual([0.5, 0.5, 6]);
  });

  test("every node gets a core box and one arm box per arm", () => {
    const model = buildModel(exampleA);
    const boxes = rackBoxes(model);
    expect(ofKind(boxes, "core")).toHaveLength(12);
    expect(ofKind(boxes, "arm")).toHaveLength(44);
    const core = ofKind(boxes, "core").find((b) => b.center[0] === 0.5 && b.center[1] === 0.5 && b.center[2] === 0.5);
    expect(core?.size).toEqual([1, 1, 1]);
  });

  test("arms sit in the neighbouring cell, slightly inset", () => {
    const boxes = rackBoxes(buildModel(smallestRack));
    const arm = ofKind(boxes, "arm").find((b) => b.center[0] === 1.5 && b.center[1] === 0.5 && b.center[2] === 0.5);
    expect(arm?.size).toEqual([0.9, 0.9, 0.9]);
  });

  test("pull-through cores are marked", () => {
    const boxes = rackBoxes(buildModel(exampleB));
    expect(ofKind(boxes, "core-pullthrough")).toHaveLength(4);
    expect(ofKind(boxes, "core")).toHaveLength(8);
  });

  test("feet are flat plates below the bottom nodes", () => {
    const boxes = rackBoxes(buildModel(exampleA));
    const feet = ofKind(boxes, "foot");
    expect(feet).toHaveLength(4);
    expect(feet[0]).toEqual({ kind: "foot", center: [0.5, 0.5, -1.1], size: [1.3, 1.3, 0.2] });
  });

  test("no foot boxes without feet", () => {
    expect(ofKind(rackBoxes(buildModel({ ...exampleA, feet: false })), "foot")).toEqual([]);
  });

  test("side panels on a stepped rack follow the edge of their own row", async () => {
    const { stepped } = await import("./fixtures");
    const model = buildModel(closeFace(stepped, "right", "interfit"));
    const panels = ofKind(rackBoxes(model), "panel");
    expect(panels.map((b) => b.center[0])).toEqual([9 - 0.075, 5 - 0.075]);
  });

  test("inter-fit panels sit just inside the face, full cover just outside", () => {
    const model = buildModel(closeFace(closeFace(exampleA, "front", "interfit"), "top", "fullcover"));
    const panels = ofKind(rackBoxes(model), "panel");
    const front = panels.find((b) => b.size[0] === 6 && b.size[2] === 5);
    expect(front).toEqual({ kind: "panel", center: [4, 0.075, 3.5], size: [6, 0.15, 5], key: "panel:6x5:interfit" });
    const top = panels.find((b) => b.size[2] === 0.15);
    expect(top).toEqual({ kind: "panel", center: [4, 4, 12.075], size: [6, 6, 0.15], key: "panel:6x6:fullcover" });
  });
});
