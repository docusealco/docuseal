import type { Config } from "../types"

const { canProcess, moduleExists } = require("./helpers")
const { requireOrError } = require("./requireOrError")
const config = require("../config") as Config
const inliningCss = require("./inliningCss")

interface StyleRule {
  test: RegExp
  use: unknown[]
  type?: string
}

const getStyleRule = (
  test: RegExp,
  preprocessors: unknown[] = []
): StyleRule | null => {
  if (moduleExists("css-loader")) {
    const tryPostcss = () =>
      canProcess("postcss-loader", (loaderPath: string) => ({
        loader: loaderPath,
        options: { sourceMap: true }
      }))

    // style-loader is required when using css modules with HMR on the webpack-dev-server

    const extractionPlugin =
      config.assets_bundler === "rspack"
        ? requireOrError("@rspack/core").CssExtractRspackPlugin.loader
        : requireOrError("mini-css-extract-plugin").loader

    // Determine CSS Modules export mode based on configuration
    // 'named' (default): Use named exports with camelCaseOnly (v9 behavior)
    // 'default': Use default exports with camelCase (v8 behavior)
    const useNamedExports = config.css_modules_export_mode !== "default"

    const use = [
      inliningCss ? "style-loader" : extractionPlugin,
      {
        loader: require.resolve("css-loader"),
        options: {
          sourceMap: true,
          importLoaders: 2,
          modules: {
            auto: true,
            // Use named exports for v9 (default), or default exports for v8 compatibility
            namedExport: useNamedExports,
            // 'camelCaseOnly' with namedExport: true (v9 default)
            // 'camelCase' with namedExport: false (v8 behavior - exports both original and camelCase)
            exportLocalsConvention: useNamedExports
              ? "camelCaseOnly"
              : "camelCase"
          }
        }
      },
      tryPostcss(),
      ...preprocessors
    ].filter(Boolean)

    const result: StyleRule = {
      test,
      use
    }

    if (config.assets_bundler === "rspack") {
      result.type = "javascript/auto"
    }

    return result
  }

  return null
}

export = { getStyleRule }
