import { describe, expect, test } from "vitest";
import { isPartialColumnList, parseColumnList } from "../src/ui/parse";

describe("parseColumnList", () => {
  test("parses comma separated integers", () => {
    expect(parseColumnList("3, 6,9")).toEqual({ columns: [3, 6, 9], bars: [] });
  });

  test("returns an empty list for blank input", () => {
    expect(parseColumnList("  ")).toEqual({ columns: [], bars: [] });
  });

  test("returns null on non-numeric entries", () => {
    expect(parseColumnList("3,x")).toBeNull();
    expect(parseColumnList("3.5")).toBeNull();
  });

  test("reads a negative entry as a gap", () => {
    expect(parseColumnList("6, -10, 6")).toEqual({ columns: [6, -10, 6], bars: [] });
  });

  test("still rejects a lone minus", () => {
    expect(parseColumnList("6, -, 6")).toBeNull();
  });

  test("reads _ prefix as a bottom bar", () => {
    expect(parseColumnList("_10, 10, -2")).toEqual({ columns: [10, 10, -2], bars: [0] });
  });

  test("multiple bars", () => {
    expect(parseColumnList("_6, 4, _8")).toEqual({ columns: [6, 4, 8], bars: [0, 2] });
  });

  test("rejects bar on a gap", () => {
    expect(parseColumnList("_-10")).toBeNull();
  });
});

describe("isPartialColumnList", () => {
  test("a trailing minus is the start of a gap, not a mistake", () => {
    expect(isPartialColumnList("6, -")).toBe(true);
    expect(isPartialColumnList("6,-")).toBe(true);
    expect(isPartialColumnList("-")).toBe(true);
  });

  test("a trailing underscore is the start of a bar", () => {
    expect(isPartialColumnList("6, _")).toBe(true);
    expect(isPartialColumnList("_")).toBe(true);
  });

  test("anything else is finished input, right or wrong", () => {
    expect(isPartialColumnList("6, -10, 6")).toBe(false);
    expect(isPartialColumnList("6, -1")).toBe(false);
    expect(isPartialColumnList("6, x")).toBe(false);
    expect(isPartialColumnList("6,")).toBe(false);
    expect(isPartialColumnList("")).toBe(false);
  });
});
