/* eslint import/no-dynamic-require: 0 */

import { resolve } from "path"
import { existsSync } from "fs"
import { merge } from "webpack-merge"
import type { RuleSetRule } from "webpack"

const LOADER_EXT_REGEX = /\.([jt]sx?)(\.erb)?$/

const getLoaderExtension = (filename: string): string => {
  const matchData = filename.match(LOADER_EXT_REGEX)

  if (!matchData) {
    return "js"
  }

  return matchData[1] ?? "js"
}

const getCustomConfig = (): Partial<RuleSetRule> => {
  const path = resolve("config", "esbuild.config.js")
  if (existsSync(path)) {
    return require(path)
  }
  return {}
}

const getEsbuildLoaderConfig = (filenameToProcess: string): RuleSetRule => {
  const customConfig = getCustomConfig()
  const defaultConfig: RuleSetRule = {
    loader: require.resolve("esbuild-loader"),
    options: {
      loader: getLoaderExtension(filenameToProcess)
    }
  }

  return merge(defaultConfig, customConfig)
}

export { getEsbuildLoaderConfig }
