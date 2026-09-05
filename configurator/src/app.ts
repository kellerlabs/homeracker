import { computeBom } from "./engine/bom";
import { defaultConfig } from "./engine/defaults";
import { bomToMarkdown } from "./engine/markdown";
import { resolveConfigAutos } from "./engine/lattice";
import { buildModel } from "./engine/model";
import { togglePanel } from "./engine/panels";
import { unprintable, type PrinterBed } from "./engine/printer";
import type { RackConfig } from "./engine/types";
import { validate } from "./engine/validate";
import { createViewer } from "./render/scene";
import { renderBom } from "./ui/bomTable";
import { el } from "./ui/dom";
import { renderForm, showIssues } from "./ui/form";
import { forgetPersistentStorage, loadBed, loadRack, saveBed, saveRack } from "./ui/storage";
import { onHashChange, readHash, shareUrl, writeHash } from "./ui/hash";

export interface ConfiguratorOptions {
  /** Base URL of the exported part meshes; omit to draw schematic boxes. */
  partsUrl?: string;
}

/**
 * Build the configurator inside `root`: controls, 3D stage and parts list.
 * Used by the standalone app (index.html) and by the site's /configurator/ page.
 */
export function mountConfigurator(root: HTMLElement, options: ConfiguratorOptions = {}): void {
  const controls = el("aside", { class: "cfg-controls", "aria-label": "Rack settings" });
  const canvas = el("canvas", { class: "cfg-canvas", "aria-label": "3D preview of the rack; click an opening to add or remove a panel" });
  const stage = el("div", { class: "cfg-stage" }, [canvas]);
  const bomRoot = el("section", { class: "cfg-bom", "aria-label": "Parts list" });
  root.replaceChildren(el("div", { class: "cfg" }, [controls, stage, bomRoot]));

  forgetPersistentStorage();

  let current: RackConfig = defaultConfig();
  let bed: PrinterBed = loadBed();

  const viewer = createViewer(canvas, {
    partsUrl: options.partsUrl,
    onOpening(opening) {
      const next = togglePanel(current, opening);
      form.write(next);
      apply(next);
    },
    onHover(opening) {
      form.highlight(opening?.id ?? null);
    },
  });

  const apply = (config: RackConfig): boolean => {
    const resolved = resolveConfigAutos(config);
    if (!resolved) {
      showIssues(controls, ["auto-fill column (?) needs a row below and must produce a valid width"]);
      return false;
    }
    const issues = validate(resolved);
    showIssues(
      controls,
      issues.map((i) => i.message),
    );
    if (issues.length > 0) return false;
    current = config;
    const model = buildModel(resolved);
    const bom = computeBom(model);
    const notPrintable = unprintable(bom, bed);
    const flagged = new Set(notPrintable);
    for (const problem of model.problems) {
      for (const id of problem.supportIds) {
        const support = model.supports.find((s) => s.id === id);
        if (support) flagged.add(`support:${support.length}`);
      }
    }
    form.showProblems(model.problems.map((p) => p.message));
    viewer.show(model, flagged);
    renderBom(bomRoot, bom, {
      flagged,
      unprintable: notPrintable,
      markdown: () => bomToMarkdown(bom, config, shareUrl(config)),
      shareUrl: () => shareUrl(config),
    });
    writeHash(config);
    // Same moment as the hash: one place where a valid rack is committed, so the two cannot drift.
    saveRack(config);
    return true;
  };

  let timer: number | undefined;
  const form = renderForm(
    controls,
    () => {
      window.clearTimeout(timer);
      timer = window.setTimeout(() => {
        bed = form.readBed();
        saveBed(bed);
        const result = form.read();
        // A half-typed gap is not a mistake: leave the rack and the issue list as they are.
        if ("pending" in result) return;
        if ("error" in result) showIssues(controls, [result.error]);
        else apply(result.config);
      }, 100);
    },
    { onHover: (opening) => viewer.highlight(opening?.id ?? null) },
  );

  const credit = el("footer", { class: "cfg-credit" });
  credit.innerHTML =
    'Configurator created by <a href="https://ko-fi.com/dirnei" target="_blank" rel="noopener">Dirnei</a>';
  controls.appendChild(credit);

  form.writeBed(bed);
  // A link someone shared always wins; otherwise pick up where this tab left off.
  const initial = readHash() ?? loadRack() ?? defaultConfig();
  form.write(initial);
  if (!apply(initial)) {
    form.write(defaultConfig());
    apply(defaultConfig());
  }
  onHashChange((config) => {
    form.write(config);
    apply(config);
  });
}
