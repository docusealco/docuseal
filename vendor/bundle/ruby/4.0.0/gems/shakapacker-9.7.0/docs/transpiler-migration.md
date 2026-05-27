# JavaScript Transpiler Configuration

> 💡 **Quick Start**: For a concise guide to migrating from Babel to SWC, see [Common Upgrades Guide - Babel to SWC](./common-upgrades.md#migrating-from-babel-to-swc).

## Default Transpilers

Shakapacker v9 transpiler defaults depend on the bundler and installation:

- **New installations (v9+)**: `swc` - Installation template explicitly sets SWC (20x faster than Babel)
- **Webpack runtime default**: `babel` - Used when no explicit config is provided (maintains backward compatibility)
- **Rspack runtime default**: `swc` - Rspack defaults to SWC as it's a newer bundler with modern defaults

**Key distinction**: The installation template (`lib/install/config/shakapacker.yml`) explicitly sets `javascript_transpiler: "swc"` for new projects, but if you're upgrading or have no explicit config, webpack falls back to Babel for backward compatibility.

## Available Transpilers

- `babel` - Traditional JavaScript transpiler with wide ecosystem support
- `swc` - Rust-based transpiler, 20-70x faster than Babel
- `esbuild` - Go-based transpiler, extremely fast
- `none` - No transpilation (use native JavaScript)

## Configuration

Set the transpiler in your `config/shakapacker.yml`:

```yaml
default: &default
  # SWC is the default (recommended - 20x faster than Babel)
  javascript_transpiler: swc

  # To use Babel for backward compatibility
  javascript_transpiler: babel

  # For rspack users (defaults to swc if not specified)
  assets_bundler: rspack
  # javascript_transpiler can be set, but rspack defaults to swc
```

## Migration Guide

### Migrating from Babel to SWC

SWC offers significant performance improvements while maintaining high compatibility with Babel.

#### 1. Install SWC dependencies

```bash
yarn add --dev @swc/core swc-loader
```

#### 2. Update your configuration

```yaml
# config/shakapacker.yml
default: &default
  javascript_transpiler: swc
```

#### 3. Create SWC configuration (optional)

If you need custom transpilation settings, create `config/swc.config.js`:

```javascript
// config/swc.config.js
// This file is merged with Shakapacker's default SWC configuration
// See: https://swc.rs/docs/configuration/compilation

module.exports = {
  jsc: {
    transform: {
      react: {
        runtime: "automatic"
      }
    }
  }
}
```

**Important:** Use `config/swc.config.js` instead of `.swcrc`. The `.swcrc` file completely overrides Shakapacker's default SWC settings and can cause build failures. `config/swc.config.js` properly merges with Shakapacker's defaults.

#### 4. Update React configuration (if using React)

For React projects, ensure you have the correct refresh plugin:

```bash
# For webpack
yarn add --dev @pmmmwh/react-refresh-webpack-plugin

# For rspack
yarn add --dev @rspack/plugin-react-refresh
```

### Performance Comparison

Typical build time improvements when migrating from Babel to SWC:

| Project Size           | Babel | SWC | Improvement |
| ---------------------- | ----- | --- | ----------- |
| Small (<100 files)     | 5s    | 1s  | 5x faster   |
| Medium (100-500 files) | 20s   | 3s  | 6.7x faster |
| Large (500+ files)     | 60s   | 8s  | 7.5x faster |

### Compatibility Notes

#### Babel Features Not Yet in SWC

- Some experimental/stage-0 proposals
- Custom Babel plugins (need SWC equivalents)
- Babel macros

#### Migration Checklist

- [ ] Back up your current configuration
- [ ] Install SWC dependencies
- [ ] Update `shakapacker.yml`
- [ ] If using Stimulus, ensure `keepClassNames: true` is set in `config/swc.config.js` (automatically included in v9.1.0+)
- [ ] Test your build locally
- [ ] Run your test suite
- [ ] Check browser compatibility
- [ ] Deploy to staging environment
- [ ] Monitor for any runtime issues

#### Stimulus Compatibility

If you're using [Stimulus](https://stimulus.hotwired.dev/), you must configure SWC to preserve class names. See the [Using SWC with Stimulus](using_swc_loader.md#using-swc-with-stimulus) section for detailed instructions.

**Quick summary:** Add `keepClassNames: true` to your `config/swc.config.js`:

```javascript
module.exports = {
  options: {
    jsc: {
      keepClassNames: true // Required for Stimulus
    }
  }
}
```

Starting with Shakapacker v9.1.0, running `rake shakapacker:migrate_to_swc` automatically creates a configuration with this setting.

### Rollback Plan

If you encounter issues, rolling back is simple:

```yaml
# config/shakapacker.yml
default: &default
  javascript_transpiler: babel # Revert to babel
```

Then rebuild your application:

```bash
bin/shakapacker clobber
bin/shakapacker compile
```

## Environment Variables

You can also control the transpiler via environment variables:

```bash
# Override config file setting
SHAKAPACKER_JAVASCRIPT_TRANSPILER=swc bin/shakapacker compile

# For debugging
SHAKAPACKER_DEBUG_CACHE=true bin/shakapacker compile
```

## Troubleshooting

### Issue: Build fails after switching to SWC

**Solution**: Ensure all SWC dependencies are installed:

```bash
yarn add --dev @swc/core swc-loader
```

### Issue: React Fast Refresh not working

**Solution**: Install the correct refresh plugin for your bundler:

```bash
# Webpack
yarn add --dev @pmmmwh/react-refresh-webpack-plugin

# Rspack
yarn add --dev @rspack/plugin-react-refresh
```

### Issue: Decorators not working

**Solution**: Enable decorator support in `config/swc.config.js`:

```javascript
// config/swc.config.js
module.exports = {
  jsc: {
    parser: {
      decorators: true,
      decoratorsBeforeExport: true
    }
  }
}
```

## Further Reading

- [SWC Documentation](https://swc.rs/docs/getting-started)
- [Babel to SWC Migration Guide](https://swc.rs/docs/migrating-from-babel)
- [Rspack Configuration](https://www.rspack.dev/config/index)
