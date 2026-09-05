import type { Bom, RackConfig } from "./types";

export function describeConfig(config: RackConfig): string {
  const rows = [...config.rows]
    .reverse()
    .map((row, i, list) => {
      const notes = [row.shift ? `shift ${row.shift}` : "", row.through && i < list.length - 1 ? "posts continue" : ""].filter(Boolean);
      const label = row.name ? `${row.name}: ` : "";
      const columns = row.columns.map((w) => (w < 0 ? `gap ${-w}` : `${w}`)).join("+");
      return `${label}${columns} wide x ${row.height} high${notes.length ? ` (${notes.join(", ")})` : ""}`;
    })
    .join(", ");
  const feet = config.feet ? "feet" : "no feet";
  return `depth ${config.depth} units; rows top to bottom: ${rows}; ${feet}`;
}

export function bomToMarkdown(bom: Bom, config: RackConfig, shareUrl: string): string {
  const hasNotes = bom.lines.some((l) => l.note);
  const header = hasNotes ? "| Qty | Part | Note |\n|---:|---|---|" : "| Qty | Part |\n|---:|---|";
  const rows = bom.lines.map((l) => (hasNotes ? `| ${l.qty} | ${l.label} | ${l.note ?? ""} |` : `| ${l.qty} | ${l.label} |`));
  return [
    "# HomeRacker parts list",
    "",
    `Rack: ${describeConfig(config)}`,
    `Outer size: ${bom.outerMm.join(" x ")} mm`,
    "",
    header,
    ...rows,
    "",
    `[Open in configurator](${shareUrl})`,
    "",
  ].join("\n");
}
