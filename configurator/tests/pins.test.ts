import { describe, expect, test } from "vitest";
import { buildModel } from "../src/engine/model";
import { closeFace } from "../src/engine/panels";
import { framePins, lockpinPart } from "../src/engine/pins";
import { exampleA } from "./fixtures";

const at = (model: ReturnType<typeof buildModel>, cell: [number, number, number]) =>
  framePins(model).find((p) => p.cell.every((v, i) => v === cell[i]));

describe("framePins", () => {
  test("a post's pin follows the front to back holes of the post", () => {
    const pin = at(buildModel(exampleA), [0, 0, 1]);
    expect(pin?.axis).toBe("y");
    expect(pin?.grip).toBe(1);
  });

  test("a beam's pin runs vertically and is pushed in from the inside", () => {
    const model = buildModel(exampleA);
    expect(at(model, [1, 0, 0])).toMatchObject({ axis: "z", grip: 1 });
    expect(at(model, [1, 0, 11])).toMatchObject({ axis: "z", grip: -1 });
  });

  test("the arm a foot plugs into takes a pin like any other", () => {
    expect(at(buildModel(exampleA), [0, 0, -1])).toMatchObject({ axis: "y" });
  });

  test("a panel corner bracket extends the end of the pin it hangs on", () => {
    const model = buildModel(closeFace(exampleA, "front", "interfit"));
    // Bottom frame: the panel is above the beam, the side the pin goes in from.
    expect(at(model, [1, 0, 0])?.extension).toBe("neck");
    // Middle frame: one panel below, one above.
    expect(at(model, [1, 0, 6])?.extension).toBe("both");
    // A pin the panels do not reach stays plain.
    expect(at(model, [1, 7, 0])?.extension).toBe("none");
  });

  test("a bracket across the face of a post claims the sideways hole of that cell", () => {
    const plain = at(buildModel(exampleA), [0, 0, 1]);
    expect(plain?.axis).toBe("y");
    const held = at(buildModel(closeFace(exampleA, "front", "interfit")), [0, 0, 1]);
    expect(held).toMatchObject({ axis: "x", extension: "neck" });
  });

  test("only the outermost holes of an edge carry a bracket", () => {
    const model = buildModel(closeFace(exampleA, "front", "interfit"));
    const extended = framePins(model).filter((p) => p.extension !== "none");
    // Two panels, four corners each, two brackets per corner, sharing the frame between the rows.
    expect(extended).toHaveLength(14);
    expect(extended.filter((p) => p.axis === "z")).toHaveLength(6);
  });
});

test("lock pin parts are named after the end they extend", () => {
  expect(lockpinPart("none")).toBe("lockpin");
  expect(lockpinPart("both")).toBe("lockpin-both");
});
