import { describe, expect, test } from "vitest";
import { defaultConfig } from "../src/engine/defaults";
import { exampleA } from "./fixtures";

describe("defaultConfig", () => {
  test("is the worked example rack", () => {
    expect(defaultConfig()).toEqual(exampleA);
  });

  test("returns a fresh object every time", () => {
    const a = defaultConfig();
    a.rows[0]!.columns.push(9);
    expect(defaultConfig()).toEqual(exampleA);
  });
});
