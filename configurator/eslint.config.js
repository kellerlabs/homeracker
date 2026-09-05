import js from "@eslint/js";
import tseslint from "typescript-eslint";

export default tseslint.config(
  { ignores: ["dist/**", "node_modules/**"] },
  js.configs.recommended,
  ...tseslint.configs.recommended,
  {
    files: ["src/engine/**/*.ts"],
    rules: {
      "no-restricted-imports": [
        "error",
        {
          patterns: [
            { group: ["three", "three/*"], message: "engine must stay free of three.js" },
            { group: ["**/render/*", "**/ui/*"], message: "engine must not depend on render or ui" },
          ],
        },
      ],
      "no-restricted-globals": ["error", "window", "document", "navigator", "location"],
    },
  },
);
