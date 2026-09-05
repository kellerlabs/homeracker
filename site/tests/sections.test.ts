import type { Root } from "hast";
import { describe, expect, test } from "vitest";
import { sectionize } from "../src/lib/sections";

const h = (tag: string, text: string) => ({ type: "element" as const, tagName: tag, properties: {}, children: [{ type: "text" as const, value: text }] });
const p = (text: string) => h("p", text);

describe("sectionize", () => {
  test("wraps each top heading with its following nodes in a section", () => {
    const tree: Root = { type: "root", children: [h("h1", "Intro"), p("a"), h("h1", "Specs"), p("b"), p("c")] };
    sectionize({ level: 1 })(tree);
    expect(tree.children.map((n) => (n as { tagName: string }).tagName)).toEqual(["section", "section"]);
    const [first, second] = tree.children as { children: { tagName: string }[]; properties: Record<string, unknown> }[];
    expect(first?.children.map((c) => c.tagName)).toEqual(["h1", "p"]);
    expect(second?.children.map((c) => c.tagName)).toEqual(["h1", "p", "p"]);
  });

  test("keeps nodes before the first heading in a lead section", () => {
    const tree: Root = { type: "root", children: [p("lead"), h("h1", "Intro"), p("a")] };
    sectionize({ level: 1 })(tree);
    const [lead] = tree.children as { properties: Record<string, unknown> }[];
    expect(lead?.properties.className).toEqual(["doc-lead"]);
  });

  test("drops sections whose heading matches the skip pattern", () => {
    const tree: Root = { type: "root", children: [h("h1", "📑 Table of Contents"), p("toc"), h("h1", "Specs"), p("b")] };
    sectionize({ level: 1, skip: /table of contents/i })(tree);
    expect(tree.children).toHaveLength(1);
  });

  test("uses the heading id as the section id", () => {
    const tree: Root = { type: "root", children: [{ ...h("h1", "Specs"), properties: { id: "-specs" } }, p("b")] };
    sectionize({ level: 1 })(tree);
    const [section] = tree.children as { properties: Record<string, unknown> }[];
    expect(section?.properties.dataSection).toBe("-specs");
  });
});

describe("demoteHeadings", () => {
  test("moves every heading one level down", async () => {
    const { demoteHeadings } = await import("../src/lib/sections");
    const tree: Root = { type: "root", children: [h("h1", "A"), h("h2", "B"), h("h6", "C"), p("x")] };
    demoteHeadings()(tree);
    expect(tree.children.map((n) => (n as { tagName: string }).tagName)).toEqual(["h2", "h3", "h6", "p"]);
  });
});
