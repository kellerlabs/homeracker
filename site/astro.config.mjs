import { unified } from "@astrojs/markdown-remark";
import { defineConfig } from "astro/config";
import { rehypeRepoLinks, rehypeSections } from "./src/lib/rehype.ts";

export default defineConfig({
  site: "https://homeracker.org",
  outDir: "dist",
  trailingSlash: "always",
  image: {
    // Only the logo is fetched and optimized at build time; other assets-repo images load as they are,
    // so a build never depends on reaching every image in kellerlabs/assets.
    remotePatterns: [
      { protocol: "https", hostname: "raw.githubusercontent.com", pathname: "/kellerlabs/assets/main/homeracker/img/homeracker_logo.png" },
    ],
  },
  markdown: {
    processor: unified({ rehypePlugins: [rehypeRepoLinks, rehypeSections] }),
  },
  vite: {
    resolve: { dedupe: ["three"] },
    server: { fs: { allow: [".."] } },
  },
});
