import { afterEach, expect, test, vi } from "vitest";
import { BASE_STRENGTH, BASE_UNIT, TOLERANCE } from "../src/engine/constants";
import { buildModel } from "../src/engine/model";
import { createMaterials } from "../src/render/materials";
import { buildRealRack, panelPlateBottom, PartLibrary } from "../src/render/meshes";

const PLATE = BASE_STRENGTH / BASE_UNIT;
/** How far a connector arm stands proud of the support it wraps (connector_outer_side_length). */
const CONNECTOR_PROUD = (BASE_STRENGTH + TOLERANCE / 2) / BASE_UNIT;

test("an inter-fit panel reaches back out to the plane of the opening", () => {
  const mountHeight = (BASE_UNIT + TOLERANCE) / BASE_UNIT;
  expect(panelPlateBottom("interfit") + PLATE + mountHeight).toBeCloseTo(0);
});

test("a full cover panel covers the connector arms instead of clashing with them", () => {
  expect(-panelPlateBottom("fullcover")).toBeGreaterThan(CONNECTOR_PROUD);
});

/** A library holding every part except the names in `missing`; each mesh is an empty binary STL. */
async function libraryWithout(...missing: string[]): Promise<PartLibrary> {
  const parts = new Proxy({} as Record<string, { file: string }>, {
    has: (_, name) => !missing.includes(String(name)),
    get: (_, name) => (missing.includes(String(name)) ? undefined : { file: `${String(name)}.stl` }),
  });
  // three's FileLoader reports progress with the DOM-only ProgressEvent.
  vi.stubGlobal("ProgressEvent", class extends Event {});
  vi.stubGlobal("fetch", async (input: RequestInfo | URL) => {
    const url = input instanceof Request ? input.url : String(input);
    return url.endsWith("manifest.json") ? { ok: true, json: async () => ({ parts }) } : new Response(new ArrayBuffer(84));
  });
  return (await PartLibrary.load("http://test/parts/"))!;
}

afterEach(() => vi.unstubAllGlobals());

/** Dividers of the two rows one unit apart leave a 0-unit beam between them. */
const zeroBeamRack = () =>
  buildModel({
    depth: 4,
    rows: [
      { height: 3, columns: [4, 4], shift: 0, through: false },
      { height: 3, columns: [8], shift: 0, through: true },
    ],
    feet: false,
    panels: [],
  });

test("a support length the library does not hold is drawn as a block instead of failing the rack", async () => {
  const model = zeroBeamRack();
  expect(model.supports.some((s) => s.length === 0)).toBe(true);
  const group = await buildRealRack(model, await libraryWithout("support-0"), createMaterials());
  expect(group.children.length).toBeGreaterThan(model.supports.length);
});

test("a missing support length the export should hold still fails the rack", async () => {
  await expect(buildRealRack(zeroBeamRack(), await libraryWithout("support-0", "support-4"), createMaterials())).rejects.toThrow(
    "part support-4 is not in the library",
  );
});

test("any other part missing from the library still fails the rack", async () => {
  await expect(buildRealRack(zeroBeamRack(), await libraryWithout("support-0", "lockpin"), createMaterials())).rejects.toThrow(
    "part lockpin is not in the library",
  );
});
