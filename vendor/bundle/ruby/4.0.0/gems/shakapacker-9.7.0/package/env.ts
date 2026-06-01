import { load } from "js-yaml"
import { readFileSync } from "fs"

const defaultConfigPath = require("./utils/defaultConfigPath")
const configPath = require("./utils/configPath")
const { isFileNotFoundError } = require("./utils/errorHelpers")
const { sanitizeEnvValue } = require("./utils/pathValidation")

const NODE_ENVIRONMENTS = ["development", "production", "test"] as const

// Sanitize environment variables to prevent injection
const initialRailsEnv = sanitizeEnvValue(process.env.RAILS_ENV)
const rawNodeEnv = sanitizeEnvValue(process.env.NODE_ENV)

// Default NODE_ENV based on RAILS_ENV to match bin/shakapacker behavior (see lib/shakapacker/runner.rb:27)
// - RAILS_ENV=production → DEFAULT="production" (safe for production builds)
// - RAILS_ENV=development, test, staging, or unset → DEFAULT="development" (good DX for dev server)
// This ensures the dev server works out of the box without requiring NODE_ENV to be set explicitly
const DEFAULT = initialRailsEnv === "production" ? "production" : "development"

// Validate NODE_ENV strictly
const nodeEnv =
  rawNodeEnv &&
  NODE_ENVIRONMENTS.includes(rawNodeEnv as (typeof NODE_ENVIRONMENTS)[number])
    ? rawNodeEnv
    : DEFAULT

// Log warning if NODE_ENV was invalid
if (
  rawNodeEnv &&
  !NODE_ENVIRONMENTS.includes(rawNodeEnv as (typeof NODE_ENVIRONMENTS)[number])
) {
  console.warn(
    `[SHAKAPACKER WARNING] Invalid NODE_ENV value: ${rawNodeEnv}. ` +
      `Valid values are: ${NODE_ENVIRONMENTS.join(", ")}. Using default: ${DEFAULT}`
  )
}

const isProduction = nodeEnv === "production"
const isDevelopment = nodeEnv === "development"

interface ConfigFile {
  [environment: string]: Record<string, unknown>
}

let config: ConfigFile
try {
  config = load(readFileSync(configPath, "utf8")) as ConfigFile
} catch (error: unknown) {
  if (isFileNotFoundError(error)) {
    // File not found, use default configuration
    try {
      config = load(readFileSync(defaultConfigPath, "utf8")) as ConfigFile
    } catch (_defaultError) {
      throw new Error(
        `Failed to load Shakapacker configuration.\n` +
          `Neither user config (${configPath}) nor default config (${defaultConfigPath}) could be loaded.\n\n` +
          `To fix this issue:\n` +
          `1. Create a config/shakapacker.yml file in your project\n` +
          `2. Or set the SHAKAPACKER_CONFIG environment variable to point to your config file\n` +
          `3. Or reinstall Shakapacker to restore the default configuration:\n` +
          `   npm install shakapacker --force\n` +
          `   yarn add shakapacker --force`
      )
    }
  } else {
    throw error
  }
}

const availableEnvironments = Object.keys(config).join("|")
const regex = new RegExp(`^(${availableEnvironments})$`, "g")

const runningWebpackDevServer = process.env.WEBPACK_SERVE === "true"

const validatedRailsEnv =
  initialRailsEnv && initialRailsEnv.match(regex) ? initialRailsEnv : DEFAULT

if (initialRailsEnv && validatedRailsEnv !== initialRailsEnv) {
  console.warn(
    `[SHAKAPACKER WARNING] Environment '${initialRailsEnv}' not found in the configuration.\n` +
      `Using '${DEFAULT}' configuration as a fallback.`
  )
}

export = {
  railsEnv: validatedRailsEnv,
  nodeEnv,
  isProduction,
  isDevelopment,
  runningWebpackDevServer
}
