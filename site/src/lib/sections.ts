import type { Element, ElementContent, Root, RootContent } from "hast";
import { toString } from "hast-util-to-string";

export interface SectionizeOptions {
  /** Heading level that starts a new section. */
  level: 1 | 2;
  /** Sections whose heading text matches are removed. */
  skip?: RegExp;
}

function section(children: RootContent[], className: string, id?: string): Element {
  const properties: Element["properties"] = { className: [className] };
  if (id) properties.dataSection = id;
  return { type: "element", tagName: "section", properties, children: children as ElementContent[] };
}

/** Rehype transform: move every heading one level down (h1 -> h2), so a page can own its h1. */
export function demoteHeadings() {
  return (tree: Root): void => {
    for (const node of tree.children) {
      if (node.type !== "element") continue;
      const level = /^h([1-5])$/.exec(node.tagName)?.[1];
      if (level) node.tagName = `h${Number(level) + 1}`;
    }
  };
}

/** Rehype transform: wrap every top-level heading and what follows it in a section element. */
export function sectionize(options: SectionizeOptions) {
  const tag = `h${options.level}`;
  return (tree: Root): void => {
    const out: RootContent[] = [];
    let current: RootContent[] = [];
    let heading: Element | null = null;

    const flush = () => {
      if (current.length === 0) return;
      if (!heading) out.push(section(current, "doc-lead"));
      else if (!options.skip?.test(toString(heading))) {
        out.push(section(current, "doc-section", String(heading.properties.id ?? "")));
      }
      current = [];
    };

    for (const node of tree.children) {
      if (node.type === "element" && node.tagName === tag) {
        flush();
        heading = node;
      }
      current.push(node);
    }
    flush();
    tree.children = out;
  };
}
