export interface ParsedColumn {
  width: number | null;
  bar: boolean;
}

/** Parse one column token: a width, `-N` gap, `_N` bar, `?` auto, or `_?` bar+auto. */
export function parseOneColumn(token: string): ParsedColumn | null {
  const match = /^(_?)(\?|-?\d+)$/.exec(token);
  if (!match) return null;
  const bar = match[1] === "_";
  if (match[2] === "?") return { width: null, bar };
  const width = Number(match[2]);
  if (bar && width < 0) return null;
  return { width, bar };
}

export interface ParsedColumns {
  columns: (number | null)[];
  bars: number[];
}

export function parseColumnList(text: string): ParsedColumns | null {
  const parts = text
    .split(",")
    .map((p) => p.trim())
    .filter(Boolean);
  const columns: (number | null)[] = [];
  const bars: number[] = [];
  for (let i = 0; i < parts.length; i++) {
    const parsed = parseOneColumn(parts[i]!);
    if (!parsed) return null;
    columns.push(parsed.width);
    if (parsed.bar) bars.push(i);
  }
  return { columns, bars };
}

/** Whether the list is merely unfinished: a trailing minus or underscore. */
export function isPartialColumnList(text: string): boolean {
  const last = (text.split(",").at(-1) ?? "").trim();
  return last === "-" || last === "_";
}
