const { requireOrError } = require("../utils/requireOrError")
const { error: logError } = require("../utils/debug")

const rspack = requireOrError("@rspack/core")

interface OptimizationConfig {
  minimize: boolean
  minimizer?: unknown[]
}

const getOptimization = (): OptimizationConfig => {
  // Use Rspack's built-in minification instead of terser-webpack-plugin
  const result: OptimizationConfig = { minimize: true }
  try {
    result.minimizer = [
      new rspack.SwcJsMinimizerRspackPlugin(),
      new rspack.LightningCssMinimizerRspackPlugin()
    ]
  } catch (error: unknown) {
    const errorMessage = error instanceof Error ? error.message : String(error)
    const errorStack = error instanceof Error ? error.stack : ""
    // Log full error with stack trace
    logError(
      `Failed to configure Rspack minimizers: ${errorMessage}\n${errorStack}`
    )
    // Re-throw the error to properly propagate it
    throw new Error(
      `Could not configure Rspack minimizers: ${errorMessage}. Please check that @rspack/core is properly installed.`
    )
  }
  return result
}

export = {
  getOptimization
}
