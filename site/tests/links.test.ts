import { describe, expect, test } from "vitest";
import { rewriteHref } from "../src/lib/links";

describe("rewriteHref", () => {
  test("leaves absolute urls and anchors alone", () => {
    expect(rewriteHref("https://makerworld.com/x", "README.md")).toBe("https://makerworld.com/x");
    expect(rewriteHref("#-use-cases", "README.md")).toBe("#-use-cases");
  });

  test("maps model readmes to model pages", () => {
    expect(rewriteHref("models/core/README.md", "README.md")).toBe("/models/core/");
    expect(rewriteHref("models/core/", "README.md")).toBe("/models/core/");
    expect(rewriteHref("core/README.md", "models/README.md")).toBe("/models/core/");
    expect(rewriteHref("../core/README.md", "models/panel/README.md")).toBe("/models/core/");
  });

  test("maps the models index and root readme", () => {
    expect(rewriteHref("../README.md", "models/core/README.md")).toBe("/models/");
    expect(rewriteHref("../../README.md#-tech-specs", "models/core/README.md")).toBe("/#-tech-specs");
  });

  test("maps the configurator readme to the app", () => {
    expect(rewriteHref("configurator/README.md", "README.md")).toBe("/configurator/");
  });

  test("mounts site routes under a preview base", () => {
    const base = "/preview/pr-42/";
    expect(rewriteHref("models/core/README.md", "README.md", base)).toBe("/preview/pr-42/models/core/");
    expect(rewriteHref("../README.md", "models/core/README.md", base)).toBe("/preview/pr-42/models/");
    expect(rewriteHref("configurator/README.md", "README.md", base)).toBe("/preview/pr-42/configurator/");
    expect(rewriteHref("../../README.md#-tech-specs", "models/core/README.md", base)).toBe("/preview/pr-42/#-tech-specs");
  });

  test("normalises any slash spelling of the base, matching what astro does with the same value", () => {
    for (const base of ["/preview/pr-42/", "/preview/pr-42", "preview/pr-42", "//preview/pr-42//"]) {
      expect(rewriteHref("models/core/README.md", "README.md", base)).toBe("/preview/pr-42/models/core/");
    }
    for (const base of ["/", "", "//"]) {
      expect(rewriteHref("models/core/README.md", "README.md", base)).toBe("/models/core/");
    }
  });

  test("leaves github fallbacks unprefixed under a preview base", () => {
    expect(rewriteHref("CONTRIBUTING.md", "README.md", "/preview/pr-42/")).toBe(
      "https://github.com/kellerlabs/homeracker/blob/main/CONTRIBUTING.md",
    );
  });

  test("sends everything else to github", () => {
    expect(rewriteHref("CONTRIBUTING.md", "README.md")).toBe("https://github.com/kellerlabs/homeracker/blob/main/CONTRIBUTING.md");
    expect(rewriteHref("../../docs/decisions/x.md", "models/panel/README.md")).toBe(
      "https://github.com/kellerlabs/homeracker/blob/main/docs/decisions/x.md",
    );
    expect(rewriteHref("lib/truss.scad", "models/panel/README.md")).toBe(
      "https://github.com/kellerlabs/homeracker/blob/main/models/panel/lib/truss.scad",
    );
  });
});
