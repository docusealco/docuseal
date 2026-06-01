import type { Config } from "../types"

const config = require("../config") as Config

const rspackRawConfig = () => ({
  resourceQuery: /raw/,
  type: "asset/source"
})

const webpackRawConfig = () => ({
  oneOf: [
    {
      // Match any file with ?raw query parameter
      resourceQuery: /raw/,
      type: "asset/source"
    },
    {
      // Fallback: match .html files without query
      test: /\.html$/,
      exclude: /\.(js|mjs|jsx|ts|tsx)$/,
      type: "asset/source"
    }
  ]
})

export = config.assets_bundler === "rspack"
  ? rspackRawConfig()
  : webpackRawConfig()
