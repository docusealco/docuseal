import type { Config } from "../types"

import { getFilteredEnv } from "./envFilter"

const { requireOrError } = require("../utils/requireOrError")
const ensureManifestExists = require("../utils/ensureManifestExists").default
// TODO: Change to `const { WebpackAssetsManifest }` when dropping 'webpack-assets-manifest < 6.0.0' (Node >=20.10.0) support
const WebpackAssetsManifest = requireOrError("webpack-assets-manifest")
const webpack = requireOrError("webpack")
const config = require("../config") as Config
const { isProduction } = require("../env")
const { moduleExists } = require("../utils/helpers")

const getPlugins = (): unknown[] => {
  ensureManifestExists(config.manifestPath)

  // TODO: Remove WebpackAssetsManifestConstructor workaround when dropping 'webpack-assets-manifest < 6.0.0' (Node >=20.10.0) support
  const WebpackAssetsManifestConstructor =
    "WebpackAssetsManifest" in WebpackAssetsManifest
      ? WebpackAssetsManifest.WebpackAssetsManifest
      : WebpackAssetsManifest

  const plugins = [
    // SECURITY: Only expose allowlisted environment variables to prevent secrets leaking
    // into client-side bundles. See envFilter.ts for the allowlist configuration.
    new webpack.EnvironmentPlugin(getFilteredEnv()),
    new WebpackAssetsManifestConstructor({
      merge: true,
      entrypoints: true,
      writeToDisk: true,
      output: config.manifestPath,
      entrypointsUseAssets: true,
      publicPath: config.publicPathWithoutCDN,
      ...(config.integrity
        ? {
            integrity: config.integrity.enabled,
            integrityHashes: config.integrity.hash_functions
          }
        : {})
    })
  ]

  if (moduleExists("css-loader") && moduleExists("mini-css-extract-plugin")) {
    const hash = isProduction || config.useContentHash ? "-[contenthash:8]" : ""
    const MiniCssExtractPlugin = requireOrError("mini-css-extract-plugin")
    plugins.push(
      new MiniCssExtractPlugin({
        filename: `css/[name]${hash}.css`,
        chunkFilename: `css/[id]${hash}.css`,
        // For projects where css ordering has been mitigated through consistent use of scoping or naming conventions,
        // the css order warnings can be disabled by setting the ignoreOrder flag.
        ignoreOrder: config.css_extract_ignore_order_warnings
      })
    )
  }

  if (
    config.integrity?.enabled &&
    moduleExists("webpack-subresource-integrity")
  ) {
    // webpack-subresource-integrity v5+ exports the plugin as a named export.
    const subresourceIntegrityModule = requireOrError(
      "webpack-subresource-integrity"
    )
    const SubresourceIntegrityPlugin =
      "SubresourceIntegrityPlugin" in subresourceIntegrityModule
        ? subresourceIntegrityModule.SubresourceIntegrityPlugin
        : subresourceIntegrityModule
    plugins.push(
      new SubresourceIntegrityPlugin({
        hashFuncNames: config.integrity.hash_functions,
        enabled: isProduction
      })
    )
  }

  return plugins
}

export = {
  getPlugins
}
