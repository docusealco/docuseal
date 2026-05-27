import { existsSync, readFileSync, realpathSync } from "fs"
import { resolve, relative, isAbsolute } from "path"
import { load as loadYaml, FAILSAFE_SCHEMA } from "js-yaml"
import {
  BundlerConfigFile,
  ResolvedBuildConfig,
  ExportOptions,
  DEFAULT_CONFIG_FILE
} from "./types"

/**
 * Loads and validates bundler configuration files
 * @example
 * const loader = new ConfigFileLoader('config/shakapacker-builds.yml')
 * const config = loader.load()
 */
export class ConfigFileLoader {
  private configFilePath: string

  /**
   * @param configFilePath - Path to config file (defaults to DEFAULT_CONFIG_FILE in cwd)
   * @throws Error if path is outside project directory
   */
  constructor(configFilePath?: string) {
    this.configFilePath =
      configFilePath || resolve(process.cwd(), DEFAULT_CONFIG_FILE)
    this.validateConfigPath()
  }

  /**
   * Validates that the config file path is within the project directory
   * to prevent path traversal attacks (including symlink traversal)
   * @throws Error if path traversal is detected
   */
  private validateConfigPath(): void {
    const absPath = resolve(this.configFilePath)
    const cwd = process.cwd()

    // Resolve symlinks to get the real path
    let realPath: string
    try {
      // Only resolve symlinks if the file exists
      if (existsSync(absPath)) {
        realPath = realpathSync(absPath)
      } else {
        // If file doesn't exist yet, just use the resolved path
        realPath = absPath
      }
    } catch {
      // If we can't resolve the path, use the original
      realPath = absPath
    }

    const rel = relative(cwd, realPath)

    if (
      rel.startsWith("..") ||
      (isAbsolute(rel) && !realPath.startsWith(cwd))
    ) {
      throw new Error(
        `Config file must be within project directory. Attempted path: ${this.configFilePath}`
      )
    }
  }

  /**
   * Checks if the config file exists
   * @returns true if file exists, false otherwise
   */
  exists(): boolean {
    return existsSync(this.configFilePath)
  }

  /**
   * Loads and validates the config file
   * @returns Parsed and validated config file
   * @throws Error if file doesn't exist, is invalid YAML, or fails validation
   */
  load(): BundlerConfigFile {
    if (!this.exists()) {
      throw new Error(
        `Config file not found: ${this.configFilePath}\n` +
          `Run 'bin/shakapacker-config --init' to generate a sample config file.`
      )
    }

    try {
      const content = readFileSync(this.configFilePath, "utf8")
      // Use FAILSAFE_SCHEMA to prevent code execution via YAML parsing
      const parsed = loadYaml(content, {
        schema: FAILSAFE_SCHEMA,
        json: true
      }) as BundlerConfigFile

      ConfigFileLoader.validate(parsed)
      return parsed
    } catch (error: unknown) {
      const errorMessage =
        error instanceof Error ? error.message : String(error)
      throw new Error(
        `Failed to load config file ${this.configFilePath}: ${errorMessage}`
      )
    }
  }

  private static validate(config: BundlerConfigFile): void {
    if (!config.builds || typeof config.builds !== "object") {
      throw new Error("Config file must contain a 'builds' object")
    }

    if (Object.keys(config.builds).length === 0) {
      throw new Error("Config file must contain at least one build")
    }

    if (
      config.default_bundler &&
      config.default_bundler !== "webpack" &&
      config.default_bundler !== "rspack"
    ) {
      throw new Error(
        `Invalid default_bundler '${config.default_bundler}'. Must be 'webpack' or 'rspack'.`
      )
    }

    // Validate each build
    for (const [name, build] of Object.entries(config.builds)) {
      // Guard: ensure build is a non-null plain object
      if (build == null || typeof build !== "object" || Array.isArray(build)) {
        let buildType: string
        if (build === null) {
          buildType = "null"
        } else if (Array.isArray(build)) {
          buildType = "array"
        } else {
          buildType = typeof build
        }
        throw new Error(
          `Invalid build '${name}': must be an object, got ${buildType}`
        )
      }

      if (
        build.bundler &&
        build.bundler !== "webpack" &&
        build.bundler !== "rspack"
      ) {
        throw new Error(
          `Invalid bundler '${build.bundler}' in build '${name}'. Must be 'webpack' or 'rspack'.`
        )
      }

      if (build.bundler_env && typeof build.bundler_env !== "object") {
        throw new Error(
          `Invalid bundler_env in build '${name}'. Must be an object.`
        )
      }

      if (build.environment && typeof build.environment !== "object") {
        throw new Error(
          `Invalid environment in build '${name}'. Must be an object.`
        )
      }

      if (build.outputs && !Array.isArray(build.outputs)) {
        throw new Error(
          `Invalid outputs in build '${name}'. Must be an array of strings.`
        )
      }
    }
  }

