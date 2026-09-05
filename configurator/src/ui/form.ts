import { BASE_UNIT, LIMITS } from "../engine/constants";
import { frames, resolveAuto, rowSegments, rowWidth } from "../engine/lattice";
import { faceDiagrams, type Diagram } from "../engine/diagrams";
import { closeOpenings, closeReason, openings, panelAt, togglePanel } from "../engine/panels";
import type { Opening, PanelSpec, PanelType, RackConfig, RackRow } from "../engine/types";
import { DEFAULT_BED, type PrinterBed } from "../engine/printer";
import { encodeColumn, MAX_ROW_NAME } from "../engine/url";
import { el, qs } from "./dom";
import { isPartialColumnList, parseColumnList } from "./parse";

const TYPE_LABEL: Record<PanelType | "open", string> = { open: "open", interfit: "inter-fit", fullcover: "full cover" };

/** `pending` means a column list is half-typed: keep the rack as it stands and say nothing yet. */
export type FormResult = { config: RackConfig } | { error: string } | { pending: true };

export interface RackForm {
  read(): FormResult;
  write(config: RackConfig): void;
  /** Assembly problems found in the current rack, shown under the rows. */
  showProblems(messages: string[]): void;
  /** Print volume as entered, in millimetres; falls back to the default bed for empty or invalid fields. */
  readBed(): PrinterBed;
  writeBed(bed: PrinterBed): void;
  /** Highlight one opening in the diagrams (by id); null clears. */
  highlight(id: string | null): void;
}

export interface FormOptions {
  /** Called when the pointer enters or leaves an opening rectangle in a diagram. */
  onHover?: (opening: Opening | null) => void;
}

/** Editable copy of a row: the column text is kept verbatim so half-typed lists are not destroyed. */
interface RowDraft {
  height: number;
  columns: string;
  shift: number;
  through: boolean;
  name: string;
  /** UI only: the card shows a one-line summary instead of its fields. */
  collapsed?: boolean;
}

const ICONS = {
  chevron: "M6 4l4 4-4 4",
  up: "M4 10l4-4 4 4",
  down: "M4 6l4 4 4-4",
  copy: "M5 3h6v6H5zM3 5v7h7",
  remove: "M4 4l8 8M12 4l-8 8",
};

function iconButton(icon: keyof typeof ICONS, label: string, action: string): HTMLButtonElement {
  const button = el("button", { type: "button", class: "cfg-icon", "aria-label": label, title: label, "data-action": action });
  button.innerHTML = `<svg viewBox="0 0 16 16" width="16" height="16" aria-hidden="true"><path d="${ICONS[icon]}" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/></svg>`;
  return button;
}

function numberField(name: string, label: string, min: number, max: number): HTMLElement {
  const input = el("input", { type: "number", name, id: `f-${name}`, min: String(min), max: String(max), step: "1" });
  const readout = el("output", { "data-readout": name });
  return el("div", { class: "field" }, [el("label", { for: `f-${name}` }, [label]), input, readout]);
}

function choice(type: "checkbox" | "radio", name: string, id: string, label: string, value?: string): HTMLElement {
  const attrs: Record<string, string> = { type, name, id };
  if (value) attrs.value = value;
  return el("div", { class: "field inline" }, [el("input", attrs), el("label", { for: id }, [label])]);
}

function infoTrigger(): HTMLElement {
  const btn = el("button", { type: "button", class: "cfg-info-btn", "aria-label": "Column syntax help" });
  btn.innerHTML = `<svg viewBox="0 0 16 16" width="14" height="14" aria-hidden="true"><circle cx="8" cy="8" r="7" fill="none" stroke="currentColor" stroke-width="1.4"/><path d="M8 7v4M8 5.2v.1" stroke="currentColor" stroke-width="1.6" stroke-linecap="round"/></svg>`;
  const tip = el("div", { class: "cfg-info-tip", hidden: "" }, [
    el("dl", { class: "cfg-info-list" }, [
      el("dt", {}, ["6, 10, 6"]),
      el("dd", {}, ["column widths separated by commas"]),
      el("dt", {}, ["-10"]),
      el("dd", {}, ["gap — same space, no beam above"]),
      el("dt", {}, ["_10"]),
      el("dd", {}, ["bottom bar — forces a beam below, over a gap"]),
      el("dt", {}, ["?"]),
      el("dd", {}, ["auto-fill to match the row below"]),
    ]),
  ]);
  document.body.append(tip);
  const position = () => {
    const r = btn.getBoundingClientRect();
    tip.style.top = `${r.bottom + 6}px`;
    tip.style.left = `${r.left}px`;
  };
  btn.addEventListener("click", (e) => {
    e.preventDefault();
    const opening = tip.hidden;
    tip.hidden = !tip.hidden;
    if (opening) position();
  });
  document.addEventListener("pointerdown", (e) => {
    if (!btn.contains(e.target as Node) && !tip.contains(e.target as Node)) tip.hidden = true;
  });
  document.addEventListener("scroll", () => { tip.hidden = true; }, true);
  return btn;
}

