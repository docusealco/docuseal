/**
 * Production environment configuration for webpack and rspack bundlers
 * @module environments/production
 */

/* eslint import/no-dynamic-require: 0 */

import type {
  Configuration as WebpackConfiguration,
  WebpackPluginInstance
} from "webpack"
import type { CompressionPluginConstructor } from "./types"
import type { Config } from "../types"

const { resolve } = require("path")
const { merge } = require("webpack-merge")
const baseConfig = require("./base")
const { moduleExists } = require("../utils/helpers")
const config = require("../config") as Config

const optimizationPath = resolve(
  __dirname,
  "..",
  "optimization",
  `${config.assets_bundler}.js`
)
const { getOptimization } = require(optimizationPath)

let CompressionPlugin: CompressionPluginConstructor | null = null
if (moduleExists("compression-webpack-plugin")) {
  CompressionPlugin = require("compression-webpack-plugin")
}

/**
 * Generate production plugins including compression
 * @returns Array of webpack plugins for production
 */
const getPlugins = (): WebpackPluginInstance[] => {
  const plugins: WebpackPluginInstance[] = []

  if (CompressionPlugin) {
    plugins.push(
      new CompressionPlugin({
        filename: "[path][base].gz[query]",
        algorithm: "gzip",
        test: /\.(js|css|html|json|ico|svg|eot|otf|ttf|map)$/
      })
    )

    if ("brotli" in process.versions) {
      plugins.push(
        new CompressionPlugin({
          filename: "[path][base].br[query]",
          algorithm: "brotliCompress",
          test: /\.(js|css|html|json|ico|svg|eot|otf|ttf|map)$/
        })
      )
    }
  }

  return plugins
}

/**
 * Production configuration with optimizations and compression
 */
const productionConfig: Partial<WebpackConfiguration> = {
  devtool: "source-map",
  stats: "normal",
  bail: true,
  plugins: getPlugins(),
  optimization: getOptimization()
}

if (config.useContentHash === false) {
  console.warn(`⚠️ WARNING
Setting 'useContentHash' to 'false' in the production environment (specified by NODE_ENV environment variable) is not allowed!
Content hashes get added to the filenames regardless of setting useContentHash in 'shakapacker.yml' to false.
`)
}

module.exports = merge(baseConfig, productionConfig)