  /**
   * Resolves a build configuration by name
   * @param buildName - Name of the build from config file
   * @param options - CLI options that may override build settings
   * @param defaultBundler - Fallback bundler if not specified
   * @returns Resolved build configuration with all settings applied
   * @throws Error if build name not found
   */
  resolveBuild(
    buildName: string,
    options: ExportOptions,
    defaultBundler: "webpack" | "rspack"
  ): ResolvedBuildConfig {
    const config = this.load()
    const build = config.builds[buildName]

    if (!build) {
      const available = Object.keys(config.builds).join(", ")
      throw new Error(
        `Build '${buildName}' not found in config file.\n` +
          `Available builds: ${available}\n` +
          `Use --list-builds to see all available builds.`
      )
    }

    // Resolve bundler with precedence
    const bundler = ConfigFileLoader.resolveBundler(
      options.bundler,
      build.bundler,
      config.default_bundler,
      defaultBundler
    )

    // Expand environment variables
    const environment = this.expandEnvironmentVariables(
      build.environment || {},
      bundler
    )

    // Convert bundler_env to CLI args
    const bundlerEnvArgs = ConfigFileLoader.convertBundlerEnvToArgs(
      build.bundler_env || {}
    )

    // Resolve and validate outputs
    const outputs = build.outputs || []

    // Validate edge cases
    if (outputs.length === 0) {
      throw new Error(
        `Build '${buildName}' has empty outputs array. ` +
          `Please specify at least one output type (client, server, or all).`
      )
    }

    // Check for duplicates
    const uniqueOutputs = new Set(outputs)
    if (uniqueOutputs.size !== outputs.length) {
      throw new Error(
        `Build '${buildName}' has duplicate output types. ` +
          `Each output type should appear only once.`
      )
    }

    // Resolve config file
    let configFile: string | undefined
    if (build.config) {
      configFile = this.expandEnvironmentVariables(
        { config: build.config },
        bundler
      ).config

      // Validate config file path (prevent path traversal)
      if (configFile) {
        // Normalize Windows backslashes for validation
        const configFileNormalized = configFile.replace(/\\/g, "/")
        if (
          configFileNormalized.includes("..") ||
          !configFileNormalized.startsWith("config/")
        ) {
          throw new Error(
            `Invalid config file path in build '${buildName}': "${configFile}". ` +
              `Config files must be within the config/ directory.`
          )
        }
      }
    }

    return {
      name: buildName,
      description: build.description,
      bundler,
      environment,
      bundlerEnvArgs,
      outputs,
      configFile
    }
  }

  private static resolveBundler(
    cliFlag?: "webpack" | "rspack",
    buildBundler?: "webpack" | "rspack",
    defaultBundler?: "webpack" | "rspack",
    fallback: "webpack" | "rspack" = "webpack"
  ): "webpack" | "rspack" {
    return cliFlag || buildBundler || defaultBundler || fallback
  }

  private expandEnvironmentVariables(
    vars: Record<string, string>,
    bundler: string
  ): Record<string, string> {
    const expanded: Record<string, string> = {}

    for (const [key, value] of Object.entries(vars)) {
      expanded[key] = this.expandString(value, bundler)
    }

    return expanded
  }

