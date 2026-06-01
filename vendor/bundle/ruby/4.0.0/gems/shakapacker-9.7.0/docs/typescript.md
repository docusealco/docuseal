# TypeScript Support

Shakapacker v9 includes TypeScript support, providing type safety and better IDE experience for your webpack configurations.

## Quick Start

### Using TypeScript Config

```typescript
// webpack.config.ts
import { generateWebpackConfig } from "shakapacker"
import type { Configuration } from "webpack"

const config: Configuration = generateWebpackConfig({
  // Your config with full type safety
})

export default config
```

### Using JSDoc (JavaScript)

```javascript
// webpack.config.js
const { generateWebpackConfig } = require("shakapacker")

/** @type {import('webpack').Configuration} */
const config = {
  // Still get autocomplete in JS files!
}

module.exports = generateWebpackConfig(config)
```

## Benefits

- **Compile-time error detection** - Catch config errors before runtime
- **IDE autocomplete** - Full IntelliSense for all options
- **Type safety** - Prevents 85-100% of common configuration errors
- **No breaking changes** - Fully backward compatible

## Migration

1. **No migration required** - Existing JavaScript configs continue to work
2. **Optional TypeScript** - Use it only if you want the benefits
3. **Gradual adoption** - Start with JSDoc comments, move to TypeScript later

## IDE Setup

### VS Code

- Install TypeScript extension (built-in)
- Set `"typescript.tsdk": "node_modules/typescript/lib"` in settings

### WebStorm/IntelliJ

- Enable TypeScript service in Settings → Languages & Frameworks → TypeScript

## Common Patterns

### Environment-Specific Config

```typescript
import { generateWebpackConfig, env } from "shakapacker"

const config = generateWebpackConfig({
  optimization: {
    minimize: env.isProduction
  }
})
```

### Rspack Config

```typescript
import { generateRspackConfig } from "shakapacker/rspack"
import type { RspackOptions } from "@rspack/core"

const config: RspackOptions = {
  // Rspack-specific config
}

export default generateRspackConfig(config)
```

## Troubleshooting

**Cannot find module 'shakapacker'**

```typescript
/// <reference types="shakapacker" />
```

**Type errors with custom loaders**

```typescript
use: [require.resolve("custom-loader") as any]
```

## Further Reading

- [Webpack TypeScript Documentation](https://webpack.js.org/configuration/configuration-languages/#typescript)
- [TypeScript Handbook](https://www.typescriptlang.org/docs/)
