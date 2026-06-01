/**
 * Bundler utilities for seamless switching between Webpack and Rspack.
 *
 * These utilities allow users to write bundler-agnostic configuration code
 * that works with both Webpack and Rspack without conditional logic.
 *
 * @example
 * const { getBundler, getCssExtractPlugin, isRspack } = require('shakapacker')
 *
 * // Get the appropriate bundler
 * const bundler = getBundler()
 * new bundler.DefinePlugin({ ... })
 *
 * // Get the CSS extraction plugin
 * const CssPlugin = getCssExtractPlugin()
 * new CssPlugin({ filename: 'styles.css' })
 */

import type { Config } from "../types"

/**
 * Common interface for bundler plugin constructors.
 * Works with both webpack and rspack plugins.
 */
export interface PluginConstructor {
  new (...args: unknown[]): unknown
}

/**
 * Options for CSS extraction plugins (MiniCssExtractPlugin / CssExtractRspackPlugin).
 */
export interface CssExtractPluginOptions {
  filename?: string
  chunkFilename?: string
  ignoreOrder?: boolean
  insert?: string | ((linkTag: unknown) => void)
  attributes?: Record<string, string>
  linkType?: string | false
  runtime?: boolean
  experimentalUseImportModule?: boolean // webpack only
}

/**
 * CSS extraction plugin constructor interface.
 */
export interface CssExtractPluginConstructor {
  new (options?: CssExtractPluginOptions): unknown
  loader: string
}

/**
 * Common interface for the bundler module (webpack or @rspack/core).
 * Contains the commonly used plugins that exist in both bundlers.
 */
export interface BundlerModule {
  DefinePlugin: PluginConstructor
  EnvironmentPlugin: PluginConstructor
  ProvidePlugin: PluginConstructor
  HotModuleReplacementPlugin: PluginConstructor
  ProgressPlugin: PluginConstructor
  [key: string]: unknown
}

const config = require("../config") as Config
const { requireOrError } = require("./requireOrError")

/**
 * Whether the current bundler is Rspack.
 *
 * @example
 * const { isRspack } = require('shakapacker')
 * if (isRspack) {
 *   // Rspack-specific configuration
 * }
 */
const isRspack: boolean = config.assets_bundler === "rspack"

/**
 * Whether the current bundler is Webpack.
 *
 * @example
 * const { isWebpack } = require('shakapacker')
 * if (isWebpack) {
 *   // Webpack-specific configuration
 * }
 */
const isWebpack: boolean = config.assets_bundler === "webpack"

/**
 * Get the current bundler module (webpack or @rspack/core).
 *
 * @returns The bundler module with common plugin constructors
 * @throws {Error} If the required bundler package is not installed
 *
 * @example
 * const { getBundler } = require('shakapacker')
 * const bundler = getBundler()
 *
 * // Use bundler-agnostic plugins
 * new bundler.DefinePlugin({ VERSION: JSON.stringify('1.0.0') })
 * new bundler.EnvironmentPlugin(['NODE_ENV'])
 */
const getBundler = (): BundlerModule =>
  (isRspack
    ? requireOrError("@rspack/core")
    : requireOrError("webpack")) as BundlerModule

/**
 * Get the CSS extraction plugin for the current bundler.
 *
 * For Webpack, returns MiniCssExtractPlugin.
 * For Rspack, returns CssExtractRspackPlugin.
 *
 * @returns The CSS extraction plugin constructor
 * @throws {Error} If the required CSS plugin package is not installed
 *
 * @example
 * const { getCssExtractPlugin } = require('shakapacker')
 * const CssExtractPlugin = getCssExtractPlugin()
 *
 * module.exports = {
 *   plugins: [
 *     new CssExtractPlugin({
 *       filename: 'css/[name].css'
 *     })
 *   ]
 * }
 */
const getCssExtractPlugin = (): CssExtractPluginConstructor => {
  if (isRspack) {
    const rspack = requireOrError("@rspack/core") as {
      CssExtractRspackPlugin: CssExtractPluginConstructor
    }
    return rspack.CssExtractRspackPlugin
  }
  return requireOrError(
    "mini-css-extract-plugin"
  ) as CssExtractPluginConstructor
}

/**
 * Get the CSS extraction plugin loader for the current bundler.
 *
 * For Webpack, returns MiniCssExtractPlugin.loader.
 * For Rspack, returns CssExtractRspackPlugin.loader.
 *
 * @returns The CSS extraction loader string
 *
 * @example
 * const { getCssExtractPluginLoader } = require('shakapacker')
 *
 * module.exports = {
 *   module: {
 *     rules: [{
 *       test: /\.css$/,
 *       use: [getCssExtractPluginLoader(), 'css-loader']
 *     }]
 *   }
 * }
 */
const getCssExtractPluginLoader = (): string => getCssExtractPlugin().loader

/**
 * Get the DefinePlugin for the current bundler.
 *
 * @returns The DefinePlugin constructor
 * @throws {Error} If the required bundler package is not installed
 *
 * @example
 * const { getDefinePlugin } = require('shakapacker')
 * const DefinePlugin = getDefinePlugin()
 *
 * module.exports = {
 *   plugins: [
 *     new DefinePlugin({
 *       'process.env.API_URL': JSON.stringify('https://api.example.com')
 *     })
 *   ]
 * }
 */
const getDefinePlugin = (): PluginConstructor => getBundler().DefinePlugin

/**
 * Get the EnvironmentPlugin for the current bundler.
 *
 * @returns The EnvironmentPlugin constructor
 * @throws {Error} If the required bundler package is not installed
 *
 * @example
 * const { getEnvironmentPlugin } = require('shakapacker')
 * const EnvironmentPlugin = getEnvironmentPlugin()
 *
 * module.exports = {
 *   plugins: [
 *     new EnvironmentPlugin(['NODE_ENV', 'DEBUG'])
 *   ]
 * }
 */
const getEnvironmentPlugin = (): PluginConstructor =>
  getBundler().EnvironmentPlugin

/**
 * Get the ProvidePlugin for the current bundler.
 *
 * @returns The ProvidePlugin constructor
 * @throws {Error} If the required bundler package is not installed
 *
 * @example
 * const { getProvidePlugin } = require('shakapacker')
 * const ProvidePlugin = getProvidePlugin()
 *
 * module.exports = {
 *   plugins: [
 *     new ProvidePlugin({
 *       $: 'jquery',
 *       jQuery: 'jquery'
 *     })
 *   ]
 * }
 */
const getProvidePlugin = (): PluginConstructor => getBundler().ProvidePlugin

export {
  isRspack,
  isWebpack,
  getBundler,
  getCssExtractPlugin,
  getCssExtractPluginLoader,
  getDefinePlugin,
  getEnvironmentPlugin,
  getProvidePlugin
}
