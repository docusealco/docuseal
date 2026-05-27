// Fast ESLint config for quick development feedback
// Skips type-aware rules that require TypeScript compilation

const { FlatCompat } = require("@eslint/eslintrc")
const js = require("@eslint/js")
const typescriptParser = require("@typescript-eslint/parser")
const typescriptPlugin = require("@typescript-eslint/eslint-plugin")
const jestPlugin = require("eslint-plugin-jest")
const prettierConfig = require("eslint-config-prettier")

const compat = new FlatCompat({
  baseDirectory: __dirname,
  recommendedConfig: js.configs.recommended
})

module.exports = [
  // Global ignores (replaces .eslintignore)
  {
    ignores: [
      "lib/**", // Ruby files, not JavaScript
      "**/node_modules/**", // Third-party dependencies
      "vendor/**", // Vendored dependencies
      "spec/**", // Ruby specs, not JavaScript
      "package/**/*.js", // Generated/compiled JavaScript from TypeScript
      "package/**/*.d.ts" // Generated TypeScript declaration files
    ]
  },

  // Global linter options
  {
    linterOptions: {
      reportUnusedDisableDirectives: "error",
      reportUnusedInlineConfigs: "error"
    }
  },

  // Base config for all JS files
  ...compat.extends("airbnb"),
  {
    languageOptions: {
      ecmaVersion: 2020,
      sourceType: "module",
      globals: {
        // Browser globals
        window: "readonly",
        document: "readonly",
        navigator: "readonly",
        console: "readonly",
        // Node globals
        process: "readonly",
        __dirname: "readonly",
        __filename: "readonly",
        module: "readonly",
        require: "readonly",
        exports: "readonly",
        global: "readonly",
        Buffer: "readonly"
      }
    },
    rules: {
      // Webpack handles module resolution, not ESLint
      "import/no-unresolved": "off",
      // Allow importing devDependencies in config/test files
      "import/no-extraneous-dependencies": "off",
      // TypeScript handles extensions, not needed for JS imports
      "import/extensions": "off",
      indent: ["error", 2],
      // Allow for...of loops - modern JS syntax
      "no-restricted-syntax": "off",
      // Allow console statements - used for debugging/logging throughout
      "no-console": "off"
    },
    settings: {
      react: {
        // Suppress "react package not installed" warning
        // This project doesn't use React but airbnb config requires react-plugin
        version: "999.999.999"
      }
    }
  },

  // Jest test files
  {
    files: ["test/**"],
    plugins: {
      jest: jestPlugin
    },
    languageOptions: {
      globals: {
        ...jestPlugin.environments.globals.globals
      }
    },
    rules: {
      ...jestPlugin.configs.recommended.rules,
      ...jestPlugin.configs.style.rules,
      "global-require": "off",
      "jest/prefer-called-with": "error",
      "jest/no-conditional-in-test": "error",
      "jest/no-test-return-statement": "error",
      "jest/prefer-expect-resolves": "error",
      "jest/require-to-throw-message": "error",
      "jest/require-top-level-describe": "error",
      "jest/prefer-hooks-on-top": "error",
      "jest/prefer-lowercase-title": [
        "error",
        { ignoreTopLevelDescribe: true }
      ],
      "jest/prefer-spy-on": "error",
      "jest/prefer-strict-equal": "error",
      "jest/prefer-todo": "error"
    }
  },

  // TypeScript files - fast mode without type-aware linting
  {
    files: ["**/*.ts", "**/*.tsx"],
    languageOptions: {
      parser: typescriptParser,
      parserOptions: {
        // No project specified - disables type-aware linting
        ecmaVersion: 2020,
        sourceType: "module"
      }
    },
    plugins: {
      "@typescript-eslint": typescriptPlugin
    },
    rules: {
      ...typescriptPlugin.configs.recommended.rules,
      // Same rules as main config minus type-aware ones
      "import/no-unresolved": "off",
      "import/no-extraneous-dependencies": "off",
      "import/extensions": "off",
      "no-use-before-define": "off",
      "@typescript-eslint/no-use-before-define": ["error"],
      "@typescript-eslint/no-unused-vars": [
        "error",
        { argsIgnorePattern: "^_", varsIgnorePattern: "^_" }
      ],
      "@typescript-eslint/no-explicit-any": "error",
      "@typescript-eslint/explicit-module-boundary-types": "off",
      "no-undef": "off"
    }
  },

  // Global rule for all TypeScript files in package/
  // Suppress require() imports - these are intentional for CommonJS compatibility
  // Will be addressed in Phase 3 (breaking changes) - see #708
  {
    files: ["package/**/*.ts"],
    rules: {
      "@typescript-eslint/no-require-imports": "off",
      "global-require": "off",
      "import/no-import-module-exports": "off"
    }
  },

  // Consolidated override for package/config.ts and package/babel/preset.ts
  {
    files: ["package/babel/preset.ts", "package/config.ts"],
    rules: {
      "@typescript-eslint/no-unused-vars": "off",
      "import/order": "off",
      "import/newline-after-import": "off",
      "import/first": "off",
      "@typescript-eslint/no-explicit-any": "off",
      "no-useless-escape": "off"
    }
  },

  // configExporter module overrides
  {
    files: ["package/configExporter/**/*.ts"],
    rules: {
      "@typescript-eslint/no-use-before-define": "off",
      "import/no-dynamic-require": "off",
      "class-methods-use-this": "off",
      "import/prefer-default-export": "off",
      "no-underscore-dangle": "off",
      "no-restricted-globals": "off",
      "@typescript-eslint/no-unused-vars": "off",
      "@typescript-eslint/no-explicit-any": "off"
    }
  },

  // Utils module overrides
  {
    files: [
      "package/utils/inliningCss.ts",
      "package/utils/errorCodes.ts",
      "package/utils/errorHelpers.ts",
      "package/utils/pathValidation.ts",
      "package/utils/getStyleRule.ts",
      "package/utils/helpers.ts",
      "package/utils/validateDependencies.ts",
      "package/webpackDevServerConfig.ts"
    ],
    rules: {
      "@typescript-eslint/no-explicit-any": "off",
      "no-useless-escape": "off"
    }
  },

  // Plugins and optimization overrides
  {
    files: ["package/plugins/**/*.ts", "package/optimization/**/*.ts"],
    rules: {
      "import/prefer-default-export": "off"
    }
  },

  // Rules, rspack, swc, esbuild, and other modules
  {
    files: [
      "package/index.ts",
      "package/rspack/index.ts",
      "package/rules/**/*.ts",
      "package/swc/index.ts",
      "package/esbuild/index.ts",
      "package/dev_server.ts",
      "package/env.ts"
    ],
    rules: {
      "@typescript-eslint/no-unused-vars": "off",
      "import/prefer-default-export": "off",
      "no-underscore-dangle": "off"
    }
  },

  // Environments module overrides
  {
    files: ["package/environments/**/*.ts"],
    rules: {
      "import/prefer-default-export": "off",
      "no-underscore-dangle": "off"
    }
  },

  // Type tests are intentionally unused - they test type compatibility
  {
    files: ["package/**/__type-tests__/**/*.ts"],
    rules: {
      "@typescript-eslint/no-unused-vars": "off"
    }
  },

  // Note: Type-aware rule overrides from main config (e.g., @typescript-eslint/no-unsafe-*,
  // @typescript-eslint/restrict-template-expressions) are intentionally omitted here since
  // fast mode doesn't enable type-aware linting (no parserOptions.project specified).
  // This keeps fast mode performant while maintaining consistency for non-type-aware rules.

  // Prettier config must be last to override other configs
  prettierConfig
]
