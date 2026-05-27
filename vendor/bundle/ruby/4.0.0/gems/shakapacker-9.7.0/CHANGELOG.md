- For the changelog of versions prior to v6, see the [5.x stable branch of rails/webpacker](https://github.com/rails/webpacker/tree/5-x-stable).
- **Please see the [v9 Upgrade Guide](./docs/v9_upgrade.md) for upgrading to version 9 and accounting for breaking changes.**
- Please see the [v8 Upgrade Guide](./docs/v8_upgrade.md) for upgrading to version 8 and accounting for breaking changes.
- Please see the [v7 Upgrade Guide](./docs/v7_upgrade.md) for upgrading to new spelling in version 7.
- Please see the [v6 Upgrade Guide](./docs/v6_upgrade.md) to go from versions prior to v6.
- [ShakaCode](https://www.shakacode.com) offers support for upgrading from Webpacker or using Shakapacker. If interested, contact Justin Gordon, [justin@shakacode.com](mailto:justin@shakacode.com).

# Versions

## [Unreleased]

## [v9.7.0] - March 15, 2026

### Added

- **Added rspack v2 support**. [PR #975](https://github.com/shakacode/shakapacker/pull/975) by [justin808](https://github.com/justin808). Peer dependencies now accept both rspack v1 and v2 (`^1.0.0 || ^2.0.0-0`). No source code changes were needed — all existing APIs work identically in v2. Note that rspack v2 requires Node.js 20.19.0+.

### Fixed

- **Fixed config exporter path traversal and annotation format validation**. [PR #914](https://github.com/shakacode/shakapacker/pull/914) by [justin808](https://github.com/justin808). Added `safeResolvePath` security check to prevent path traversal in export save paths, and enforced YAML format when using annotations with build exports.
- **Fixed `webpack-subresource-integrity` v5 named export handling**. [PR #978](https://github.com/shakacode/shakapacker/pull/978) by [justin808](https://github.com/justin808). Supports both the default export (older versions) and the named `SubresourceIntegrityPlugin` export (v5.1+), preventing runtime breakage when upgrading the plugin. Fixes [#972](https://github.com/shakacode/shakapacker/issues/972).

## [v9.6.1] - March 8, 2026

### Fixed

- **Fixed `Env#current` crashing when Rails is not loaded**. [PR #963](https://github.com/shakacode/shakapacker/pull/963) by [ihabadham](https://github.com/ihabadham). Added `defined?(Rails)` guard to `Shakapacker::Env#current` so it falls back to `RAILS_ENV`/`RACK_ENV` environment variables when called from non-Rails Ruby processes (e.g., `bin/dev` scripts). Previously, this would raise a `NameError` and silently fall back to `"production"`.

### Documentation

- **Added Node package API documentation**. [PR #900](https://github.com/shakacode/shakapacker/pull/900) by [justin808](https://github.com/justin808). New guide (`docs/node_package_api.md`) documenting the JavaScript API exports, configuration objects, import entrypoints for webpack and rspack, and built-in third-party support resources.

## [v9.6.0] - March 7, 2026

### Security

- Removed default `Access-Control-Allow-Origin: *` header from dev server configuration. This header allowed any website to access dev server resources. **If your setup runs webpack-dev-server on a different port from your Rails server, uncomment the `headers` section in `config/shakapacker.yml` to restore cross-origin asset loading.** [PR #936](https://github.com/shakacode/shakapacker/pull/936) by [justin808](https://github.com/justin808). Fixes [#935](https://github.com/shakacode/shakapacker/issues/935).

### Added

- **Added `SKIP=true` installer mode to preserve existing files**. [PR #926](https://github.com/shakacode/shakapacker/pull/926) by [justin808](https://github.com/justin808). Running `rails shakapacker:install SKIP=true` now skips conflicting files instead of overwriting them. This is useful for CI/CD pipelines and automated setups where you want to install only missing files without touching existing configuration.
- **Export bundler utility functions for Webpack/Rspack compatibility**. [PR #922](https://github.com/shakacode/shakapacker/pull/922) by [justin808](https://github.com/justin808). New utility functions that make it easier to write bundler-agnostic configuration code: `isRspack`, `isWebpack`, `getBundler()`, `getCssExtractPlugin()`, `getCssExtractPluginLoader()`, `getDefinePlugin()`, `getEnvironmentPlugin()`, and `getProvidePlugin()`. Users no longer need to write conditional logic to handle differences between Webpack and Rspack.

  ```javascript
  // Before: manual conditional logic
  const { config } = require("shakapacker")
  const CssPlugin =
    config.assets_bundler === "rspack"
      ? require("@rspack/core").CssExtractRspackPlugin
      : require("mini-css-extract-plugin")

  // After: use bundler utilities
  const { getCssExtractPlugin } = require("shakapacker")
  const CssPlugin = getCssExtractPlugin()
  ```

### Changed

- **Changed default file rule type from `asset/resource` to `asset`**. [PR #901](https://github.com/shakacode/shakapacker/pull/901) by [justin808](https://github.com/justin808). Static assets (images, fonts, SVGs) now use webpack/rspack's `asset` type instead of `asset/resource`, allowing the bundler to automatically inline small files as data URIs for better performance.
- Allow `compression-webpack-plugin` v12. [PR #937](https://github.com/shakacode/shakapacker/pull/937) by [G-Rath](https://github.com/G-Rath).
- **BREAKING: sass-loader now defaults to modern Sass API**. [PR #879](https://github.com/shakacode/shakapacker/pull/879) by [justin808](https://github.com/justin808). The sass-loader configuration now uses `api: "modern"` instead of the deprecated legacy API. This improves compatibility with plugins like sass-resources-loader that require the modern API. If you experience issues after upgrading, you can revert to the legacy API by customizing your webpack config:

  ```javascript
  // config/webpack/webpack.config.js
  const { generateWebpackConfig } = require("shakapacker")
  const config = generateWebpackConfig()

  // Find and modify sass-loader options
  config.module.rules.forEach((rule) => {
    if (rule.use) {
      rule.use.forEach((loader) => {
        if (loader.loader?.includes("sass-loader")) {
          loader.options.api = "legacy"
        }
      })
    }
  })

  module.exports = config
  ```

### Fixed

- **Fixed hidden dotfiles and dot-directories being treated as entrypoints**. [PR #915](https://github.com/shakacode/shakapacker/pull/915) by [justin808](https://github.com/justin808). Entry discovery now ignores files and directories whose names start with `.` when traversing `source_entry_path`, preventing unintended bundles from being created. Closes [#853](https://github.com/shakacode/shakapacker/issues/853).
- **Fixed orphaned webpack/rspack processes when foreman receives SIGTERM**. [PR #888](https://github.com/shakacode/shakapacker/pull/888) by [jordan-brough](https://github.com/jordan-brough). When running under foreman, sending SIGTERM to foreman (e.g. `kill <pid>`) would kill the Ruby shakapacker process but leave the webpack/rspack child process running as an orphan. DevServerRunner now uses `exec` to replace the Ruby process entirely, and Runner uses `spawn` with SIGTERM forwarding to ensure the child process is properly terminated.
- **Fixed missing-environment fallback to use production instead of development**. [PR #894](https://github.com/shakacode/shakapacker/pull/894) by [justin808](https://github.com/justin808). When a Rails environment (e.g., staging) is not defined in `shakapacker.yml`, Shakapacker now falls back to the `production` configuration instead of `development`. This ensures unknown environments get production-optimized webpack/rspack builds by default.
- **Fixed installer writing wrong shakapacker version in package.json**. [PR #899](https://github.com/shakacode/shakapacker/pull/899) by [justin808](https://github.com/justin808). The `shakapacker:install` generator now keeps the `package.json` dependency value in sync with the exact version or path that was requested, instead of relying on the post-install value which could differ.
- **Fixed `privateOutputPath` not being computed in JavaScript config**. [PR #891](https://github.com/shakacode/shakapacker/pull/891) by [ihabadham](https://github.com/ihabadham). The `private_output_path` setting from `shakapacker.yml` is now properly resolved to an absolute path and exposed as `privateOutputPath` in the JavaScript configuration, matching the behavior already present in the Ruby configuration.
- **Fixed installer not updating `shakapacker.yml` when selecting a non-default transpiler**. [PR #895](https://github.com/shakacode/shakapacker/pull/895) by [codex-rs](https://github.com/apps/codex-rs). Installing with `JAVASCRIPT_TRANSPILER=babel` (or `esbuild`) now correctly updates `config/shakapacker.yml` to match the selected transpiler instead of leaving it set to `swc`. Previously, a quote mismatch in the `gsub_file` call meant the config was never actually updated, and the condition also excluded `JAVASCRIPT_TRANSPILER=babel` from the update entirely. Additionally, `JAVASCRIPT_TRANSPILER=babel` no longer installs SWC packages.
- **Fixed ENOENT crash on clean builds when using `webpack-assets-manifest` v6 with `merge: true`**. [PR #931](https://github.com/shakacode/shakapacker/pull/931) by [justin808](https://github.com/justin808). Seeds an empty `{}` manifest file before instantiating the plugin, so the merge read succeeds on first build rather than throwing an unhandled ENOENT.
- **Improved error message when manifest is empty or missing**. [PR #872](https://github.com/shakacode/shakapacker/pull/872) by [justin808](https://github.com/justin808). When the bundler is still compiling (empty manifest) or hasn't run yet (missing manifest file), users now see clear, actionable error messages instead of the generic 7-point checklist.
- **Fixed NODE_ENV=test causing DefinePlugin warnings**. [PR #870](https://github.com/shakacode/shakapacker/pull/870) by [justin808](https://github.com/justin808). When RAILS_ENV=test, Shakapacker now sets NODE_ENV=development instead of NODE_ENV=test. This prevents webpack/rspack DefinePlugin conflicts since these bundlers only recognize "development" and "production" as valid NODE_ENV values.
- **Fixed `--json` flag output being corrupted by log messages**. [PR #869](https://github.com/shakacode/shakapacker/pull/869) by [justin808](https://github.com/justin808). When `--json` is in the command arguments, `[Shakapacker]` log messages are now written to stderr instead of stdout, keeping stdout clean for valid JSON output. This allows `bin/shakapacker --profile --json` to be piped to tools like `webpack-bundle-analyzer`. Normal (non-JSON) usage is unchanged. Resolves [#868](https://github.com/shakacode/shakapacker/issues/868).
- **Require explicit truthy values for all installer env vars**. [PR #926](https://github.com/shakacode/shakapacker/pull/926), [PR #943](https://github.com/shakacode/shakapacker/pull/943) by [justin808](https://github.com/justin808). Previously, any set value (including `"false"` or `"0"`) would activate these flags. Now only explicit truthy values (`true`, `1`, `yes`, case-insensitive) are recognized for `SKIP`, `FORCE`, `USE_BABEL_PACKAGES`, `SHAKAPACKER_USE_TYPESCRIPT`, and `SKIP_COMMON_LOADERS`. This behavior change may require CI/scripts that relied on arbitrary non-empty values to switch to recognized truthy values like `true`.

### Documentation

- **Added CDN limitation warnings for Early Hints feature**. [PR #878](https://github.com/shakacode/shakapacker/pull/878) by [justin808](https://github.com/justin808). The early hints documentation now prominently notes that most CDNs (Cloudflare, AWS CloudFront, AWS ALB) strip HTTP 103 responses before they reach end users. Debug mode also includes CDN warnings in HTML comments.

## [v9.5.0] - January 7, 2026

### Security

- **CRITICAL: Fixed environment variable leak via EnvironmentPlugin**. [PR #857](https://github.com/shakacode/shakapacker/pull/857) by [justin808](https://github.com/justin808). The default webpack and rspack plugins were passing the entire `process.env` to `EnvironmentPlugin`, which exposed ALL build environment variables (including secrets like `DATABASE_URL`, `AWS_SECRET_ACCESS_KEY`, `RAILS_MASTER_KEY`, etc.) to client-side JavaScript bundles when code referenced `process.env.VARIABLE_NAME`. **Note**: This issue is especially critical with webpack 5.103+ due to a [serialization change](https://github.com/webpack/webpack/commit/eecdeeb746b2f996ed4ab74365dd72c95070196b) that can embed all environment variables into bundles when `import.meta.env` is accessed conditionally. This vulnerability was inherited from webpacker v1.0.0 (January 2017) and has been present in all versions of webpacker and shakapacker. **Action required**: After upgrading, rotate any secrets that may have been exposed in production JavaScript bundles.

### Added

- **Added `SHAKAPACKER_PUBLIC_*` prefix convention for client-side environment variables**. [PR #857](https://github.com/shakacode/shakapacker/pull/857) by [justin808](https://github.com/justin808). Any environment variable prefixed with `SHAKAPACKER_PUBLIC_` is automatically exposed to client-side JavaScript. This follows the same convention used by Next.js (`NEXT_PUBLIC_*`) and Vite (`VITE_*`), making it explicit which variables are intended for client-side use.

  ```bash
  # These are automatically available in your JavaScript
  export SHAKAPACKER_PUBLIC_API_URL=https://api.example.com
  export SHAKAPACKER_PUBLIC_ANALYTICS_ID=UA-12345
  ```

- **Added `SHAKAPACKER_ENV_VARS` environment variable as escape hatch for extending allowed client-side env vars**. [PR #857](https://github.com/shakacode/shakapacker/pull/857) by [justin808](https://github.com/justin808). Set `SHAKAPACKER_ENV_VARS=VAR1,VAR2,VAR3` to expose additional environment variables to client-side JavaScript beyond the default allowlist (`NODE_ENV`, `RAILS_ENV`, `WEBPACK_SERVE`). Only add non-sensitive variables that are safe to embed in public JavaScript bundles.

### Changed

- **BREAKING: EnvironmentPlugin now uses allowlist instead of exposing all env vars**. [PR #857](https://github.com/shakacode/shakapacker/pull/857) by [justin808](https://github.com/justin808). Only `NODE_ENV`, `RAILS_ENV`, `WEBPACK_SERVE`, and any `SHAKAPACKER_PUBLIC_*` variables are exposed by default. If your client-side code relies on other environment variables, either rename them with the `SHAKAPACKER_PUBLIC_` prefix (recommended), add them via `SHAKAPACKER_ENV_VARS`, or customize your webpack/rspack config. This is a security fix - the previous behavior was dangerous.

  **Migration examples:**

  ```bash
  # Option 1 (recommended): Use the SHAKAPACKER_PUBLIC_ prefix
  export SHAKAPACKER_PUBLIC_API_BASE_URL=https://api.example.com

  # Option 2: Use SHAKAPACKER_ENV_VARS for existing variable names
  SHAKAPACKER_ENV_VARS=API_BASE_URL bundle exec rails assets:precompile
  ```

### Fixed

- **Fixed gemspec to exclude Gemfile.lock from published gem**. [PR #856](https://github.com/shakacode/shakapacker/pull/856) by [adrien-k](https://github.com/adrien-k). The gemspec's file pattern now correctly excludes `Gemfile.lock`, preventing vulnerability alerts during Docker image scans caused by outdated pinned versions in the lock file.

## [v9.4.0] - November 22, 2025

### Added

- **Added `SHAKAPACKER_SKIP_PRECOMPILE_HOOK` environment variable to skip precompile hook**. [PR #850](https://github.com/shakacode/shakapacker/pull/850) by [justin808](https://github.com/justin808). Set `SHAKAPACKER_SKIP_PRECOMPILE_HOOK=true` to skip the precompile hook during compilation. This is useful when using process managers like Foreman or Overmind to run the hook once before starting multiple webpack processes, preventing duplicate hook execution. **Migration tip:** If you have a custom `bin/dev` script that starts multiple webpack processes, you can now run the precompile hook once in the script and set this environment variable to prevent each webpack process from running the hook again. See the [precompile hook documentation](./docs/precompile_hook.md#skipping-the-hook) for implementation examples.

## [v9.3.4] - November 17, 2025

### Fixed

- **Fixed `switch_bundler` task to remove packages from both dependencies and devDependencies**. [PR #838](https://github.com/shakacode/shakapacker/pull/838) by [justin808](https://github.com/justin808). The task now correctly removes old bundler packages regardless of whether they're in `dependencies` or `devDependencies` sections, fixing an issue where packages in `dependencies` were not being removed when switching bundlers.

## [v9.3.3] - November 15, 2025

### Fixed

- **Fixed `switch_bundler` task to preserve shared dependencies**. [PR #836](https://github.com/shakacode/shakapacker/pull/836) by [justin808](https://github.com/justin808). The task no longer removes `@swc/core`, `swc-loader`, and `webpack-merge` when switching bundlers, as these packages are shared between webpack and rspack configurations.

## [v9.3.2] - November 10, 2025

### Fixed

- **Fixed TypeScript import error in public types when webpack is not installed**. [PR #828](https://github.com/shakacode/shakapacker/pull/828) by [G-Rath](https://github.com/G-Rath). Uses `@ts-ignore` instead of `@ts-expect-error` to suppress potential import error when webpack is not installed.
- **Fixed bundler switch task to add missing `assets_bundler` config**. [PR #833](https://github.com/shakacode/shakapacker/pull/833) by [justin808](https://github.com/justin808). The `rake shakapacker:switch_bundler` task now automatically adds the `assets_bundler` key to `shakapacker.yml` if it's missing, preventing silent failures when switching bundlers.
- **Fixed rake tasks to use `bundle exec rake` instead of `bundle exec rails`**. [PR #830](https://github.com/shakacode/shakapacker/pull/830) by [Judahmeek](https://github.com/Judahmeek). Rake tasks should be invoked with `bundle exec rake` to support command-line flags properly, as Rails commands don't support flags.

### Added

- **Support for esbuild 0.26 and 0.27**. [PR #832](https://github.com/shakacode/shakapacker/pull/832) by [justin808](https://github.com/justin808). Extended peer dependency range to support newer esbuild versions.

### Changed

- **Simplified `switch_bundler` task to only support rake command**. [PR #831](https://github.com/shakacode/shakapacker/pull/831) by [justin808](https://github.com/justin808). The `rake shakapacker:switch_bundler` task now only works with `bundle exec rake`, not `bundle exec rails`. Use `bundle exec rake shakapacker:switch_bundler [bundler] -- [options]` for clearer command-line flag support.

## [v9.3.1] - November 9, 2025

### Fixed

- **Fixed NODE_ENV not being set when running shakapacker-dev-server**. [PR #823](https://github.com/shakacode/shakapacker/pull/823) by [Seifeldin7](https://github.com/Seifeldin7). Resolves [#802](https://github.com/shakacode/shakapacker/issues/802). The dev server now properly initializes NODE_ENV to match RAILS_ENV (or "production" by default), fixing webpack configurations that dynamically load environment-specific files.
- Extended manifest merging for multiple client configurations to all environments. [PR #800](https://github.com/shakacode/shakapacker/pull/800) by [Judahmeek](https://github.com/Judahmeek).

### Added

- **RBS type signatures for all public APIs**. [PR #822](https://github.com/shakacode/shakapacker/pull/822) by [justin808](https://github.com/justin808). Shakapacker now includes comprehensive RBS type signatures in the `sig/` directory for static type checking and improved IDE support (autocomplete, Steep/TypeProf integration). See README for usage examples.
- **Support for `css_modules_export_mode` configuration option**. [PR #817](https://github.com/shakacode/shakapacker/pull/817) by [justin808](https://github.com/justin808). Adds `css_modules_export_mode` setting in `shakapacker.yml` to control CSS Modules export style. Set to `"named"` (default, v9+ behavior with true named exports) or `"default"` (v8 behavior with default export object). Allows teams to opt into v8-style exports for easier migration from v8 or when using TypeScript with strict type checking.
- **`Configuration#data` public API method** with enhanced documentation and safety. [PR #820](https://github.com/shakacode/shakapacker/pull/820) by [justin808](https://github.com/justin808). The `Configuration#data` method is now part of the public Ruby API, providing stable access to raw configuration data. Returns a frozen hash with symbolized keys to prevent accidental mutations. Includes comprehensive test coverage and detailed RDoc documentation.
- **Support for `javascript_transpiler: 'none'`** for completely custom webpack configurations. [PR #799](https://github.com/shakacode/shakapacker/pull/799) by [justin808](https://github.com/justin808). Allows users with custom webpack configs to skip Shakapacker's transpiler setup and validation by setting `javascript_transpiler: 'none'` in `shakapacker.yml`. Useful when managing transpilation entirely outside of Shakapacker's defaults.

## [v9.3.0] - November 2, 2025

### Fixed

- **Enhanced error handling for better security and debugging**. [PR #786](https://github.com/shakacode/shakapacker/pull/786) by [justin808](https://github.com/justin808).
  - Path validation now properly reports permission errors instead of silently handling them
  - Module loading errors now include original error context for easier troubleshooting
  - Improved security by only catching ENOENT errors in path resolution, rethrowing permission and access errors
  - Better type safety with custom ErrorWithCause interface and optional chaining for error.code checks
- **Improved type safety and error handling in configExporter module**. [PR #778](https://github.com/shakacode/shakapacker/pull/778) by [justin808](https://github.com/justin808). Resolves [#707](https://github.com/shakacode/shakapacker/issues/707).
  - Enhanced type safety across configFile, buildValidator, and yamlSerializer modules
  - Improved error message preservation for webpack/rspack build failures
  - Fixed edge cases in YAML serialization (empty arrays, malformed objects)
  - More robust constructor name detection for object serialization
  - Better handling of Symbol, BigInt, and edge case types
- **Default template no longer triggers production warning**. [PR #774](https://github.com/shakacode/shakapacker/pull/774) by [justin808](https://github.com/justin808). Fixes [#703](https://github.com/shakacode/shakapacker/issues/703).
  - Changed default `useContentHash` to `true` in `shakapacker.yml` template
  - Eliminates confusing warning about `useContentHash: false` not being allowed in production
  - Development environment now explicitly sets `useContentHash: false` for faster builds
  - Production no longer needs explicit override since it inherits the correct default
- Fixed Rails constant error when using custom environments like staging. [PR #681](https://github.com/shakacode/shakapacker/pull/681) by [justin808](https://github.com/justin808). `RAILS_ENV=staging` no longer causes "uninitialized constant Shakapacker::Instance::Rails" error. Shakapacker now works in non-Rails contexts.
- Fixed TypeScript type definitions to export proper types instead of `any`. [PR #684](https://github.com/shakacode/shakapacker/pull/684) by [justin808](https://github.com/justin808). Previously `package/index.d.ts` was exporting all types as `any`, breaking IDE autocomplete. Now properly exports typed interfaces.
- Fixed integrity config handling and sass-loader version check. [PR #688](https://github.com/shakacode/shakapacker/pull/688) by [justin808](https://github.com/justin808). Properly handles subresource integrity configuration and correctly detects sass-loader version for conditional logic.

### Added

- **HTTP 103 Early Hints support** for faster asset loading. [PR #722](https://github.com/shakacode/shakapacker/pull/722) by [justin808](https://github.com/justin808). Automatically sends early hints when `early_hints: enabled: true` in `shakapacker.yml`. Works with `append_javascript_pack_tag`/`append_stylesheet_pack_tag`, supports per-controller/action configuration, and includes helpers like `configure_pack_early_hints` and `skip_send_pack_early_hints`. Requires Rails 5.2+ and HTTP/2-capable server. See [Early Hints Guide](docs/early_hints.md).
- **`--help=verbose` flag** to display all available webpack/rspack bundler options. [PR #763](https://github.com/shakacode/shakapacker/pull/763) by [justin808](https://github.com/justin808). Run `bin/shakapacker --help=verbose` to see complete bundler documentation.
- **Support for arbitrary output names in build configurations**. [PR #752](https://github.com/shakacode/shakapacker/pull/752) by [justin808](https://github.com/justin808). The `outputs` array now accepts any custom names (e.g., `client-modern`, `client-legacy`, `server-bundle`) instead of being limited to only `client`, `server`, and `all`.
- **Enhanced error reporting in config exporter**. [PR #752](https://github.com/shakacode/shakapacker/pull/752) by [justin808](https://github.com/justin808). Shows detailed environment variable state when config functions fail and provides actionable suggestions based on error patterns.
- **Config count validation for build outputs**. [PR #752](https://github.com/shakacode/shakapacker/pull/752) by [justin808](https://github.com/justin808). Validates webpack/rspack config array length matches `outputs` array with clear error messages and suggested fixes.
- **`precompile_hook` configuration option** to run custom commands during asset precompilation. [PR #678](https://github.com/shakacode/shakapacker/pull/678) by [justin808](https://github.com/justin808). Configure in `shakapacker.yml` with `precompile_hook: "command to run"`.
- **`assets_bundler_config_path` configuration option** for custom bundler config locations. [PR #710](https://github.com/shakacode/shakapacker/pull/710) by [justin808](https://github.com/justin808). Allows specifying a custom path for webpack/rspack configuration files.
- **YAML output format support for `bin/shakapacker-config`** (formerly `bin/export-bundler-config`). [PR #704](https://github.com/shakacode/shakapacker/pull/704) by [justin808](https://github.com/justin808). New `--format yaml` option exports bundler configuration as YAML.
- **Plugin names displayed in YAML config export**. [PR #750](https://github.com/shakacode/shakapacker/pull/750) by [justin808](https://github.com/justin808). Shows plugin constructor names in exported configuration to help identify which plugins are active.
- **Custom help messages for `bin/shakapacker` commands**. [PR #702](https://github.com/shakacode/shakapacker/pull/702) by [justin808](https://github.com/justin808). Improved help output for better command discoverability with clear usage examples.
- **HMR client config export in doctor mode**. [PR #701](https://github.com/shakacode/shakapacker/pull/701) by [justin808](https://github.com/justin808). `bin/shakapacker-config --doctor` now includes HMR client configuration to help debug Hot Module Replacement issues.
- **Build timing logs** for webpack and rspack. [PR #706](https://github.com/shakacode/shakapacker/pull/706) by [justin808](https://github.com/justin808). Shows duration of build operations to help identify performance bottlenecks.
- **Named build configurations with `--build` flag**. [PR #728](https://github.com/shakacode/shakapacker/pull/728) by [justin808](https://github.com/justin808). Allows specifying custom build configurations like `bin/shakapacker --build=production` or `bin/shakapacker --build=test`.
- **Build validation in `bin/shakapacker-config`**. [PR #717](https://github.com/shakacode/shakapacker/pull/717) by [justin808](https://github.com/justin808). Validates webpack/rspack configuration before export to catch errors early.
- **Backward compatibility for rspack config in `config/webpack/`**. [PR #734](https://github.com/shakacode/shakapacker/pull/734) by [justin808](https://github.com/justin808). Rspack configurations can now be placed in `config/webpack/` directory for easier migration.
- **Merge option for WebpackAssetsManifestPlugin**. [PR #760](https://github.com/shakacode/shakapacker/pull/760) by [justin808](https://github.com/justin808). Adds `merge` option to control manifest merging behavior, useful for multi-compiler setups.
- Support for esbuild-loader v5. [PR #758](https://github.com/shakacode/shakapacker/pull/758) by [justin808](https://github.com/justin808).

### Changed

- **Generated `swc.config.js` now uses single quotes and trailing commas**. [PR #755](https://github.com/shakacode/shakapacker/pull/755) by [justin808](https://github.com/justin808). Consistent code style in generated configuration files.
- Updated @rspack dependencies to 1.5.8. [PR #700](https://github.com/shakacode/shakapacker/pull/700) by [justin808](https://github.com/justin808).

### Improved

- **Improved error messages** to suggest `assets_bundler_config_path`. [PR #712](https://github.com/shakacode/shakapacker/pull/712) by [justin808](https://github.com/justin808). More helpful error messages when bundler config is not found, suggesting use of `assets_bundler_config_path` for custom locations.
- **Improved doctor command output** clarity and accuracy. [PR #682](https://github.com/shakacode/shakapacker/pull/682) by [justin808](https://github.com/justin808). Better formatting and organization of diagnostic information with more actionable recommendations.

## [v9.2.0] - October 9, 2025

### Added

- **New config export utility for debugging webpack/rspack configurations** [PR #647](https://github.com/shakacode/shakapacker/pull/647) by [justin808](https://github.com/justin808).
  - Adds `bin/shakapacker-config` utility (originally named `bin/export-bundler-config`, renamed in PR #728) with three modes:
    - **Doctor mode** (`--doctor`): Exports all configs (dev + prod, client + server) to `shakapacker-config-exports/` directory - best for troubleshooting
    - **Save mode** (`--save`): Export current environment configs to files
    - **Stdout mode** (default): View configs in terminal
  - **Output formats:** YAML (with optional inline documentation), JSON, or Node.js inspect
  - **Smart features:**
    - Environment isolation ensures dev/prod configs are truly different
    - Auto-detects bundler from `shakapacker.yml`
    - Pretty-prints functions (up to 50 lines)
    - Validates bundler value and output paths
    - Sanitizes filenames to prevent path traversal
    - Helpful `.gitignore` suggestions
  - **Usage:** `bin/shakapacker-config --doctor` or `bundle exec rake shakapacker:export_bundler_config`
  - Works seamlessly with `rake shakapacker:switch_bundler` for comparing webpack vs rspack configs
  - Lays groundwork for future config diff feature (tracked in [#667](https://github.com/shakacode/shakapacker/issues/667))

### Fixed

- Fixed NoMethodError when custom environment (e.g., staging) is not defined in shakapacker.yml. [PR #669](https://github.com/shakacode/shakapacker/pull/669) by [justin808](https://github.com/justin808).
  - When deploying to environments like Heroku staging with `RAILS_ENV=staging`, shakapacker would crash with `undefined method 'deep_symbolize_keys' for nil:NilClass`
  - **Configuration fallback:** Now properly falls back to production environment configuration (appropriate for staging)
  - **NODE_ENV handling:** `bin/shakapacker` now automatically sets `NODE_ENV=production` for custom environments (staging, etc.)
    - Previously: `RAILS_ENV=staging` would set `NODE_ENV=development`, breaking webpack optimizations
    - Now: `RAILS_ENV` in `[development, test]` uses that value for `NODE_ENV`, everything else uses `production`
  - Logs informational message when falling back to help with debugging
  - This ensures shakapacker works with any Rails environment even if not explicitly defined in shakapacker.yml
  - Fixes [#663](https://github.com/shakacode/shakapacker/issues/663)

## [v9.1.0] - October 8, 2025

**⚠️ IMPORTANT:** This release includes a breaking change for SWC users. Please see the [v9 Upgrade Guide - SWC Loose Mode Breaking Change](./docs/v9_upgrade.md#swc-loose-mode-breaking-change-v910) for migration details.

### ⚠️ Breaking Changes

- **SWC default configuration now uses `loose: false` for spec-compliant transforms** ([#658](https://github.com/shakacode/shakapacker/pull/658))
  - Previously, Shakapacker set `loose: true` by default in SWC configuration, which caused:
    - Silent failures with Stimulus controllers
    - Incorrect behavior with spread operators on iterables (e.g., `[...new Set()]`)
    - Deviation from both SWC and Babel upstream defaults
  - Now defaults to `loose: false`, matching SWC's default and fixing compatibility with Stimulus
  - This aligns with the previous fix to Babel configuration in [PR #107](https://github.com/shakacode/shakapacker/pull/107)
  - **Migration:** Most projects need no changes as the new default provides spec-compliant behavior. Projects with Stimulus will benefit from this fix. See [v9 Upgrade Guide - SWC Loose Mode](./docs/v9_upgrade.md#swc-loose-mode-breaking-change-v910) for details
  - If you must restore the old behavior (not recommended), add to `config/swc.config.js`:
    ```javascript
    module.exports = {
      options: {
        jsc: {
          // Only use this if you have code that requires loose transforms.
          // This provides slightly faster build performance but may cause runtime bugs.
          loose: true // Restore v9.0.0 behavior
        }
      }
    }
    ```

### Added

- **New `shakapacker:switch_bundler` rake task** for easy switching between webpack and rspack
  - Automatically updates `config/shakapacker.yml` to switch bundler configuration
  - Optional `--install-deps` flag to automatically manage dependencies
  - `--no-uninstall` flag for faster switching by keeping both bundlers installed
  - **Supports all package managers**: Auto-detects and uses npm, yarn, pnpm, or bun
  - Shows clear list of packages being added/removed during dependency management
  - Support for custom dependency configuration via `.shakapacker-switch-bundler-dependencies.yml`
  - Includes SWC dependencies (`@swc/core`, `swc-loader`) in default webpack setup
  - Preserves config file structure and comments during updates
  - Updates `javascript_transpiler` to `swc` when switching to rspack (recommended)
  - Ruby 2.7+ compatible YAML loading with proper alias/anchor support
  - Secure command execution (prevents shell injection)
  - Usage: `rails shakapacker:switch_bundler [webpack|rspack] [--install-deps] [--no-uninstall]`
  - See rake task help: `rails shakapacker:switch_bundler --help`
- **Stimulus compatibility built into SWC migration** ([#658](https://github.com/shakacode/shakapacker/pull/658))
  - `rake shakapacker:migrate_to_swc` now creates `config/swc.config.js` with `keepClassNames: true`
  - Prevents SWC from mangling class names, which breaks Stimulus controller discovery
  - Includes React Fast Refresh configuration by default
- **Comprehensive Stimulus documentation** for SWC users ([#658](https://github.com/shakacode/shakapacker/pull/658))
  - Added "Using SWC with Stimulus" section to [docs/using_swc_loader.md](./docs/using_swc_loader.md#using-swc-with-stimulus)
  - Documents symptoms of missing configuration (silent failures)
  - Explains common errors like `env` and `jsc.target` conflicts
  - Added Stimulus compatibility checklist to migration guide
- **Enhanced `rake shakapacker:doctor` for SWC configuration validation** ([#658](https://github.com/shakacode/shakapacker/pull/658))
  - Detects `loose: true` in config and warns about potential issues
  - Detects missing `keepClassNames: true` when Stimulus is installed
  - Detects conflicting `jsc.target` and `env` configuration
  - Provides actionable warnings with links to documentation

### Fixed

- Fixed `rake shakapacker:migrate_to_swc` to correctly set `javascript_transpiler: "swc"` instead of unused `swc: true` flag ([#659](https://github.com/shakacode/shakapacker/pull/659))
  - The migration now properly configures SWC as the transpiler
  - Users who previously ran the migration should update their `config/shakapacker.yml` to use `javascript_transpiler: "swc"` instead of `swc: true`
- Restore `RspackPlugin` type as an alias to `RspackPluginInstance` for backward compatibility. The type is now deprecated in favor of `RspackPluginInstance`. [#650](https://github.com/shakacode/shakapacker/issues/650)

## [v9.0.0] - October 5, 2025

See the [v9 Upgrade Guide](https://github.com/shakacode/shakapacker/blob/main/docs/v9_upgrade.md) for detailed migration instructions.

### ⚠️ Breaking Changes

1. **SWC is now the default JavaScript transpiler instead of Babel** ([PR 603](https://github.com/shakacode/shakapacker/pull/603) by [justin808](https://github.com/justin808))
   - Babel dependencies are no longer included as peer dependencies
   - Improves compilation speed by 20x
   - **Migration for existing projects:**
     - **Option 1 (Recommended):** Switch to SWC - Run `rake shakapacker:migrate_to_swc` or manually:
       ```yaml
       # config/shakapacker.yml
       javascript_transpiler: "swc"
       ```
       Then install: `npm install @swc/core swc-loader`
     - **Option 2:** Keep using Babel:
       ```yaml
       # config/shakapacker.yml
       javascript_transpiler: "babel"
       ```

2. **CSS Modules now use named exports by default** ([PR 599](https://github.com/shakacode/shakapacker/pull/599))
   - **JavaScript:** Use named imports: `import { className } from './styles.module.css'`
   - **TypeScript:** Use namespace imports: `import * as styles from './styles.module.css'`
   - To keep the old behavior with default imports, see [CSS Modules Export Mode documentation](./docs/css-modules-export-mode.md) for configuration instructions

3. **Configuration option renamed from `webpack_loader` to `javascript_transpiler`**
   - Better reflects its purpose of configuring JavaScript transpilation
   - Old `webpack_loader` option deprecated but still supported with warning

### Added

- **Rspack support** as an alternative assets bundler to webpack ([PR 589](https://github.com/shakacode/shakapacker/pull/589), [PR 590](https://github.com/shakacode/shakapacker/pull/590))
  - Configure `assets_bundler: 'rspack'` in `shakapacker.yml`
  - Faster Rust-based bundling with webpack-compatible APIs
  - Built-in SWC loader and CSS extraction
  - Automatic bundler detection in `bin/shakapacker`
- **TypeScript type definitions** for improved IDE support and autocomplete ([PR 602](https://github.com/shakacode/shakapacker/pull/602))
  - Types available via `import type { WebpackConfig, RspackConfig, EnvironmentConfig } from "shakapacker/types"`
  - Installer automatically creates TypeScript config files when `tsconfig.json` is detected ([PR 633](https://github.com/shakacode/shakapacker/pull/633))
  - See [TypeScript Documentation](./docs/typescript.md) for migration and usage instructions
- **Optional peer dependencies** - All peer dependencies now marked as optional, preventing installation warnings while maintaining version compatibility tracking ([PR 603](https://github.com/shakacode/shakapacker/pull/603))
- **Private output path** for server-side rendering bundles ([PR 592](https://github.com/shakacode/shakapacker/pull/592))
  - Configure `private_output_path` for private server bundles separate from public assets
- **`rake shakapacker:doctor` diagnostic command** to check for configuration issues and missing dependencies ([PR 609](https://github.com/shakacode/shakapacker/pull/609))
- **`rake shakapacker:migrate_to_swc`** migration helper to assist with switching from Babel to SWC ([PR 613](https://github.com/shakacode/shakapacker/pull/613), [PR 635](https://github.com/shakacode/shakapacker/pull/635))

### Security

- **Path Validation Utilities** ([PR 614](https://github.com/shakacode/shakapacker/pull/614) by [justin808](https://github.com/justin808))
  - Added validation to prevent directory traversal attacks
  - Implemented environment variable sanitization to prevent injection
  - Enforced strict port validation (reject strings with non-digits)
  - Added SHAKAPACKER_NPM_PACKAGE path validation (only .tgz/.tar.gz allowed)
  - Path traversal security checks now run regardless of validation mode

### Fixed

- Fixed NODE_ENV defaulting to production breaking dev server ([PR 632](https://github.com/shakacode/shakapacker/pull/632)). NODE_ENV now defaults to development unless RAILS_ENV is explicitly set to production. This ensures the dev server works out of the box without requiring NODE_ENV to be set.
- Fixed SWC migration to use `config/swc.config.js` instead of `.swcrc` ([PR 635](https://github.com/shakacode/shakapacker/pull/635)). The `.swcrc` file bypasses webpack-merge and overrides Shakapacker's defaults, while `config/swc.config.js` properly merges with defaults.
- Fixed private_output_path configuration edge cases ([PR 604](https://github.com/shakacode/shakapacker/pull/604))
- Updated webpack-dev-server to secure versions (^4.15.2 || ^5.2.2) ([PR 585](https://github.com/shakacode/shakapacker/pull/585))

## [v8.4.0] - September 8, 2024

### Added

- Support for subresource integrity. [PR 570](https://github.com/shakacode/shakapacker/pull/570) by [panagiotisplytas](https://github.com/panagiotisplytas).

### Fixed

- Install the latest major version of peer dependencies [PR 576](https://github.com/shakacode/shakapacker/pull/576) by [G-Rath](https://github.com/g-rath).

## [v8.3.0] - April 28, 2024

### Added

- Allow `webpack-assets-manifest` v6. [PR 562](https://github.com/shakacode/shakapacker/pull/562) by [tagliala](https://github.com/tagliala), [shoeyn](https://github.com/shoeyn).

### Changed

- Instead of a fixed `core-js` version, take the current one from `node_modules` if available. [PR 556](https://github.com/shakacode/shakapacker/pull/556) by [alexeyr-ci2](https://github.com/alexeyr-ci2).
- Require webpack >= 5.76.0 to reduce exposure to CVE-2023-28154. [PR 568](https://github.com/shakacode/shakapacker/pull/568) by [granowski](https://github.com/granowski).

### Fixed

- More precise types for `devServer` and `rules` in the configuration. [PR 555](https://github.com/shakacode/shakapacker/pull/555) by [alexeyr-ci2](https://github.com/alexeyr-ci2).

## [v8.2.0] - March 12, 2025

### Added

- Support for `async` attribute in `javascript_pack_tag`, `append_javascript_pack_tag`, and `prepend_javascript_pack_tag`. [PR 554](https://github.com/shakacode/shakapacker/pull/554) by [AbanoubGhadban](https://github.com/abanoubghadban).
- Allow `babel-loader` v10. [PR 552](https://github.com/shakacode/shakapacker/pull/552) by [shoeyn](https://github.com/shoeyn).

## [v8.1.0] - January 20, 2025

### Added

- Allow `webpack-cli` v6. [PR 533](https://github.com/shakacode/shakapacker/pull/533) by [tagliala](https://github.com/tagliala).

### Changed

- Changed internal `require`s to `require_relative` to make code less dependent on the load path. [PR 516](https://github.com/shakacode/shakapacker/pull/516) by [tagliala](https://github.com/tagliala).
- Allow configuring webpack from a Typescript file (`config/webpack/webpack.config.ts`). [PR 524](https://github.com/shakacode/shakapacker/pull/524) by [jdelStrother](https://github.com/jdelStrother).

### Fixed

- Fix error when rails environment is required from outside the rails root directory [PR 520](https://github.com/shakacode/shakapacker/pull/520)

## [v8.0.2] - August 28, 2024

### Fixed

- Fix wrong instruction in esbuild loader documentation [PR 504](https://github.com/shakacode/shakapacker/pull/504) by [adriangohjw](https://github.com/adriangohjw).
- Add logic to sass rule conditional on sass-loader version [PR 508](https://github.com/shakacode/shakapacker/pull/508) by [Judahmeek](https://github.com/Judahmeek).

## [v8.0.1] - July 10, 2024

### Changed

- Update outdated GitHub Actions to use Node.js 20.0 versions instead [PR 497](https://github.com/shakacode/shakapacker/pull/497) by [adriangohjw](https://github.com/adriangohjw).
- Allow `webpack-merge` v6 to be used [PR 502](https://github.com/shakacode/shakapacker/pull/502) by [G-Rath](https://github.com/g-rath).

### Fixed

- Fixes failing tests for Ruby 2.7 due to `Rack::Handler::Puma.respond_to?(:config)` [PR 501](https://github.com/shakacode/shakapacker/pull/501) by [adriangohjw](https://github.com/adriangohjw)

- Improve documentation for using Yarn PnP [PR 484](https://github.com/shakacode/shakapacker/pull/484) by [G-Rath](https://github.com/g-rath).

- Remove old `yarn` bin script [PR 483](https://github.com/shakacode/shakapacker/pull/483) by [G-Rath](https://github.com/g-rath).

## [v8.0.0] - May 17, 2024

See the [v8 Upgrade Guide](https://github.com/shakacode/shakapacker/blob/main/docs/v8_upgrade.md).

### Fixed

- Fixes incorrect removal of files in the assets:clean task [PR 474](https://github.com/shakacode/shakapacker/pull/474) by [tomdracz](https://github.com/tomdracz).

- Support v9 PNPM lockfiles [PR 472](https://github.com/shakacode/shakapacker/pull/472) by [G-Rath](https://github.com/g-rath).

### Breaking changes

- Removes CDN url from the manifest.json paths. [PR 473](https://github.com/shakacode/shakapacker/pull/473) by [tomdracz](https://github.com/tomdracz). This returns to the Webpacker behaviour prior to the aborted Webpacker v6.

- Remove `relative_url_root` [PR 413](https://github.com/shakacode/shakapacker/pull/413) by [G-Rath](https://github.com/g-rath).

- Removes deprecated support of `Webpacker` spelling, config variables and constants. [PR 429](https://github.com/shakacode/shakapacker/pull/429) by [tomdracz](https://github.com/tomdracz).

  The usage of those has been deprecated in Shakapacker v7 and now fully removed in v8. See the [v7 Upgrade Guide](./docs/v7_upgrade.md) for more information if you are still yet to address this deprecation.

- Remove `globalMutableWebpackConfig` global [PR 439](https://github.com/shakacode/shakapacker/pull/439) by [G-Rath](https://github.com/g-rath).

  Use `generateWebpackConfig` instead.

- Use `package_json` gem to manage Node dependencies and commands, and use `npm` by default [PR 430](https://github.com/shakacode/shakapacker/pull/430) by [G-Rath](https://github.com/g-rath)

  This enables support for package managers other than `yarn`, with `npm` being the default; to continue using Yarn,
  specify it in `package.json` using the [`packageManager`](https://nodejs.org/api/packages.html#packagemanager) property.

  This also removed `@node_modules_bin_path`, `SHAKAPACKER_NODE_MODULES_BIN_PATH`, and support for installing `Shakapacker`'s javascript package in a separate directory from the Gemfile containing `Shakapacker`'s ruby gem.

- Remove `yarn_install` rake task, and stop installing js packages automatically as part of `assets:precompile` [PR 412](https://github.com/shakacode/shakapacker/pull/412) by [G-Rath](https://github.com/g-rath).

- Remove `check_yarn` rake task [PR 443](https://github.com/shakacode/shakapacker/pull/443) by [G-Rath](https://github.com/g-rath).

- Remove `https` option for `webpack-dev-server` [PR 414](https://github.com/shakacode/shakapacker/pull/414) by [G-Rath](https://github.com/g-rath).

- Remove `verify_file_existance` method [PR 446](https://github.com/shakacode/shakapacker/pull/446) by [G-Rath](https://github.com/g-rath).

- Drop support for Ruby 2.6 [PR 415](https://github.com/shakacode/shakapacker/pull/415) by [G-Rath](https://github.com/g-rath).

- Drop support for Node v12 [PR 431](https://github.com/shakacode/shakapacker/pull/431) by [G-Rath](https://github.com/g-rath).

- Enable `ensure_consistent_versioning` by default [PR 447](https://github.com/shakacode/shakapacker/pull/447) by [G-Rath](https://github.com/g-rath).

- Asset files put in `additional_paths` will have their path stripped just like with the `source_path`. [PR 403](https://github.com/shakacode/shakapacker/pull/403) by [paypro-leon](https://github.com/paypro-leon).

- Remove `isArray` utility (just use `Array.isArray` directly) and renamed a few files [PR 454](https://github.com/shakacode/shakapacker/pull/454) by [G-Rath](https://github.com/g-rath).

- Make JavaScript test helper utilities internal (`chdirTestApp`, `chdirCwd`, `resetEnv`) [PR 458](https://github.com/shakacode/shakapacker/pull/458) by [G-Rath](https://github.com/g-rath).

## [v7.2.3] - March 23, 2024

### Added

- Emit warnings instead of errors when compilation is success but stderr is not empty. [PR 416](https://github.com/shakacode/shakapacker/pull/416) by [n-rodriguez](https://github.com/n-rodriguez).
- Allow `webpack-dev-server` v5. [PR 418](https://github.com/shakacode/shakapacker/pull/418) by [G-Rath](https://github.com/g-rath)

### Removed

- Removes dependency on `glob` library. [PR 435](https://github.com/shakacode/shakapacker/pull/435) by [tomdracz](https://github.com/tomdracz).

### Fixed

- Uses config file passed in `SHAKAPACKER_CONFIG` consistently.[PR 448](https://github.com/shakacode/shakapacker/pull/448) by [tomdracz](https://github.com/tomdracz).

  Previously this could have been ignored in few code branches, especially when checking for available environments.

## [v7.2.2] - January 19, 2024

### Added

- Allow `compression-webpack-plugin` v11. [PR 406](https://github.com/shakacode/shakapacker/pull/406) by [tagliala](https://github.com/tagliala).

## [v7.2.1] - December 30, 2023

### Fixed

- Show deprecation message for `relative_url_root` only if it is set. [PR 400](https://github.com/shakacode/shakapacker/pull/400) by [ahangarha](https://github.com/ahangarha).

## [v7.2.0] - December 28, 2023

### Added

- Experimental support for other JS package managers using `package_json` gem [PR 349](https://github.com/shakacode/shakapacker/pull/349) by [G-Rath](https://github.com/g-rath).
- Support `hmr: only` configuration [PR 378](https://github.com/shakacode/shakapacker/pull/378) by [SimenB](https://github.com/SimenB).
- Use `config/shakapacker.yml` as the secondary source for `asset_host` and `relative_url_root` configurations [PR 376](https://github.com/shakacode/shakapacker/pull/376) by [ahangarha](https://github.com/ahangarha).

### Fixed

- Recommend `server` option instead of the deprecated `https` option when `--https` is provided [PR 380](https://github.com/shakacode/shakapacker/pull/380) by [G-Rath](https://github.com/g-rath)
- Recompile assets on asset host change [PR 364](https://github.com/shakacode/shakapacker/pull/364) by [ahangarha](https://github.com/ahangarha).
- Add deprecation warning for `https` option in `shakapacker.yml` (use `server: 'https'` instead) [PR 382](https://github.com/shakacode/shakapacker/pull/382) by [G-Rath](https://github.com/g-rath).
- Disable Hot Module Replacement in `webpack-dev-server` when `hmr: false` [PR 392](https://github.com/shakacode/shakapacker/pull/392) by [thedanbob](https://github.com/thedanbob).

### Deprecated

- The usage of `relative_url_root` is deprecated in Shakapacker and will be removed in v8. [PR 376](https://github.com/shakacode/shakapacker/pull/376) by [ahangarha](https://github.com/ahangarha).

## [v7.1.0] - September 30, 2023

### Added

- Support passing custom webpack config directly to `generateWebpackConfig` for merging [PR 343](https://github.com/shakacode/shakapacker/pull/343) by [G-Rath](https://github.com/g-rath).

### Fixed

- Use `NODE_OPTIONS` to enable Node-specific debugging flags [PR 350](https://github.com/shakacode/shakapacker/pull/350).
- Add the boilerplate `application.js` into `packs/` [PR 363](https://github.com/shakacode/shakapacker/pull/363).

## [v7.0.3] - July 7, 2023

### Fixed

- Fixed commands execution for projects with space in the absolute path [PR 322](https://github.com/shakacode/shakapacker/pull/322) by [kukicola](https://github.com/kukicola).

## [v7.0.2] - July 3, 2023

### Fixed

- Fixed creation of assets:precompile if it is missing [PR 325](https://github.com/shakacode/shakapacker/pull/325) by [ahangarha](https://github.com/ahangarha).

## [v7.0.1] - June 27, 2023

### Fixed

- Fixed the condition for showing warning for setting `useContentHash` to `false` in the production environment. [PR 320](https://github.com/shakacode/shakapacker/pull/320) by [ahangarha](https://github.com/ahangarha).

## [v7.0.0] - June 23, 2023

### Breaking changes

- Removes defaults passed to `@babel/preset-typescript`. [PR 273](https://github.com/shakacode/shakapacker/pull/273) by [tomdracz](https://github.com/tomdracz).

  `@babel/preset-typescript` has been initialised in default configuration with `{ allExtensions: true, isTSX: true }` - meaning every file in the codebase was treated as TSX leading to potential issues. This has been removed and returns to sensible default of the preset which is to figure out the file type from the extensions. This change might affect generated output however so it is marked as breaking.

- Export immutable webpackConfig function. [PR 293](https://github.com/shakacode/shakapacker/pull/293) by [tomdracz](https://github.com/tomdracz).

  The `webpackConfig` property in the `shakapacker` module has been updated to be a function instead of a global mutable webpack configuration. This function now returns an immutable webpack configuration object, which ensures that any modifications made to it will not affect any other usage of the webpack configuration. If a project still requires the old mutable object, it can be accessed by replacing `webpackConfig` with `globalMutableWebpackConfig`. Check [v7-upgrade](https://github.com/shakacode/shakapacker/blob/main/docs/v7_upgrade.md) documentation for more detail.

### Added

- Set CSS modules mode depending on file type. [PR 261](https://github.com/shakacode/shakapacker/pull/261) by [talyuk](https://github.com/talyuk).
- All standard webpack entries with the camelCase format are now supported in `shakapacker.yml` in snake_case format. [PR276](https://github.com/shakacode/shakapacker/pull/276) by [ahangarha](https://github.com/ahangarha).
- The `shakapacker:install` rake task now has an option to force overriding files using `FORCE=true` environment variable [PR311](https://github.com/shakacode/shakapacker/pull/311) by [ahangarha](https://github.com/ahangarha).
- Allow configuration of use of contentHash for specific environment [PR 234](https://github.com/shakacode/shakapacker/pull/234) by [justin808](https://github/justin808).

### Changed

- Rename Webpacker to Shakapacker in the entire project including config files, binstubs, environment variables, etc. with a high degree of backward compatibility.

  This change might be breaking for certain setups and edge cases. More information: [v7 Upgrade Guide](./docs/v7_upgrade.md) [PR157](https://github.com/shakacode/shakapacker/pull/157) by [ahangarha](https://github.com/ahangarha)

- Set `source_entry_path` to `packs` and `nested_entries` to `true` in`shakapacker.yml` [PR 284](https://github.com/shakacode/shakapacker/pull/284) by [ahangarha](https://github.com/ahangarha).
- Dev server configuration is modified to follow [webpack recommended configurations](https://webpack.js.org/configuration/dev-server/) for dev server. [PR276](https://github.com/shakacode/shakapacker/pull/276) by [ahangarha](https://github.com/ahangarha):
  - Deprecated `https` entry is removed from the default configuration file, allowing to set `server` or `https` as per the project requirements. For more detail, check webpack documentation. The `https` entry can be effective only if there is no `server` entry in the config file.
  - `allowed_hosts` is now set to `auto` instead of `all` by default.

- Remove the arbitrary stripping of the top-level directory when generating static file paths. [PR 283](https://github.com/shakacode/shakapacker/pull/283) by [tomdracz](https://github.com/tomdracz).

  Prior to this change, top level directory of static assets like images and fonts was stripped. This meant that file in `app/javascript/images/image.png` would be output to `static/image.png` directory and could be referenced through helpers as `image_pack_tag("image.jpg")` or `image_pack_tag("static/image.jpg")`.

  Going forward, the top level directory of static files will be retained so this will necessitate the update of file name references in asset helpers. In the example above, the file sourced from `app/javascript/images/image.png` will be now output to `static/images/image.png` and needs to be referenced as `image_pack_tag("images/image.jpg")` or `image_pack_tag("static/images/image.jpg")`.

### Fixed

- Move compilation lock file into the working directory. [PR 272](https://github.com/shakacode/shakapacker/pull/272) by [tomdracz](https://github.com/tomdracz).
- Process `source_entry_path` with values starting with `/` as a relative path to `source_path` [PR 284](https://github.com/shakacode/shakapacker/pull/284) by [ahangarha](https://github.com/ahangarha).
- Removes defaults passed to `@babel/preset-typescript` to make it possible to have projects with mix of JS and TS code [PR 273](https://github.com/shakacode/shakapacker/pull/273) by [tomdracz](https://github.com/tomdracz).

  `@babel/preset-typescript` has been initialised in default configuration with `{ allExtensions: true, isTSX: true }` - meaning every file in the codebase was treated as TSX leading to potential issues. This has been removed and returns to sensible default of the preset which is to figure out the file type from the extensions. This change might affect generated output however so it is marked as breaking.

- Fixed RC version detection during installation. [PR312](https://github.com/shakacode/shakapacker/pull/312) by [ahangarha](https://github.com/ahangarha)
- Fix addition of webpack-dev-server to devDependencies during installation. [PR310](https://github.com/shakacode/shakapacker/pull/310) by [ahangarha](https://github.com/ahangarha)

### Removed

- Remove redundant enhancement for precompile task to run `yarn install` [PR 270](https://github.com/shakacode/shakapacker/pull/270) by [ahangarha](https://github.com/ahangarha).
- Remove deprecated `check_yarn_integrity` from `Shakapacker::Configuration` [PR SP288](https://github.com/shakacode/shakapacker/pull/288) by [ahangarha](https://github.com/ahangarha).

## [v6.6.0] - March 7, 2023

### Improved

- Allow configuration of webpacker.yml through env variable. [PR 254](https://github.com/shakacode/shakapacker/pull/254) by [alecslupu](https://github.com/alecslupu).

## [v6.5.6] - February 11, 2023

### Fixed

- Fixed failing to update `bin/setup` file due to different formats of the file in different versions of Rails. [PR 229](https://github.com/shakacode/shakapacker/pull/229) by [ahangarha](https://github.com/ahangarha).

- Upgrade several JS dependencies to fix security issues. [PR 243](https://github.com/shakacode/shakapacker/pull/243) by [ahangarha](https://github.com/ahangarha).

- Added `prepend_javascript_pack_tag` to helpers. Allows to move an entry to the top of queue. Handy when calling from the layout to make sure an entry goes before the view and partial `append_javascript_pack_tag` entries. [PR 235](https://github.com/shakacode/shakapacker/pull/235) by [paypro-leon](https://github.com/paypro-leon).

- Fixed [issue](https://github.com/shakacode/shakapacker/issues/208) to support directories under `node_modules/*` in the `additional_paths` property of `webpacker.yml` [PR 240](https://github.com/shakacode/shakapacker/pull/240) by [vaukalak](https://github.com/vaukalak).
- Remove duplicate yarn installs. [PR 238](https://github.com/shakacode/shakapacker/pull/238) by [justin808](https://github/justin808).
- Remove unneeded code related to CSP config for generator. [PR 223](https://github.com/shakacode/shakapacker/pull/223) by [ahangarha](https://github/ahangarha).

## [v6.5.5] - December 28, 2022

### Improved

- Describe keys different from `webpack-dev-server` in generated `webpacker.yml`. [PR 194](https://github.com/shakacode/shakapacker/pull/194) by [alexeyr](https://github.com/alexeyr).
- Allow webpack-cli v5 [PR 216](https://github.com/shakacode/shakapacker/pull/216) by [tagliala](https://github.com/tagliala).
- Allow babel-loader v9 [PR 215](https://github.com/shakacode/shakapacker/pull/215) by [tagliala](https://github.com/tagliala).

## [v6.5.4] - November 4, 2022

### Fixed

- Fixed regression caused by 6.5.3. PR #192 introduce extra split() call. [PR 202](https://github.com/shakacode/shakapacker/pull/202) by [Eric-Guo](https://github.com/Eric-Guo).

## [v6.5.3] - November 1, 2022

### Improved

- Set RAILS_ENV and BUNDLE_GEMFILE env values before requiring `bundler/setup`, `webpacker`, and `webpacker/webpack_runner`. [PR 190](https://github.com/shakacode/shakapacker/pull/190) by [betmenslido](https://github.com/betmenslido).
- The `mini-css-extract-plugin` may cause various warnings indicating CSS order conflicts when using a [File-System-based automated bundle generation feature](https://www.shakacode.com/react-on-rails/docs/guides/file-system-based-automated-bundle-generation/).
  CSS order warnings can be disabled in projects where CSS ordering has been mitigated by consistent use of scoping or naming conventions. Added `css_extract_ignore_order_warnings` flag to webpacker configuration to disable the order warnings by [pulkitkkr](https://github.com/shakacode/shakapacker/pull/185) in [PR 192](https://github.com/shakacode/shakapacker/pull/192).

## [v6.5.2] - September 8, 2022

### Upgrade

Remove the setting of the NODE_ENV in your `bin/webpacker` and `bin/webpacker-dev-server` files per [PR 185](https://github.com/shakacode/shakapacker/pull/185).

### Fixed

- Changed NODE_ENV defaults to the following and moved from binstubs to the runner. [PR 185](https://github.com/shakacode/shakapacker/pull/185) by [mage1711](https://github.com/mage1711).

```
ENV["NODE_ENV"] ||= (ENV["RAILS_ENV"] == "production") ? "production" : "development"
```

## [v6.5.1] - August 15, 2022

### Improved

- Resolve exact npm package version from lockfiles for constraint checking. [PR 170](https://github.com/shakacode/shakapacker/pull/170) by [G-Rath](https://github.com/G-Rath).

### Fixed

- `append_javascript_pack_tag` and `append_stylesheet_pack_tag` helpers return `nil` to prevent rendering the queue into view when using `<%= … %>` ERB syntax. [PR 167](https://github.com/shakacode/shakapacker/pull/167) by [ur5us](https://github.com/ur5us). While `<%=` should not be used, it's OK to return nil in case it's misused.
- Fixed non-runnable test due to wrong code nesting. [PR 173](https://github.com/shakacode/shakapacker/pull/173) by [ur5us](https://github.com/ur5us).
- Fixed default configurations not working for custom Rails environments [PR 168](https://github.com/shakacode/shakapacker/pull/168) by [ur5us](https://github.com/ur5us).
- Added accessor method for `nested_entries` configuration. [PR 176](https://github.com/shakacode/shakapacker/pull/176) by [pulkitkkr](https://github.com/pulkitkkr).

## [v6.5.0] - July 4, 2022

### Added

- `append_stylesheet_pack_tag` helper. It helps in configuring stylesheet pack names from the view for a route or partials. It is also required for filesystem-based automated Component Registry API on React on Rails gem. [PR 144](https://github.com/shakacode/shakapacker/pull/144) by [pulkitkkr](https://github.com/pulkitkkr).

### Improved

- Make sure at most one compilation runs at a time [PR 139](https://github.com/shakacode/shakapacker/pull/139) by [artemave](https://github.com/artemave)

## [v6.4.1] - June 5, 2022

### Fixed

- Restores automatic installation of yarn packages removed in [#131](https://github.com/shakacode/shakapacker/pull/131), with added deprecation notice. [PR 140](https://github.com/shakacode/shakapacker/pull/140) by [tomdracz](https://github.com/tomdracz).

  This will be again removed in Shakapacker v7 so you need to ensure you are installing yarn packages explicitly before the asset compilation, rather than relying on this behaviour through `asset:precompile` task (e.g. Capistrano deployment).

- Disable Spring being used by `rails-erb-loader`. [PR 141](https://github.com/shakacode/shakapacker/pull/141) by [tomdracz](https://github.com/tomdracz).

## [v6.4.0] - June 2, 2022

### Fixed

- Fixed [Issue 123: Rails 7.0.3 - Webpacker configuration file not found when running rails webpacker:install (shakapacker v6.3)](https://github.com/shakacode/shakapacker/issues/123) in [PR 136: Don't enhance precompile if no config #136](https://github.com/shakacode/shakapacker/pull/136) by [justin808](https://github.com/justin808).

### Added

- Configuration boolean option `nested_entries` to use nested entries. This was the default prior to v6.0. Because entries maybe generated, it's useful to allow a `generated` subdirectory. [PR 121](https://github.com/shakacode/shakapacker/pull/121) by [justin808](https://github.com/justin808).

### Improved

- Allow v10 of `compression-webpack-plugin` as a peer dependency. [PR 117](https://github.com/shakacode/shakapacker/pull/117) by [aried3r](https://github.com/aried3r).

- [Remove assets:precompile task enhancement #131](https://github.com/shakacode/shakapacker/pull/131) by [James Herdman](https://github.com/jherdman): Removed the `yarn:install` Rake task, and no longer enhance `assets:precompile` with said task. These tasks were used to ensure required NPM packages were installed before asset precompilation. Going forward you will need to ensure these packages are already installed yourself. Should you wish to restore this behaviour you'll need to [reimplement the task](https://github.com/shakacode/shakapacker/blob/bee661422f2c902aa8ac9cf8fa1f7ccb8142c914/lib/tasks/yarn.rake) in your own application.

## [v6.3.0] - May 19, 2022

### Improved

- Add ability to configure usage of either last modified timestamp and digest strategies when checking asset freshness. [PR 112](https://github.com/shakacode/shakapacker/pull/112) by [tomdracz](https://github.com/tomdracz).

### Fixed

- On Windows CSS urls no longer contain backslashes resulting in 404 errors. [PR 115](https://github.com/shakacode/shakapacker/pull/115) by [daniel-rikowski](https://github.com/daniel-rikowski).

## [v6.3.0-rc.1] - April 24, 2022

Note: [Rubygem is 6.3.0.pre.rc.1](https://rubygems.org/gems/shakapacker/versions/6.3.0.pre.rc.1) and [NPM is 6.3.0-rc.1](https://www.npmjs.com/package/shakapacker/v/6.3.0-rc.1).

### Changed

- Remove Loose mode from the default @babel-preset/env configuration. [PR 107](https://github.com/shakacode/shakapacker/pull/107) by [Jeremy Liberman](https://github.com/MrLeebo).

  Loose mode compiles the bundle down to be compatible with ES5, but saves space by skipping over behaviors that are considered edge cases. Loose mode can affect how your code runs in a variety of ways, but in newer versions of Babel it's better to use [Compiler Assumptions](https://babeljs.io/docs/en/assumptions) to have finer-grained control over which edge cases you're choosing to ignore.

  This change may increase the file size of your bundles, and may change some behavior in your app if your code touches upon one of the edge cases where Loose mode differs from native JavaScript. There are notes in the linked PR about how to turn Loose mode back on if you need to, but consider migrating to Compiler Assumptions when you can. If you have already customized your babel config, this change probably won't affect you.

### Added

- Adds `webpacker_precompile` setting to `webpacker.yml` to allow controlling precompile behaviour, similar to existing `ENV["WEBPACKER_PRECOMPILE"]` variable. [PR 102](https://github.com/shakacode/shakapacker/pull/102) by [Judahmeek](https://github.com/Judahmeek).
- Adds `append_javascript_pack_tag` helper. Allows for easier usage and coordination of multiple javascript packs. [PR 94](https://github.com/shakacode/shakapacker/pull/94) by [tomdracz](https://github.com/tomdracz).

### Improved

- Use last modified timestamps rather than file digest to determine compiler freshness. [PR 97](https://github.com/shakacode/shakapacker/pull/97) by [tomdracz](https://github.com/tomdracz).

  Rather than calculating SHA digest of all the files in the paths watched by the compiler, we are now comparing the modified time of the `manifest.json` file versus the latest modified timestamp of files and directories in watched paths. Unlike calculating digest, which only looked at the files, the new calculation also considers directory timestamps, including the parent ones (i.e. `config.source_path` folder timestamp will be checked together will timestamps of all files and directories inside of it).

  This change should result in improved compiler checks performance but might be breaking for certain setups and edge cases. If you encounter any issues, please report them at https://github.com/shakacode/shakapacker/issues.

- Bump dependency versions in package.json to address security vulnerabilities. [PR 109](https://github.com/shakacode/shakapacker/pull/109) by [tomdracz](https://github.com/tomdracz).
- Add `webpack-dev-server` as `peerDependency` to make its usage clear. [PR 109](https://github.com/shakacode/shakapacker/pull/109) by [tomdracz](https://github.com/tomdracz).

## [v6.2.1] - April 15, 2022

### Fixed

- Put back config.public_manifest_path, removed in 6.2.0 in PR 78. [PR 104](https://github.com/shakacode/shakapacker/pull/104) by [justin808](https://github.com/justin808).

## [v6.2.0] - March 22, 2022

### Added

- Make manifest_path configurable, to keep manifest.json private if desired. [PR 78](https://github.com/shakacode/shakapacker/pull/78) by [jdelStrother](https://github.com/jdelStrother).
- Rewrite webpack module rules as regular expressions. Allows for easy iteration during config customization. [PR 60](https://github.com/shakacode/shakapacker/pull/60) by [blnoonan](https://github.com/blnoonan).
- Initialization check to ensure shakapacker gem and NPM package version are consistent. Opt-in behaviour enabled by setting `ensure_consistent_versioning` configuration variable. [PR 51](https://github.com/shakacode/shakapacker/pull/51) by [tomdracz](https://github.com/tomdracz).
- Add `dev_server.inline_css: bool` config option to allow for opting out of style-loader and into mini-css-extract-plugin for CSS HMR in development. [PR 69](https://github.com/shakacode/shakapacker/pull/69) by [cheald](https://github.com/cheald).

### Improved

- Increase default connect timeout for dev server connections, establishing connections more reliably for busy machines. [PR 74](https://github.com/shakacode/shakapacker/pull/74) by [stevecrozz](https://github.com/stevecrozz).
- Allow multiple invocations of stylesheet_pack_tag (eg for a regular stylesheet & a print stylesheet). [PR 82](https://github.com/shakacode/shakapacker/pull/82) by [jdelStrother](https://github.com/jdelStrother).
- Tweak swc config for parity with Babel. [PR 79](https://github.com/shakacode/shakapacker/pull/79) by [dleavitt](https://github.com/dleavitt).

## [v6.1.1] - February 6, 2022

### Added

- Support for esbuild-loader. [PR 53](https://github.com/shakacode/shakapacker/pull/53) by [tomdracz](https://github.com/tomdracz).

## [v6.1.0] - February 4, 2022

### Added

- Support for SWC loader. [PR 29](https://github.com/shakacode/shakapacker/pull/29) by [tomdracz](https://github.com/tomdracz).

### Fixed

- Static asset subdirectories are retained after compilation, matching Webpacker v5 behaviour. [PR 47](https://github.com/shakacode/shakapacker/pull/47) by [tomdracz](https://github.com/tomdracz). Fixes issues [rails/webpacker#2956](https://github.com/rails/webpacker/issues/2956) which broke in [rails/webpacker#2802](https://github.com/rails/webpacker/pull/2802).

## [v6.0.2] - January 25, 2022

### Improved

- Fix incorrect command name in warning. [PR 33](https://github.com/shakacode/shakapacker/pull/33) by [tricknotes](https://github.com/tricknotes).

## [v6.0.1] - January 24, 2022

### Improved

- PR #21 removed pnp-webpack-plugin as a dev dependency but did not remove it from the peer dependency list. [PR 30](https://github.com/shakacode/shakapacker/pull/30) by [t27duck](https://github.com/t27duck).

## [v6.0.0 changes from v6.0.0.rc.6] - January 22, 2022

### Improved

- Raise on multiple invocations of javascript_pack_tag and stylesheet_pack_tag helpers. [PR 19](https://github.com/shakacode/shakapacker/pull/19) by [tomdracz](https://github.com/tomdracz).
- Remove automatic addition of node_modules into rails asset load path. [PR 20](https://github.com/shakacode/shakapacker/pull/20) by [tomdracz](https://github.com/tomdracz).
- Remove pnp-webpack-plugin. [PR 21](https://github.com/shakacode/shakapacker/pull/21) by [tomdracz](https://github.com/tomdracz).

### Merged from rails/webpacker

- Make watched_files_digest thread safe. [rails/webpacker #3233](https://github.com/rails/webpacker/pull/3233)
- Use single webpack config webpack.config.js. [rails/webpacker #3240](https://github.com/rails/webpacker/pull/3240)
- Switch to peer dependencies. [rails/webpacker #3234](https://github.com/rails/webpacker/pull/3234)

### Upgrading from rails/webpacker 6.0.0.rc.6

- Single default configuration file of `config/webpack/webpack.config.js`. Previously, the config file was set
  to `config/webpack/#{NODE_ENV}.js`.
- Changed all package.json dependencies to peerDependencies, so upgrading requires adding the dependencies, per the [UPGRADE GUIDE](./docs/v6_upgrade.md).

## [v6.0.0.rc.6 changes from v5.4] - Forked January 16, 2022

- `node_modules` will no longer be babel transformed compiled by default. This primarily fixes [rails issue #35501](https://github.com/rails/rails/issues/35501) as well as [numerous other webpacker issues](https://github.com/rails/webpacker/issues/2131#issuecomment-581618497). The disabled loader can still be required explicitly via:

  ```js
  const nodeModules = require("@rails/webpacker/rules/node_modules.js")
  environment.loaders.append("nodeModules", nodeModules)
  ```

- If you have added `environment.loaders.delete('nodeModules')` to your `environment.js`, this must be removed or you will receive an error (`Item nodeModules not found`).
- `extract_css` option was removed. Webpacker will generate a separate `application.css` file for the default `application` pack, as supported by multiple files per entry introduced in 5.0.0. [#2608](https://github.com/rails/webpacker/pull/2608). However, CSS will be inlined when the webpack-dev-server is used with `hmr: true`. JS package exports `inliningCss`. This is useful to enable HMR for React.
- Webpacker's wrapper to the `splitChunks()` API will now default `runtimeChunk: 'single'` which will help prevent potential issues when using multiple entry points per page [#2708](https://github.com/rails/webpacker/pull/2708).
- Changes `@babel/preset-env` modules option to `'auto'` per recommendation in the Babel docs [#2709](https://github.com/rails/webpacker/pull/2709)
- Adds experimental Yarn 2 support. Note you must manually set `nodeLinker: node-modules` in your `.yarnrc.yml`.
- Fixes dev server issues [#2898](https://github.com/rails/webpacker/pull/2898)
- Update static files path to from `media/` to `static/`.
- Deprecated configuration option `watched_paths`. Use `additional_paths` instead in `webpacker.yml`.

### Breaking changes

- Renamed `/bin/webpack` to `/bin/webpacker` and `/bin/webpack-dev-server` to `bin/webpacker-dev-server` to avoid confusion with underlying webpack executables.
- Removed integration installers
- Splitchunks enabled by default
- CSS extraction enabled by default, except when devServer is configured and running

## v5.4.3 and prior changes from rails/webpacker

See [CHANGELOG.md in rails/webpacker (up to v5.4.3)](https://github.com/rails/webpacker/blob/master/CHANGELOG.md)

[Unreleased]: https://github.com/shakacode/shakapacker/compare/v9.7.0...main
[v9.7.0]: https://github.com/shakacode/shakapacker/compare/v9.6.1...v9.7.0
[v9.6.1]: https://github.com/shakacode/shakapacker/compare/v9.6.0...v9.6.1
[v9.6.0]: https://github.com/shakacode/shakapacker/compare/v9.5.0...v9.6.0
[v9.5.0]: https://github.com/shakacode/shakapacker/compare/v9.4.0...v9.5.0
[v9.4.0]: https://github.com/shakacode/shakapacker/compare/v9.3.4...v9.4.0
[v9.3.4]: https://github.com/shakacode/shakapacker/compare/v9.3.3...v9.3.4
[v9.3.3]: https://github.com/shakacode/shakapacker/compare/v9.3.2...v9.3.3
[v9.3.2]: https://github.com/shakacode/shakapacker/compare/v9.3.1...v9.3.2
[v9.3.1]: https://github.com/shakacode/shakapacker/compare/v9.3.0...v9.3.1
[v9.3.0]: https://github.com/shakacode/shakapacker/compare/v9.2.0...v9.3.0
[v9.2.0]: https://github.com/shakacode/shakapacker/compare/v9.1.0...v9.2.0
[v9.1.0]: https://github.com/shakacode/shakapacker/compare/v9.0.0...v9.1.0
[v9.0.0]: https://github.com/shakacode/shakapacker/compare/v8.4.0...v9.0.0
[v8.4.0]: https://github.com/shakacode/shakapacker/compare/v8.3.0...v8.4.0
[v8.3.0]: https://github.com/shakacode/shakapacker/compare/v8.2.0...v8.3.0
[v8.2.0]: https://github.com/shakacode/shakapacker/compare/v8.1.0...v8.2.0
[v8.1.0]: https://github.com/shakacode/shakapacker/compare/v8.0.2...v8.1.0
[v8.0.2]: https://github.com/shakacode/shakapacker/compare/v8.0.1...v8.0.2
[v8.0.1]: https://github.com/shakacode/shakapacker/compare/v8.0.0...v8.0.1
[v8.0.0]: https://github.com/shakacode/shakapacker/compare/v7.2.3...v8.0.0
[v7.2.3]: https://github.com/shakacode/shakapacker/compare/v7.2.2...v7.2.3
[v7.2.2]: https://github.com/shakacode/shakapacker/compare/v7.2.1...v7.2.2
[v7.2.1]: https://github.com/shakacode/shakapacker/compare/v7.2.0...v7.2.1
[v7.2.0]: https://github.com/shakacode/shakapacker/compare/v7.1.0...v7.2.0
[v7.1.0]: https://github.com/shakacode/shakapacker/compare/v7.0.3...v7.1.0
[v7.0.3]: https://github.com/shakacode/shakapacker/compare/v7.0.2...v7.0.3
[v7.0.2]: https://github.com/shakacode/shakapacker/compare/v7.0.1...v7.0.2
[v7.0.1]: https://github.com/shakacode/shakapacker/compare/v7.0.0...v7.0.1
[v7.0.0]: https://github.com/shakacode/shakapacker/compare/v6.6.0...v7.0.0
[v6.6.0]: https://github.com/shakacode/shakapacker/compare/v6.5.6...v6.6.0
[v6.5.6]: https://github.com/shakacode/shakapacker/compare/v6.5.5...v6.5.6
[v6.5.5]: https://github.com/shakacode/shakapacker/compare/v6.5.4...v6.5.5
[v6.5.4]: https://github.com/shakacode/shakapacker/compare/v6.5.3...v6.5.4
[v6.5.3]: https://github.com/shakacode/shakapacker/compare/v6.5.2...v6.5.3
[v6.5.2]: https://github.com/shakacode/shakapacker/compare/v6.5.1...v6.5.2
[v6.5.1]: https://github.com/shakacode/shakapacker/compare/v6.5.0...v6.5.1
[v6.5.0]: https://github.com/shakacode/shakapacker/compare/v6.4.1...v6.5.0
[v6.4.1]: https://github.com/shakacode/shakapacker/compare/v6.4.0...v6.4.1
[v6.4.0]: https://github.com/shakacode/shakapacker/compare/v6.3.0...v6.4.0
[v6.3.0]: https://github.com/shakacode/shakapacker/compare/v6.2.1...v6.3.0
[v6.2.1]: https://github.com/shakacode/shakapacker/compare/v6.2.0...v6.2.1
[v6.2.0]: https://github.com/shakacode/shakapacker/compare/v6.1.1...v6.2.0
[v6.1.1]: https://github.com/shakacode/shakapacker/compare/v6.1.0...v6.1.1
[v6.1.0]: https://github.com/shakacode/shakapacker/compare/v6.0.2...v6.1.0
[v6.0.2]: https://github.com/shakacode/shakapacker/compare/v6.0.1...v6.0.2
[v6.0.1]: https://github.com/shakacode/shakapacker/compare/v6.0.0...v6.0.1
[v6.0.0 changes from v6.0.0.rc.6]: https://github.com/shakacode/shakapacker/compare/aba79635e6ff6562ec04d3c446d57ef19a5fef7d...v6.0.0
[v6.0.0.rc.6 changes from v5.4]: https://github.com/rails/webpacker/compare/v5.4.3...aba79635e6ff6562ec04d3c446d57ef19a5fef7d
