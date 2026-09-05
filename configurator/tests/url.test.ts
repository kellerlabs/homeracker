import { describe, expect, test } from "vitest";
import { defaultConfig } from "../src/engine/defaults";
import { closeFace } from "../src/engine/panels";
import type { RackConfig } from "../src/engine/types";
import { decodeConfig, encodeConfig } from "../src/engine/url";
import { exampleB, mixedPosts, stepped, twoColumns, uShape } from "./fixtures";

describe("encodeConfig", () => {
  test("produces a compact query string", () => {
    expect(encodeConfig(defaultConfig())).toBe("v=4&d=6&r=5:6_4:6&f=1");
  });

  test("marks rows whose posts continue from the row below", () => {
    expect(encodeConfig(exampleB)).toBe("v=4&d=6&r=5:6_4:6*&f=1");
    expect(encodeConfig(mixedPosts)).toBe("v=4&d=4&r=3:4_3:4*_3:4&f=0");
  });

  test("encodes columns, shifts and per-opening panels", () => {
    const config: RackConfig = {
      ...stepped,
      rows: [stepped.rows[0]!, { height: 3, columns: [3], shift: 2, through: true }],
      panels: [
        { face: "front", at: 0, index: 1, type: "interfit" },
        { face: "horizontal", at: 2, index: 0, type: "fullcover" },
        { face: "left", at: 1, index: 0, type: "interfit" },
      ],
    };
    expect(encodeConfig(config)).toBe("v=4&d=4&r=3:3.3_3:3~2*&f=0&pn=f0.1i_h2.0f_l1.0i");
  });
});

describe("row names in links", () => {
  test("named rows travel as one parameter per row, unnamed rows are left out", () => {
    const config: RackConfig = {
      ...exampleB,
      rows: [{ ...exampleB.rows[0]!, name: "Storage" }, { ...exampleB.rows[1]!, name: "Servers & Switch_2" }],
    };
    expect(encodeConfig(config)).toBe("v=4&d=6&r=5:6_4:6*&f=1&n0=Storage&n1=Servers%20%26%20Switch_2");
    expect(decodeConfig(encodeConfig(config))).toEqual(config);
    const partial: RackConfig = { ...exampleB, rows: [exampleB.rows[0]!, { ...exampleB.rows[1]!, name: "Top" }] };
    expect(encodeConfig(partial)).toBe("v=4&d=6&r=5:6_4:6*&f=1&n1=Top");
    expect(decodeConfig(encodeConfig(partial))).toEqual(partial);
  });

  test("ignores names for rows that do not exist and trims long names", () => {
    expect(decodeConfig("v=4&d=6&r=5:6&f=1&n3=Ghost")?.rows[0]?.name).toBeUndefined();
    const long = "x".repeat(80);
    expect(decodeConfig(`v=4&d=6&r=5:6&f=1&n0=${long}`)?.rows[0]?.name).toHaveLength(40);
  });
});

describe("decodeConfig", () => {
  test("round-trips every config", () => {
    const withPanels = closeFace(closeFace(twoColumns, "back", "fullcover"), "shelves", "interfit");
    for (const config of [defaultConfig(), exampleB, mixedPosts, twoColumns, stepped, withPanels]) {
      expect(decodeConfig(encodeConfig(config))).toEqual(config);
    }
  });

  test("accepts a leading hash", () => {
    expect(decodeConfig("#v=4&d=6&r=5:6_4:6&f=1")).toEqual(defaultConfig());
  });

  test("converts version 3 links, where continuous posts applied to every junction", () => {
    expect(decodeConfig("v=3&d=6&r=5:6_4:6&f=1&p=s")).toEqual(defaultConfig());
    expect(decodeConfig("v=3&d=6&r=5:6_4:6&f=1&p=c")).toEqual(exampleB);
    expect(decodeConfig("v=3&d=6&r=5:6_4:6&f=1&p=s&pn=f0.0i")?.panels).toEqual([{ face: "front", at: 0, index: 0, type: "interfit" }]);
  });

  test("expands version 2 face panels to every opening of that face", () => {
    const decoded = decodeConfig("v=2&d=6&r=5:6_4:6&f=1&p=s&pn=front.i_top.f");
    expect(decoded).toEqual(closeFace(closeFace(defaultConfig(), "front", "interfit"), "top", "fullcover"));
  });

  test("converts version 1 links into rows and openings", () => {
    expect(decodeConfig("v=1&w=6&d=6&h=10&l=6&f=1&p=s")).toEqual(defaultConfig());
    expect(decodeConfig("v=1&w=6&d=6&h=10&f=1&p=c&pn=front.i")).toEqual(
      closeFace({ depth: 6, rows: [{ height: 10, columns: [6], shift: 0, through: false }], feet: true, panels: [] }, "front", "interfit"),
    );
  });

  test("returns null for an empty or unknown version", () => {
    expect(decodeConfig("")).toBeNull();
    expect(decodeConfig("v=5&d=6")).toBeNull();
  });

  test("returns null for garbage values", () => {
    expect(decodeConfig("v=4&d=six&r=5:6&f=1")).toBeNull();
    expect(decodeConfig("v=4&d=6&r=5:&f=1")).toBeNull();
    expect(decodeConfig("v=4&d=6&r=5:6**&f=1")).toBeNull();
    expect(decodeConfig("v=4&d=6&r=5:6&f=1&pn=x0.0i")).toBeNull();
    expect(decodeConfig("v=3&d=6&r=5:6&f=1&p=zigzag")).toBeNull();
  });
});

describe("gap columns in links", () => {
  test("a gap travels as a negative width", () => {
    expect(encodeConfig(uShape)).toBe("v=4&d=6&r=5:6.10.6_4:6.-10.6&f=0");
  });

  test("round trips", () => {
    expect(decodeConfig(`#${encodeConfig(uShape)}`)).toEqual(uShape);
  });

  test("the version stays 4, so an older build still reads links without gaps", () => {
    expect(decodeConfig("#v=4&d=6&r=5:6_4:6&f=1")).toEqual(defaultConfig());
  });
});

describe("bottom bars in links", () => {
  test("a bar travels as _ prefix on a column", () => {
    const config: RackConfig = {
      ...uShape,
      rows: [uShape.rows[0]!, { ...uShape.rows[1]!, bars: [0] }],
    };
    expect(encodeConfig(config)).toBe("v=4&d=6&r=5:6.10.6_4:_6.-10.6&f=0");
    expect(decodeConfig(encodeConfig(config))).toEqual(config);
  });
});

describe("auto-fill columns in links", () => {
  test("an auto column travels as ?", () => {
    const config: RackConfig = {
      depth: 6,
      rows: [
        { height: 5, columns: [6, 10, 6], shift: 0, through: false },
        { height: 4, columns: [0], shift: 0, through: false, autos: [0] },
      ],
      feet: false,
      panels: [],
    };
    expect(encodeConfig(config)).toBe("v=4&d=6&r=5:6.10.6_4:?&f=0");
    expect(decodeConfig(encodeConfig(config))).toEqual(config);
  });

  test("auto with bar prefix round-trips", () => {
    const config: RackConfig = {
      depth: 6,
      rows: [
        { height: 5, columns: [6, 10, 6], shift: 0, through: false },
        { height: 4, columns: [0, 4], shift: 0, through: false, autos: [0], bars: [0] },
      ],
      feet: false,
      panels: [],
    };
    expect(encodeConfig(config)).toBe("v=4&d=6&r=5:6.10.6_4:_?.4&f=0");
    expect(decodeConfig(encodeConfig(config))).toEqual(config);
  });
});
