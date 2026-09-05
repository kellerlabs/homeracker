export interface CatalogCard {
  slug: string;
  title: string;
  description: string;
  /** Path relative to the models directory, or null when the index has no render for it. */
  image: string | null;
  deprecated: boolean;
}

/** Turn the `### Model` blocks of models/README.md into catalog cards, in document order. */
export function parseCatalog(body: string): CatalogCard[] {
  const cards: CatalogCard[] = [];
  const blocks = body.split(/^### /m).slice(1);
  for (const block of blocks) {
    const [heading = "", ...rest] = block.split("\n");
    const content = rest.join("\n").split(/^## /m)[0] ?? "";
    const slug = content.match(/\[([\w-]+)\/README\.md\]/)?.[1];
    if (!slug) continue;
    const description = content
      .split(/\n\s*\n/)
      .map((p) => p.trim())
      .find((p) => p && !p.startsWith("!") && !p.startsWith("See "));
    const image = content.match(/!\[[^\]]*\]\((?:\.\/)?([^)]+\.png)\)/)?.[1] ?? null;
    cards.push({
      slug,
      title: heading.trim(),
      description: description ?? "",
      image,
      deprecated: /deprecated/i.test(heading),
    });
  }
  return cards;
}
