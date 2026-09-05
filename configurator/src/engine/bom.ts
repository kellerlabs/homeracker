import { classifyConnector, connectorLabel } from "./connector";
import { BASE_STRENGTH, BASE_UNIT, LIMITS, TOLERANCE } from "./constants";
import { panelPins } from "./panels";
import type { Bom, BomLine, Dir, RackModel } from "./types";

const PANEL_TYPE_PARAM = { interfit: 1, fullcover: 2 } as const;

/** Connector envelope: the core is a unit plus two walls and tolerance; an arm reaches one unit past the core centre. */
const CORE_HALF = (BASE_UNIT + 2 * BASE_STRENGTH + TOLERANCE) / 2;
const ARM_REACH = BASE_UNIT * 1.5;
const MOUNT_HEIGHT = { interfit: BASE_UNIT + TOLERANCE, fullcover: BASE_UNIT + TOLERANCE + BASE_STRENGTH } as const;
const round = (v: number) => Math.round(v * 10) / 10;

function connectorSize(arms: ReadonlySet<Dir>): [number, number, number] {
  const axisSize = (axis: "x" | "y" | "z") => round((arms.has(`+${axis}`) ? ARM_REACH : CORE_HALF) + (arms.has(`-${axis}`) ? ARM_REACH : CORE_HALF));
  return [axisSize("x"), axisSize("y"), axisSize("z")];
}

function panelSizeMm(unitsX: number, unitsY: number, type: "interfit" | "fullcover"): [number, number, number] {
  const deduction = type === "interfit" ? 2 * BASE_STRENGTH + TOLERANCE : -BASE_UNIT;
  return [round(unitsX * BASE_UNIT - deduction), round(unitsY * BASE_UNIT - deduction), round(BASE_STRENGTH + MOUNT_HEIGHT[type])];
}
const PANEL_TYPE_LABEL = { interfit: "inter-fit", fullcover: "full cover" } as const;

function add(lines: Map<string, BomLine>, line: Omit<BomLine, "qty">, qty = 1): void {
  const existing = lines.get(line.key);
  if (existing) existing.qty += qty;
  else lines.set(line.key, { ...line, qty });
}

export function computeBom(model: RackModel): Bom {
  const lines = new Map<string, BomLine>();

  for (const s of model.supports) {
    add(lines, {
      kind: "support",
      key: `support:${s.length}`,
      label: `Support ${s.length} units (${s.length * BASE_UNIT} mm)`,
      size: [BASE_UNIT, BASE_UNIT, s.length * BASE_UNIT],
      ...(s.length < LIMITS.span.min ? { note: `cannot be assembled: two connectors need at least ${LIMITS.span.min} units between them` } : {}),
      scad: { part: "core/support", params: { units: s.length } },
    });
  }

  let framePins = 0;
  let feet = 0;
  for (const n of model.nodes) {
    const spec = classifyConnector(n.arms, n.pullThrough);
    add(lines, {
      kind: "connector",
      key: `connector:${spec.dimensions}D${spec.ways}W:${spec.pullThrough}`,
      label: `Connector ${connectorLabel(spec)}`,
      size: connectorSize(n.arms),
      scad: {
        part: "core/connector",
        params: { dimensions: spec.dimensions, directions: spec.ways, pull_through_axis: spec.pullThrough },
      },
    });
    framePins += n.arms.size;
    if (n.foot) feet++;
  }

  let panelPinsStandard = 0;
  let panelPinsExtended = 0;
  for (const p of model.panels) {
    const pins = panelPins(p.unitsX, p.unitsY);
    panelPinsStandard += pins.standard;
    panelPinsExtended += pins.extended;
    const oversize = Math.max(p.unitsX, p.unitsY) > LIMITS.panelCustomizer;
    const note = p.blocked ?? (oversize ? `beyond the Customizer slider (${LIMITS.panelCustomizer}); type the units in or print split` : undefined);
    add(lines, {
      kind: "panel",
      key: `panel:${p.unitsX}x${p.unitsY}:${p.type}${p.blocked ? ":blocked" : ""}`,
      label: `Panel ${p.unitsX}x${p.unitsY} units ${PANEL_TYPE_LABEL[p.type]}`,
      size: panelSizeMm(p.unitsX, p.unitsY, p.type),
      ...(note ? { note } : {}),
      scad: { part: "panel/panel", params: { panel_type: PANEL_TYPE_PARAM[p.type], units_x: p.unitsX, units_y: p.unitsY } },
    });
  }

  const pinSize: [number, number, number] = [8, 22.1, 3.8];
  add(lines, { kind: "lockpin", key: "lockpin:frame", label: "Lock pin", size: pinSize, scad: { part: "core/lockpin", params: { grip_type: 0 } } }, framePins);
  if (panelPinsStandard > 0) {
    add(
      lines,
      {
        kind: "lockpin",
        key: "lockpin:panel",
        label: "Lock pin for panels",
        note: "one per mount plate hole; estimate",
        size: pinSize,
        scad: { part: "core/lockpin", params: { grip_type: 0 } },
      },
      panelPinsStandard,
    );
  }
  if (panelPinsExtended > 0) {
    add(
      lines,
      {
        kind: "lockpin",
        key: "lockpin:panel-extended",
        label: "Extended lock pin for panel corners",
        note: "small panels use corner mounts; estimate",
        size: pinSize,
        scad: { part: "core/lockpin", params: { grip_type: 0, neck_extension: 1 } },
      },
      panelPinsExtended,
    );
  }
  if (feet > 0) add(lines, { kind: "foot", key: "foot", label: "Foot insert", size: [19.2, 19.2, 17.1], scad: { part: "foot/foot", params: {} } }, feet);

  const order: BomLine["kind"][] = ["support", "connector", "lockpin", "foot", "panel"];
  const sorted = [...lines.values()].sort((a, b) => {
    const byKind = order.indexOf(a.kind) - order.indexOf(b.kind);
    if (byKind !== 0) return byKind;
    if (a.kind === "support") return (b.scad?.params.units as number) - (a.scad?.params.units as number);
    return a.key.localeCompare(b.key);
  });

  const sum = (kind: BomLine["kind"]) => sorted.filter((l) => l.kind === kind).reduce((n, l) => n + l.qty, 0);
  return {
    lines: sorted,
    totals: {
      supports: model.supports.length,
      supportUnits: model.supports.reduce((n, s) => n + s.length, 0),
      connectors: model.nodes.length,
      lockPins: sum("lockpin"),
      feet,
      panels: model.panels.length,
    },
    outerMm: [model.extent[0] * BASE_UNIT, model.extent[1] * BASE_UNIT, model.extent[2] * BASE_UNIT],
  };
}
