import type { Bom, BomKind } from "../engine/types";
import { el } from "./dom";

const GROUPS: [BomKind, string][] = [
  ["support", "Supports"],
  ["connector", "Connectors"],
  ["lockpin", "Lock pins"],
  ["foot", "Feet"],
  ["panel", "Panels"],
];

export interface BomView {
  /** Keys of lines to mark as problems (unprintable parts, short beams, panels that fit nothing). */
  flagged: Set<string>;
  /** Keys of lines whose part does not fit the printer bed; these get the bed note. */
  unprintable: Set<string>;
  markdown: () => string;
  shareUrl: () => string;
}

/** A button that copies text to the clipboard, with a visible fallback when the clipboard is unavailable. */
function copyButton(root: HTMLElement, id: string, label: string, text: () => string): HTMLButtonElement {
  const button = el("button", { type: "button", id, class: "cfg-copy" }, [label]);
  button.addEventListener("click", async () => {
    const value = text();
    try {
      await navigator.clipboard.writeText(value);
      button.textContent = "Copied";
    } catch {
      const area = el("textarea", { readonly: "" }, [value]);
      root.append(area);
      area.select();
      button.textContent = "Select and copy the text below";
    }
    setTimeout(() => {
      button.textContent = label;
    }, 2000);
  });
  return button;
}

const mm = (size: readonly [number, number, number]) => size.map((v) => Math.round(v)).join(" x ");

export function renderBom(root: HTMLElement, bom: Bom, view: BomView): void {
  const rows: HTMLElement[] = [];
  for (const [kind, title] of GROUPS) {
    const lines = bom.lines.filter((l) => l.kind === kind);
    if (lines.length === 0) continue;
    rows.push(el("tr", { class: "group" }, [el("th", { colspan: "3" }, [title])]));
    for (const line of lines) {
      const flagged = view.flagged.has(line.key);
      const blocked = line.key.endsWith(":blocked");
      const note = view.unprintable.has(line.key) && line.size ? `${mm(line.size)} mm, does not fit the printbed` : (line.note ?? "");
      const attrs: Record<string, string> = flagged || blocked ? { class: "is-unprintable" } : {};
      rows.push(
        el("tr", attrs, [
          el("td", { class: "qty" }, [String(line.qty)]),
          el("td", {}, [line.label]),
          el("td", { class: "note" }, [note]),
        ]),
      );
    }
  }
  const total = bom.lines.reduce((n, l) => n + l.qty, 0);
  rows.push(
    el("tr", { class: "total" }, [
      el("td", { class: "qty" }, [String(total)]),
      el("td", { colspan: "2" }, ["printed parts in total"]),
    ]),
  );

  const flaggedCount = bom.lines.filter((l) => view.unprintable.has(l.key)).reduce((n, l) => n + l.qty, 0);
  const warning =
    flaggedCount > 0
      ? [el("p", { class: "cfg-warning", role: "status" }, [`${flaggedCount} part${flaggedCount === 1 ? "" : "s"} do${flaggedCount === 1 ? "es" : ""} not fit your printbed.`])]
      : [];

  root.replaceChildren(
    el("h2", {}, ["Parts list"]),
    ...warning,
    el("table", {}, [el("tbody", {}, rows)]),
    el("div", { class: "cfg-bom-actions" }, [
      copyButton(root, "copy-link", "Copy link", view.shareUrl),
      copyButton(root, "copy-md", "Copy as Markdown", view.markdown),
    ]),
  );
}
