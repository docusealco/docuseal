# Shakapacker Configuration Guide

This guide covers all configuration options available in `config/shakapacker.yml` and how to use them effectively.

## Table of Contents

- [Quick Reference](#quick-reference)
- [Basic Configuration](#basic-configuration)
- [Source Configuration](#source-configuration)
- [Output Configuration](#output-configuration)
- [Bundler Configuration](#bundler-configuration)
- [Development Server](#development-server)
- [Compilation Options](#compilation-options)
- [Advanced Options](#advanced-options)
  - [Subresource Integrity](#integrity)
  - [Early Hints](#early_hints)
- [Environment-Specific Configuration](#environment-specific-configuration)
- [Build Configurations (config/shakapacker-builds.yml)](#build-configurations-configshakapacker-buildsyml)

## Quick Reference

Common configuration options with their defaults:

| Option                         | Type    | Default                                 | Description                                                |
| ------------------------------ | ------- | --------------------------------------- | ---------------------------------------------------------- |
| `assets_bundler`               | string  | `"webpack"`                             | Bundler to use: `"webpack"` or `"rspack"`                  |
| `assets_bundler_config_path`   | string  | `"config/webpack"` or `"config/rspack"` | Directory containing bundler config files                  |
| `javascript_transpiler`        | string  | `"swc"`\*                               | Transpiler: `"swc"`, `"babel"`, or `"esbuild"`             |
| `source_path`                  | string  | `"app/javascript"`                      | Root directory for JavaScript source files                 |
| `source_entry_path`            | string  | `"packs"`                               | Subdirectory within `source_path` for entry points         |
| `nested_entries`               | boolean | `true`                                  | Discover entry points in subdirectories                    |
| `public_output_path`           | string  | `"packs"`                               | Subdirectory within `public_root_path` for compiled assets |
| `private_output_path`          | string  | `nil`                                   | Directory for private server-side bundles (e.g., SSR)      |
| `compile`                      | boolean | env-specific                            | Compile assets on-demand when requests are made            |
| `cache_manifest`               | boolean | `false` (dev), `true` (prod)            | Cache manifest.json in memory                              |
| `compiler_strategy`            | string  | `"mtime"` (dev), `"digest"` (prod)      | How to determine if recompilation is needed                |
| `useContentHash`               | boolean | `false` (dev), `true` (prod)            | Include content hashes in asset filenames                  |
| `webpack_compile_output`       | boolean | `true`                                  | Show webpack/rspack compilation output                     |
| `shakapacker_precompile`       | boolean | `true`                                  | Include in `bundle exec rake assets:precompile`            |
| `ensure_consistent_versioning` | boolean | `true`                                  | Enforce gem/npm version matching                           |
| `dev_server.host`              | string  | `"localhost"`                           | Development server host                                    |
| `dev_server.port`              | number  | `3035`                                  | Development server port                                    |
| `dev_server.hmr`               | boolean | `false`                                 | Enable Hot Module Replacement                              |

For detailed explanations, examples, and additional options, see the sections below.

**\*Note on `javascript_transpiler` default**: The installation template sets this to `"swc"` for new projects. However, at runtime, if no explicit value is configured, webpack defaults to `"babel"` (for backward compatibility) while rspack defaults to `"swc"`.

## Basic Configuration

### `assets_bundler`

**Type:** `string`
**Default:** `"webpack"`
**Options:** `"webpack"` or `"rspack"`

Specifies which bundler to use for compiling assets.

```yaml
# Use webpack (default)
assets_bundler: "webpack"

# Use rspack for faster builds
assets_bundler: "rspack"
```

See [RSpack Migration Guide](rspack_migration_guide.md) for details on switching bundlers.

### `assets_bundler_config_path`

**Type:** `string`
**Default:** `"config/webpack"` for webpack, `"config/rspack"` for rspack

Specifies the directory containing your webpack/rspack config files.

```yaml
# Use default paths (config/webpack or config/rspack)
# assets_bundler_config_path: config/webpack

# Use custom directory
assets_bundler_config_path: "build_configs"

# Use project root directory
assets_bundler_config_path: "."
```

**When to use:**

- When migrating from another build tool and want to preserve existing config locations
- When organizing configs in a monorepo structure
- When following custom project conventions

### `javascript_transpiler`

**Type:** `string`
**Default:** `"swc"` (new installations), `"babel"` (webpack runtime), `"swc"` (rspack runtime)
**Options:** `"swc"`, `"babel"`, or `"esbuild"`

Specifies which transpiler to use for JavaScript/TypeScript.

```yaml
# Use SWC (recommended - 20x faster than Babel, set by default in new installations)
javascript_transpiler: "swc"

# Use Babel (for maximum compatibility, webpack runtime default if not configured)
javascript_transpiler: "babel"

# Use esbuild (fastest, but may have compatibility issues)
javascript_transpiler: "esbuild"
```

**Important default behavior:**

- **New installations**: The installation template explicitly sets `javascript_transpiler: "swc"`
- **Webpack runtime default**: If not explicitly configured, defaults to `"babel"` for backward compatibility
- **Rspack runtime default**: If not explicitly configured, defaults to `"swc"` as rspack is a newer bundler

See [Transpiler Performance Guide](transpiler-performance.md) for benchmarks and migration guides.

## Source Configuration

### `source_path`

**Type:** `string`
**Default:** `"app/javascript"`

The root directory for your JavaScript source files.

```yaml
# Default
source_path: app/javascript

# Custom location
source_path: app/frontend
```

### `source_entry_path`

**Type:** `string`
**Default:** `"packs"`

Subdirectory within `source_path` containing entry points.

```yaml
# Recommended: use a subdirectory
source_entry_path: packs

# Use the entire source_path as entry directory
source_entry_path: /
```

**Note:** Cannot use `/` when `nested_entries` is `true`.

### `nested_entries`

**Type:** `boolean`
**Default:** `true`

Whether to automatically discover entry points in subdirectories within `source_entry_path`.

```yaml
# Enable nested entries (recommended)
nested_entries: true

# Disable - only top-level files are entries
nested_entries: false
```

**Example with nested entries:**

```
app/javascript/packs/
  application.js       # Entry: application
  admin/
    dashboard.js       # Entry: admin/dashboard
```

### `additional_paths`

**Type:** `array`
**Default:** `[]`

Additional directories for webpack/rspack to search for modules.

```yaml
additional_paths:
  - app/assets
  - vendor/assets
  - node_modules/legacy-lib
```

**Use cases:**

- Resolving modules from Rails asset directories
- Including vendored JavaScript
- Sharing code between engines

## Output Configuration

### `public_root_path`

**Type:** `string`
**Default:** `"public"`

The public directory where assets are served from.

```yaml
public_root_path: public
```

### `public_output_path`

**Type:** `string`
**Default:** `"packs"`

Subdirectory within `public_root_path` for compiled assets.

```yaml
# Default - outputs to public/packs
public_output_path: packs

# Custom output directory
public_output_path: webpack-bundles
```

### `private_output_path`

**Type:** `string`
**Default:** `nil`

Directory for private server-side bundles (e.g., for SSR) that should not be publicly accessible.

```yaml
# Enable private output for SSR bundles
private_output_path: ssr-generated
```

**Important:** Must be different from `public_output_path` to prevent serving private bundles.

### `manifest_path`

**Type:** `string`
**Default:** `"{public_output_path}/manifest.json"`

Location of the manifest.json file that maps entry points to compiled assets.

```yaml
# Custom manifest location
manifest_path: public/assets/webpack-manifest.json
```

**Note:** Rarely needs to be changed from the default.

### `cache_path`

**Type:** `string`
**Default:** `"tmp/shakapacker"`

Directory for webpack/rspack cache files.

```yaml
cache_path: tmp/shakapacker

# Use a shared cache in CI
cache_path: /mnt/shared/webpack-cache
```

## Bundler Configuration

### `webpack_compile_output`

**Type:** `boolean`
**Default:** `true`

Whether to show webpack/rspack compilation output in the console.

```yaml
# Show detailed output (helpful for debugging)
webpack_compile_output: true

# Minimal output (cleaner logs)
webpack_compile_output: false
```

### `useContentHash`

**Type:** `boolean`
**Default:** `false` (development), `true` (production - enforced)

Whether to include content hashes in asset filenames for cache busting.

```yaml
# Production only (default)
useContentHash: false

# Always use content hash (not recommended for development)
useContentHash: true
```

**Note:** In production, this is always `true` regardless of configuration.

### `css_extract_ignore_order_warnings`

**Type:** `boolean`
**Default:** `false`

Whether to suppress mini-css-extract-plugin order warnings.

```yaml
# Enable if you have consistent CSS scoping
css_extract_ignore_order_warnings: true
```

**When to enable:**

- When using CSS modules or scoped styles
- When following BEM or similar naming conventions
- When order warnings are false positives

## Development Server

### `dev_server`

Configuration for `bin/shakapacker-dev-server`. See [Dev Server Options](#dev-server-options) below.

#### Dev Server Options

```yaml
dev_server:
  # Host to bind to
  host: localhost

  # Port to listen on
  port: 3035

  # Enable HTTPS
  # server: https

  # Hot Module Replacement
  hmr: false

  # Live reload (alternative to HMR)
  # live_reload: true

  # Inline CSS with HMR (requires style-loader)
  inline_css: true

  # Compression
  compress: true

  # Allowed hosts (security)
  allowed_hosts: "auto"

  # Client configuration
  client:
    # Show error overlay
    overlay: true

    # Custom WebSocket URL
    # webSocketURL:
    #   hostname: '0.0.0.0'
    #   pathname: '/ws'
    #   port: 8080

  # Custom headers for dev server responses
  # Uncomment to enable CORS (e.g., when webpack-dev-server runs on a different
  # port than your Rails server and the browser blocks cross-origin asset requests):
  # headers:
  #   "Access-Control-Allow-Origin": "*"

  # Static file serving
  static:
    watch:
      ignored: "**/node_modules/**"
```

**Key Options:**

- **hmr:** Hot Module Replacement updates modules without full reload. Requires additional setup.
- **inline_css:** With HMR, CSS is delivered via JavaScript. Set to `false` to use `<link>` tags.
- **overlay:** Shows errors/warnings in browser overlay. Helpful for development.
- **allowed_hosts:** Protects against DNS rebinding attacks. Use `"all"` to disable (not recommended).

## Compilation Options

### `compile`

**Type:** `boolean`
**Environment-specific**

Whether to compile assets on-demand when requests are made.

```yaml
development:
  compile: true # Compile on demand

production:
  compile: false # Assets must be precompiled
```

### `shakapacker_precompile`

**Type:** `boolean`
**Default:** `true`

Whether `bundle exec rake assets:precompile` should compile webpack/rspack assets.

```yaml
# Include in assets:precompile (recommended)
shakapacker_precompile: true

# Skip webpack compilation during assets:precompile
shakapacker_precompile: false
```

**Override via environment variable:**

```bash
SHAKAPACKER_PRECOMPILE=false bundle exec rake assets:precompile
```

### `cache_manifest`

**Type:** `boolean`
**Default:** `false` (development), `true` (production)

Whether to cache manifest.json in memory.

```yaml
development:
  cache_manifest: false # Reload on every request

production:
  cache_manifest: true # Cache for performance
```

### `compiler_strategy`

**Type:** `string`
**Default:** `"mtime"` (development), `"digest"` (production)
**Options:** `"mtime"` or `"digest"`

How to determine if assets need recompilation.

```yaml
development:
  # Fast: check file modification times
  compiler_strategy: mtime

production:
  # Accurate: check content hashes
  compiler_strategy: digest
```

**mtime:** Faster but may miss changes if timestamps are unreliable.
**digest:** Slower but guarantees accuracy by comparing content hashes.

## Advanced Options

### `precompile_hook`

**Type:** `string`
**Default:** `nil`

Command to run before webpack/rspack compilation. Useful for generating dynamic entry points.

```yaml
precompile_hook: "bin/shakapacker-precompile-hook"
```

**Security:** Only reference trusted scripts within your project. The path is validated.

See [Precompile Hook Guide](precompile_hook.md) for examples and use cases.

### `ensure_consistent_versioning`

**Type:** `boolean`
**Default:** `true`

Raises an error if shakapacker gem and npm package versions don't match.

```yaml
# Enforce version matching (recommended)
ensure_consistent_versioning: true

# Allow version mismatches (not recommended)
ensure_consistent_versioning: false
```

### `asset_host`

**Type:** `string`
**Default:** `nil` (uses Rails asset host)

Override Rails asset host for webpack assets specifically.

```yaml
# Use custom CDN for webpack assets
asset_host: https://cdn.example.com
```

**Environment variable override:**

```bash
SHAKAPACKER_ASSET_HOST=https://cdn.example.com
```

See [CDN Setup Guide](cdn_setup.md) for complete configuration.

### `integrity`

**Type:** `object`
**Default:** `{ enabled: false }`

Enable Subresource Integrity (SRI) for security.

```yaml
integrity:
  enabled: true
  hash_functions: ["sha384"] # or ["sha256"], ["sha512"]
  cross_origin: "anonymous" # or "use-credentials"
```

See [Subresource Integrity Guide](subresource_integrity.md) for details.

### `early_hints`

**Type:** `object`
**Default:** `{ enabled: false, css: "preload", js: "preload" }`
**Requires:** Rails 5.2+, HTTP/2 server

Automatically send HTTP 103 Early Hints for faster asset loading.

```yaml
early_hints:
  enabled: true # Master switch (default: false)
  css: "preload" # 'preload' | 'prefetch' | 'none' (default: 'preload')
  js: "preload" # 'preload' | 'prefetch' | 'none' (default: 'preload')
```

**Options:**

- `enabled`: Enable/disable early hints (default: `false`)
- `css`: Hint type for CSS - `'preload'`, `'prefetch'`, or `'none'` (default: `'preload'`)
- `js`: Hint type for JS - `'preload'`, `'prefetch'`, or `'none'` (default: `'preload'`)

⚠️ **Performance note**: May improve or hurt page load depending on content. Configure per-page for best results.

See the [Early Hints Guide](early_hints.md) for:

- Performance considerations and warnings
- Per-page configuration (`configure_pack_early_hints`)
- Dynamic configuration examples
- Hero image preloading with `preload_link_tag`
- Troubleshooting and testing recommendations

## Environment-Specific Configuration

Shakapacker supports per-environment configuration with fallback logic:

1. Checks for environment-specific config (e.g., `development`, `staging`)
2. Falls back to `production` if not found
3. Uses bundled defaults if neither exists

```yaml
# Shared defaults
default: &default
  source_path: app/javascript
  assets_bundler: "webpack"

# Development
development:
  <<: *default
  compile: true
  compiler_strategy: mtime
  dev_server:
    hmr: true

# Test
test:
  <<: *default
  compile: true
  public_output_path: packs-test

# Production
production:
  <<: *default
  compile: false
  cache_manifest: true
  compiler_strategy: digest
  useContentHash: true # Enforced regardless
```

### Custom Environments

For custom environments (e.g., `staging`), define a section or let it fall back to production:

```yaml
# Option 1: Explicit staging config
staging:
  <<: *default
  compile: false
  # staging-specific options

# Option 2: Let staging fall back to production
# (no staging section needed)
```

## Configuration Validation

Shakapacker validates configuration at runtime and provides helpful error messages:

- **Missing config files:** Suggests creating config or checking `assets_bundler_config_path`
- **Transpiler mismatch:** Warns if package.json dependencies don't match configured transpiler
- **Path conflicts:** Prevents `private_output_path` from being the same as `public_output_path`
- **Version mismatches:** Detects gem/npm version differences when `ensure_consistent_versioning` is enabled

## Environment Variables

Some options can be overridden via environment variables:

| Variable                     | Description                                        | Example                      |
| ---------------------------- | -------------------------------------------------- | ---------------------------- |
| `SHAKAPACKER_CONFIG`         | Path to shakapacker.yml                            | `config/webpack.yml`         |
| `SHAKAPACKER_ASSETS_BUNDLER` | Override assets bundler                            | `rspack`                     |
| `SHAKAPACKER_PRECOMPILE`     | Override precompile flag                           | `false`                      |
| `SHAKAPACKER_ASSET_HOST`     | Override asset host                                | `https://cdn.example.com`    |
| `SHAKAPACKER_PUBLIC_*`       | Auto-exposed to client-side JS (prefix convention) | `SHAKAPACKER_PUBLIC_API_URL` |
| `SHAKAPACKER_ENV_VARS`       | Additional env vars to expose to client-side JS    | `API_URL,FEATURE_FLAGS`      |
| `NODE_ENV`                   | Node environment                                   | `production`                 |
| `RAILS_ENV`                  | Rails environment                                  | `staging`                    |

### Exposing Environment Variables to Client-Side JavaScript

By default, only `NODE_ENV`, `RAILS_ENV`, and `WEBPACK_SERVE` are exposed to client-side JavaScript via webpack/rspack's `EnvironmentPlugin`. This is a security measure to prevent accidentally leaking secrets like `DATABASE_URL`, `API_SECRET_KEY`, etc. into your JavaScript bundles.

#### SHAKAPACKER*PUBLIC*\* Prefix (Recommended)

Any environment variable prefixed with `SHAKAPACKER_PUBLIC_` is automatically exposed to client-side code. This follows the same convention used by Next.js (`NEXT_PUBLIC_*`) and Vite (`VITE_*`):

```bash
# These are automatically available in your JavaScript
export SHAKAPACKER_PUBLIC_API_URL=https://api.example.com
export SHAKAPACKER_PUBLIC_ANALYTICS_ID=UA-12345
export SHAKAPACKER_PUBLIC_FEATURE_FLAGS=dark_mode,beta_ui
```

```javascript
// Access in your JavaScript code
console.log(process.env.SHAKAPACKER_PUBLIC_API_URL)
console.log(process.env.SHAKAPACKER_PUBLIC_ANALYTICS_ID)
```

The prefix makes it explicit which variables are intended for client-side use, preventing accidental exposure of secrets.

#### SHAKAPACKER_ENV_VARS (Legacy/Escape Hatch)

For variables without the `SHAKAPACKER_PUBLIC_` prefix, you can use `SHAKAPACKER_ENV_VARS` to expose them:

```bash
# Expose additional variables during build
SHAKAPACKER_ENV_VARS=API_BASE_URL,FEATURE_FLAGS bundle exec rake assets:precompile

# In development
SHAKAPACKER_ENV_VARS=API_BASE_URL bin/shakapacker-dev-server
```

```javascript
// These are available after adding to SHAKAPACKER_ENV_VARS
console.log(process.env.API_BASE_URL)
console.log(process.env.FEATURE_FLAGS)
```

## Best Practices

1. **Use default paths** unless you have a specific reason to change them
2. **Enable SWC transpiler** for faster builds (20x faster than Babel)
3. **Use rspack** for even faster builds if compatible with your setup
4. **Cache manifest** in production for better performance
5. **Enable integrity hashes** in production for security
6. **Keep development and production configs aligned** except for optimization settings
7. **Use content hashes** in production for proper cache busting
8. **Validate after changes** by running `bin/shakapacker` to ensure compilation works

## Common Configuration Patterns

### Fast Development Setup

```yaml
development:
  assets_bundler: "rspack"
  javascript_transpiler: "swc"
  compiler_strategy: mtime
  webpack_compile_output: true
  dev_server:
    hmr: true
    inline_css: true
```

### Production-Optimized

```yaml
production:
  assets_bundler: "rspack"
  javascript_transpiler: "swc"
  compiler_strategy: digest
  cache_manifest: true
  useContentHash: true
  integrity:
    enabled: true
```

### Monorepo Setup

```yaml
default: &default
  source_path: packages/frontend/src
  assets_bundler_config_path: build_configs/webpack
  additional_paths:
    - packages/shared
    - packages/ui-components
```

## Build Configurations (config/shakapacker-builds.yml)

Shakapacker supports defining reusable build configurations in `config/shakapacker-builds.yml`. This allows you to run predefined builds with a simple command, making it easy to switch between different build scenarios.

### Creating a Build Configuration File

Generate `config/shakapacker-builds.yml` with example builds:

```bash
bin/shakapacker --init  # Creates config/shakapacker-builds.yml
```

This generates a file with example builds for common scenarios (HMR development, standard development, and production).

### Running Builds by Name

Once you have `config/shakapacker-builds.yml`, you can run builds by name:

```bash
# List available builds
bin/shakapacker --list-builds

# Run a specific build
bin/shakapacker --build dev-hmr    # Client bundle with HMR (automatically uses dev server)
bin/shakapacker --build prod        # Client and server bundles for production
bin/shakapacker --build dev         # Client bundle for development
```

### Build Configuration Format

Example `config/shakapacker-builds.yml`:

```yaml
builds:
  dev-hmr:
    description: Client bundle with HMR (React Fast Refresh)
    bundler: rspack # Optional: override assets_bundler from config/shakapacker.yml
    environment:
      NODE_ENV: development
      RAILS_ENV: development
      WEBPACK_SERVE: "true" # Automatically uses bin/shakapacker-dev-server
    outputs:
      - client
    config: config/${BUNDLER}/custom.config.js # Optional: custom config file with variable substitution

  prod:
    description: Production client and server bundles
    environment:
      NODE_ENV: production
      RAILS_ENV: production
    outputs:
      - client # Multiple outputs - builds both client and server bundles
      - server
```

### Build Configuration Options

- **`description`** (optional): Human-readable description of the build
- **`bundler`** (optional): Override the default bundler from `config/shakapacker.yml` (`webpack` or `rspack`)
- **`dev_server`** (optional): Boolean flag to force routing to dev server (overrides environment variable detection)
- **`environment`**: Environment variables to set when running the build
- **`outputs`**: Array of output types - can include `client`, `server`, or both for multiple bundles in a single build
- **`config`** (optional): Custom config file path (supports `${BUNDLER}` variable substitution)
- **`bundler_env`** (optional): Key-value pairs passed as bundler `--env` flags (e.g., `{ analyze: true }` becomes `--env analyze=true`)

### Automatic Dev Server Detection

Shakapacker automatically uses `bin/shakapacker-dev-server` instead of the regular build command when:

1. The build has `dev_server: true` explicitly set (preferred method - takes precedence over environment variables), OR
2. The build has `WEBPACK_SERVE=true` or `HMR=true` in its environment variables (fallback for backward compatibility)

Example:

```bash
# These are equivalent:
bin/shakapacker --build dev-hmr
WEBPACK_SERVE=true bin/shakapacker-dev-server  # (with dev-hmr environment vars)
```

### Variable Substitution

The `config` field supports `${BUNDLER}` substitution:

```yaml
builds:
  custom:
    bundler: rspack
    config: config/${BUNDLER}/custom.config.js # Becomes: config/rspack/custom.config.js
```

### When to Use Build Configurations

Build configurations are useful for:

- **Multiple build scenarios**: Use when you need different builds for HMR development, standard development, and production
- **CI/CD pipelines**: Use when you want predefined builds that can be referenced in deployment scripts
- **Team consistency**: Use to ensure all developers use the same build configurations
- **Complex setups**: Use to manage different bundler configs or environment variables for different scenarios

## Troubleshooting

If you encounter configuration issues:

1. **Check error messages** - they often suggest the fix
2. **Validate YAML syntax** - use a YAML validator to ensure proper formatting
3. **Review fallback behavior** - missing environment configs fall back to production
4. **Check environment variables** - they override config file settings
5. **Inspect manifest.json** - verify assets are being compiled correctly

See [Troubleshooting Guide](troubleshooting.md) for more help.

## Related Guides

- [RSpack Migration Guide](rspack_migration_guide.md)
- [Transpiler Performance Guide](transpiler-performance.md)
- [Deployment Guide](deployment.md)
- [CDN Setup Guide](cdn_setup.md)
- [Precompile Hook Guide](precompile_hook.md)
- [Early Hints Guide](early_hints.md)
- [Subresource Integrity Guide](subresource_integrity.md)
- [Troubleshooting Guide](troubleshooting.md)
