# Node Package API

Shakapacker ships a Node package that exposes configuration and helper utilities
for both webpack and rspack.

## Import Paths

```js
// Webpack entrypoint
const shakapacker = require("shakapacker")

// Rspack entrypoint
const rspack = require("shakapacker/rspack")
```

## Webpack Exports (`shakapacker`)

| Export                                                    | Type      | Description                                                  |
| --------------------------------------------------------- | --------- | ------------------------------------------------------------ |
| `config`                                                  | object    | Parsed `config/shakapacker.yml` plus computed fields         |
| `devServer`                                               | object    | Dev server configuration                                     |
| `generateWebpackConfig(extraConfig?)`                     | function  | Generates final webpack config and merges optional overrides |
| `baseConfig`                                              | object    | Base config object from `package/environments/base`          |
| `env`                                                     | object    | Environment metadata (`railsEnv`, `nodeEnv`, booleans)       |
| `rules`                                                   | array     | Loader rules for current bundler                             |
| `moduleExists(name)`                                      | function  | Returns whether module can be resolved                       |
| `canProcess(rule, fn)`                                    | function  | Runs callback only if loader dependency is available         |
| `inliningCss`                                             | boolean   | Whether CSS should be inlined in current dev-server mode     |
| `merge`, `mergeWithCustomize`, `mergeWithRules`, `unique` | functions | Re-exported from `webpack-merge`                             |

## Rspack Exports (`shakapacker/rspack`)

| Export                                                    | Type      | Description                                                 |
| --------------------------------------------------------- | --------- | ----------------------------------------------------------- |
| `config`                                                  | object    | Parsed `config/shakapacker.yml` plus computed fields        |
| `devServer`                                               | object    | Dev server configuration                                    |
| `generateRspackConfig(extraConfig?)`                      | function  | Generates final rspack config and merges optional overrides |
| `baseConfig`                                              | object    | Base config object                                          |
| `env`                                                     | object    | Environment metadata (`railsEnv`, `nodeEnv`, booleans)      |
| `rules`                                                   | array     | Rspack loader rules                                         |
| `moduleExists(name)`                                      | function  | Returns whether module can be resolved                      |
| `canProcess(rule, fn)`                                    | function  | Runs callback only if loader dependency is available        |
| `inliningCss`                                             | boolean   | Whether CSS should be inlined in current dev-server mode    |
| `merge`, `mergeWithCustomize`, `mergeWithRules`, `unique` | functions | Re-exported from `webpack-merge`                            |

## `config` Object

`config` includes:

- Raw values from `config/shakapacker.yml` (`source_path`, `public_output_path`, `javascript_transpiler`, etc.)
- Computed absolute paths (`outputPath`, `publicPath`, `manifestPath`, `publicPathWithoutCDN`)
- Optional sections like `dev_server` and `integrity`

For the full key list and types, see:

- [`package/types.ts`](../package/types.ts)
- [Configuration Guide](./configuration.md)

## Built-in Third-Party Support

Installer defaults include support for:

- Bundlers: webpack, rspack
- JavaScript transpilers: SWC (default), Babel, esbuild
- Common style/tooling loaders: css, sass, less, stylus, file/raw rules
- Common optimization/plugins for webpack/rspack production builds

Dependency presets used by the installer are defined in:

- [`lib/install/package.json`](../lib/install/package.json)
