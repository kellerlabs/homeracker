import { describe, expect, test } from "vitest";
import type { PanelSpec } from "../src/engine/types";
import { remapPanels } from "../src/ui/form";

const p = (face: PanelSpec["face"], at: number): PanelSpec => ({ face, at, index: 0, type: "interfit" });

describe("remapPanels", () => {
  const panels = [p("front", 0), p("front", 1), p("horizontal", 0), p("horizontal", 1), p("horizontal", 2)];

  test("inserting a row shifts the rows and frames above it", () => {
    expect(remapPanels(panels, "insert", 1)).toEqual([p("front", 0), p("front", 2), p("horizontal", 0), p("horizontal", 1), p("horizontal", 3)]);
  });

  test("removing a row drops its panels and the frame above it", () => {
    expect(remapPanels(panels, "remove", 0)).toEqual([p("front", 0), p("horizontal", 0), p("horizontal", 1)]);
  });

  test("swapping rows swaps their vertical panels and keeps the frame between them", () => {
    expect(remapPanels(panels, "swap", 0)).toEqual([p("front", 1), p("front", 0), p("horizontal", 0), p("horizontal", 1), p("horizontal", 2)]);
  });
});
