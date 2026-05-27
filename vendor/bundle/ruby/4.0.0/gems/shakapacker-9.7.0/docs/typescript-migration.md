# TypeScript Migration Guide for Shakapacker

This guide helps you adopt TypeScript types in your Shakapacker configuration files for better type safety and IDE support.

## Table of Contents

- [Benefits](#benefits)
- [Quick Start](#quick-start)
- [Migration Steps](#migration-steps)
- [Common Patterns](#common-patterns)
- [Troubleshooting](#troubleshooting)

## Benefits

Using TypeScript with Shakapacker provides:

- **Type Safety**: Catch configuration errors at compile time
- **IDE Support**: Get autocompletion and inline documentation
- **Better Refactoring**: Safely rename and restructure configurations
- **Self-documenting**: Types serve as inline documentation

## Quick Start

### 1. Install TypeScript Dependencies

```bash
yarn add --dev typescript @types/node @types/webpack
# or
npm install --save-dev typescript @types/node @types/webpack
```

### 2. Create a tsconfig.json

```json
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "commonjs",
    "lib": ["ES2020"],
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true,
    "moduleResolution": "node",
    "allowJs": true,
    "checkJs": false,
    "noEmit": true
  },
  "include": ["config/webpack/**/*"],
  "exclude": ["node_modules"]
}
```

### 3. Convert Your Webpack Config to TypeScript

Rename `config/webpack/webpack.config.js` to `config/webpack/webpack.config.ts`:

```typescript
// config/webpack/webpack.config.ts
import { generateWebpackConfig, merge } from "shakapacker"
import type { WebpackConfigWithDevServer } from "shakapacker/types"
import type { Configuration } from "webpack"

const customConfig: Configuration = {
  resolve: {
    extensions: [".css", ".ts", ".tsx"]
  }
}

const config: Configuration = generateWebpackConfig(customConfig)

export default config
```

## Migration Steps

### Step 1: Import Types

Start by importing the types you need:

```typescript
import type {
  Config,
  WebpackConfigWithDevServer,
  RspackConfigWithDevServer,
  CompressionPluginOptions
} from "shakapacker/types"
```

### Step 2: Type Your Configuration Objects

Add type annotations to your configuration objects:

```typescript
// Before (JavaScript)
const customConfig = {
  resolve: {
    extensions: [".css", ".ts", ".tsx"]
  }
}

// After (TypeScript)
import type { Configuration } from "webpack"

const customConfig: Configuration = {
  resolve: {
    extensions: [".css", ".ts", ".tsx"]
  }
}
```

### Step 3: Type Your Custom Functions

If you have custom configuration functions, add type annotations:

```typescript
// Before (JavaScript)
function modifyConfig(config) {
  config.plugins.push(new MyPlugin())
  return config
}

// After (TypeScript)
import type { Configuration } from "webpack"
import type { WebpackPluginInstance } from "shakapacker/types"

function modifyConfig(config: Configuration): Configuration {
  const plugins = config.plugins as WebpackPluginInstance[]
  plugins.push(new MyPlugin())
  return config
}
```

### Step 4: Handle Environment-Specific Configurations

```typescript
// config/webpack/development.ts
import { generateWebpackConfig } from "shakapacker"
import type { WebpackConfigWithDevServer } from "shakapacker/types"

const developmentConfig: WebpackConfigWithDevServer = generateWebpackConfig({
  devtool: "eval-cheap-module-source-map",
  devServer: {
    hot: true,
    port: 3035
  }
})

export default developmentConfig
```

## Common Patterns

### Pattern 1: Custom Loaders

```typescript
import type { RuleSetRule } from "webpack"

const customLoader: RuleSetRule = {
  test: /\.svg$/,
  use: ["@svgr/webpack"]
}

const config: Configuration = generateWebpackConfig({
  module: {
    rules: [customLoader]
  }
})
```

### Pattern 2: Plugin Configuration

```typescript
import CompressionPlugin from "compression-webpack-plugin"
import type { CompressionPluginOptions } from "shakapacker/types"

const compressionOptions: CompressionPluginOptions = {
  filename: "[path][base].gz",
  algorithm: "gzip",
  test: /\.(js|css|html|json|ico|svg|eot|otf|ttf)$/
}

const config: Configuration = generateWebpackConfig({
  plugins: [new CompressionPlugin(compressionOptions)]
})
```

### Pattern 3: Conditional Configuration

```typescript
import type { Configuration } from "webpack"
import { env } from "shakapacker"

const config: Configuration = generateWebpackConfig()

if (env.isProduction) {
  // TypeScript knows config.optimization exists
  config.optimization = {
    ...config.optimization,
    minimize: true,
    sideEffects: false
  }
}

export default config
```

### Pattern 4: Rspack Configuration

```typescript
// config/rspack/rspack.config.ts
import type { RspackConfigWithDevServer } from "shakapacker/types"
import { generateWebpackConfig } from "shakapacker"

const rspackConfig: RspackConfigWithDevServer = generateWebpackConfig({
  mode: "development",
  devServer: {
    hot: true,
    port: 3036
  }
})

export default rspackConfig
```

## Type-checking Your Configuration

Add a script to your package.json to type-check your configuration:

```json
{
  "scripts": {
    "type-check": "tsc --noEmit",
    "webpack:type-check": "tsc --noEmit config/webpack/*.ts"
  }
}
```

Run type checking:

```bash
yarn type-check
# or
npm run type-check
```

## Available Types Reference

### Core Types

- `Config` - Shakapacker configuration from shakapacker.yml
- `Env` - Environment variables and helpers
- `DevServerConfig` - Development server configuration

### Webpack/Rspack Types

- `WebpackConfigWithDevServer` - Webpack configuration with dev server
- `RspackConfigWithDevServer` - Rspack configuration with dev server
- `WebpackPluginInstance` - Webpack plugin instance type
- `RspackPluginInstance` - Rspack plugin instance type
- `RspackPlugin` - **⚠️ Deprecated:** Use `RspackPluginInstance` instead

### Helper Types

- `CompressionPluginOptions` - Compression plugin configuration
- `ReactRefreshWebpackPlugin` - React refresh for Webpack
- `ReactRefreshRspackPlugin` - React refresh for Rspack

## Troubleshooting

### Issue: "Cannot find module 'shakapacker/types'"

**Solution**: Make sure you're using Shakapacker v9.0.0 or later:

```bash
yarn upgrade shakapacker
```

### Issue: Type errors with plugins

**Solution**: Cast plugin arrays when needed:

```typescript
const plugins = (config.plugins || []) as WebpackPluginInstance[]
plugins.push(new MyPlugin())
```

### Issue: Missing types for custom loaders

**Solution**: Install type definitions or declare them:

```typescript
// If types aren't available, declare them
declare module "my-custom-loader" {
  const loader: any
  export default loader
}
```

### Issue: Conflicting types between webpack versions

**Solution**: Ensure your webpack types match your webpack version:

```bash
yarn add --dev @types/webpack@^5
```

## Gradual Migration

You don't need to convert everything at once. Start with:

1. Convert your main webpack.config.js to TypeScript
2. Add types to the most complex configurations
3. Gradually type other configuration files
4. Add type checking to your CI pipeline

## Example: Full Configuration

Here's a complete example of a typed webpack configuration:

```typescript
// config/webpack/webpack.config.ts
import {
  generateWebpackConfig,
  merge,
  config as shakapackerConfig
} from "shakapacker"
import type { Configuration } from "webpack"
import type { WebpackConfigWithDevServer } from "shakapacker/types"
import CompressionPlugin from "compression-webpack-plugin"
import { resolve } from "path"

// Type-safe custom configuration
const customConfig: Configuration = {
  resolve: {
    extensions: [".css", ".ts", ".tsx"],
    alias: {
      "@": resolve(__dirname, "../../app/javascript"),
      components: resolve(__dirname, "../../app/javascript/components"),
      utils: resolve(__dirname, "../../app/javascript/utils")
    }
  },
  module: {
    rules: [
      {
        test: /\.svg$/,
        use: ["@svgr/webpack"],
        issuer: /\.(tsx?|jsx?)$/
      }
    ]
  }
}

// Generate the final configuration
const webpackConfig: Configuration = generateWebpackConfig(customConfig)

// Type-safe modifications based on environment
if (shakapackerConfig.env === "production") {
  const plugins = (webpackConfig.plugins || []) as WebpackPluginInstance[]

  plugins.push(
    new CompressionPlugin({
      filename: "[path][base].br",
      algorithm: "brotliCompress",
      test: /\.(js|css|html|json|ico|svg|eot|otf|ttf)$/
    })
  )
}

export default webpackConfig
```

## Next Steps

After migrating to TypeScript:

1. **Enable strict checks**: Gradually enable stricter TypeScript options
2. **Add custom types**: Create type definitions for your application-specific configurations
3. **Share types**: Export reusable configuration types for your team
4. **Document with types**: Use JSDoc comments with your types for better documentation

## Resources

- [TypeScript Handbook](https://www.typescriptlang.org/docs/handbook/intro.html)
- [Webpack TypeScript Configuration](https://webpack.js.org/configuration/configuration-languages/#typescript)
- [Shakapacker Types Documentation](./types/README.md)
- [Migration Examples](https://github.com/shakacode/shakapacker/tree/main/examples/typescript-config)
