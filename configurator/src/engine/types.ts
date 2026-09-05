export type Axis = "x" | "y" | "z";
export type Dir = "+x" | "-x" | "+y" | "-y" | "+z" | "-z";

export const AXIS_INDEX: Record<Axis, 0 | 1 | 2> = { x: 0, y: 1, z: 2 };

export function dirVector(dir: Dir): Vec3 {
  const sign = dir[0] === "+" ? 1 : -1;
  const v: [number, number, number] = [0, 0, 0];
  v[AXIS_INDEX[dir[1] as Axis]] = sign;
  return v;
}
export type PanelType = "interfit" | "fullcover";
export type Vec3 = readonly [number, number, number];

/** Where an opening sits: a vertical face of a row, or a horizontal frame (bottom, shelf, top). */
export type PanelFace = "front" | "back" | "left" | "right" | "horizontal";

/** Groups of openings the UI can close in one go. */
export type FaceGroup = "front" | "back" | "left" | "right" | "top" | "bottom" | "shelves";

/** One row of the rack: a band of bays between two frames. */
export interface RackRow {
  /** Length of the vertical supports in this row, in units. */
  height: number;
  /** Width of each bay in units, left to right. Dividers between bays are one unit (a connector core). */
  columns: number[];
  /** How many units the row starts to the right of x = 0. */
  shift: number;
  /**
   * Posts continue from the row below through the frame under this row (pull-through connectors there)
   * instead of ending in a standard connector and starting a new support. Ignored on the bottom row.
   */
  through: boolean;
  /** Column indices whose bottom beam is forced despite a gap in the row below. */
  bars?: number[];
  /** Column indices whose width was computed from `?` (auto-fill to match the row below). */
  autos?: number[];
  /** Optional label shown in the editor and the parts list, e.g. "Servers". */
  name?: string;
}

/** A closed opening. `at` is the row index for vertical faces and the frame index for horizontal ones. */
export interface PanelSpec {
  face: PanelFace;
  at: number;
  /** Column index (front/back), span index (horizontal), segment index (left/right). */
  index: number;
  type: PanelType;
}

export interface RackConfig {
  /** Length of the depth supports in units, shared by every row. */
  depth: number;
  /** Rows from bottom to top. At least one. */
  rows: RackRow[];
  feet: boolean;
  panels: PanelSpec[];
}

/** An opening bounded by supports on all four sides that a panel can close. */
export interface Opening {
  id: string;
  face: PanelFace;
  at: number;
  index: number;
  /** Horizontal support length bounding the opening. */
  length: number;
  /** Vertical (or depth, for horizontal openings) support length bounding the opening. */
  height: number;
  /** Node at the near corner of the opening (min x, y, z). */
  origin: Vec3;
  /** Outward normal: where a full-cover panel sits. */
  normal: Dir;
}

export interface ConnectorSpec {
  dimensions: 1 | 2 | 3;
  ways: 1 | 2 | 3 | 4 | 5 | 6;
  pullThrough: Axis | "none";
}

export interface RackNode {
  id: string;
  pos: Vec3;
  arms: Set<Dir>;
  pullThrough: Axis | "none";
  foot: boolean;
}

export interface RackSupport {
  id: string;
  axis: Axis;
  /** First lattice cell occupied by the support. */
  from: Vec3;
  length: number;
  /** Nodes whose arms this support occupies: two ends plus any pass-throughs. */
  nodeIds: string[];
}

export interface RackPanel {
  id: string;
  face: PanelFace;
  type: PanelType;
  unitsX: number;
  unitsY: number;
  origin: Vec3;
  normal: Dir;
  /** Why no standard panel fits this opening, when the spec was kept anyway (e.g. from an older link). */
  blocked?: string;
}

/** Something that cannot be assembled as configured, tied to the rows that cause it. */
export interface RackProblem {
  message: string;
  /** Row indices involved, bottom to top. */
  rows: number[];
  supportIds: string[];
}

export interface RackModel {
  config: RackConfig;
  nodes: RackNode[];
  supports: RackSupport[];
  openings: Opening[];
  panels: RackPanel[];
  problems: RackProblem[];
  /** Outer size in units. */
  extent: Vec3;
}

export type BomKind = "support" | "connector" | "lockpin" | "foot" | "panel";

export interface BomLine {
  kind: BomKind;
  key: string;
  label: string;
  qty: number;
  note?: string;
  /** Bounding box of one printed part in millimetres, for print-bed checks. */
  size?: readonly [number, number, number];
  scad?: { part: string; params: Record<string, string | number | boolean> };
}

export interface Bom {
  lines: BomLine[];
  totals: {
    supports: number;
    supportUnits: number;
    connectors: number;
    lockPins: number;
    feet: number;
    panels: number;
  };
  outerMm: Vec3;
}

export interface ValidationIssue {
  field: keyof RackConfig;
  message: string;
}
