# Common Shakapacker Upgrade Guides

This document provides step-by-step instructions for the most common upgrade scenarios in Shakapacker projects.

**📖 For configuration options, see the [Configuration Guide](./configuration.md)**

## Table of Contents

- [Upgrading Shakapacker](#upgrading-shakapacker)
- [Migrating Package Managers](#migrating-package-managers)
  - [Yarn to npm](#yarn-to-npm)
  - [npm to Yarn](#npm-to-yarn)
  - [Migrating to pnpm](#migrating-to-pnpm)
- [Migrating from Babel to SWC](#migrating-from-babel-to-swc)
- [Migrating from Webpack to Rspack](#migrating-from-webpack-to-rspack)

---

## Upgrading Shakapacker

> **⚠️ Important:** Shakapacker is both a Ruby gem AND an npm package. **You must update BOTH** when upgrading.

Shakapacker consists of two components that must be updated together:

1. **Ruby gem** - provides Rails integration and view helpers
2. **npm package** - provides webpack/rspack configuration and build tools

### Upgrade Steps

#### 1. Update `Gemfile`

```ruby
gem "shakapacker", "9.3.0"  # or the version you want to upgrade to
```

**Pre-release versions:** Ruby gems use dot notation (e.g., `"9.3.0.beta.1"`)

#### 2. Update `package.json`

```json
{
  "dependencies": {
    "shakapacker": "9.3.0"
  }
}
```

**Pre-release versions:** npm uses hyphen notation (e.g., `"9.3.0-beta.1"`)

#### 3. Run bundler and package manager

```bash
bundle update shakapacker
yarn install  # or npm install, pnpm install, bun install
```

#### 4. Test your build

```bash
bin/shakapacker
bin/shakapacker-dev-server
```

### Why Both Must Be Updated

- **Mismatched versions can cause build failures** - The Ruby gem expects specific configuration formats from the npm package
- **Feature compatibility** - New features in the gem require corresponding npm package updates
- **Bug fixes** - Fixes often span both Ruby and JavaScript code

### Version Format Differences

Note that pre-release versions use different formats:

| Component    | Stable Version | Pre-release Version |
| ------------ | -------------- | ------------------- |
| Gemfile      | `"9.3.0"`      | `"9.3.0.beta.1"`    |
| package.json | `"9.3.0"`      | `"9.3.0-beta.1"`    |

### Finding the Latest Version

- **Ruby gem:** Check [RubyGems.org](https://rubygems.org/gems/shakapacker)
- **npm package:** Check [npmjs.com](https://www.npmjs.com/package/shakapacker)
- **Releases:** See [GitHub Releases](https://github.com/shakacode/shakapacker/releases)

### Major Version Upgrades

For major version upgrades, always consult the version-specific upgrade guides for breaking changes and new features:

- [V9 Upgrade Guide](./v9_upgrade.md) - Upgrading from v8 to v9 (includes CSS Modules changes, SWC defaults, and more)
- [V8 Upgrade Guide](./v8_upgrade.md) - Upgrading from v7 to v8
- [V7 Upgrade Guide](./v7_upgrade.md) - Upgrading from v6 to v7
- [V6 Upgrade Guide](./v6_upgrade.md) - Upgrading from v5 to v6

> **💡 Note:** Major version upgrades may include breaking changes. The steps above cover the basic gem/package updates that apply to all versions, but you should always review the version-specific guide for additional migration steps.

---

## Migrating Package Managers

### Yarn to npm

Migrating from Yarn to npm is straightforward as both use similar package management concepts.

#### 1. Remove Yarn lock file

```bash
rm yarn.lock
```

#### 2. Install dependencies with npm

```bash
npm install
```

This will create a new `package-lock.json` file.

#### 3. Update scripts (if necessary)

Review your `package.json` scripts and any deployment scripts that may reference `yarn` commands. Replace them with npm equivalents:

```json
{
  "scripts": {
    "build": "shakapacker",
    "dev": "shakapacker-dev-server"
  }
}
```

#### 4. Update CI/CD pipelines

If you have CI/CD pipelines, update them to use `npm install` instead of `yarn install`.

#### 5. Test your build

```bash
npm run build
```

#### Common npm equivalents

| Yarn Command               | npm Equivalent                     |
| -------------------------- | ---------------------------------- |
| `yarn`                     | `npm install`                      |
| `yarn add <package>`       | `npm install <package>`            |
| `yarn add --dev <package>` | `npm install --save-dev <package>` |
| `yarn remove <package>`    | `npm uninstall <package>`          |
| `yarn run <script>`        | `npm run <script>`                 |

### npm to Yarn

Converting from npm to Yarn is equally straightforward.

#### 1. Remove npm lock file

```bash
rm package-lock.json
```

#### 2. Install Yarn (if not already installed)

Use Corepack (recommended for modern Node.js):

```bash
corepack enable
corepack prepare yarn@stable --activate
```

Alternative - install globally via npm:

```bash
npm install -g yarn
```

#### 3. Install dependencies with Yarn

```bash
yarn install
```

This will create a new `yarn.lock` file.

#### 4. Update scripts

Yarn can run scripts directly without the `run` command:

```bash
# Both work with Yarn
yarn build
yarn run build
```

#### 5. Test your build

```bash
yarn build
```

### Migrating to pnpm

[pnpm](https://pnpm.io/) is a fast, disk space-efficient package manager that's gaining popularity.

#### 1. Install pnpm

Use Corepack (recommended):

```bash
corepack enable
corepack prepare pnpm@latest --activate
```

Alternative - install globally via npm:

```bash
npm install -g pnpm
```

#### 2. Remove existing lock files

```bash
rm yarn.lock package-lock.json
```

#### 3. Install dependencies with pnpm

```bash
pnpm install
```

This creates a `pnpm-lock.yaml` file.

#### 4. Update scripts (if necessary)

pnpm uses the same script syntax as npm/Yarn:

```bash
pnpm run build
pnpm dev
```

#### 5. Configure pnpm workspace (optional)

If you have a monorepo setup, create a `pnpm-workspace.yaml`:

```yaml
packages:
  - "packages/*"
```

#### 6. Test your build

```bash
pnpm run build
```

#### pnpm benefits

- **Faster installs**: Up to 2x faster than npm/Yarn
- **Disk space efficient**: Uses hard links to save disk space
- **Strict**: Better at catching dependency issues

---

## Migrating from Babel to SWC

SWC is a Rust-based JavaScript/TypeScript compiler that's significantly faster than Babel (20-70x on multi-core with optimal setup, 5-7.5x in typical single-threaded scenarios). For complete details, see [JavaScript Transpiler Configuration](./transpiler-migration.md).

### Quick Migration Steps

#### 1. Install SWC dependencies

```bash
# Using Yarn
yarn add --dev @swc/core swc-loader

# Using npm
npm install --save-dev @swc/core swc-loader

# Using pnpm
pnpm add --save-dev @swc/core swc-loader
```

#### 2. Update shakapacker.yml

```yaml
# config/shakapacker.yml
default: &default
  javascript_transpiler: swc
```

#### 3. Run the migration rake task (recommended)

```bash
bundle exec rake shakapacker:migrate_to_swc
```

This will automatically create a `config/swc.config.js` with sensible defaults, including Stimulus compatibility if needed.

#### 4. Create SWC configuration (if not using rake task)

If you're configuring manually, create `config/swc.config.js`:

```javascript
// config/swc.config.js
// This file is merged with Shakapacker's default SWC configuration
// See: https://swc.rs/docs/configuration/compilation

module.exports = {
  options: {
    jsc: {
      // CRITICAL for Stimulus compatibility: Prevents SWC from mangling class names
      keepClassNames: true,
      transform: {
        react: {
          runtime: "automatic"
        }
      }
    }
  }
}
```

**Note:** The `options` wrapper is required for proper merging with Shakapacker's defaults. Using `.swcrc` instead will completely override Shakapacker's settings and may cause build failures.

#### 5. Update React refresh plugin (if using React)

```bash
# For webpack
yarn add --dev @pmmmwh/react-refresh-webpack-plugin

# For rspack
yarn add --dev @rspack/plugin-react-refresh
```

#### 6. Test your build

```bash
bin/shakapacker
```

#### 7. Run your test suite

```bash
# Ensure everything works as expected
bundle exec rspec
```

### Performance Expectations

Typical build time improvements when migrating from Babel to SWC (single-threaded transpilation):

| Project Size           | Babel | SWC | Improvement |
| ---------------------- | ----- | --- | ----------- |
| Small (<100 files)     | 5s    | 1s  | 5x faster   |
| Medium (100-500 files) | 20s   | 3s  | 6.7x faster |
| Large (500+ files)     | 60s   | 8s  | 7.5x faster |

**Note:** With multi-core optimization and ideal conditions, SWC can achieve 20-70x improvements over Babel.

### Common Issues

#### Issue: Decorators not working

Add decorator support to `config/swc.config.js`:

```javascript
module.exports = {
  options: {
    jsc: {
      parser: {
        decorators: true,
        decoratorsBeforeExport: true
      }
    }
  }
}
```

#### Issue: Stimulus controllers not working

Ensure `keepClassNames: true` is set in `config/swc.config.js`.

### Rollback

If you need to revert:

```yaml
# config/shakapacker.yml
default: &default
  javascript_transpiler: babel
```

Then rebuild:

```bash
bin/shakapacker clobber
bin/shakapacker compile
```

---

## Migrating from Webpack to Rspack

[Rspack](https://rspack.rs/) is a high-performance bundler written in Rust, offering 5-10x faster build times than webpack with excellent webpack compatibility. For complete details, see [Rspack Migration Guide](./rspack_migration_guide.md).

### Quick Migration Steps

#### 1. Use the switch bundler rake task (recommended)

Shakapacker provides a convenient rake task to automate the migration:

```bash
# Switch to rspack with automatic dependency management (note the -- separator)
bin/rake shakapacker:switch_bundler rspack -- --install-deps

# Fast switching without uninstalling webpack (keeps both)
bin/rake shakapacker:switch_bundler rspack -- --install-deps --no-uninstall
```

> **⚠️ Important:** This task must be run with `bin/rake`, not `bin/rails`.

The task will:

- Update `config/shakapacker.yml` to use rspack
- Install rspack dependencies (with `--install-deps`)
- Optionally uninstall webpack dependencies (default) or keep both (with `--no-uninstall`)
- Update `javascript_transpiler` to `swc` (recommended for rspack)
- Preserve your config file comments and structure

**Custom dependencies:** You can customize which dependencies are installed:

```bash
bin/rake shakapacker:switch_bundler -- --init-config
```

#### 2. Manual installation (alternative)

If you prefer manual control:

```bash
# Install Rspack dependencies
# Using Yarn
yarn add --dev @rspack/core @rspack/cli

# Using npm
npm install --save-dev @rspack/core @rspack/cli

# Using pnpm
pnpm add --save-dev @rspack/core @rspack/cli

# Remove webpack dependencies (optional)
yarn remove webpack webpack-cli webpack-dev-server
# Or: npm uninstall webpack webpack-cli webpack-dev-server
# Or: pnpm remove webpack webpack-cli webpack-dev-server
```

Then update `config/shakapacker.yml`:

```yaml
default: &default
  assets_bundler: rspack
  javascript_transpiler: swc # Rspack defaults to SWC for best performance
```

#### 3. Create Rspack configuration

Create `config/rspack/rspack.config.js` based on your webpack config. Start with a minimal configuration:

```javascript
// config/rspack/rspack.config.js
const { rspack } = require("@rspack/core")
const { merge } = require("webpack-merge")
const baseConfig = require("../shakapacker")

module.exports = merge(baseConfig, {
  module: {
    rules: [
      {
        test: /\.(js|jsx|ts|tsx)$/,
        loader: "builtin:swc-loader",
        options: {
          jsc: {
            parser: {
              syntax: "ecmascript",
              jsx: true
            },
            transform: {
              react: {
                runtime: "automatic"
              }
            }
          }
        }
      }
    ]
  }
})
```

#### 4. Update TypeScript configuration

Add `isolatedModules: true` to your `tsconfig.json`:

```json
{
  "compilerOptions": {
    "isolatedModules": true
  }
}
```

#### 5. Replace incompatible plugins

Some webpack plugins need Rspack equivalents:

| Webpack Plugin                         | Rspack Alternative                  |
| -------------------------------------- | ----------------------------------- |
| `mini-css-extract-plugin`              | `rspack.CssExtractRspackPlugin`     |
| `copy-webpack-plugin`                  | `rspack.CopyRspackPlugin`           |
| `terser-webpack-plugin`                | `rspack.SwcJsMinimizerRspackPlugin` |
| `fork-ts-checker-webpack-plugin`       | `ts-checker-rspack-plugin`          |
| `@pmmmwh/react-refresh-webpack-plugin` | `@rspack/plugin-react-refresh`      |

Example plugin update:

```javascript
// Before (webpack)
const MiniCssExtractPlugin = require("mini-css-extract-plugin")
plugins: [new MiniCssExtractPlugin()]

// After (rspack)
const { rspack } = require("@rspack/core")
plugins: [new rspack.CssExtractRspackPlugin()]
```

#### 6. Update asset handling

Replace file loaders with asset modules:

```javascript
// Before (webpack with file-loader)
{
  test: /\.(png|jpg|gif)$/,
  use: ['file-loader']
}

// After (rspack with asset modules)
{
  test: /\.(png|jpg|gif)$/,
  type: 'asset/resource'
}
```

#### 7. Install React refresh plugin (if using React)

```bash
yarn add --dev @rspack/plugin-react-refresh
```

Update your config:

```javascript
const ReactRefreshPlugin = require("@rspack/plugin-react-refresh")
const { rspack } = require("@rspack/core")

module.exports = {
  plugins: [new ReactRefreshPlugin(), new rspack.HotModuleReplacementPlugin()]
}
```

#### 8. Test your build

```bash
# Development build
bin/shakapacker

# Production build
bin/shakapacker --mode production
```

#### 9. Update development workflow

Rspack's dev server works the same way:

```bash
bin/shakapacker-dev-server
```

### Migration Checklist

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

### Performance Benefits

Typical build time improvements when migrating from webpack to Rspack:

| Build Type       | Webpack | Rspack | Improvement |
| ---------------- | ------- | ------ | ----------- |
| Cold build       | 60s     | 8s     | 7.5x faster |
| Hot reload       | 3s      | 0.5s   | 6x faster   |
| Production build | 120s    | 15s    | 8x faster   |

**Note:** Actual improvements vary based on project size, configuration, and hardware. Rspack's Rust-based architecture provides consistent 5-10x performance gains across most scenarios.

### Common Issues

#### Issue: LimitChunkCountPlugin Error

```
Error: Cannot read properties of undefined (reading 'tap')
```

**Solution:** Remove `webpack.optimize.LimitChunkCountPlugin` and use `splitChunks` configuration instead.

#### Issue: CSS not extracting

**Solution:** Use `rspack.CssExtractRspackPlugin` instead of `mini-css-extract-plugin`.

#### Issue: TypeScript errors

**Solution:** Ensure `isolatedModules: true` is set in `tsconfig.json`.

### Rollback

If you need to revert to webpack:

```yaml
# config/shakapacker.yml
default: &default
  assets_bundler: webpack
  javascript_transpiler: babel # or swc
```

Then rebuild:

```bash
bin/shakapacker clobber
bin/shakapacker compile
```

---

## Combined Migration Path

For maximum performance improvements, you can combine multiple migrations:

### Recommended: Webpack + Babel → Rspack + SWC

This combination provides the best performance improvement (up to 50-70x faster builds):

1. **First, migrate to SWC** (while still on webpack)
   - Follow [Migrating from Babel to SWC](#migrating-from-babel-to-swc)
   - Test thoroughly
   - This is a smaller change to validate first

2. **Then, migrate to Rspack**
   - Follow [Migrating from Webpack to Rspack](#migrating-from-webpack-to-rspack)
   - Rspack will use your existing SWC configuration
   - Test thoroughly

### Alternative: Webpack + Babel → Rspack + SWC (all at once)

If you're confident, you can do both migrations simultaneously:

```yaml
# config/shakapacker.yml
default: &default
  assets_bundler: rspack
  javascript_transpiler: swc
```

Follow both migration guides, installing all required dependencies at once.

---

## Getting Help

- [Shakapacker Documentation](../README.md)
- [Shakapacker Slack Channel](https://reactrails.slack.com/join/shared_invite/enQtNjY3NTczMjczNzYxLTlmYjdiZmY3MTVlMzU2YWE0OWM0MzNiZDI0MzdkZGFiZTFkYTFkOGVjODBmOWEyYWQ3MzA2NGE1YWJjNmVlMGE)
- [GitHub Issues](https://github.com/shakacode/shakapacker/issues)
- [SWC Documentation](https://swc.rs/)
- [Rspack Documentation](https://rspack.rs/)
- [pnpm Documentation](https://pnpm.io/)