const SVG = "http://www.w3.org/2000/svg";

/** Human label of an opening for tooltips and screen readers. */
function openingLabel(opening: Opening, config: RackConfig): string {
  if (opening.face === "horizontal") {
    const level = opening.at === 0 ? "bottom" : `top of row ${opening.at}`;
    return `${level}, span ${opening.index + 1}`;
  }
  if (opening.face === "front" || opening.face === "back") return `${opening.face}, row ${opening.at + 1}, bay ${opening.index + 1}`;
  const row = config.rows[opening.at];
  const sections = row ? rowSegments(row).length : 1;
  return `${opening.face}, row ${opening.at + 1}${sections > 1 ? `, section ${opening.index + 1}` : ""}`;
}

/** A to-scale SVG of one face; every opening is a focusable rectangle that cycles its panel state. */
function diagramView(diagram: Diagram, config: RackConfig): HTMLElement {
  const svg = document.createElementNS(SVG, "svg");
  svg.setAttribute("viewBox", `0 0 ${diagram.width} ${diagram.height}`);
  svg.setAttribute("class", "cfg-diagram");
  svg.setAttribute("role", "group");
  svg.setAttribute("aria-label", diagram.title);
  const scale = Math.min(1, 26 / diagram.width);
  svg.style.width = `${diagram.width * 10 * scale}px`;
  svg.style.height = `${diagram.height * 10 * scale}px`;
  const frame = document.createElementNS(SVG, "rect");
  frame.setAttribute("class", "cfg-diagram-frame");
  frame.setAttribute("x", "0");
  frame.setAttribute("y", "0");
  frame.setAttribute("width", String(diagram.width));
  frame.setAttribute("height", String(diagram.height));
  svg.append(frame);
  for (const cell of diagram.cells) {
    const reason = closeReason(config, cell.opening);
    const closable = reason === null;
    const state = panelAt(config, cell.opening) ?? "open";
    const label = openingLabel(cell.opening, config);
    const size = `${cell.opening.length}x${cell.opening.height} units`;
    const problem = !closable && state !== "open";
    const text = closable
      ? `${label}: ${size}, ${TYPE_LABEL[state]}`
      : problem
        ? `${label}: ${size}, ${TYPE_LABEL[state]} panel placed but ${reason}. Click to remove it.`
        : `${label}: ${size}, ${reason}`;
    const rect = document.createElementNS(SVG, "rect");
    rect.setAttribute("x", String(cell.x));
    rect.setAttribute("y", String(cell.y));
    rect.setAttribute("width", String(cell.w));
    rect.setAttribute("height", String(cell.h));
    rect.setAttribute("class", "cfg-cell");
    rect.setAttribute("data-opening", cell.opening.id);
    rect.setAttribute("data-state", closable ? state : problem ? "problem" : "blocked");
    rect.setAttribute("role", "button");
    rect.setAttribute("aria-label", text);
    rect.setAttribute("tabindex", closable || problem ? "0" : "-1");
    const title = document.createElementNS(SVG, "title");
    title.textContent = text;
    rect.append(title);
    svg.append(rect);
  }
  // "All" shortcuts: set every closable opening of this drawing at once.
  const all = el("span", { class: "cfg-face-all", role: "group", "aria-label": `${diagram.title}: set all openings` }, [
    ...(["open", "interfit", "fullcover"] as const).map((state) =>
      el("button", {
        type: "button",
        class: "cfg-open",
        "data-state": state,
        "data-all": state,
        "data-diagram": diagram.id,
        "aria-label": `${diagram.title}: all ${TYPE_LABEL[state]}`,
        title: `All ${TYPE_LABEL[state]}`,
      }),
    ),
  ]);
  return el("figure", { class: "cfg-face" }, [el("figcaption", {}, [diagram.title, all]), svg]);
}

