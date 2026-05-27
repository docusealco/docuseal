import { resolve } from "path"
import { load } from "js-yaml"
import { existsSync, readFileSync } from "fs"
import { merge } from "webpack-merge"
const { ensureTrailingSlash } = require("./utils/helpers")
const { railsEnv } = require("./env")
const configPath = require("./utils/configPath")
const defaultConfigPath = require("./utils/defaultConfigPath")
import { Config, YamlConfig } from "./types"
const {
  isValidYamlConfig,
  createConfigValidationError,
  isPartialConfig
} = require("./utils/typeGuards")
const {
  isFileNotFoundError,
  createFileOperationError
} = require("./utils/errorHelpers")

const loadAndValidateYaml = (path: string): YamlConfig => {
  const fileContent = readFileSync(path, "utf8")
  const yamlContent = load(fileContent)

  if (!isValidYamlConfig(yamlContent)) {
    throw createConfigValidationError(path, railsEnv, "Invalid YAML structure")
  }

  return yamlContent as YamlConfig
}

const getDefaultConfig = (): Partial<Config> => {
  try {
    const defaultConfig = loadAndValidateYaml(defaultConfigPath)
    return defaultConfig[railsEnv] || defaultConfig.production || {}
  } catch (error) {
    if (isFileNotFoundError(error)) {
      throw createFileOperationError(
        "read",
        defaultConfigPath,
        `Default configuration not found at ${defaultConfigPath}. Please ensure Shakapacker is properly installed. You may need to run 'yarn add shakapacker' or 'npm install shakapacker'.`
      )
    }
    throw error
  }
}

const defaults = getDefaultConfig()
let config: Config

if (existsSync(configPath)) {
  try {
    const appYmlObject = loadAndValidateYaml(configPath)

    const envAppConfig = appYmlObject[railsEnv]

    if (!envAppConfig) {
      console.warn(
        `[SHAKAPACKER WARNING] Environment '${railsEnv}' not found in ${configPath}\n` +
          `Available environments: ${Object.keys(appYmlObject).join(", ")}\n` +
          `Using 'production' configuration as fallback.\n\n` +
          `To fix this, either:\n` +
          `  - Add a '${railsEnv}' section to your shakapacker.yml\n` +
          `  - Set RAILS_ENV to one of the available environments\n` +
          `  - Copy settings from another environment as a starting point`
      )
    }

    // Merge returns the merged type
    const mergedConfig = merge(defaults, envAppConfig || {})

    // Validate merged config before type assertion
    if (!isPartialConfig(mergedConfig)) {
      throw createConfigValidationError(
        configPath,
        railsEnv,
        `Invalid configuration structure in ${configPath}. Please check your shakapacker.yml syntax and ensure all required fields are properly defined.`
      )
    }

    // After merging with defaults, config should be complete
    // Use type assertion only after validation
    config = mergedConfig as Config
  } catch (error) {
    if (isFileNotFoundError(error)) {
      // File not found is OK, use defaults
      if (!isPartialConfig(defaults)) {
        throw createConfigValidationError(
          defaultConfigPath,
          railsEnv,
          `Invalid default configuration. This may indicate a corrupted Shakapacker installation. Try reinstalling with 'yarn add shakapacker --force'.`
        )
      }
      // Using defaults only, might be partial
      config = defaults as Config
    } else {
      throw error
    }
  }
} else {
  // No user config, use defaults
  if (!isPartialConfig(defaults)) {
    throw createConfigValidationError(
      defaultConfigPath,
      railsEnv,
      `Invalid default configuration. This may indicate a corrupted Shakapacker installation. Try reinstalling with 'yarn add shakapacker --force'.`
    )
  }
  // Using defaults only, might be partial
  config = defaults as Config
}

config.outputPath = resolve(config.public_root_path, config.public_output_path)

if (config.private_output_path) {
  config.privateOutputPath = resolve(config.private_output_path)
}

// Ensure that the publicPath includes our asset host so dynamic imports
// (code-splitting chunks and static assets) load from the CDN instead of a relative path.
const getPublicPath = (): string => {
  const rootUrl = ensureTrailingSlash(process.env.SHAKAPACKER_ASSET_HOST || "/")
  return `${rootUrl}${config.public_output_path}/`
}

config.publicPath = getPublicPath()
config.publicPathWithoutCDN = `/${config.public_output_path}/`

if (config.manifest_path) {
  config.manifestPath = resolve(config.manifest_path)
} else {
  config.manifestPath = resolve(config.outputPath, "manifest.json")
}
// Ensure no duplicate hash functions exist in the returned config object
if (config.integrity?.hash_functions) {
  config.integrity.hash_functions = [
    ...new Set(config.integrity.hash_functions)
  ]
}

// Ensure assets_bundler has a default value
if (!config.assets_bundler) {
  config.assets_bundler = "webpack"
}

// Allow ENV variable to override assets_bundler
if (process.env.SHAKAPACKER_ASSETS_BUNDLER) {
  config.assets_bundler = process.env.SHAKAPACKER_ASSETS_BUNDLER
}

// Define clear defaults
// Keep Babel as default for webpack to maintain backward compatibility
// Use SWC for rspack as it's a newer bundler where we can set modern defaults
const DEFAULT_JAVASCRIPT_TRANSPILER =
  config.assets_bundler === "rspack" ? "swc" : "babel"

// Backward compatibility: Check for webpack_loader using proper type guard
function hasWebpackLoader(
  obj: unknown
): obj is Config & { webpack_loader: string } {
  return (
    typeof obj === "object" &&
    obj !== null &&
    "webpack_loader" in obj &&
    typeof (obj as Record<string, unknown>).webpack_loader === "string"
  )
}

// Allow environment variable to override javascript_transpiler
if (process.env.SHAKAPACKER_JAVASCRIPT_TRANSPILER) {
  config.javascript_transpiler = process.env.SHAKAPACKER_JAVASCRIPT_TRANSPILER
} else if (hasWebpackLoader(config) && !config.javascript_transpiler) {
  console.warn(
    "[SHAKAPACKER DEPRECATION] The 'webpack_loader' configuration option is deprecated.\n" +
      "Please use 'javascript_transpiler' instead as it better reflects its purpose of configuring JavaScript transpilation regardless of the bundler used."
  )
  config.javascript_transpiler = config.webpack_loader
} else if (!config.javascript_transpiler) {
  config.javascript_transpiler = DEFAULT_JAVASCRIPT_TRANSPILER
}

// Ensure webpack_loader is always available for backward compatibility
Object.defineProperty(config, "webpack_loader", {
  value: config.javascript_transpiler,
  writable: true,
  enumerable: true,
  configurable: true
})

export = config
