# Rspack Migration Guide for Shakapacker

> 💡 **Quick Start**: For a step-by-step migration guide from Webpack to Rspack, see [Common Upgrades Guide - Webpack to Rspack](./common-upgrades.md#migrating-from-webpack-to-rspack).

## Table of Contents

- [Overview](#overview)
- [Before You Migrate](#before-you-migrate)
  - [Migration Timeline Expectations](#migration-timeline-expectations)
  - [Testing Strategy](#testing-strategy)
  - [Server-Side Rendering (SSR) Considerations](#server-side-rendering-ssr-considerations)
- [Key Differences from Webpack](#key-differences-from-webpack)
- [Migration Steps](#migration-steps)
- [Build Verification](#build-verification)
- [Configuration Best Practices](#configuration-best-practices)
- [Common Migration Issues](#common-migration-issues)
- [Common Issues and Solutions](#common-issues-and-solutions)
- [Performance Tips](#performance-tips)
- [Debugging Configuration](#debugging-configuration)
- [Resources](#resources)

## Overview

This guide documents the differences between webpack and Rspack configurations in Shakapacker, and provides migration guidance for users switching to Rspack.

[Rspack](https://rspack.rs/) is a high-performance bundler written in Rust, offering 5-10x faster build times than webpack with excellent webpack compatibility.

## Before You Migrate

### Migration Timeline Expectations

Based on real-world migrations, plan your migration time accordingly:

- **Simple projects** (no SSR, no CSS modules, no custom config): 1-2 hours
- **Standard projects** (CSS modules, basic SSR): 4-8 hours
- **Complex projects** (CSS modules, SSR, ReScript, custom config): 2-3 days

**Without good documentation**: A complex migration can take 3+ days with 11+ commits to resolve all issues.

**With this documentation**: Most issues can be resolved in 2-3 commits.

### Testing Strategy

When migrating from webpack to Rspack, follow this testing strategy to minimize issues:

1. **Test locally first**: Ensure you can run the full test suite locally before pushing
2. **Incremental migration**: Consider migrating to SWC first (while on webpack), test thoroughly, then migrate to Rspack
3. **Watch for test flakiness**: SSR-related issues (especially CSS extraction) can cause non-deterministic test failures
4. **Run full test suite**: Don't rely solely on CI - run tests locally to catch issues faster

### Server-Side Rendering (SSR) Considerations

⚠️ **If your application uses SSR**, be aware of these critical issues before migrating:

1. **CSS Extraction Differences**: Rspack uses different loader paths than webpack for CSS extraction
2. **CSS Modules Breaking Change**: Shakapacker 9 changed from default exports to named exports
3. **React Runtime Compatibility**: SWC's automatic runtime may not work with React on Rails SSR detection

**SSR Migration Checklist** (complete before migrating):

- [ ] Understand how your server bundle filters CSS extraction loaders
- [ ] Know whether you're using CSS modules and how they're imported
- [ ] Check if you're using React on Rails SSR (may need classic React runtime)
- [ ] Plan for potential configuration changes to handle both webpack and Rspack paths

**Detailed SSR solutions** are provided in the [Common Issues](#common-issues-and-solutions) section below.

## Key Differences from Webpack

### 1. Built-in Loaders

Rspack provides built-in loaders for better performance:

**JavaScript/TypeScript:**

- Use `builtin:swc-loader` instead of `babel-loader` or `ts-loader`
- 20x faster than Babel on single thread, 70x on multiple cores
- Configuration example:

```javascript
{
  test: /\.(js|jsx|ts|tsx)$/,
  loader: 'builtin:swc-loader',
  options: {
    jsc: {
      parser: {
        syntax: 'typescript', // or 'ecmascript'
        tsx: true, // for TSX files
        jsx: true  // for JSX files
      },
      transform: {
        react: {
          runtime: 'automatic'
        }
      }
    }
  }
}
```

### 2. Plugin Replacements

#### Built-in Rspack Alternatives

| Webpack Plugin                 | Rspack Alternative                         | Status      |
| ------------------------------ | ------------------------------------------ | ----------- |
| `copy-webpack-plugin`          | `rspack.CopyRspackPlugin`                  | ✅ Built-in |
| `mini-css-extract-plugin`      | `rspack.CssExtractRspackPlugin`            | ✅ Built-in |
| `terser-webpack-plugin`        | `rspack.SwcJsMinimizerRspackPlugin`        | ✅ Built-in |
| `css-minimizer-webpack-plugin` | `rspack.LightningCssMinimizerRspackPlugin` | ✅ Built-in |

#### Community Alternatives

| Webpack Plugin                         | Rspack Alternative             | Package                                 |
| -------------------------------------- | ------------------------------ | --------------------------------------- |
| `fork-ts-checker-webpack-plugin`       | `ts-checker-rspack-plugin`     | `npm i -D ts-checker-rspack-plugin`     |
| `@pmmmwh/react-refresh-webpack-plugin` | `@rspack/plugin-react-refresh` | `npm i -D @rspack/plugin-react-refresh` |
| `eslint-webpack-plugin`                | `eslint-rspack-plugin`         | `npm i -D eslint-rspack-plugin`         |

#### Incompatible Plugins

The following webpack plugins are NOT compatible with Rspack:

- `webpack.optimize.LimitChunkCountPlugin` - Use `optimization.splitChunks` configuration instead
- `webpack-manifest-plugin` - Use `rspack-manifest-plugin` instead
- Git revision plugins - Use alternative approaches

### 3. Asset Module Types

Replace file loaders with asset modules:

- `file-loader` → `type: 'asset/resource'`
- `url-loader` → `type: 'asset/inline'`
- `raw-loader` → `type: 'asset/source'`

### 4. Configuration Differences

#### TypeScript Configuration

**Required:** Add `isolatedModules: true` to your `tsconfig.json`:

```json
{
  "compilerOptions": {
    "isolatedModules": true
  }
}
```

#### React Fast Refresh

```javascript
// Development configuration
const ReactRefreshPlugin = require("@rspack/plugin-react-refresh")

module.exports = {
  plugins: [new ReactRefreshPlugin(), new rspack.HotModuleReplacementPlugin()]
}
```

### 5. Optimization Differences

#### Code Splitting

Rspack's `splitChunks` configuration is similar to webpack but with some differences:

```javascript
optimization: {
  splitChunks: {
    chunks: 'all',
    cacheGroups: {
      vendor: {
        test: /[\\/]node_modules[\\/]/,
        priority: -10,
        reuseExistingChunk: true
      }
    }
  }
}
```

#### Minimization

```javascript
optimization: {
  minimize: true,
  minimizer: [
    new rspack.SwcJsMinimizerRspackPlugin(),
    new rspack.LightningCssMinimizerRspackPlugin()
  ]
}
```

### 6. Development Server

Rspack uses its own dev server with some configuration differences:

```javascript
devServer: {
  // Rspack-specific: Force writing assets to disk
  devMiddleware: {
    writeToDisk: true
  }
}
```

## Migration Steps

### Quick Start: Using the Switch Bundler Task

Shakapacker provides a convenient rake task to switch between webpack and rspack:

```bash
# Switch to rspack with automatic dependency management
bin/rake shakapacker:switch_bundler rspack -- --install-deps

# Fast switching without uninstalling old bundler (keeps both)
bin/rake shakapacker:switch_bundler rspack -- --install-deps --no-uninstall

# Switch to rspack manually (you manage dependencies yourself)
bin/rake shakapacker:switch_bundler rspack

# Switch back to webpack if needed
bin/rake shakapacker:switch_bundler webpack -- --install-deps

# Show help
bin/rake shakapacker:switch_bundler -- --help
```

> **⚠️ Important:** This task must be run with `bin/rake`, not `bin/rails`.

The task will:

- Update `config/shakapacker.yml` to switch the bundler
- Optionally install/uninstall npm dependencies with `--install-deps`
- Use `--no-uninstall` to skip uninstalling the old bundler's packages (faster switching, keeps both bundlers installed)
- Update `javascript_transpiler` to `swc` when switching to rspack (recommended)
- Preserve your config file comments and structure

**Custom Dependencies:** You can customize which dependencies are installed by creating a `.shakapacker-switch-bundler-dependencies.yml` file:

```bash
bundle exec rake shakapacker:switch_bundler --init-config
```

### Manual Migration Steps

If you prefer to migrate manually or need more control:

#### Step 1: Update Dependencies

```bash
# Remove webpack dependencies
npm uninstall webpack webpack-cli webpack-dev-server

# Install Rspack
npm install --save-dev @rspack/core @rspack/cli
```

#### Step 2: Update Configuration Files

1. Create `config/rspack/rspack.config.js` based on your webpack config
2. Update `config/shakapacker.yml`:

```yaml
assets_bundler: "rspack"
```

#### Step 3: Replace Loaders

- Replace `babel-loader` with `builtin:swc-loader`
- Remove `file-loader`, `url-loader`, `raw-loader` - use asset modules
- Update CSS loaders to use Rspack's built-in support

#### Step 4: Update Plugins

- Replace plugins with Rspack alternatives (see table above)
- Remove incompatible plugins
- Add Rspack-specific plugins as needed

#### Step 5: TypeScript Setup

1. Add `isolatedModules: true` to `tsconfig.json`
2. Optional: Add `ts-checker-rspack-plugin` for type checking

#### Step 6: Test Your Build

```bash
# Development build
bin/shakapacker

# Production build
bin/shakapacker --mode production
```

#### Step 7: Review Migration Checklist

- [ ] Install Rspack dependencies
- [ ] Update `config/shakapacker.yml`
- [ ] Create `config/rspack/rspack.config.js`
- [ ] Replace incompatible plugins
- [ ] Update TypeScript config (add `isolatedModules: true`)
- [ ] Convert file loaders to asset modules
- [ ] Test development build
- [ ] Test production build
- [ ] Run test suite
- [ ] Update CI/CD pipelines
- [ ] Deploy to staging
- [ ] Monitor performance improvements

## Build Verification

After completing your migration, verify that everything works correctly:

### Basic Build Verification

```bash
# Clean previous build artifacts
rm -rf public/packs public/packs-test

# Test development build
bin/shakapacker

# Test production build
RAILS_ENV=production bin/shakapacker

# Verify assets were generated
ls -la public/packs/
```

### SSR Build Verification

If your application uses Server-Side Rendering, perform these additional checks:

```bash
# 1. Verify server bundle was created
ls -la public/packs/*-server-bundle.js

# 2. Test SSR rendering in Rails console
bundle exec rails console
# In console:
ReactOnRails::ServerRenderingPool.reset_pool
# Then visit a page that uses SSR and check for errors

# 3. Run full test suite (watch for SSR-related failures)
bundle exec rspec

# 4. Check for CSS extraction issues in SSR
# Look for "Cannot read properties of undefined" errors in tests
# or intermittent test failures related to styling
```

### Common Verification Issues

**Silent SSR failures**: If your SSR pages render without errors but components appear unstyled or with missing data, check:

- Server bundle is being generated correctly
- CSS extraction is disabled for server bundle (see [Common Migration Issues](#common-migration-issues))
- React runtime configuration is compatible with your SSR framework

**Error patterns to watch for**:

- `Cannot read properties of undefined (reading 'className')` - CSS Modules configuration issue
- `Invalid call to renderToString` - React runtime compatibility issue
- `Module not found: Can't resolve './Module.bs.js'` - File extension resolution issue
- Intermittent/flaky tests - CSS extraction leaking into server bundle

### Testing Strategy for SSR

For applications with SSR, follow this verification order:

1. Test client-only pages first (verify basic Rspack build works)
2. Test SSR pages without CSS modules (verify SSR configuration)
3. Test SSR pages with CSS modules (verify CSS extraction + SSR work together)
4. Run full test suite multiple times to catch flaky tests
5. Test in production mode (some issues only appear with minification)

## Configuration Best Practices

### Configuration Organization

**Recommended approach**: Keep webpack and rspack configs in the same directory with conditional logic:

```javascript
// config/webpack/webpack.config.js (works for both bundlers)
const { config } = require("shakapacker")
const bundler =
  config.assets_bundler === "rspack"
    ? require("@rspack/core")
    : require("webpack")

// Use for plugins
clientConfig.plugins.push(
  new bundler.ProvidePlugin({
    /* ... */
  })
)

serverConfig.plugins.unshift(
  new bundler.optimize.LimitChunkCountPlugin({ maxChunks: 1 })
)
```

**Avoid**: Creating separate `config/rspack/` directory unless configs diverge significantly.

**Benefits**:

- Smaller diff when comparing configurations
- Easy to see what's different between bundlers
- Single source of truth for webpack/rspack config
- Easier maintenance and debugging

### CSS Modules Configuration Placement

**Critical**: CSS modules configuration overrides must be inside the config function:

```javascript
// ✅ CORRECT - Inside function (applied fresh each time)
const commonWebpackConfig = () => {
  const baseConfig = generateWebpackConfig()

  baseConfig.module.rules.forEach((rule) => {
    // Override CSS modules here
  })

  return merge({}, baseConfig, commonOptions)
}

// ❌ INCORRECT - Outside function (may not apply consistently)
const baseConfig = generateWebpackConfig()
baseConfig.module.rules.forEach((rule) => {
  // This may not work correctly
})
```

### Handling Breaking Changes

When upgrading to Shakapacker 9 with Rspack:

1. **CSS Modules default exports → named exports**: This is a breaking change. Either:
   - Update your code to use named imports (recommended for new projects)
   - Override the configuration to keep default exports (easier for existing large codebases)

2. **Document your decisions**: Add comments explaining why you chose a particular configuration approach

3. **Create patches for broken dependencies**: If ReScript or other compiled-to-JS dependencies are missing build configs, use `patch-package` and file upstream issues

### Common Pitfalls to Avoid

1. **Don't commit generated files**: Check your `.gitignore` for files that should not be committed (e.g., `i18n/translations.js`)
2. **Update lockfiles**: Always run your package manager after adding dependencies (especially `patch-package`)
3. **Test with frozen lockfile**: Ensure your CI runs with `--frozen-lockfile` or equivalent to catch lockfile issues
4. **Check Node version compatibility**: Verify your Node version meets all dependency requirements
5. **Don't make empty commits**: If CI fails but local passes, investigate the root cause - don't try to "trigger CI re-run" with empty commits

## Common Migration Issues

This section highlights the most critical configuration issues that cause build failures during webpack-to-Rspack migration. These issues are especially important for applications using Server-Side Rendering (SSR), CSS Modules, or non-standard file extensions.

### 1. SWC React Runtime for SSR (CRITICAL for React on Rails)

**Problem**: React on Rails SSR detection expects specific function signatures that may not work with SWC's automatic React runtime.

**Symptoms**:

- Error: `Invalid call to renderToString. Possibly you have a renderFunction...`
- SSR pages fail to render or render without React hydration

**Solution**: Configure SWC to use classic React runtime instead of automatic:

```javascript
// config/swc.config.js
const customConfig = {
  options: {
    jsc: {
      transform: {
        react: {
          runtime: "classic", // Use 'classic' instead of 'automatic' for SSR
          refresh: env.isDevelopment && env.runningWebpackDevServer
        }
      }
    }
  }
}
```

**Why this matters**: The automatic runtime changes how React imports work (`import { jsx as _jsx }` vs `import React`), which breaks React on Rails' SSR function detection logic. This is a silent failure that only manifests at runtime.

**Implementation checklist for SSR users**:

- [ ] Locate your SWC configuration file (typically `config/swc.config.js`)
- [ ] Change `runtime: 'automatic'` to `runtime: 'classic'`
- [ ] Test SSR rendering in development and production modes
- [ ] Verify React hydration works correctly on client side
- [ ] Run full test suite to catch any related issues

### 2. CSS Modules Configuration for Server Bundles (CRITICAL for SSR + CSS Modules)

**Problem**: When configuring server bundles, you must preserve Shakapacker 9's CSS Modules settings (`namedExport: true`) while adding SSR-specific settings. Simply setting `exportOnlyLocals: true` will override the base configuration and break CSS imports.

**Symptoms**:

- Error: `export 'default' (imported as 'css') was not found`
- CSS classes return undefined in SSR
- Client-side CSS works but SSR fails
- Intermittent/flaky test failures

**Solution**: Use spread operator to merge CSS Modules options instead of replacing them:

```javascript
// config/webpack/serverWebpackConfig.js
if (cssLoader && cssLoader.options && cssLoader.options.modules) {
  // ✅ CORRECT - Preserves namedExport and other settings
  cssLoader.options.modules = {
    ...cssLoader.options.modules,
    exportOnlyLocals: true
  }

  // ❌ INCORRECT - Overwrites all settings
  // cssLoader.options.modules.exportOnlyLocals = true
}
```

**Why this matters**: Shakapacker 9 changed the default CSS Modules configuration to use named exports. If you only set `exportOnlyLocals: true` without preserving the base config, you'll lose the `namedExport: true` setting, causing import/export mismatches between client and server bundles.

**Related configuration**: You must also filter out CSS extraction loaders in server bundles:

```javascript
// config/webpack/serverWebpackConfig.js
rule.use = rule.use.filter((item) => {
  let testValue
  if (typeof item === "string") {
    testValue = item
  } else if (typeof item.loader === "string") {
    testValue = item.loader
  }
  // Handle both Webpack and Rspack CSS extract loaders
  return !(
    testValue?.match(/mini-css-extract-plugin/) ||
    testValue?.includes("cssExtractLoader") || // Rspack uses this path
    testValue === "style-loader"
  )
})
```

**Implementation checklist for SSR + CSS Modules users**:

- [ ] Update server bundle config to use spread operator for CSS Modules options
- [ ] Ensure CSS extraction loaders are filtered for both webpack and Rspack paths
- [ ] Test SSR pages with CSS Modules imports
- [ ] Verify CSS classes are defined (not undefined) during SSR
- [ ] Run tests multiple times to catch flaky failures

### 3. ReScript File Resolution (CRITICAL for ReScript users)

**Problem**: Rspack requires explicit configuration to resolve `.bs.js` extensions (ReScript compiled output), while webpack handled this automatically.

**Symptoms**:

- Error: `Module not found: Can't resolve './Module.bs.js'`
- ReScript modules fail to import
- Build fails with missing module errors

**Solution**: Add `.bs.js` to resolve extensions:

```javascript
// config/webpack/webpack.config.js (works for both webpack and rspack)
const commonOptions = {
  resolve: {
    extensions: [".css", ".ts", ".tsx", ".bs.js"] // Add .bs.js for ReScript
  }
}

module.exports = merge({}, baseConfig, commonOptions)
```

**Why this matters**: ReScript compiles `.res` source files to `.bs.js` JavaScript files. If your bundler can't resolve these extensions, all ReScript imports will fail, even though the compiled files exist.

**Additional consideration - Missing compiled files**: Some ReScript npm packages ship only `.res` source files without compiled `.bs.js` files. If you encounter this, use `patch-package` to fix the dependency's `bsconfig.json` (see detailed solution in [Common Issues and Solutions](#issue-rescript-dependencies-missing-compiled-files)).

**Implementation checklist for ReScript users**:

- [ ] Add `.bs.js` to resolve extensions in webpack/rspack config
- [ ] Verify all ReScript modules can be imported
- [ ] Check if any ReScript dependencies are missing compiled files
- [ ] If needed, patch broken dependencies with `patch-package`
- [ ] Test build with all ReScript code paths

### 4. Build Verification Steps (IMPORTANT for all migrations)

**Problem**: The migration documentation lacked practical verification procedures, leaving developers without guidance on testing SSR functionality or identifying configuration errors.

**Solution**: Follow the comprehensive verification steps in the [Build Verification](#build-verification) section above, which includes:

- Basic build verification commands
- SSR-specific testing procedures
- Error pattern identification
- Testing strategy for SSR applications

**Why this matters**: Silent SSR failures and configuration issues often only manifest in specific scenarios (production mode, certain page types, race conditions in tests). Without systematic verification, these issues may slip into production.

**Implementation checklist for all users**:

- [ ] Clean build artifacts before testing
- [ ] Test both development and production builds
- [ ] Verify generated assets in `public/packs/`
- [ ] For SSR: verify server bundle generation
- [ ] For SSR: test rendering in Rails console
- [ ] Run full test suite multiple times
- [ ] Check for error patterns listed in Build Verification

### Configuration Differences: webpack vs Rspack Summary

Quick reference for the key differences that cause migration issues:

| Area                       | Webpack                   | Rspack                              | Migration Action                            |
| -------------------------- | ------------------------- | ----------------------------------- | ------------------------------------------- |
| CSS Extraction Loader Path | `mini-css-extract-plugin` | `cssExtractLoader.js`               | Filter both paths in SSR config             |
| React Runtime (SSR)        | Works with both           | Classic required for React on Rails | Use `runtime: 'classic'`                    |
| ReScript Extensions        | Auto-resolves `.bs.js`    | Requires explicit config            | Add to `resolve.extensions`                 |
| CSS Modules Default        | `namedExport: true` (v9+) | Same                                | Preserve with spread operator in SSR config |

## Common Issues and Solutions

### Issue: CSS Modules Returning Undefined (CRITICAL)

**Error:** `Cannot read properties of undefined (reading 'className')` in SSR or `export 'default' (imported as 'css') was not found`

**Root Cause:** Shakapacker 9 changed the default CSS Modules configuration to use named exports (`namedExport: true`), which is a breaking change from v8's default export behavior.

**Solution:** If you want to keep the v8 default export behavior, override the CSS loader configuration:

```javascript
// config/webpack/commonWebpackConfig.js (or rspack equivalent)
const { generateWebpackConfig, merge } = require("shakapacker")

const commonWebpackConfig = () => {
  const baseWebpackConfig = generateWebpackConfig()

  // Override CSS modules to use default exports for backward compatibility
  baseWebpackConfig.module.rules.forEach((rule) => {
    if (rule.use && Array.isArray(rule.use)) {
      const cssLoader = rule.use.find((loader) => {
        const loaderName = typeof loader === "string" ? loader : loader?.loader
        return loaderName?.includes("css-loader")
      })

      if (cssLoader?.options?.modules) {
        cssLoader.options.modules.namedExport = false
        cssLoader.options.modules.exportLocalsConvention = "camelCase"
      }
    }
  })

  return merge({}, baseWebpackConfig, commonOptions)
}
```

**Important:** This configuration must be inside the function so it applies to fresh config each time.

See [CSS Modules Export Mode](./css-modules-export-mode.md) for detailed migration guidance.

### Issue: Server-Side Rendering CSS Extraction (CRITICAL for SSR)

**Error:** Intermittent failures with `Cannot read properties of undefined (reading 'className')` or flaky tests

**Root Cause:** When configuring server bundles, the code that removes CSS extraction loaders must handle both webpack and Rspack loader paths. Rspack uses `cssExtractLoader.js` instead of `mini-css-extract-plugin`.

**Solution:** Update your server webpack config to filter both loader types:

```javascript
// config/webpack/serverWebpackConfig.js
rule.use = rule.use.filter((item) => {
  let testValue
  if (typeof item === "string") {
    testValue = item
  } else if (typeof item.loader === "string") {
    testValue = item.loader
  }
  // Handle both Webpack and Rspack CSS extract loaders
  return !(
    testValue?.match(/mini-css-extract-plugin/) ||
    testValue?.includes("cssExtractLoader") || // Rspack loader path!
    testValue === "style-loader"
  )
})
```

**Additional SSR Requirement:** When modifying CSS modules options for SSR, use spread operator to preserve common config:

```javascript
if (cssLoader && cssLoader.options && cssLoader.options.modules) {
  // Preserve existing modules config but add exportOnlyLocals for SSR
  cssLoader.options.modules = {
    ...cssLoader.options.modules, // Preserve namedExport and other settings!
    exportOnlyLocals: true
  }
}
```

### Issue: SWC React Runtime with SSR

**Error:** `Invalid call to renderToString. Possibly you have a renderFunction...`

**Root Cause:** React on Rails SSR detection logic expects a specific function signature that may not work with SWC's automatic React runtime.

**Solution:** Use classic React runtime in your SWC configuration:

```javascript
// config/swc.config.js
const customConfig = {
  options: {
    jsc: {
      transform: {
        react: {
          runtime: "classic", // Changed from 'automatic' for SSR compatibility
          refresh: env.isDevelopment && env.runningWebpackDevServer
        }
      }
    }
  }
}
```

### Issue: ReScript Module Resolution

**Error:** `Module not found: Can't resolve './Actions.bs.js'`

**Solution:** Add `.bs.js` to your resolve extensions:

```javascript
const commonOptions = {
  resolve: {
    extensions: [".css", ".ts", ".tsx", ".bs.js"] // Add .bs.js for ReScript
  }
}
```

### Issue: ReScript Dependencies Missing Compiled Files

**Error:** `Module not found: Can't resolve '@some-package/src/Module.bs.js'`

**Root Cause:** Some ReScript packages ship only `.res` source files without compiled `.bs.js` files, or have broken `bsconfig.json` configurations.

**Solution:** Use `patch-package` to fix the dependency:

1. Install patch-package:

```bash
npm install --save-dev patch-package
```

2. Add postinstall script to `package.json`:

```json
{
  "scripts": {
    "postinstall": "patch-package"
  }
}
```

3. Fix the package's `bsconfig.json` (example for a package missing `package-specs`):

```json
{
  "name": "@package/name",
  "sources": ["src"],
  "package-specs": [
    {
      "module": "esmodule",
      "in-source": true
    }
  ],
  "suffix": ".bs.js"
}
```

4. Generate the patch:

```bash
npx patch-package @package/name
```

5. Consider filing an issue with the upstream package maintainer.

### Issue: LimitChunkCountPlugin Error

**Error:** `Cannot read properties of undefined (reading 'tap')`

**Solution:** Remove `webpack.optimize.LimitChunkCountPlugin` and use `splitChunks` configuration instead.

### Issue: Missing Loaders

**Error:** Module parse errors

**Solution:** Check console logs for skipped loaders and install missing dependencies.

### Issue: CSS Extraction

**Error:** CSS not being extracted properly

**Solution:** Use `rspack.CssExtractRspackPlugin` instead of `mini-css-extract-plugin`.

### Issue: TypeScript Errors

**Error:** TypeScript compilation errors

**Solution:** Ensure `isolatedModules: true` is set in `tsconfig.json`.

## Performance Tips

1. **Use Built-in Loaders:** Always prefer Rspack's built-in loaders for better performance
2. **Minimize Plugins:** Use only necessary plugins as each adds overhead
3. **Enable Caching:** Rspack has built-in persistent caching
4. **Use SWC:** The built-in SWC loader is significantly faster than Babel

**Expected Performance Improvements:**

| Build Type       | Webpack | Rspack | Improvement |
| ---------------- | ------- | ------ | ----------- |
| Cold build       | 60s     | 8s     | 7.5x faster |
| Hot reload       | 3s      | 0.5s   | 6x faster   |
| Production build | 120s    | 15s    | 8x faster   |

**Note:** Actual improvements vary based on project size, configuration, and hardware. Rspack's Rust-based architecture provides consistent 5-10x performance gains across most scenarios.

## Debugging Configuration

To compare your webpack and rspack configurations during migration:

```bash
# Export webpack configs before switching
bin/shakapacker-config --doctor

# Switch to rspack
bundle exec rake shakapacker:switch_bundler rspack --install-deps

# Export rspack configs to compare
bin/shakapacker-config --doctor

# Compare the files in shakapacker-config-exports/
diff shakapacker-config-exports/webpack-production-client.yaml \
     shakapacker-config-exports/rspack-production-client.yaml
```

The config export utility creates annotated YAML files that make it easy to:

- Verify plugin replacements are correct
- Compare loader configurations
- Identify missing or different options
- Debug configuration issues

See the [Troubleshooting Guide](./troubleshooting.md#exporting-webpack--rspack-configuration) for more details.

## Resources

- [Rspack Documentation](https://rspack.rs)
- [Rspack Examples](https://github.com/rspack-contrib/rspack-examples)
- [Awesome Rspack](https://github.com/rspack-contrib/awesome-rspack)
- [Rspack Migration Guide](https://rspack.rs/guide/migration/webpack)
- [Real-world Migration Example](https://github.com/shakacode/react-webpack-rails-tutorial/pull/680) - Complete migration from webpack to Rspack with SSR, CSS Modules, and ReScript