/** One editable row. `index` counts from the bottom; rows are listed top first to match the 3D view. */
function rowCard(draft: RowDraft, index: number): HTMLElement {
  const id = (name: string) => `f-row-${index}-${name}`;
  const min = String(LIMITS.span.min);
  const max = String(LIMITS.span.max);

  const toggle = iconButton("chevron", draft.collapsed ? "Expand row" : "Collapse row", "toggle");
  toggle.setAttribute("aria-expanded", String(!draft.collapsed));
  const summary = [
    `${draft.height} high`,
    `${draft.columns.trim() || "?"} wide`,
    draft.shift ? `shift ${draft.shift}` : "",
    index > 0 && draft.through ? "posts continue" : "",
  ].filter(Boolean);
  return el("div", { class: `cfg-row${draft.collapsed ? " is-collapsed" : ""}`, "data-index": String(index) }, [
    el("div", { class: "cfg-row-head" }, [
      toggle,
      el("span", { class: "cfg-row-name" }, [
        el("input", {
          type: "text",
          name: "name",
          id: id("name"),
          class: "cfg-row-title",
          value: draft.name,
          maxlength: String(MAX_ROW_NAME),
          placeholder: `Row ${index + 1}`,
          "aria-label": `Name of row ${index + 1}`,
          size: String(Math.max(6, Math.min(MAX_ROW_NAME, (draft.name.trim() || `Row ${index + 1}`).length + 1))),
        }),
      ]),
      el("span", { class: "cfg-row-summary" }, [summary.join(" · ")]),
      el("span", { class: "cfg-row-tools" }, [
        iconButton("up", "Move row up", "up"),
        iconButton("down", "Move row down", "down"),
        iconButton("copy", "Duplicate row", "copy"),
        iconButton("remove", "Remove row", "remove"),
      ]),
    ]),
    el("div", { class: "cfg-row-fields" }, [
      el("div", { class: "field" }, [
        el("label", { for: id("height") }, ["Height"]),
        el("input", { type: "number", name: "height", id: id("height"), min, max, step: "1", value: String(draft.height) }),
      ]),
      el("div", { class: "field" }, [
        el("label", { for: id("shift") }, ["Shift"]),
        el("input", { type: "number", name: "shift", id: id("shift"), min: "0", max, step: "1", value: String(draft.shift) }),
      ]),
      el("div", { class: "field wide" }, [
        el("label", { for: id("columns") }, ["Column widths ", infoTrigger()]),
        el("input", { type: "text", name: "columns", id: id("columns"), value: draft.columns, placeholder: "e.g. 4, 4 or 6, -10, 6" }),
      ]),
    ]),
    ...(index > 0
      ? [
          el("div", { class: "field inline cfg-through" }, [
            el("input", { type: "checkbox", name: "through", id: id("through"), ...(draft.through ? { checked: "" } : {}) }),
            el("label", { for: id("through") }, ["Posts continue from the row below"]),
          ]),
        ]
      : []),
  ]);
}

/** Keep panel specs attached to the right rows and frames when rows are inserted, removed or swapped. */
export function remapPanels(panels: PanelSpec[], op: "insert" | "remove" | "swap", at: number): PanelSpec[] {
  const out: PanelSpec[] = [];
  for (const p of panels) {
    const vertical = p.face !== "horizontal";
    if (op === "insert") {
      // New row lands at index `at`; rows from `at` up and frames above `at` move up by one.
      if (vertical && p.at >= at) out.push({ ...p, at: p.at + 1 });
      else if (!vertical && p.at > at) out.push({ ...p, at: p.at + 1 });
      else out.push(p);
    } else if (op === "remove") {
      // Row `at` and the frame above it disappear.
      if (vertical && p.at === at) continue;
      if (!vertical && p.at === at + 1) continue;
      if (vertical && p.at > at) out.push({ ...p, at: p.at - 1 });
      else if (!vertical && p.at > at + 1) out.push({ ...p, at: p.at - 1 });
      else out.push(p);
    } else {
      // Rows `at` and `at + 1` trade places; the frame between them keeps its index.
      if (vertical && p.at === at) out.push({ ...p, at: at + 1 });
      else if (vertical && p.at === at + 1) out.push({ ...p, at });
      else out.push(p);
    }
  }
  return out;
}

