/**
 * Manual type definitions for Shakapacker package exports.
 *
 * This file is manually maintained because TypeScript cannot infer types
 * from the `export =` syntax with dynamic require() calls in index.ts.
 *
 * When adding/modifying exports in index.ts, update this file accordingly.
 */

// @ts-ignore: webpack is an optional peer dependency (using type-only import)
import type { Configuration, RuleSetRule } from "webpack"
import type { Config, DevServerConfig, Env } from "./types"
import type {
  PluginConstructor,
  CssExtractPluginConstructor,
  BundlerModule
} from "./utils/bundlerUtils"

/**
 * The shape of the Shakapacker module exports.
 * This interface represents the object exported via CommonJS `export =`.
 */
interface ShakapackerExports {
  /** Shakapacker configuration from shakapacker.yml */
  config: Config
  /** Development server configuration */
  devServer: DevServerConfig
  /** Base webpack/rspack configuration */
  baseConfig: Configuration
  /** Environment configuration (railsEnv, nodeEnv, etc.) */
  env: Env
  /** Array of webpack/rspack loader rules */
  rules: RuleSetRule[]
  /** Check if a module exists in node_modules */
  moduleExists: (packageName: string) => boolean
  /** Process a file if a specific loader is available */
  canProcess: <T = unknown>(
    rule: string,
    fn: (modulePath: string) => T
  ) => T | null
  /** Whether CSS should be inlined (dev server with HMR) */
  inliningCss: boolean
  /** Generate webpack configuration with optional custom config */
  generateWebpackConfig: (extraConfig?: Configuration) => Configuration
  /** Whether the current bundler is Rspack */
  isRspack: boolean
  /** Whether the current bundler is Webpack */
  isWebpack: boolean
  /** Get the bundler module (webpack or @rspack/core) */
  getBundler: () => BundlerModule
  /** Get the CSS extraction plugin for the current bundler */
  getCssExtractPlugin: () => CssExtractPluginConstructor
  /** Get the CSS extraction plugin loader for the current bundler */
  getCssExtractPluginLoader: () => string
  /** Get the DefinePlugin for the current bundler */
  getDefinePlugin: () => PluginConstructor
  /** Get the EnvironmentPlugin for the current bundler */
  getEnvironmentPlugin: () => PluginConstructor
  /** Get the ProvidePlugin for the current bundler */
  getProvidePlugin: () => PluginConstructor
  /** webpack-merge's merge function */
  merge: typeof import("webpack-merge").merge
  /** webpack-merge's mergeWithCustomize function */
  mergeWithCustomize: typeof import("webpack-merge").mergeWithCustomize
  /** webpack-merge's mergeWithRules function */
  mergeWithRules: typeof import("webpack-merge").mergeWithRules
  /** webpack-merge's unique function */
  unique: typeof import("webpack-merge").unique
}

declare const shakapacker: ShakapackerExports
export = shakapacker
