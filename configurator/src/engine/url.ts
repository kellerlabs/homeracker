import { closeFace } from "./panels";
import type { FaceGroup, PanelFace, PanelSpec, PanelType, RackConfig, RackRow } from "./types";

const FACE_CODE: Record<PanelFace, string> = { front: "f", back: "b", left: "l", right: "r", horizontal: "h" };
const GROUPS_V2: FaceGroup[] = ["front", "back", "left", "right", "top", "bottom"];
const PANEL_CODE: Record<PanelType, string> = { interfit: "i", fullcover: "f" };

function keyOf<T extends string>(codes: Record<T, string>, code: string): T | null {
  const entry = (Object.entries(codes) as [T, string][]).find(([, c]) => c === code);
  return entry ? entry[0] : null;
}

/** Minimal query codec so the engine stays free of DOM globals like URLSearchParams. */
function parseQuery(query: string): Map<string, string> {
  const params = new Map<string, string>();
  for (const pair of query.split("&").filter(Boolean)) {
    const [key, value = ""] = pair.split("=");
    if (key) params.set(decodeURIComponent(key), decodeURIComponent(value));
  }
  return params;
}

function integer(value: string | undefined): number | null {
  if (value === undefined || !/^\d+$/.test(value)) return null;
  return Number(value);
}

function decodeColumn(value: string | undefined) {
  if (value === undefined) return null;
  const match = /^(_?)(\?|-?\d+)$/.exec(value);
  if (!match) return null;
  const bar = match[1] === "_";
  if (match[2] === "?") return { width: 0, bar, auto: true };
  const width = Number(match[2]);
  if (bar && width < 0) return null;
  return { width, bar, auto: false };
}

export function encodeColumn(row: RackRow, i: number): string {
  const prefix = row.bars?.includes(i) ? "_" : "";
  if (row.autos?.includes(i)) return `${prefix}?`;
  return `${prefix}${row.columns[i]}`;
}

function encodeRow(row: RackRow): string {
  const cols = row.columns.map((_, i) => encodeColumn(row, i)).join(".");
  return `${row.height}:${cols}${row.shift ? `~${row.shift}` : ""}${row.through ? "*" : ""}`;
}

function decodeRow(token: string): RackRow | null {
  const match = /^(\d+):([\d._?-]+)(?:~(\d+))?(\*)?$/.exec(token);
  if (!match) return null;
  const parsed = match[2]!.split(".").map(decodeColumn);
  if (parsed.some((c) => c === null)) return null;
  const cols = parsed as { width: number; bar: boolean; auto: boolean }[];
  const bars = cols.flatMap((c, i) => (c.bar ? [i] : []));
  const autos = cols.flatMap((c, i) => (c.auto ? [i] : []));
  return {
    height: Number(match[1]),
    columns: cols.map((c) => c.width),
    shift: match[3] ? Number(match[3]) : 0,
    through: match[4] === "*",
    ...(bars.length > 0 ? { bars } : {}),
    ...(autos.length > 0 ? { autos } : {}),
  };
}

/** Panel token: face letter, position, `.`, index, type letter: `f0.1i`. */
function encodePanel(panel: PanelSpec): string {
  return `${FACE_CODE[panel.face]}${panel.at}.${panel.index}${PANEL_CODE[panel.type]}`;
}

function decodePanel(token: string): PanelSpec | null {
  const match = /^([fblrh])(\d+)\.(\d+)([if])$/.exec(token);
  if (!match) return null;
  const face = keyOf(FACE_CODE, match[1]!);
  const type = keyOf(PANEL_CODE, match[4]!);
  if (!face || !type) return null;
  return { face, at: Number(match[2]), index: Number(match[3]), type };
}

/** Longest row name kept in a link. */
export const MAX_ROW_NAME = 40;