export function renderForm(root: HTMLElement, onChange: () => void, options: FormOptions = {}): RackForm {
  let drafts: RowDraft[] = [];
  let panels: PanelSpec[] = [];

  const rowList = el("div", { class: "cfg-rows" });
  const problems = el("ul", { class: "cfg-problems", role: "status" });
  const faces = el("div", { class: "cfg-faces" });
  /** Face groups start folded; drawings are re-rendered on every change, so the fold state lives here. */
  const foldedGroups = new Set<string>(["Front and back", "Sides", "Tops and bottom"]);
  const addButton = el("button", { type: "button", class: "cfg-add", "data-action": "add" }, ["Add row on top"]);
  const section = (title: string, children: (Node | string)[]) =>
    el("details", { class: "cfg-section", open: "" }, [el("summary", {}, [title]), ...children]);
  const form = el("form", { id: "rack-form" }, [
    section("Rows, top to bottom", [
      addButton,
      rowList,
      el("ul", { id: "issues", role: "alert" }),
      problems,
      el("div", { class: "cfg-outer", "data-readout": "outer", hidden: "" }, [
        el("span", { class: "cfg-outer-label" }, ["Outer size"]),
        el("span", { class: "cfg-outer-value" }),
      ]),
    ]),
    section("Panels", [
      el("p", { class: "cfg-legend" }, [
        el("span", { class: "cfg-open", "data-state": "open", "aria-hidden": "true" }),
        " open ",
        el("span", { class: "cfg-open", "data-state": "interfit", "aria-hidden": "true" }),
        " inter-fit ",
        el("span", { class: "cfg-open", "data-state": "fullcover", "aria-hidden": "true" }),
        " full cover",
      ]),
      faces,
    ]),

    el("fieldset", {}, [
      el("legend", {}, ["Footprint"]),
      numberField("depth", "Depth (units)", LIMITS.span.min, LIMITS.span.max),
    ]),
    el("fieldset", {}, [el("legend", {}, ["Structure"]), choice("checkbox", "feet", "f-feet", "Feet")]),
    el("fieldset", { class: "cfg-printer" }, [
      el("legend", {}, ["Printbed size"]),
      el("div", { class: "cfg-bed" }, [
        ...(["x", "y", "z"] as const).map((axis) =>
          el("div", { class: "field" }, [
            el("label", { for: `f-bed-${axis}` }, [`${axis.toUpperCase()} (mm)`]),
            el("input", { type: "number", name: `bed-${axis}`, id: `f-bed-${axis}`, min: "50", max: "2000", step: "1" }),
          ]),
        ),
      ]),
    ]),
  ]);
  root.append(form);

  const input = <T extends HTMLElement>(name: string) => qs<T>(form, `[name="${name}"]`);
  const num = (name: string) => Number(input<HTMLInputElement>(name).value);

  const draftRows = (): RackRow[] | null => {
    const rows: RackRow[] = [];
    for (let i = 0; i < drafts.length; i++) {
      const d = drafts[i]!;
      const parsed = parseColumnList(d.columns);
      if (!parsed) return null;
      const autos = parsed.columns.flatMap((c, j) => (c === null ? [j] : []));
      let columns: number[];
      if (autos.length > 0) {
        if (i === 0) return null;
        const resolved = resolveAuto(parsed.columns, d.shift, rows[i - 1]!);
        if (!resolved) return null;
        columns = resolved;
      } else {
        columns = parsed.columns as number[];
      }
      const name = d.name.trim();
      rows.push({
        height: d.height,
        columns,
        shift: d.shift,
        through: d.through,
        ...(parsed.bars.length > 0 ? { bars: parsed.bars } : {}),
        ...(autos.length > 0 ? { autos } : {}),
        ...(name ? { name } : {}),
      });
    }
    return rows;
  };

  /** Config as currently drafted, or null while a column list is unparsable. */
  const draftConfig = (): RackConfig | null => {
    const rows = draftRows();
    if (!rows || rows.length === 0) return null;
    return { depth: num("depth"), rows, feet: input<HTMLInputElement>("feet").checked, panels };
  };

  const updateReadouts = () => {
    qs<HTMLOutputElement>(form, '[data-readout="depth"]').textContent = `${(num("depth") + 2) * BASE_UNIT} mm outer`;
    const config = draftConfig();
    const outer = qs<HTMLElement>(form, '[data-readout="outer"]');
    const outerValue = qs<HTMLElement>(form, ".cfg-outer-value");
    if (!config) {
      outer.hidden = true;
      return;
    }
    outer.hidden = false;
    const width = Math.max(...config.rows.map((r) => r.shift + rowWidth(r)));
    const height = (frames(config).at(-1)?.z ?? 0) + 1;
    outerValue.textContent = `${width * BASE_UNIT} x ${(config.depth + 2) * BASE_UNIT} x ${height * BASE_UNIT} mm`;
  };

  const renderFaces = () => {
    const config = draftConfig();
    if (!config) {
      faces.replaceChildren();
      return;
    }
    const diagrams = faceDiagrams(config);
    const groups: [string, Diagram[]][] = [
      ["Front and back", diagrams.filter((d) => d.id === "front" || d.id === "back")],
      ["Sides", diagrams.filter((d) => d.id === "left" || d.id === "right" || d.id.startsWith("gap:"))],
      ["Tops and bottom", diagrams.filter((d) => d.id.startsWith("horizontal"))],
    ];
    faces.replaceChildren(
      ...groups.map(([title, list]) => {
        const group = el("details", { class: "cfg-face-group", "data-group": title, ...(foldedGroups.has(title) ? {} : { open: "" }) }, [
          el("summary", { class: "cfg-face-group-title" }, [title]),
          el("div", { class: "cfg-face-group-list" }, list.map((d) => diagramView(d, config))),
        ]);
        group.addEventListener("toggle", () => {
          if (group.open) foldedGroups.delete(title);
          else foldedGroups.add(title);
        });
        return group;
      }),
    );
  };

  const renderRows = () => {
    const cards = drafts.map((d, i) => rowCard(d, i)).reverse();
    rowList.replaceChildren(...cards);
    renderFaces();
    updateReadouts();
  };

  const changed = () => {
    renderFaces();
    updateReadouts();
    onChange();
  };

  const toggleOpening = (id: string | undefined) => {
    const config = draftConfig();
    const opening = config && openings(config).find((o) => o.id === id);
    if (!config || !opening) return;
    if (closeReason(config, opening) !== null) {
      if (!panelAt(config, opening)) return;
      panels = closeOpenings(config, [opening], null).panels;
    } else {
      panels = togglePanel(config, opening).panels;
    }
    changed();
  };

  const cellOf = (target: EventTarget | null) => (target as Element | null)?.closest<SVGRectElement>("rect[data-opening]") ?? null;

  faces.addEventListener("click", (event) => {
    const cell = cellOf(event.target);
    if (cell) {
      toggleOpening(cell.dataset.opening);
      return;
    }
    const all = (event.target as Element).closest<HTMLButtonElement>("button[data-all]");
    const config = all && draftConfig();
    if (!all || !config) return;
    const diagram = faceDiagrams(config).find((d) => d.id === all.dataset.diagram);
    if (!diagram) return;
    const state = all.dataset.all as PanelType | "open";
    panels = closeOpenings(config, diagram.cells.map((c) => c.opening), state === "open" ? null : state).panels;
    changed();
  });
  faces.addEventListener("keydown", (event) => {
    const cell = cellOf(event.target);
    if (!cell || (event.key !== "Enter" && event.key !== " ")) return;
    event.preventDefault();
    toggleOpening(cell.dataset.opening);
  });
  faces.addEventListener("pointerover", (event) => {
    const cell = cellOf(event.target);
    const config = cell && draftConfig();
    options.onHover?.(config ? (openings(config).find((o) => o.id === cell.dataset.opening) ?? null) : null);
  });
  faces.addEventListener("pointerleave", () => options.onHover?.(null));

  rowList.addEventListener("input", (event) => {
    const target = event.target as HTMLInputElement;
    const index = Number(target.closest<HTMLElement>(".cfg-row")?.dataset.index);
    const draft = drafts[index];
    if (!draft) return;
    if (target.name === "height") draft.height = Number(target.value);
    if (target.name === "columns") draft.columns = target.value;
    if (target.name === "shift") draft.shift = Number(target.value);
    if (target.name === "through") draft.through = (target as HTMLInputElement).checked;
    if (target.name === "name") {
      // The title is the input itself; grow it with its content and keep focus (no re-render).
      draft.name = target.value;
      target.size = Math.max(6, Math.min(MAX_ROW_NAME, (target.value.trim() || `Row ${index + 1}`).length + 1));
    }
    changed();
  });

  form.addEventListener("click", (event) => {
    const target = event.target as HTMLElement;
    const button = target.closest<HTMLButtonElement>("button[data-action]");
    if (!button) return;
    const action = button.dataset.action;
    const index = Number(button.closest<HTMLElement>(".cfg-row")?.dataset.index ?? -1);
    const current = drafts[index];
    if (action === "toggle" && current) {
      current.collapsed = !current.collapsed;
      renderRows();
      return;
    }
    if (action === "add") {
      const top = drafts[drafts.length - 1];
      drafts.push(top ? { ...top, name: "", collapsed: false, through: false } : { height: 4, columns: "6", shift: 0, through: false, name: "", collapsed: false });
    } else if (action === "copy" && current) {
      drafts.splice(index + 1, 0, { ...current, name: "", collapsed: false });
      panels = remapPanels(panels, "insert", index + 1);
    } else if (action === "remove" && current && drafts.length > 1) {
      drafts.splice(index, 1);
      panels = remapPanels(panels, "remove", index);
    } else if (action === "up" && current && index < drafts.length - 1) {
      drafts.splice(index, 2, drafts[index + 1]!, current);
      panels = remapPanels(panels, "swap", index);
    } else if (action === "down" && current && index > 0) {
      drafts.splice(index - 1, 2, current, drafts[index - 1]!);
      panels = remapPanels(panels, "swap", index - 1);
    } else {
      return;
    }
    renderRows();
    onChange();
  });

  form.addEventListener("input", (event) => {
    if (rowList.contains(event.target as Node)) return;
    changed();
  });

  const bedInput = (axis: "x" | "y" | "z") => input<HTMLInputElement>(`bed-${axis}`);

  return {
    showProblems(messages) {
      problems.replaceChildren(...messages.map((m) => el("li", {}, [m])));
    },
    readBed() {
      const value = (axis: "x" | "y" | "z") => {
        const n = Number(bedInput(axis).value);
        return Number.isFinite(n) && n >= 50 ? n : DEFAULT_BED[axis];
      };
      return { x: value("x"), y: value("y"), z: value("z") };
    },
    writeBed(bed) {
      for (const axis of ["x", "y", "z"] as const) bedInput(axis).value = String(bed[axis]);
    },
    highlight(id) {
      for (const rect of faces.querySelectorAll<SVGRectElement>("rect[data-opening]")) {
        rect.classList.toggle("is-hot", rect.dataset.opening === id);
      }
    },
    read() {
      const config = draftConfig();
      if (!config) {
        if (drafts.some((d) => parseColumnList(d.columns) === null && isPartialColumnList(d.columns))) return { pending: true };
        return { error: "column widths must be whole numbers separated by commas; a negative width is a gap" };
      }
      const all = openings(config);
      const live = panels.filter((p) => all.some((o) => o.face === p.face && o.at === p.at && o.index === p.index));
      return { config: { ...config, panels: live } };
    },
    write(config) {
      drafts = config.rows.map((r) => ({
        height: r.height,
        columns: r.columns.map((_, i) => encodeColumn(r, i)).join(", "),
        shift: r.shift,
        through: r.through,
        name: r.name ?? "",
        collapsed: true,
      }));
      panels = [...config.panels];
      input<HTMLInputElement>("depth").value = String(config.depth);
      input<HTMLInputElement>("feet").checked = config.feet;
      renderRows();
    },
  };
}

export function showIssues(root: HTMLElement, messages: string[]): void {
  const list = qs<HTMLUListElement>(root, "#issues");
  list.replaceChildren(...messages.map((m) => el("li", {}, [m])));
}
