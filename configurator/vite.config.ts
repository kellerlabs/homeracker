import { defineConfig } from "vitest/config";

export default defineConfig({
  base: "/configurator/",
  // Serve the part meshes exported for the site (site/public/parts) in standalone mode too.
  publicDir: "../site/public",
  build: {
    outDir: "dist",
    copyPublicDir: false,
    chunkSizeWarningLimit: 800,
  },
  test: {
    environment: "node",
    include: ["tests/**/*.test.ts"],
  },
});
