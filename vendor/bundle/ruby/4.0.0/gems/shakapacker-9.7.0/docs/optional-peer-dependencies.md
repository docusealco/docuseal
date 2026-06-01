# Optional Peer Dependencies in Shakapacker

## Overview

As of Shakapacker v9, all peer dependencies are marked as optional via `peerDependenciesMeta`. This design provides maximum flexibility while maintaining clear version constraints.

## Key Benefits

1. **No Installation Warnings** - Package managers (npm, yarn, pnpm) won't warn about missing peer dependencies
2. **Install Only What You Need** - Users only install packages for their chosen configuration
3. **Clear Version Constraints** - When packages are installed, version compatibility is still enforced
4. **Smaller Node Modules** - Reduced disk usage by not installing unnecessary packages

## Implementation Details

### Package.json Structure

```json
{
  "dependencies": {
    "js-yaml": "^4.1.0",
    "path-complete-extname": "^1.0.0",
    "webpack-merge": "^5.8.0" // Direct dependency - always available
  },
  "peerDependencies": {
    "webpack": "^5.76.0",
    "@rspack/core": "^1.0.0"
    // ... all build tools
  },
  "peerDependenciesMeta": {
    "webpack": { "optional": true },
    "@rspack/core": { "optional": true }
    // ... all marked as optional
  }
}
```

### TypeScript Type-Only Imports

To prevent runtime errors when optional packages aren't installed, all webpack imports use type-only syntax:

```typescript
// @ts-ignore: webpack is an optional peer dependency (using type-only import)
import type { Configuration } from "webpack"
```

Type-only imports are erased during compilation and don't trigger module resolution at runtime.

## Configuration Examples

### Webpack + Babel (Traditional)

```json
{
  "dependencies": {
    "shakapacker": "^9.0.0",
    "webpack": "^5.76.0",
    "webpack-cli": "^5.0.0",
    "babel-loader": "^8.2.4",
    "@babel/core": "^7.17.9",
    "@babel/preset-env": "^7.16.11"
  }
}
```

### Webpack + SWC (20x Faster)

```json
{
  "dependencies": {
    "shakapacker": "^9.0.0",
    "webpack": "^5.76.0",
    "webpack-cli": "^5.0.0",
    "@swc/core": "^1.3.0",
    "swc-loader": "^0.2.0"
  }
}
```

### Rspack + SWC (10x Faster Bundling)

```json
{
  "dependencies": {
    "shakapacker": "^9.0.0",
    "@rspack/core": "^1.0.0",
    "@rspack/cli": "^1.0.0",
    "rspack-manifest-plugin": "^5.0.0"
  }
}
```

## Migration Guide

### From v8 to v9

If upgrading from Shakapacker v8:

1. **No action required** - Your existing dependencies will continue to work
2. **No more warnings** - Peer dependency warnings will disappear after upgrading
3. **Option to optimize** - You can now remove unused dependencies (e.g., remove Babel if using SWC)

### New Installations

The installer (`bundle exec rake shakapacker:install`) only adds packages needed for your configuration:

- Detects your preferred bundler (webpack/rspack)
- Installs appropriate JavaScript transpiler (babel/swc/esbuild)
- Adds only required dependencies

## Version Constraints

Version ranges are carefully chosen for compatibility:

- **Broader ranges for peer deps** - Allows flexibility (e.g., `^5.76.0` for webpack)
- **Specific versions in devDeps** - Ensures testing against known versions
- **Forward compatibility** - Ranges include future minor versions (e.g., `^5.0.0 || ^6.0.0`)

## Testing

### Installation Tests

Test that no warnings appear during installation:

```bash
# Test script available at test/peer-dependencies.sh
./test/peer-dependencies.sh
```

### Runtime Tests

Verify Shakapacker loads without optional dependencies:

```javascript
// This works even without webpack installed (when using rspack)
const shakapacker = require("shakapacker")
```

### CI Integration

The test suite includes:

- `spec/shakapacker/optional_dependencies_spec.rb` - Package.json structure validation
- `spec/shakapacker/doctor_optional_peer_spec.rb` - Doctor command validation
- `test/peer-dependencies.sh` - Installation warning tests

## Troubleshooting

### Still seeing peer dependency warnings?

1. Ensure you're using Shakapacker v9.0.0 or later
2. Clear your package manager cache:
   - npm: `npm cache clean --force`
   - yarn: `yarn cache clean`
   - pnpm: `pnpm store prune`
3. Reinstall dependencies

### Module not found errors?

1. Check you've installed required dependencies for your configuration
2. Refer to the configuration examples above
3. Run `bundle exec rake shakapacker:doctor` for diagnostics

### TypeScript errors?

The `@ts-ignore` comments are intentional and necessary for optional dependencies.
They prevent TypeScript errors when optional packages aren't installed.

## Contributing

When adding new dependencies:

1. Add to `peerDependencies` with appropriate version range
2. Mark as optional in `peerDependenciesMeta`
3. Use type-only imports in TypeScript: `import type { ... }`
4. Test with all package managers (npm, yarn, pnpm)
5. Update this documentation if needed

## Design Rationale

This approach balances several concerns:

1. **User Experience** - No confusing warnings during installation
2. **Flexibility** - Support multiple configurations without forcing unnecessary installs
3. **Compatibility** - Maintain version constraints for safety
4. **Performance** - Reduce installation time and disk usage
5. **Type Safety** - TypeScript support without runtime dependencies

## Future Improvements

Potential enhancements for future versions:

1. **Conditional exports** - Use package.json exports field for better tree-shaking
2. **Dynamic imports** - Load bundler-specific code only when needed
3. **Doctor updates** - Enhance doctor command to better understand optional dependencies
4. **Automated testing** - Add CI jobs testing each configuration combination

## References

- [npm: peerDependenciesMeta](https://docs.npmjs.com/cli/v8/configuring-npm/package-json#peerdependenciesmeta)
- [TypeScript: Type-Only Imports](https://www.typescriptlang.org/docs/handbook/modules.html#type-only-imports-and-exports)
- [Shakapacker Issue #565](https://github.com/shakacode/shakapacker/issues/565)
- [Pull Request #615](https://github.com/shakacode/shakapacker/pull/615)
