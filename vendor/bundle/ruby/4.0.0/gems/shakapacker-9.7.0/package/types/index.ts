/**
 * Central type exports for Shakapacker
 * This file re-exports all public TypeScript types for easier consumer imports
 *
 * @example
 * ```typescript
 * import type { Config, WebpackConfigWithDevServer } from 'shakapacker/types'
 * ```
 *
 * @module shakapacker/types
 */

// Core configuration types
export type {
  Config,
  YamlConfig,
  LegacyConfig,
  Env,
  DevServerConfig
} from "../types"

// Loader types
export type {
  ShakapackerLoader,
  ShakapackerLoaderOptions,
  LoaderResolver,
  LoaderConfig
} from "../loaders"

// Webpack-specific types
export type {
  ShakapackerWebpackConfig,
  ShakapackerRule,
  ShakapackerLoaderOptions as WebpackLoaderOptions,
  ShakapackerLoader as WebpackLoader,
  LoaderType,
  LoaderUtils
} from "../webpack-types"

// Environment configuration types
export type {
  WebpackConfigWithDevServer,
  RspackPluginInstance,
  RspackPlugin,
  RspackDevServerConfig,
  RspackConfigWithDevServer,
  CompressionPluginOptions,
  CompressionPluginConstructor,
  ReactRefreshWebpackPlugin,
  ReactRefreshRspackPlugin
} from "../environments/types"

// Bundler utility types
export type {
  PluginConstructor,
  CssExtractPluginOptions,
  CssExtractPluginConstructor,
  BundlerModule
} from "../utils/bundlerUtils"

// Node.js error type (re-exported for convenience)
export type NodeJSError = NodeJS.ErrnoException

// Re-export commonly used webpack types for convenience
export type {
  Configuration as WebpackConfiguration,
  WebpackPluginInstance,
  RuleSetRule
} from "webpack"
