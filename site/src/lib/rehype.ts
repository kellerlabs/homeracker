import type { Root } from "hast";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { visit } from "unist-util-visit";
import type { VFile } from "vfile";
import { rewriteHref } from "./links";
import { demoteHeadings, sectionize, type SectionizeOptions } from "./sections";

const REPO_ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../../..");
// Read from the environment rather than import.meta.env: rehype plugins run in Node during the
// build, outside the client bundle Vite injects BASE_URL into. Mirrors base in astro.config.mjs.
const BASE = process.env.SITE_BASE ?? "/";

/** Rewrite relative markdown links to site routes or GitHub, based on the file being rendered. */
export function rehypeRepoLinks() {
  return (tree: Root, file: VFile): void => {
    const sourcePath = path.relative(REPO_ROOT, file.path ?? "").split(path.sep).join("/");
    visit(tree, "element", (node) => {
      if (node.tagName !== "a" || typeof node.properties.href !== "string") return;
      node.properties.href = rewriteHref(node.properties.href, sourcePath, BASE);
      if (/^https?:/.test(node.properties.href)) {
        node.properties.target = "_blank";
        node.properties.rel = ["noopener"];
      }
    });
  };
}

/** Root README: demote headings (the hero owns the h1) and section by h2. Model READMEs: section by h2. */
export function rehypeSections() {
  return (tree: Root, file: VFile): void => {
    const isRoot = path.relative(REPO_ROOT, file.path ?? "") === "README.md";
    if (isRoot) demoteHeadings()(tree);
    const options: SectionizeOptions = isRoot ? { level: 2, skip: /table of contents/i } : { level: 2 };
    sectionize(options)(tree);
  };
}
