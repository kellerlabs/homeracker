const GITHUB_BLOB = "https://github.com/kellerlabs/homeracker/blob/main/";

/** Resolve a relative link against the directory of a repo-relative markdown path. */
function resolveRepoPath(href: string, sourcePath: string): string {
  const dir = sourcePath.split("/").slice(0, -1);
  const parts = [...dir];
  for (const segment of href.split("/")) {
    if (segment === "" || segment === ".") continue;
    if (segment === "..") parts.pop();
    else parts.push(segment);
  }
  return parts.join("/");
}

/**
 * Rewrite a markdown link target so it points at a site page, or at GitHub when the site has no
 * page for it. `base` is the site's mount point and must end in a slash.
 */
export function rewriteHref(href: string, sourcePath: string, base = "/"): string {
  if (/^([a-z]+:|#|\/)/i.test(href)) return href;
  const [pathPart, anchor] = href.split("#");
  const repoPath = resolveRepoPath(pathPart ?? "", sourcePath);
  const suffix = anchor ? `#${anchor}` : "";
  const trailingDir = (pathPart ?? "").endsWith("/");

  if (repoPath === "README.md" || repoPath === "") return `${base}${suffix}`;
  if (repoPath === "models/README.md" || repoPath === "models") return `${base}models/${suffix}`;
  if (repoPath === "configurator/README.md" || repoPath === "configurator") return `${base}configurator/${suffix}`;
  const model = repoPath.match(/^models\/([^/]+)(\/README\.md)?$/);
  if (model && (model[2] || trailingDir)) return `${base}models/${model[1]}/${suffix}`;
  return `${GITHUB_BLOB}${repoPath}${suffix}`;
}
