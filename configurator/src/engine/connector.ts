import type { Axis, ConnectorSpec, Dir } from "./types";

export function axisOf(dir: Dir): Axis {
  return dir[1] as Axis;
}

/**
 * Map an occupied arm set to a HomeRacker connector. Mirrors CONNECTOR_CONFIGS in
 * models/core/lib/connector.scad: dimensions = axes used, ways = arm count. Every arm set
 * with the same (dimensions, ways) is a rotation of the canonical configuration.
 */
export function classifyConnector(arms: ReadonlySet<Dir>, pullThrough: Axis | "none"): ConnectorSpec {
  if (arms.size === 0) throw new Error("connector needs at least one arm");
  if (pullThrough !== "none" && !(arms.has(`+${pullThrough}`) && arms.has(`-${pullThrough}`))) {
    throw new Error(`pull-through on ${pullThrough} needs arms on both sides`);
  }
  const axes = new Set([...arms].map(axisOf));
  return {
    dimensions: axes.size as ConnectorSpec["dimensions"],
    ways: arms.size as ConnectorSpec["ways"],
    pullThrough,
  };
}

export function connectorLabel(spec: ConnectorSpec): string {
  const base = `${spec.dimensions}D${spec.ways}W`;
  return spec.pullThrough === "none" ? base : `${base} pull-through ${spec.pullThrough.toUpperCase()}`;
}
