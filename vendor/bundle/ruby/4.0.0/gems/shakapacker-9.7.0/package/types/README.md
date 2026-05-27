# Shakapacker TypeScript Types

This directory exports all TypeScript types used in Shakapacker for easier consumer imports.

## Usage

Instead of importing types from deep paths:

```typescript
// ❌ Old way - importing from multiple deep paths
import type { Config } from "shakapacker/package/types"
import type { WebpackConfigWithDevServer } from "shakapacker/package/environments/types"
```

You can now import all types from a single location:

```typescript
// ✅ New way - single import path
import type {
  Config,
  WebpackConfigWithDevServer,
  RspackConfigWithDevServer
} from "shakapacker/types"
```

## Available Types

### Core Configuration Types

- `Config` - Main Shakapacker configuration interface
- `YamlConfig` - YAML configuration structure
- `LegacyConfig` - Legacy configuration with deprecated options
- `Env` - Environment variables interface
- `DevServerConfig` - Development server configuration

### Loader Types

- `ShakapackerLoader` - Loader interface
- `ShakapackerLoaderOptions` - Loader options interface
- `LoaderResolver` - Function type for resolving loaders
- `LoaderConfig` - Loader configuration interface

### Webpack/Rspack Types

- `WebpackConfigWithDevServer` - Webpack config with dev server
- `RspackConfigWithDevServer` - Rspack config with dev server
- `RspackPluginInstance` - Rspack plugin instance type
- `RspackPlugin` - **⚠️ Deprecated:** Use `RspackPluginInstance` instead
- `RspackDevServerConfig` - Rspack dev server configuration
- `CompressionPluginOptions` - Options for compression plugin
- `CompressionPluginConstructor` - Constructor type for compression plugin
- `ReactRefreshWebpackPlugin` - React refresh plugin for Webpack
- `ReactRefreshRspackPlugin` - React refresh plugin for Rspack

### Webpack-Specific Types

- `ShakapackerWebpackConfig` - Extended Webpack configuration
- `ShakapackerRule` - Extended Webpack rule
- `LoaderType` - String or loader object type
- `LoaderUtils` - Loader utility functions

### Re-exported Types

- `WebpackConfiguration` - From 'webpack'
- `WebpackPluginInstance` - From 'webpack'
- `RuleSetRule` - From 'webpack'
- `NodeJSError` - Node.js error exception type

## Example Usage

```typescript
import type { Config, WebpackConfigWithDevServer } from "shakapacker/types"

const config: Config = {
  source_path: "app/javascript",
  source_entry_path: "packs",
  public_root_path: "public",
  public_output_path: "packs"
  // ... other config
}

const webpackConfig: WebpackConfigWithDevServer = {
  mode: "development",
  devServer: {
    hot: true,
    port: 3035
  }
  // ... other webpack config
}
```