export function encodeConfig(config: RackConfig): string {
  const params: [string, string][] = [
    ["v", "4"],
    ["d", String(config.depth)],
    ["r", config.rows.map(encodeRow).join("_")],
    ["f", config.feet ? "1" : "0"],
  ];
  if (config.panels.length > 0) params.push(["pn", config.panels.map(encodePanel).join("_")]);
  config.rows.forEach((row, i) => {
    if (row.name) params.push([`n${i}`, row.name.slice(0, MAX_ROW_NAME)]);
  });
  const enc = (v: string) => encodeURIComponent(v).replace(/%3A/g, ":").replace(/%2A/g, "*").replace(/%3F/g, "?");
  return params.map(([k, v]) => `${enc(k)}=${enc(v)}`).join("&");
}

/** Versions 1 to 3 had one post mode for the whole rack: continuous meant every junction lets posts through. */
function legacyPosts(params: Map<string, string>): boolean | null {
  const code = params.get("p") ?? "";
  if (code === "s") return false;
  if (code === "c") return true;
  return null;
}

function applyThrough(rows: RackRow[], through: boolean): RackRow[] {
  return rows.map((row, i) => ({ ...row, through: through && i > 0 }));
}

/** Versions 1 and 2 stored one panel type per face; expand it to every opening of that face. */
function applyFacePanels(config: RackConfig, raw: string): RackConfig | null {
  let result = config;
  for (const entry of raw.split("_").filter(Boolean)) {
    const [group, code] = entry.split(".");
    const type = keyOf(PANEL_CODE, code ?? "");
    if (!group || !GROUPS_V2.includes(group as FaceGroup) || type === null) return null;
    result = closeFace(result, group as FaceGroup, type);
  }
  return result;
}

/** Version 1 links described one column with a total height and intermediate level positions. */
function decodeV1(params: Map<string, string>): RackConfig | null {
  const width = integer(params.get("w"));
  const depth = integer(params.get("d"));
  const height = integer(params.get("h"));
  const through = legacyPosts(params);
  if (width === null || depth === null || height === null || through === null) return null;
  const levelsRaw = params.get("l");
  const levels = levelsRaw ? levelsRaw.split(".").map((z) => integer(z)) : [];
  if (levels.some((z) => z === null)) return null;
  const zs = [0, ...(levels as number[]), height + 1];
  const rows = zs.slice(1).map((z, i) => ({ height: z - (zs[i] ?? 0) - 1, columns: [width], shift: 0, through: false }));
  return applyFacePanels({ depth, rows: applyThrough(rows, through), feet: params.get("f") === "1", panels: [] }, params.get("pn") ?? "");
}

function decodeRows(params: Map<string, string>): Pick<RackConfig, "depth" | "rows"> | null {
  const depth = integer(params.get("d"));
  const rows = (params.get("r") ?? "").split(/_(?=\d+:)/).map(decodeRow);
  if (depth === null || rows.length === 0 || rows.some((r) => r === null)) return null;
  return { depth, rows: rows as RackRow[] };
}

export function decodeConfig(hash: string): RackConfig | null {
  const params = parseQuery(hash.replace(/^#/, ""));
  const version = params.get("v");
  if (version === "1") return decodeV1(params);
  if (version !== "2" && version !== "3" && version !== "4") return null;
  const shape = decodeRows(params);
  if (!shape) return null;
  const feet = params.get("f") === "1";
  const raw = params.get("pn") ?? "";
  if (version !== "4") {
    const through = legacyPosts(params);
    if (through === null) return null;
    const base: RackConfig = { depth: shape.depth, rows: applyThrough(shape.rows, through), feet, panels: [] };
    if (version === "2") return applyFacePanels(base, raw);
    const panels = raw.split("_").filter(Boolean).map(decodePanel);
    if (panels.some((p) => p === null)) return null;
    return { ...base, panels: panels as PanelSpec[] };
  }
  const panels = raw.split("_").filter(Boolean).map(decodePanel);
  if (panels.some((p) => p === null)) return null;
  const rows = shape.rows.map((row, i) => {
    const name = params.get(`n${i}`)?.trim().slice(0, MAX_ROW_NAME);
    return name ? { ...row, name } : row;
  });
  return { depth: shape.depth, rows, feet, panels: panels as PanelSpec[] };
}
