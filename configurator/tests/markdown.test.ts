import { describe, expect, test } from "vitest";
import { computeBom } from "../src/engine/bom";
import { bomToMarkdown, describeConfig } from "../src/engine/markdown";
import { buildModel } from "../src/engine/model";
import { closeFace } from "../src/engine/panels";
import { exampleA, exampleB, twoColumns, uShape } from "./fixtures";

describe("describeConfig", () => {
  test("lists rows top to bottom with their columns", () => {
    expect(describeConfig(exampleA)).toBe("depth 6 units; rows top to bottom: 6 wide x 4 high, 6 wide x 5 high; feet");
    expect(describeConfig(twoColumns)).toBe("depth 6 units; rows top to bottom: 4+4 wide x 5 high; feet");
  });

  test("marks a gap column distinctly instead of showing its raw negative width", () => {
    expect(describeConfig(uShape)).toBe(
      "depth 6 units; rows top to bottom: 6+gap 10+6 wide x 4 high, 6+10+6 wide x 5 high; no feet",
    );
  });

  test("uses row names when given", () => {
    const named = { ...exampleA, rows: [{ ...exampleA.rows[0]!, name: "Storage" }, exampleA.rows[1]!] };
    expect(describeConfig(named)).toBe("depth 6 units; rows top to bottom: 6 wide x 4 high, Storage: 6 wide x 5 high; feet");
  });

  test("marks rows whose posts continue from below", () => {
    expect(describeConfig(exampleB)).toBe("depth 6 units; rows top to bottom: 6 wide x 4 high (posts continue), 6 wide x 5 high; feet");
  });
});

describe("bomToMarkdown", () => {
  const config = closeFace(exampleA, "top", "fullcover");
  const md = bomToMarkdown(computeBom(buildModel(config)), config, "https://homeracker.org/configurator/#v=4");

  test("starts with a heading and the outer size", () => {
    expect(md).toMatch(/^# HomeRacker parts list\n/);
    expect(md).toContain("120 x 120 x 180 mm");
  });

  test("summarises the config", () => {
    expect(md).toContain("Rack: depth 6 units; rows top to bottom: 6 wide x 4 high, 6 wide x 5 high; feet");
  });

  test("lists one table row per line with quantities", () => {
    expect(md).toContain("| 12 | Support 6 units (90 mm) |");
    expect(md).toContain("| 8 | Connector 3D4W |");
    expect(md).toContain("| 44 | Lock pin |");
    expect(md).toContain("| 4 | Foot insert |");
    expect(md).toContain("| 1 | Panel 6x6 units full cover |");
  });

  test("keeps notes in the table", () => {
    expect(md).toContain("| 16 | Lock pin for panels | one per mount plate hole; estimate |");
  });

  test("ends with the share link", () => {
    expect(md.trimEnd()).toMatch(/\[Open in configurator\]\(https:\/\/homeracker\.org\/configurator\/#v=4\)$/);
  });
});
