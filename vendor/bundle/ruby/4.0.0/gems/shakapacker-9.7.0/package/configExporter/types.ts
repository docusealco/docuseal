/**
 * Environment variable names that can be set by build configurations.
 * These are the only environment variables that build configs are allowed to set.
 * This whitelist prevents malicious configs from modifying critical system variables.
 */
export const BUILD_ENV_VARS = [
  "NODE_ENV",
  "RAILS_ENV",
  "NODE_OPTIONS",
  "BABEL_ENV",
  "WEBPACK_SERVE",
  "CLIENT_BUNDLE_ONLY",
  "SERVER_BUNDLE_ONLY"
] as const

/**
 * Environment variables that must never be set by build configurations.
 * Setting these could compromise system security or cause unexpected behavior.
 */
export const DANGEROUS_ENV_VARS = [
  "PATH",
  "HOME",
  "LD_PRELOAD",
  "LD_LIBRARY_PATH",
  "DYLD_LIBRARY_PATH",
  "DYLD_INSERT_LIBRARIES"
] as const

/**
 * Type predicate to check if a string is in the BUILD_ENV_VARS whitelist
 *
 * Note: The type assertion is necessary because TypeScript's type system cannot
 * infer that .includes() on a readonly const array will properly narrow the type.
 * The assertion is safe because we're only widening the type for the includes() check.
 */
export function isBuildEnvVar(
  key: string
): key is (typeof BUILD_ENV_VARS)[number] {
  return (BUILD_ENV_VARS as readonly string[]).includes(key)
}

/**
 * Type predicate to check if a string is in the DANGEROUS_ENV_VARS blacklist
 *
 * Note: The type assertion is necessary because TypeScript's type system cannot
 * infer that .includes() on a readonly const array will properly narrow the type.
 * The assertion is safe because we're only widening the type for the includes() check.
 */
export function isDangerousEnvVar(
  key: string
): key is (typeof DANGEROUS_ENV_VARS)[number] {
  return (DANGEROUS_ENV_VARS as readonly string[]).includes(key)
}

/**
 * Default directory for config exports when using --doctor or file output modes.
 */
export const DEFAULT_EXPORT_DIR = "shakapacker-config-exports"

/**
 * Default config file path for bundler build configurations.
 */
export const DEFAULT_CONFIG_FILE = "config/shakapacker-builds.yml"

export interface ExportOptions {
  doctor?: boolean
  saveDir?: string
  stdout?: boolean
  bundler?: "webpack" | "rspack"
  env?: "development" | "production" | "test"
  clientOnly?: boolean
  serverOnly?: boolean
  output?: string
  format?: "yaml" | "json" | "inspect"
  annotate?: boolean
  verbose?: boolean
  depth?: number | null
  help?: boolean
  // New config file options
  init?: boolean
  ssr?: boolean
  configFile?: string
  build?: string
  listBuilds?: boolean
  allBuilds?: boolean
  // Validation options
  validate?: boolean
  validateBuild?: string
}

export interface ConfigMetadata {
  exportedAt: string
  bundler: string
  environment: string
  configFile: string
  /**
   * Type of webpack/rspack config output.
   * Built-in types: "client", "server", "all", "client-hmr"
   * Custom types: Any string matching your outputs array (e.g., "client-modern", "client-legacy", "server-bundle")
   */
  configType: string
  configCount: number
  buildName?: string // New: name of the build from config file
  environmentVariables: {
    NODE_ENV?: string
    RAILS_ENV?: string
    CLIENT_BUNDLE_ONLY?: string
    SERVER_BUNDLE_ONLY?: string
    WEBPACK_SERVE?: string
    HMR?: string
  }
}

export interface FileOutput {
  filename: string
  content: string
  metadata: ConfigMetadata
}

// Config file schema types
export interface BundlerConfigFile {
  default_bundler?: "webpack" | "rspack"
  shakapacker_doctor_default_builds_here?: boolean
  builds: Record<string, BuildConfig>
}

export interface BuildConfig {
  description?: string
  bundler?: "webpack" | "rspack"
  dev_server?: boolean
  environment?: Record<string, string>
  bundler_env?: Record<string, string | boolean>
  outputs?: string[]
  config?: string
}

export interface ResolvedBuildConfig {
  name: string
  description?: string
  bundler: "webpack" | "rspack"
  environment: Record<string, string>
  bundlerEnvArgs: string[] // Converted bundler_env to CLI args
  outputs: string[]
  configFile?: string
}

export interface BuildValidationResult {
  buildName: string
  success: boolean
  errors: string[]
  warnings: string[]
  output: string[]
  outputs?: string[] // Build outputs (e.g., ["client", "server"])
  configFile?: string // Config file path if specified
  outputPath?: string // Output directory where files are written
  startTime?: number // Unix timestamp in milliseconds
  endTime?: number // Unix timestamp in milliseconds
  duration?: number // Duration in milliseconds
}
