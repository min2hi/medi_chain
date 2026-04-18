import { defineConfig, globalIgnores } from "eslint/config";
import nextVitals from "eslint-config-next/core-web-vitals";
import nextTs from "eslint-config-next/typescript";

const eslintConfig = defineConfig([
  ...nextVitals,
  ...nextTs,
  // Override default ignores of eslint-config-next.
  globalIgnores([
    // Default ignores of eslint-config-next:
    ".next/**",
    "out/**",
    "build/**",
    "next-env.d.ts",
  ]),
  // Project-specific rule overrides
  {
    rules: {
      // Downgrade from error to warn: this rule produces false positives for
      // legitimate React patterns: SSR mount guards, auth guards, localStorage hydration.
      // These are one-time initializations, not reactive cascades.
      "react-hooks/set-state-in-effect": "warn",
    },
  },
]);

export default eslintConfig;
