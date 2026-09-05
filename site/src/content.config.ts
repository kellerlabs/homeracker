import { glob } from "astro/loaders";
import { defineCollection } from "astro:content";

const models = defineCollection({
  loader: glob({
    pattern: "*/README.md",
    base: "../models",
    generateId: ({ entry }) => entry.split("/")[0] ?? entry,
  }),
});

const docs = defineCollection({
  loader: glob({
    pattern: ["README.md", "models/README.md"],
    base: "..",
    generateId: ({ entry }) => (entry === "README.md" ? "home" : "models"),
  }),
});

export const collections = { models, docs };
