/* eslint import/no-dynamic-require: 0 */
import type { Config } from "../types"

const config = require("../config") as Config

interface ErrorWithCause extends Error {
  cause?: unknown
}

const requireOrError = (moduleName: string): unknown => {
  try {
    return require(moduleName)
  } catch (originalError: unknown) {
    const error: ErrorWithCause = new Error(
      `[SHAKAPACKER]: ${moduleName} is required for ${config.assets_bundler} but is not installed. View Shakapacker's documented dependencies at https://github.com/shakacode/shakapacker/tree/main/docs/peer-dependencies.md`
    )
    // Add the original error as the cause for better debugging (ES2022+)
    // Using custom interface since target is ES2020 but runtime supports it
    error.cause = originalError
    throw error
  }
}

export = { requireOrError }
