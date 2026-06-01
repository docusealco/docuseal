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
      // Allow for...of loops - modern JS syntax, won't pollute client code
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

  // TypeScript files
  {
    files: ["**/*.ts", "**/*.tsx"],
    languageOptions: {
      parser: typescriptParser,
      parserOptions: {
        // Enables type-aware linting for better type safety
        // Note: This can slow down linting on large codebases
        // Consider using --cache flag with ESLint if performance degrades
        project: "./tsconfig.eslint.json",
        tsconfigRootDir: __dirname
      }
    },
    plugins: {
      "@typescript-eslint": typescriptPlugin
    },
    rules: {
      ...typescriptPlugin.configs.recommended.rules,
      ...typescriptPlugin.configs["recommended-requiring-type-checking"].rules,
      // TypeScript compiler handles module resolution
      "import/no-unresolved": "off",
      // Allow importing devDependencies in TypeScript files
      "import/no-extraneous-dependencies": "off",
      // TypeScript handles file extensions via moduleResolution
      "import/extensions": "off",
      // Disable base rule in favor of TypeScript version
      "no-use-before-define": "off",
      "@typescript-eslint/no-use-before-define": ["error"],
      // Allow unused vars if they start with underscore (convention for ignored params and type tests)
      "@typescript-eslint/no-unused-vars": [
        "error",
        { argsIgnorePattern: "^_", varsIgnorePattern: "^_" }
      ],
      // Strict: no 'any' types allowed - use 'unknown' or specific types instead
      "@typescript-eslint/no-explicit-any": "error",
      // Allow implicit return types - TypeScript can infer them
      "@typescript-eslint/explicit-module-boundary-types": "off",
      // Disable no-undef for TypeScript - TypeScript compiler handles this
      // This prevents false positives for ambient types like NodeJS.ProcessEnv
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

  // Temporary overrides for files with remaining errors
  // See ESLINT_TECHNICAL_DEBT.md for detailed documentation
  //
  // These overrides suppress ~94 type safety errors that require:
  // 1. Major type refactoring (any/unsafe-* rules)
  // 2. Proper type definitions for config objects
  //
  // GitHub Issue tracking this technical debt:
  // - #790: TypeScript ESLint Phase 2b: Type Safety Improvements (~94 errors)
  {
    // Consolidated override for package/config.ts and package/babel/preset.ts
    // Combines rules from both previous override blocks to avoid duplication
    files: ["package/babel/preset.ts", "package/config.ts"],
    rules: {
      "@typescript-eslint/no-unused-vars": "off",
      "@typescript-eslint/no-unsafe-call": "off",
      "import/order": "off",
      "import/newline-after-import": "off",
      "import/first": "off",
      "@typescript-eslint/no-unsafe-assignment": "off",
      "@typescript-eslint/no-unsafe-member-access": "off",
      "@typescript-eslint/no-unsafe-argument": "off",
      "@typescript-eslint/no-explicit-any": "off",
      "no-useless-escape": "off"
    }
  },
  {
    // #707: Significant type safety improvements in configExporter module!
    // - configFile.ts: ✅ Fully type-safe (0 type errors)
    // - buildValidator.ts: ✅ Fully type-safe (0 type errors)
    // - yamlSerializer.ts: ✅ Fully type-safe (0 type errors)
    // - cli.ts: ⚠️ Partial (dynamic webpack config loading requires some `any`)
    //
    // Remaining overrides are for:
    // 1. Code style/organization (not type safety)
    // 2. Dynamic require() in cli.ts for webpack config loading
    files: ["package/configExporter/**/*.ts"],
    rules: {
      // Code organization (functions before use due to large file)
      "@typescript-eslint/no-use-before-define": "off",
      // Import style (CommonJS require for dynamic imports)
      "import/no-dynamic-require": "off",
      // Class methods that are part of public API
      "class-methods-use-this": "off",
      // Template expressions (valid use cases with union types)
      "@typescript-eslint/restrict-template-expressions": "off",
      // Style preferences
      "import/prefer-default-export": "off",
      "no-underscore-dangle": "off",
      "no-restricted-globals": "off",
      "@typescript-eslint/no-unused-vars": "off",
      "@typescript-eslint/require-await": "off"
    }
  },
  {
    // cli.ts: Dynamic webpack config loading requires `any` types
    // This is acceptable as webpack configs can have any shape
    files: ["package/configExporter/cli.ts"],
    rules: {
      "@typescript-eslint/no-explicit-any": "off",
      "@typescript-eslint/no-unsafe-assignment": "off",
      "@typescript-eslint/no-unsafe-member-access": "off",
      "@typescript-eslint/no-unsafe-call": "off",
      "@typescript-eslint/no-unsafe-return": "off"
    }
  },
  {
    // Remaining utils files that need type safety improvements
    // These use dynamic requires and helper functions that return `any`
    files: [
      "package/utils/bundlerUtils.ts",
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
      "@typescript-eslint/no-unsafe-assignment": "off",
      "@typescript-eslint/no-unsafe-member-access": "off",
      "@typescript-eslint/no-unsafe-argument": "off",
      "@typescript-eslint/no-unsafe-call": "off",
      "@typescript-eslint/no-unsafe-return": "off",
      "@typescript-eslint/no-explicit-any": "off",
      "no-useless-escape": "off"
    }
  },
  {
    files: ["package/plugins/**/*.ts", "package/optimization/**/*.ts"],
    rules: {
      "@typescript-eslint/no-unsafe-assignment": "off",
      "@typescript-eslint/no-unsafe-call": "off",
      "@typescript-eslint/no-unsafe-member-access": "off",
      "@typescript-eslint/no-redundant-type-constituents": "off",
      "import/prefer-default-export": "off"
    }
  },
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
      "@typescript-eslint/no-unsafe-assignment": "off",
      "@typescript-eslint/no-unsafe-call": "off",
      "@typescript-eslint/no-unsafe-return": "off",
      "@typescript-eslint/no-unsafe-member-access": "off",
      "@typescript-eslint/no-unsafe-argument": "off",
      "@typescript-eslint/no-redundant-type-constituents": "off",
      "@typescript-eslint/no-unused-vars": "off",
      "@typescript-eslint/no-unsafe-function-type": "off",
      "import/prefer-default-export": "off",
      "no-underscore-dangle": "off"
    }
  },
  {
    // package/environments/**/*.ts now passes no-unused-vars rule
    // Type test functions use underscore prefix (argsIgnorePattern: "^_")
    // All other variables are used in the code
    files: ["package/environments/**/*.ts"],
    rules: {
      "@typescript-eslint/no-unsafe-assignment": "off",
      "@typescript-eslint/no-unsafe-call": "off",
      "@typescript-eslint/no-unsafe-return": "off",
      "@typescript-eslint/no-unsafe-member-access": "off",
      "@typescript-eslint/no-unsafe-argument": "off",
      "@typescript-eslint/no-redundant-type-constituents": "off",
      "@typescript-eslint/no-unsafe-function-type": "off",
      "import/prefer-default-export": "off",
      "no-underscore-dangle": "off"
    }
  },

  // Prettier config must be last to override other configs
  prettierConfig
]
