import { describe, expect, test } from "vitest";
import { defaultConfig } from "../src/engine/defaults";
import { closeFace } from "../src/engine/panels";
import type { PanelSpec, RackConfig, RackRow } from "../src/engine/types";
import { validate } from "../src/engine/validate";

const cfg = (patch: Partial<RackConfig>): RackConfig => ({ ...defaultConfig(), ...patch });
const rows = (...list: [number, number[], number?][]): RackRow[] =>
  list.map(([height, columns, shift = 0]) => ({ height, columns, shift, through: false }));
const fields = (c: RackConfig) => validate(c).map((i) => i.field);

describe("validate", () => {
  test("accepts the default config", () => {
    expect(validate(defaultConfig())).toEqual([]);
  });

  test("rejects depth outside 2..50 or non-integer", () => {
    expect(fields(cfg({ depth: 1 }))).toEqual(["depth"]);
    expect(fields(cfg({ depth: 51 }))).toEqual(["depth"]);
    expect(fields(cfg({ depth: 2.5 }))).toEqual(["depth"]);
  });

  test("requires at least one row", () => {
    expect(fields(cfg({ rows: [] }))).toEqual(["rows"]);
  });

  test("rejects row heights and column widths outside 2..50 (two connectors need two units between them)", () => {
    expect(fields(cfg({ rows: rows([1, [6]]) }))).toEqual(["rows"]);
    expect(fields(cfg({ rows: rows([5, [1]]) }))).toEqual(["rows"]);
    expect(fields(cfg({ rows: rows([5, [6, 51]]) }))).toEqual(["rows"]);
    expect(fields(cfg({ rows: rows([5, []]) }))).toEqual(["rows"]);
  });

  test("rejects negative or fractional shifts", () => {
    expect(fields(cfg({ rows: rows([5, [6], -1]) }))).toEqual(["rows"]);
    expect(fields(cfg({ rows: rows([5, [6], 1.5]) }))).toEqual(["rows"]);
  });

  test("names the offending row", () => {
    const [issue] = validate(cfg({ rows: rows([5, [6]], [0, [6]]) }));
    expect(issue?.message).toMatch(/row 2/i);
  });

  test("panels never invalidate a rack, even on openings no standard panel fits", () => {
    const front: PanelSpec = { face: "front", at: 0, index: 0, type: "interfit" };
    const left: PanelSpec = { face: "left", at: 0, index: 0, type: "interfit" };
    expect(fields(cfg({ rows: rows([5, [2]]), panels: [front] }))).toEqual([]);
    expect(fields(cfg({ rows: rows([2, [6]]), panels: [left] }))).toEqual([]);
    expect(validate(closeFace(cfg({ rows: rows([5, [2]]) }), "left", "interfit"))).toEqual([]);
  });

  test("ignores panels whose opening no longer exists", () => {
    expect(validate(cfg({ panels: [{ face: "front", at: 9, index: 0, type: "interfit" }] }))).toEqual([]);
  });

  test("accepts a gap between two bays", () => {
    expect(fields(cfg({ rows: rows([4, [6, -10, 6]]) }))).toEqual([]);
  });

  test("holds a gap to the same span limits as a bay", () => {
    expect(fields(cfg({ rows: rows([4, [6, -1, 6]]) }))).toEqual(["rows"]);
    expect(fields(cfg({ rows: rows([4, [6, -51, 6]]) }))).toEqual(["rows"]);
  });

  test("accepts a gap anywhere in the row: it only takes away the beam above itself", () => {
    expect(fields(cfg({ rows: rows([4, [6, 10, -6]]) }))).toEqual([]);
    expect(fields(cfg({ rows: rows([4, [-10, 6]]) }))).toEqual([]);
    expect(fields(cfg({ rows: rows([4, [6, -4, -4, 6]]) }))).toEqual([]);
    expect(fields(cfg({ rows: rows([4, [-6]]) }))).toEqual([]);
  });
});
