/**
 * Validates that required dependencies are installed for the selected bundler
 */

const { moduleExists } = require("./helpers")
const { error } = require("./debug")

const validateRspackDependencies = (): void => {
  const requiredDependencies = ["@rspack/core", "rspack-manifest-plugin"]

  const missingDependencies = requiredDependencies.filter(
    (dep) => !moduleExists(dep)
  )

  if (missingDependencies.length > 0) {
    error(
      `Missing required dependencies for RSpack:\n${missingDependencies
        .map((dep) => `  - ${dep}`)
        .join(
          "\n"
        )}\n\nPlease install them with:\n  npm install ${missingDependencies.join(
        " "
      )}`
    )
    throw new Error(
      `Missing RSpack dependencies: ${missingDependencies.join(", ")}`
    )
  }
}

const validateWebpackDependencies = (): void => {
  const requiredDependencies = [
    "webpack",
    "webpack-cli",
    "webpack-assets-manifest"
  ]

  const missingDependencies = requiredDependencies.filter(
    (dep) => !moduleExists(dep)
  )

  if (missingDependencies.length > 0) {
    error(
      `Missing required dependencies for Webpack:\n${missingDependencies
        .map((dep) => `  - ${dep}`)
        .join(
          "\n"
        )}\n\nPlease install them with:\n  npm install ${missingDependencies.join(
        " "
      )}`
    )
    throw new Error(
      `Missing Webpack dependencies: ${missingDependencies.join(", ")}`
    )
  }
}

export = {
  validateRspackDependencies,
  validateWebpackDependencies
}