  private expandString(str: string, bundler: string): string {
    // Replace \${BUNDLER} with actual bundler
    let expanded = str.replace(/\$\{BUNDLER\}/g, bundler)

    // Replace ${VAR:-default} with VAR value or default
    expanded = expanded.replace(
      /\$\{([^}:]+):-([^}]*)\}/g,
      (_: string, varName: string, defaultValue: string) => {
        // Validate env var name to prevent regex injection
        if (!ConfigFileLoader.isValidEnvVarName(varName)) {
          console.warn(
            `[Config Exporter] Warning: Invalid environment variable name: ${varName}`
          )
          return `\${${varName}:-${defaultValue}}`
        }
        return process.env[varName] || defaultValue
      }
    )

    // Replace ${VAR} with VAR value
    expanded = expanded.replace(
      /\$\{([^}:]+)\}/g,
      (_: string, varName: string) => {
        // Validate env var name to prevent regex injection
        if (!ConfigFileLoader.isValidEnvVarName(varName)) {
          console.warn(
            `[Config Exporter] Warning: Invalid environment variable name: ${varName}`
          )
          return `\${${varName}}`
        }
        return process.env[varName] || ""
      }
    )

    return expanded
  }

  /**
   * Validates that an environment variable name matches the standard format
   * Must start with letter or underscore, followed by letters, numbers, or underscores
   * @param name - The variable name to validate
   * @returns true if valid, false otherwise
   */
  private static isValidEnvVarName(name: string): boolean {
    return /^[A-Z_][A-Z0-9_]*$/i.test(name)
  }

  private static convertBundlerEnvToArgs(
    bundlerEnv: Record<string, string | boolean>
  ): string[] {
    const args: string[] = []

    for (const [key, value] of Object.entries(bundlerEnv)) {
      // YAML parser converts boolean true to string "true", so check both
      if (value === true || value === "true") {
        // Boolean true becomes --env key
        args.push("--env", key)
      } else if (typeof value === "string" && value !== "false") {
        // String value becomes --env key=value (skip "false" strings)
        args.push("--env", `${key}=${value}`)
      }
      // false or "false" are ignored
    }

    return args
  }

  /**
   * Lists all available builds from the config file
   * Prints formatted output to console
   * @throws Error if config file doesn't exist or is invalid
   */
  listBuilds(): void {
    const config = this.load()
    const { builds } = config

    console.log(`\nAvailable builds in ${this.configFilePath}:\n`)

    for (const [name, build] of Object.entries(builds)) {
      const bundler =
        build.bundler || config.default_bundler || "webpack (default)"
      const outputs = build.outputs ? build.outputs.join(", ") : "auto-detect"

      console.log(`  ${name}`)
      if (build.description) {
        console.log(`    Description: ${build.description}`)
      }
      console.log(`    Bundler: ${bundler}`)
      console.log(`    Outputs: ${outputs}`)
      console.log()
    }
  }
}

/**
 * Generates a sample configuration file with examples and documentation
 * @returns YAML content as string ready to be written to file
 */
export function generateSampleConfigFile(ssr: boolean = false): string {
  // Using ${'$'} to escape template literal substitution in comments
  if (ssr) {
    return generateSSRConfigFile()
  }

  return `# Bundler Build Configurations
# Generated by: bin/shakapacker-config --init
#
# Run builds with: bin/shakapacker --build <name>
# List builds: bin/shakapacker --list-builds

builds:
  # ===========================================================================
  # DEVELOPMENT WITH HMR (Hot Module Replacement)
  # ===========================================================================
  dev-hmr:
    description: Client bundle with HMR (React Fast Refresh)
    dev_server: true  # Auto-delegates to bin/shakapacker-dev-server
    environment:
      NODE_ENV: development
      RAILS_ENV: development
      WEBPACK_SERVE: true
    outputs:
      - client

  # ===========================================================================
  # DEVELOPMENT (Standard - no HMR)
  # ===========================================================================
  dev:
    description: Development client bundle
    environment:
      NODE_ENV: development
      RAILS_ENV: development
    outputs:
      - client

  # ===========================================================================
  # PRODUCTION
  # ===========================================================================
  prod:
    description: Production client bundle
    environment:
      NODE_ENV: production
      RAILS_ENV: production
    outputs:
      - client

  # ===========================================================================
  # REACT ON RAILS WITH SSR (Uncomment to enable)
  # ===========================================================================
  # Run separate client and server bundles for server-side rendering
  # For more info: https://github.com/shakacode/react_on_rails

  # dev-client-hmr:
  #   description: Development client bundle with HMR for SSR
  #   dev_server: true
  #   environment:
  #     NODE_ENV: development
  #     RAILS_ENV: development
  #     WEBPACK_SERVE: "true"
  #     CLIENT_BUNDLE_ONLY: "yes"
  #   outputs:
  #     - client

  # dev-server:
  #   description: Development server bundle for SSR
  #   environment:
  #     NODE_ENV: development
  #     RAILS_ENV: development
  #     SERVER_BUNDLE_ONLY: "yes"
  #   outputs:
  #     - server

  # prod-client:
  #   description: Production client bundle for SSR
  #   environment:
  #     NODE_ENV: production
  #     RAILS_ENV: production
  #     CLIENT_BUNDLE_ONLY: "yes"
  #   outputs:
  #     - client

  # prod-server:
  #   description: Production server bundle for SSR
  #   environment:
  #     NODE_ENV: production
  #     RAILS_ENV: production
  #     SERVER_BUNDLE_ONLY: "yes"
  #   outputs:
  #     - server

  # ============================================================================
  # ADDITIONAL EXAMPLES
  # ============================================================================

  # Example: Single bundle only (client or server)
  # dev-client-only:
  #   description: Development client bundle only
  #   environment:
  #     NODE_ENV: development
  #     RAILS_ENV: development
  #     CLIENT_BUNDLE_ONLY: "yes"
  #   outputs:
  #     - client

  # Example: Using bundler --env flags
  # prod-modern:
  #   description: Production with custom webpack/rspack --env flags
  #   environment:
  #     NODE_ENV: production
  #     RAILS_ENV: production
  #   bundler_env:
  #     target: modern         # Becomes: --env target=modern
  #     instrumented: true     # Becomes: --env instrumented
  #   outputs:
  #     - client
  #     - server

  # Example: Variable substitution with defaults
  # staging:
  #   description: Staging environment with variable substitution
  #   environment:
  #     NODE_ENV: production
  #     RAILS_ENV: ${"$"}{RAILS_ENV:-staging}  # Use env var or default to 'staging'
  #   outputs:
  #     - client
  #     - server

  # Example: Custom config file path (uses ${"$"}{BUNDLER} substitution)
  # custom-config:
  #   description: Using custom config file location
  #   environment:
  #     NODE_ENV: development
  #   config: config/${"$"}{BUNDLER}/${"$"}{BUNDLER}.config.js
  #   outputs:
  #     - client
  #     - server

# ============================================================================
# USAGE EXAMPLES
# ============================================================================
#
# Initialize this config file:
#   bin/shakapacker-config --init
#
# List all available builds:
#   bin/shakapacker-config --list-builds
#
# Export development build configs:
#   bin/shakapacker-config --build=dev-hmr
#   Creates: rspack-dev-hmr-client.yml
#
#   bin/shakapacker-config --build=dev
#   Creates: rspack-dev-client.yml, rspack-dev-server.yml
#
# Export production build:
#   bin/shakapacker-config --build=prod
#   Creates: rspack-prod-client.yml, rspack-prod-server.yml
#
# Use webpack instead of default rspack:
#   bin/shakapacker-config --build=prod --webpack
#   Creates: webpack-prod-client.yml, webpack-prod-server.yml
#
# Export to stdout for inspection (no files created):
#   bin/shakapacker-config --build=dev --stdout
#
# Export to custom directory:
#   bin/shakapacker-config --build=prod --save-dir=./debug
#
# Doctor mode (comprehensive troubleshooting):
#   bin/shakapacker-config --doctor
#   Creates files in: shakapacker-config-exports/
#
`
}

