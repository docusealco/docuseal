/* eslint import/no-dynamic-require: 0 */

import { resolve } from "path"
import { existsSync } from "fs"
import { merge } from "webpack-merge"
import type { RuleSetRule } from "webpack"

const JSX_FILE_REGEX = /\.(jsx|tsx)(\.erb)?$/
const TYPESCRIPT_FILE_REGEX = /\.(ts|tsx)(\.erb)?$/

const isJsxFile = (filename: string): boolean =>
  !!filename.match(JSX_FILE_REGEX)

const isTypescriptFile = (filename: string): boolean =>
  !!filename.match(TYPESCRIPT_FILE_REGEX)

const getCustomConfig = (): Partial<RuleSetRule> => {
  const path = resolve("config", "swc.config.js")
  if (existsSync(path)) {
    return require(path)
  }
  return {}
}

const getSwcLoaderConfig = (filenameToProcess: string): RuleSetRule => {
  const customConfig = getCustomConfig()
  const isTs = isTypescriptFile(filenameToProcess)
  const isJsx = isJsxFile(filenameToProcess)
  const jsxKey = isTs ? "tsx" : "jsx"

  const defaultConfig: RuleSetRule = {
    loader: require.resolve("swc-loader"),
    options: {
      jsc: {
        parser: {
          dynamicImport: true,
          syntax: isTs ? "typescript" : "ecmascript",
          [jsxKey]: isJsx
        },
        loose: false
      },
      sourceMaps: true,
      env: {
        coreJs: 3,
        exclude: ["transform-typeof-symbol"],
        mode: "entry"
      }
    }
  }

  return merge(defaultConfig, customConfig)
}

export { getSwcLoaderConfig }
