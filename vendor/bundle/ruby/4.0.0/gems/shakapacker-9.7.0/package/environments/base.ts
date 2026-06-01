/* eslint import/no-dynamic-require: 0 */

import { Dirent } from "fs"
import type { Configuration, Entry } from "webpack"
import type { Config } from "../types"

const { basename, dirname, join, relative, resolve } = require("path")
const { existsSync, readdirSync } = require("fs")
const extname = require("path-complete-extname")
const config = require("../config") as Config
const { isProduction } = require("../env")

const pluginsPath = resolve(
  __dirname,
  "..",
  "plugins",
  `${config.assets_bundler}.js`
)
const { getPlugins } = require(pluginsPath)
const rulesPath = resolve(
  __dirname,
  "..",
  "rules",
  `${config.assets_bundler}.js`
)
const rules = require(rulesPath)

// Don't use contentHash except for production for performance
// https://webpack.js.org/guides/build-performance/#avoid-production-specific-tooling
const hash = isProduction || config.useContentHash ? "-[contenthash]" : ""

const getFilesInDirectory = (dir: string, includeNested: boolean): string[] => {
  if (!existsSync(dir)) {
    return []
  }

  return readdirSync(dir, { withFileTypes: true }).flatMap((dirent: Dirent) => {
    if (dirent.name.startsWith(".")) {
      return []
    }

    const filePath = join(dir, dirent.name)

    if (dirent.isDirectory() && includeNested) {
      return getFilesInDirectory(filePath, includeNested)
    }
    if (dirent.isFile()) {
      return filePath
    }
    return []
  })
}

const getEntryObject = (): Entry => {
  const entries: Entry = {}
  const rootPath = join(config.source_path, config.source_entry_path)
  if (config.source_entry_path === "/" && config.nested_entries) {
    throw new Error(
      `Invalid Shakapacker configuration detected!\n\n` +
        `You have set source_entry_path to '/' with nested_entries enabled.\n` +
        `This would create webpack entry points for EVERY file in your source directory,\n` +
        `which would severely impact build performance.\n\n` +
        `To fix this issue, either:\n` +
        `1. Set 'nested_entries: false' in your shakapacker.yml\n` +
        `2. Change 'source_entry_path' to a specific subdirectory (e.g., 'packs')\n` +
        `3. Or use both options for better organization of your entry points`
    )
  }

  getFilesInDirectory(rootPath, config.nested_entries).forEach((path) => {
    const namespace = relative(join(rootPath), dirname(path))
    const name = join(namespace, basename(path, extname(path)))
    const assetPath: string = resolve(path)

    // Allows for multiple filetypes per entry (https://webpack.js.org/guides/entry-advanced/)
    // Transforms the config object value to an array with all values under the same name
    const previousPaths = entries[name]
    if (previousPaths) {
      const pathArray = Array.isArray(previousPaths)
        ? previousPaths
        : [previousPaths as string]
      pathArray.push(assetPath)
      entries[name] = pathArray
    } else {
      entries[name] = assetPath
    }
  })

  return entries
}

const getModulePaths = (): string[] => {
  const result = [resolve(config.source_path)]

  if (config.additional_paths) {
    config.additional_paths.forEach((path: string) =>
      result.push(resolve(path))
    )
  }
  result.push("node_modules")

  return result
}

const baseConfig: Configuration = {
  mode: "production",
  output: {
    filename: `js/[name]${hash}.js`,
    chunkFilename: `js/[name]${hash}.chunk.js`,

    // https://webpack.js.org/configuration/output/#outputhotupdatechunkfilename
    hotUpdateChunkFilename: "js/[id].[fullhash].hot-update.js",
    path: config.outputPath,
    publicPath: config.publicPath,

    // This is required for SRI to work.
    crossOriginLoading:
      config.integrity && config.integrity.enabled
        ? (config.integrity.cross_origin as
            | "anonymous"
            | "use-credentials"
            | false)
        : false
  },
  entry: getEntryObject(),
  resolve: {
    extensions: [".js", ".jsx", ".mjs", ".ts", ".tsx", ".coffee"],
    modules: getModulePaths()
  },

  plugins: getPlugins(),

  resolveLoader: {
    modules: ["node_modules"]
  },

  optimization: {
    splitChunks: { chunks: "all" },
    runtimeChunk: "single"
  },

  module: {
    rules
  }
}

export = baseConfig