/**
 * Generates SSR-specific configuration file for React on Rails
 * Includes separate client and server builds for development and production
 * @returns YAML content as string ready to be written to file
 */
function generateSSRConfigFile(): string {
  return `# Bundler Build Configurations for React on Rails with SSR
# Generated by: bin/shakapacker-config --init ssr
#
# Run builds with: bin/shakapacker --build <name>
# List builds: bin/shakapacker --list-builds

builds:
  # ===========================================================================
  # DEVELOPMENT - CLIENT WITH HMR
  # ===========================================================================
  dev-client-hmr:
    description: Development client bundle with HMR for SSR
    dev_server: true  # Auto-delegates to bin/shakapacker-dev-server
    environment:
      NODE_ENV: development
      RAILS_ENV: development
      WEBPACK_SERVE: true
      CLIENT_BUNDLE_ONLY: "yes"
    outputs:
      - client

  # ===========================================================================
  # DEVELOPMENT - CLIENT (Standard - no HMR)
  # ===========================================================================
  dev-client:
    description: Development client bundle for SSR (no HMR)
    environment:
      NODE_ENV: development
      RAILS_ENV: development
      CLIENT_BUNDLE_ONLY: "yes"
    outputs:
      - client

  # ===========================================================================
  # DEVELOPMENT - SERVER
  # ===========================================================================
  dev-server:
    description: Development server bundle for SSR
    environment:
      NODE_ENV: development
      RAILS_ENV: development
      SERVER_BUNDLE_ONLY: "yes"
    outputs:
      - server

  # ===========================================================================
  # PRODUCTION - CLIENT
  # ===========================================================================
  prod-client:
    description: Production client bundle for SSR
    environment:
      NODE_ENV: production
      RAILS_ENV: production
      CLIENT_BUNDLE_ONLY: "yes"
    outputs:
      - client

  # ===========================================================================
  # PRODUCTION - SERVER
  # ===========================================================================
  prod-server:
    description: Production server bundle for SSR
    environment:
      NODE_ENV: production
      RAILS_ENV: production
      SERVER_BUNDLE_ONLY: "yes"
    outputs:
      - server

# ==============================================================================
# USAGE EXAMPLES
# ==============================================================================
#
# Development with HMR:
#   bin/shakapacker --build dev-client-hmr  # Client with HMR
#   bin/shakapacker --build dev-server      # Server bundle
#
# Development without HMR:
#   bin/shakapacker --build dev-client      # Client bundle
#   bin/shakapacker --build dev-server      # Server bundle
#
# Production:
#   bin/shakapacker --build prod-client     # Client bundle
#   bin/shakapacker --build prod-server     # Server bundle
#
# For more info on React on Rails with SSR:
#   https://github.com/shakacode/react_on_rails
#
`
}
