import { spawn } from "child_process"
import { existsSync } from "fs"
import { resolve, relative } from "path"
import { ResolvedBuildConfig, BuildValidationResult } from "./types"

export interface ValidatorOptions {
  verbose: boolean
  timeout?: number // milliseconds
  strictBinaryResolution?: boolean // If true, fail if binaries not found locally (recommended for CI)
  maxConcurrentBuilds?: number // Maximum number of builds to validate concurrently
}

/**
 * Maximum buffer size for stdout/stderr to prevent memory exhaustion
 */
const MAX_BUFFER_SIZE = 10 * 1024 * 1024 // 10MB

/**
 * Default timeout for build validation in milliseconds
 */
const DEFAULT_TIMEOUT_MS = 120000 // 2 minutes

/**
 * Safety timeout after SIGTERM before forcing resolution (milliseconds)
 */
const KILL_SAFETY_TIMEOUT_MS = 5000 // 5 seconds

/**
 * Exit code for SIGTERM signal
 */
const SIGTERM_EXIT_CODE = 143

/**
 * TypeScript interface for webpack/rspack JSON output structure
 */
interface WebpackJsonOutput {
  errors?: Array<string | { message: string }>
  warnings?: Array<string | { message: string }>
  hash?: string
  time?: number
  builtAt?: number
  outputPath?: string
}

/**
 * Whitelisted environment variables that are safe to pass to build processes.
 * This prevents arbitrary environment variable injection from config files.
 *
 * Note: PATH is essential for webpack/rspack to find node and other binaries.
 * HOME is needed for tools that read user config (e.g., .npmrc, .yarnrc).
 */
const SAFE_ENV_VARS = [
  "PATH",
  "HOME",
  "NODE_ENV",
  "RAILS_ENV",
  "NODE_OPTIONS",
  "BABEL_ENV",
  "WEBPACK_SERVE",
  "HMR",
  "CLIENT_BUNDLE_ONLY",
  "SERVER_BUNDLE_ONLY",
  "PUBLIC_URL",
  "ASSET_HOST",
  "CDN_HOST",
  "TMPDIR",
  "TEMP",
  "TMP"
] as const

/**
 * Success patterns for detecting successful compilation in webpack/rspack output.
 * These patterns are used to determine when webpack-dev-server has successfully
 * compiled and is ready to serve, or when a static build has completed.
 *
 * Note: Patterns use substring matching, not exact matching, to support version variations.
 * For example, "webpack 5." matches "webpack 5.95.0 compiled successfully"
 *
 * Patterns are checked after excluding lines starting with ERROR: or WARNING:
 * to prevent false positives in error messages.
 */
const SUCCESS_PATTERNS = [
  "webpack compiled",
  "Compiled successfully",
  "rspack compiled successfully",
  "webpack: Compiled successfully",
  "Compilation completed",
  "wds: Compiled successfully", // webpack-dev-server 4.x
  "webpack-dev-server: Compiled", // webpack-dev-server 5.x
  "[webpack-dev-server] Compiled successfully", // webpack-dev-server 5.x alternative format
  "webpack 5.", // matches "webpack 5.95.0 compiled successfully" (any 5.x.x version)
  "rspack 0.", // matches "rspack 0.7.5 compiled successfully" (any 0.x.x version)
  "rspack-dev-server: Compiled" // rspack-dev-server output
]

/**
 * Error patterns for detecting compilation errors in webpack/rspack output
 */
const ERROR_PATTERNS = ["ERROR", "Error:", "Failed to compile"]

/**
 * Warning patterns for detecting compilation warnings in webpack/rspack output
 */
const WARNING_PATTERNS = ["WARNING", "Warning:"]

/**
 * Pattern to detect suspicious characters in environment variable values
 * that could indicate command injection attempts
 */
const SUSPICIOUS_ENV_PATTERN = /[;&|`$()]/

/**
 * Validates webpack/rspack builds by running them and checking for errors
 * For HMR builds, starts webpack-dev-server and shuts down after successful start
 */
export class BuildValidator {
  private options: ValidatorOptions

  constructor(options: ValidatorOptions) {
    this.options = {
      verbose: options.verbose,
      timeout: options.timeout || DEFAULT_TIMEOUT_MS,
      strictBinaryResolution:
        options.strictBinaryResolution ||
        process.env.CI === "true" ||
        process.env.GITHUB_ACTIONS === "true",
      maxConcurrentBuilds: options.maxConcurrentBuilds || 3
    }
  }

  /**
   * Filters environment variables to only include whitelisted safe variables.
   * This prevents command injection and limits exposure of sensitive data.
   * Also validates environment variable values for suspicious patterns.
   */
  private filterEnvironment(
    buildEnv: Record<string, string>
  ): Record<string, string> {
    const filtered: Record<string, string> = {}

    // Start with current process.env but only whitelisted vars
    SAFE_ENV_VARS.forEach((key) => {
      if (process.env[key]) {
        filtered[key] = process.env[key]!
      }
    })

    // Override with build-specific env vars (also filtered)
    Object.entries(buildEnv).forEach(([key, value]) => {
      if ((SAFE_ENV_VARS as readonly string[]).includes(key)) {
        // Validate for suspicious patterns that could indicate command injection
        if (SUSPICIOUS_ENV_PATTERN.test(value)) {
          if (this.options.verbose) {
            console.warn(
              `   [Security Warning] Suspicious pattern detected in environment variable ${key}: ${value}`
            )
          }
        }
        filtered[key] = value
      }
    })

    return filtered
  }

  /**
   * Validates that a config file exists and returns the resolved path.
   * Throws an error if the config file is not found or attempts path traversal.
   *
   * @param configFile - The config file path from the build configuration
   * @param appRoot - The application root directory
   * @param buildName - The name of the build (for error messages)
   * @returns The resolved absolute path to the config file
   * @throws Error if the config file does not exist or is outside appRoot
   */
  private static validateConfigPath(
    configFile: string,
    appRoot: string,
    buildName: string
  ): string {
    const configPath = resolve(appRoot, configFile)

    // Security: Ensure resolved path is within appRoot using path.relative
    // This works cross-platform (Windows/Unix) and prevents path traversal attacks
    const rel = relative(appRoot, configPath)

    // Path is valid if:
    // 1. rel === "" (same as appRoot) OR
    // 2. rel doesn't start with ".." (not outside appRoot)
    // Note: On Windows, ".." will be used for parent dir regardless of path separator
    if (rel !== "" && rel.startsWith("..")) {
      throw new Error(
        `Invalid config file path for build '${buildName}': Path must be within project directory. ` +
          `Config file: ${configFile}, Resolved path: ${configPath}, Project root: ${appRoot}`
      )
    }

    if (!existsSync(configPath)) {
      throw new Error(
        `Config file not found for build '${buildName}': ${configPath}. ` +
          `Check the 'config' setting in your build configuration.`
      )
    }

    return configPath
  }

  /**
   * Validates a single build configuration by running the appropriate bundler command.
   * For HMR builds, starts webpack-dev-server and validates successful compilation.
   * For static builds, runs a full build and validates the output.
   *
   * @param build - The resolved build configuration to validate
   * @param appRoot - The application root directory
   * @returns A promise that resolves to the build validation result
   */
  async validateBuild(
    build: ResolvedBuildConfig,
    appRoot: string
  ): Promise<BuildValidationResult> {
    // Detect HMR builds by checking for WEBPACK_SERVE or HMR environment variables
    const isHMR =
      build.environment.WEBPACK_SERVE === "true" ||
      build.environment.HMR === "true"
    const { bundler } = build

    if (isHMR) {
      return this.validateHMRBuild(build, appRoot, bundler)
    }
    return this.validateStaticBuild(build, appRoot, bundler)
  }

  /**
   * Validates an HMR build by starting webpack-dev-server
   * Waits for successful compilation, then shuts down
   */
  private async validateHMRBuild(
    build: ResolvedBuildConfig,
    appRoot: string,
    bundler: "webpack" | "rspack"
  ): Promise<BuildValidationResult> {
    const startTime = Date.now()
    const result: BuildValidationResult = {
      buildName: build.name,
      success: false,
      errors: [],
      warnings: [],
      output: [],
      outputs: build.outputs,
      configFile: build.configFile,
      startTime
    }

    // Determine the dev server command
    const devServerCmd =
      bundler === "rspack" ? "rspack-dev-server" : "webpack-dev-server"
    const devServerBin = this.findBinary(devServerCmd, appRoot)

    if (!devServerBin) {
      const packageManager = existsSync(resolve(appRoot, "yarn.lock"))
        ? "yarn add"
        : "npm install"
      result.errors.push(
        `Could not find ${devServerCmd} binary. Please install it:\n` +
          `   ${packageManager} -D ${bundler}-dev-server`
      )
      return result
    }

    // Build arguments
    const args: string[] = []

    // Add config file if specified
    if (build.configFile) {
      try {
        const configPath = BuildValidator.validateConfigPath(
          build.configFile,
          appRoot,
          build.name
        )
        args.push("--config", configPath)
      } catch (error) {
        const errorMessage =
          error instanceof Error ? error.message : String(error)
        result.errors.push(errorMessage)
        return result
      }
    } else {
      // Use default config path
      const defaultConfig = resolve(
        appRoot,
        `config/${bundler}/${bundler}.config.js`
      )
      if (existsSync(defaultConfig)) {
        args.push("--config", defaultConfig)
      }
    }

    // Add bundler env args (--env flags)
    if (build.bundlerEnvArgs && build.bundlerEnvArgs.length > 0) {
      args.push(...build.bundlerEnvArgs)
    }

    return new Promise((resolvePromise) => {
      const child = spawn(devServerBin, args, {
        cwd: appRoot,
        env: this.filterEnvironment(build.environment),
        stdio: ["ignore", "pipe", "pipe"]
      })

      let hasCompiled = false
      let hasError = false
      let resolved = false
      let processKilled = false

      const resolveOnce = (res: BuildValidationResult) => {
        if (!resolved) {
          resolved = true
          resolvePromise(res)
        }
      }

      const timeoutId = setTimeout(() => {
        if (!hasCompiled && !resolved && !processKilled) {
          result.errors.push(
            `Timeout: webpack-dev-server did not compile within ${this.options.timeout}ms.`
          )
          processKilled = true
          child.kill("SIGTERM")
          // Remove listeners to prevent further callbacks
          child.stdout?.removeAllListeners()
          child.stderr?.removeAllListeners()
          child.removeAllListeners()
          resolveOnce(result)
        }
      }, this.options.timeout)

      const processOutput = (data: Buffer) => {
        const lines = data.toString().split("\n")
        lines.forEach((line) => {
          if (!line.trim()) return

          // Always output in real-time in verbose mode so user sees progress
          if (this.options.verbose) {
            console.log(`   ${line}`)
          }

          // Store all output
          result.output.push(line)

          // Check for successful compilation
          // Only match success patterns if the line doesn't start with ERROR: or WARNING:
          const isErrorOrWarning =
            line.trim().startsWith("ERROR") || line.trim().startsWith("WARNING")
          if (
            !processKilled &&
            !isErrorOrWarning &&
            SUCCESS_PATTERNS.some((pattern) => line.includes(pattern))
          ) {
            hasCompiled = true
            result.success = true
            // Set processKilled BEFORE clearing timeout to prevent race condition
            // where timeout could fire between clearTimeout and setting the flag
            processKilled = true
            clearTimeout(timeoutId)
            child.kill("SIGTERM")
            // Don't call resolveOnce here - let the exit handler do it
            // This ensures proper cleanup order and avoids race conditions

            // Safety timeout: if process doesn't exit within 5 seconds, force resolve
            // This prevents hanging if kill() fails or process is unresponsive
            setTimeout(() => {
              if (!resolved) {
                if (this.options.verbose) {
                  console.warn(
                    `   [Warning] Process did not exit after SIGTERM, forcing resolution.`
                  )
                }
                child.stdout?.removeAllListeners()
                child.stderr?.removeAllListeners()
                child.removeAllListeners()
                resolveOnce(result)
              }
            }, KILL_SAFETY_TIMEOUT_MS)
          }

          // Check for errors
          if (ERROR_PATTERNS.some((pattern) => line.includes(pattern))) {
            hasError = true
            result.errors.push(line)
          }

          // Check for warnings
          if (WARNING_PATTERNS.some((pattern) => line.includes(pattern))) {
            result.warnings.push(line)
          }
        })
      }

      child.stdout?.on("data", (data: Buffer) => processOutput(data))
      child.stderr?.on("data", (data: Buffer) => processOutput(data))

      child.on("exit", (code) => {
        clearTimeout(timeoutId)
        // Clean up listeners after exit
        child.stdout?.removeAllListeners()
        child.stderr?.removeAllListeners()
        child.removeAllListeners()

        // Record timing
        result.endTime = Date.now()
        result.duration = result.endTime - (result.startTime || result.endTime)

        if (!hasCompiled && !hasError && !resolved) {
          if (code !== 0 && code !== null && code !== SIGTERM_EXIT_CODE) {
            result.errors.push(
              `${devServerCmd} exited with code ${code} before compilation completed.`
            )
          }
        }
        resolveOnce(result)
      })

      child.on("error", (err) => {
        clearTimeout(timeoutId)
        // Provide more helpful error messages for common spawn failures
        let errorMessage = `Failed to start ${devServerCmd}: ${err.message}`

        // Check for specific error codes and provide actionable guidance
        if ("code" in err) {
          const { code } = err as NodeJS.ErrnoException
          if (code === "ENOENT") {
            errorMessage += `. Binary not found. Install with: npm install -D ${devServerCmd}`
          } else if (code === "EMFILE" || code === "ENFILE") {
            errorMessage += `. Too many open files. Increase system file descriptor limit or reduce concurrent builds`
          } else if (code === "EACCES") {
            errorMessage += `. Permission denied. Check file permissions for the binary`
          }
        }

        result.errors.push(errorMessage)
        resolveOnce(result)
      })
    })
  }

  /**
   * Validates a static build by running webpack/rspack in production mode
   * Uses --json flag to get structured output
   */
  private async validateStaticBuild(
    build: ResolvedBuildConfig,
    appRoot: string,
    bundler: "webpack" | "rspack"
  ): Promise<BuildValidationResult> {
    const startTime = Date.now()
    const result: BuildValidationResult = {
      buildName: build.name,
      success: false,
      errors: [],
      warnings: [],
      output: [],
      outputs: build.outputs,
      configFile: build.configFile,
      startTime
    }

    const bundlerBin = this.findBinary(bundler, appRoot)

    if (!bundlerBin) {
      const packageManager = existsSync(resolve(appRoot, "yarn.lock"))
        ? "yarn add"
        : "npm install"
      result.errors.push(
        `Could not find ${bundler} binary. Please install it:\n` +
          `   ${packageManager} -D ${bundler}`
      )
      return result
    }

    // Build arguments - use --dry-run if available, otherwise just build
    const args: string[] = []

    // Add config file if specified
    if (build.configFile) {
      try {
        const configPath = BuildValidator.validateConfigPath(
          build.configFile,
          appRoot,
          build.name
        )
        args.push("--config", configPath)
      } catch (error) {
        const errorMessage =
          error instanceof Error ? error.message : String(error)
        result.errors.push(errorMessage)
        return result
      }
    } else {
      // Use default config path
      const defaultConfig = resolve(
        appRoot,
        `config/${bundler}/${bundler}.config.js`
      )
      if (existsSync(defaultConfig)) {
        args.push("--config", defaultConfig)
      }
    }

    // Add bundler env args (--env flags)
    if (build.bundlerEnvArgs && build.bundlerEnvArgs.length > 0) {
      args.push(...build.bundlerEnvArgs)
    }

    // Add --json for structured output (helps parse errors)
    args.push("--json")

    return new Promise((resolvePromise) => {
      const child = spawn(bundlerBin, args, {
        cwd: appRoot,
        env: this.filterEnvironment(build.environment),
        stdio: ["ignore", "pipe", "pipe"]
      })

      const stdoutChunks: Buffer[] = []
      const stderrChunks: Buffer[] = []

      let stdoutSize = 0
      let stderrSize = 0
      let bufferOverflow = false

      const timeoutId = setTimeout(() => {
        result.errors.push(
          `Timeout: ${bundler} did not complete within ${this.options.timeout}ms.`
        )
        child.kill("SIGTERM")
        resolvePromise(result)
      }, this.options.timeout)

      child.stdout?.on("data", (data: Buffer) => {
        // Check buffer size to prevent memory issues
        if (stdoutSize + data.length > MAX_BUFFER_SIZE) {
          if (!bufferOverflow) {
            bufferOverflow = true
            const warning = `Output buffer limit exceeded (${MAX_BUFFER_SIZE / 1024 / 1024}MB). Build output is too large - data will be truncated.`
            result.warnings.push(warning)
            if (this.options.verbose) {
              console.warn(`   [Warning] ${warning}`)
            }
          }
          // Explicitly skip this chunk - don't silently drop
          return
        }

        stdoutChunks.push(data)
        stdoutSize += data.length

        // Don't output JSON in verbose mode - it's too large and not useful
        // JSON is for parsing errors, not for human consumption
      })

      child.stderr?.on("data", (data: Buffer) => {
        // Check buffer size
        if (stderrSize + data.length > MAX_BUFFER_SIZE) {
          if (!bufferOverflow) {
            bufferOverflow = true
            const warning = `Error output buffer limit exceeded (${MAX_BUFFER_SIZE / 1024 / 1024}MB). Build errors are too large - data will be truncated.`
            result.warnings.push(warning)
            if (this.options.verbose) {
              console.warn(`   [Warning] ${warning}`)
            }
          }
          // Explicitly skip this chunk - don't silently drop
          return
        }

        stderrChunks.push(data)
        stderrSize += data.length

        // In verbose mode, show useful stderr output (warnings, progress, etc.)
        if (this.options.verbose) {
          const output = data.toString()
          // Only show meaningful output, not just noise
          const lines = output.split("\n")
          lines.forEach((line) => {
            if (line.trim()) {
              console.log(`   ${line}`)
            }
          })
        }
      })

      child.on("exit", (code) => {
        clearTimeout(timeoutId)

        // Record timing
        result.endTime = Date.now()
        result.duration = result.endTime - (result.startTime || result.endTime)

        // Combine chunks into strings
        const stdoutData = Buffer.concat(stdoutChunks).toString()
        const stderrData = Buffer.concat(stderrChunks).toString()

        // Parse JSON output
        try {
          const jsonOutput = JSON.parse(stdoutData) as WebpackJsonOutput

          // Extract output path if available
          if (jsonOutput.outputPath) {
            result.outputPath = jsonOutput.outputPath
          }

          // Check for errors in webpack/rspack JSON output
          if (jsonOutput.errors && jsonOutput.errors.length > 0) {
            jsonOutput.errors.forEach((error) => {
              let errorMsg: string
              if (typeof error === "string") {
                errorMsg = error
              } else if (error.message) {
                errorMsg = error.message
              } else {
                // Attempt to extract useful info from malformed error using all enumerable props
                try {
                  errorMsg = JSON.stringify(
                    error,
                    Object.getOwnPropertyNames(error)
                  )
                } catch {
                  errorMsg = "[Error object with no message]"
                }
              }
              result.errors.push(errorMsg)
              // Also add to output for visibility
              if (!this.options.verbose) {
                result.output.push(errorMsg)
              }
            })
          }

          // Check for warnings
          if (jsonOutput.warnings && jsonOutput.warnings.length > 0) {
            jsonOutput.warnings.forEach((warning) => {
              let warningMsg: string
              if (typeof warning === "string") {
                warningMsg = warning
              } else if (warning.message) {
                warningMsg = warning.message
              } else {
                // Attempt to extract useful info from malformed warning using all enumerable props
                try {
                  warningMsg = JSON.stringify(
                    warning,
                    Object.getOwnPropertyNames(warning)
                  )
                } catch {
                  warningMsg = "[Warning object with no message]"
                }
              }
              result.warnings.push(warningMsg)
            })
          }

          result.success =
            code === 0 && (!jsonOutput.errors || jsonOutput.errors.length === 0)

          // If build failed but no errors were captured, add helpful message
          if (code !== 0 && result.errors.length === 0) {
            result.errors.push(
              `${bundler} exited with code ${code} but no errors were captured. ` +
                `This may indicate a configuration issue. Run with --verbose for full output.`
            )
          }
        } catch (err) {
          // If JSON parsing fails, log the parsing error in verbose mode
          if (this.options.verbose) {
            const parseError = err instanceof Error ? err.message : String(err)
            console.log(`   [Debug] Failed to parse JSON output: ${parseError}`)
          }

          // Fall back to stderr analysis
          if (stderrData && stderrData.length > 0) {
            const lines = stderrData.split("\n")
            lines.forEach((line) => {
              if (ERROR_PATTERNS.some((pattern) => line.includes(pattern))) {
                result.errors.push(line)
              }
              if (WARNING_PATTERNS.some((pattern) => line.includes(pattern))) {
                result.warnings.push(line)
              }
            })
          }

          if (code !== 0) {
            result.errors.push(`${bundler} exited with code ${code}.`)
          }

          result.success = code === 0 && result.errors.length === 0
        }

        // Add stderr to output if there were errors and not verbose
        if (
          !this.options.verbose &&
          result.errors.length > 0 &&
          stderrData &&
          stderrData.length > 0
        ) {
          result.output.push(stderrData)
        }

        resolvePromise(result)
      })

      child.on("error", (err) => {
        clearTimeout(timeoutId)
        // Provide more helpful error messages for common spawn failures
        let errorMessage = `Failed to start ${bundler}: ${err.message}`

        // Check for specific error codes and provide actionable guidance
        if ("code" in err) {
          const { code } = err as NodeJS.ErrnoException
          if (code === "ENOENT") {
            errorMessage += `. Binary not found. Install with: npm install -D ${bundler}`
          } else if (code === "EMFILE" || code === "ENFILE") {
            errorMessage += `. Too many open files. Increase system file descriptor limit or reduce concurrent builds`
          } else if (code === "EACCES") {
            errorMessage += `. Permission denied. Check file permissions for the binary`
          }
        }

        result.errors.push(errorMessage)
        resolvePromise(result)
      })
    })
  }

  /**
   * Finds the binary for webpack, rspack, or dev servers.
   * Prefers local node_modules/.bin installation for security.
   * Falls back to global installation and PATH resolution with a warning in verbose mode.
   *
   * SECURITY NOTE: The PATH fallback allows resolving binaries from the system PATH,
   * which could be a security risk in untrusted environments where an attacker could
   * manipulate the PATH environment variable. This fallback is included for flexibility
   * and backward compatibility with systems that use npx or have binaries installed in
   * non-standard locations. In production CI/CD environments, ensure binaries are
   * installed locally in node_modules to avoid PATH resolution.
   *
   * @param name - The binary name to find (e.g., "webpack", "webpack-dev-server")
   * @param appRoot - The application root directory
   * @returns The path to the binary, or the bare name for PATH resolution
   */
  private findBinary(name: string, appRoot: string): string | null {
    // Try node_modules/.bin (preferred for security)
    const nodeModulesBin = resolve(appRoot, "node_modules", ".bin", name)
    if (existsSync(nodeModulesBin)) {
      return nodeModulesBin
    }

    // Try global installation
    const globalBin = resolve("/usr/local/bin", name)
    if (existsSync(globalBin)) {
      if (this.options.verbose) {
        console.log(
          `   [Security Warning] Using global ${name} from /usr/local/bin. ` +
            `Consider installing locally: npm install -D ${name}`
        )
      }
      return globalBin
    }

    // Fall back to PATH resolution (least secure but most flexible)
    // SECURITY: This allows the binary to be found via PATH, which could be
    // exploited if an attacker controls the PATH environment variable.

    // In strict mode (CI environments), fail instead of falling back to PATH
    if (this.options.strictBinaryResolution) {
      return null // Caller will handle the error
    }

    if (this.options.verbose) {
      console.log(
        `   [Security Warning] Binary '${name}' not found locally. ` +
          `Falling back to PATH resolution. In production, install locally: npm install -D ${name}`
      )
    }

    // Return the bare binary name to use PATH resolution
    // This maintains backward compatibility with npx and non-standard installations
    return name
  }

  /**
   * Formats validation results for display in the terminal.
   * Shows a summary of all builds with success/failure status,
   * error messages, warnings, and optional output logs.
   *
   * @param results - Array of validation results from all builds
   * @returns Formatted string ready for console output
   */
  formatResults(results: BuildValidationResult[]): string {
    const lines: string[] = []

    lines.push(`\n${"=".repeat(80)}`)
    lines.push("🔍 Build Validation Results")
    lines.push(`${"=".repeat(80)}\n`)

    const totalBuilds = results.length
    let successCount = 0
    let failureCount = 0

    results.forEach((result) => {
      if (result.success) {
        successCount += 1
      } else {
        failureCount += 1
      }

      const icon = result.success ? "✅" : "❌"

      // Format timing information
      let timingInfo = ""
      if (result.duration !== undefined) {
        const seconds = (result.duration / 1000).toFixed(2)
        timingInfo = ` (${seconds}s)`
      }

      lines.push(`${icon} Build: ${result.buildName}${timingInfo}`)

      // Show outputs (client/server bundles)
      if (result.outputs && result.outputs.length > 0) {
        lines.push(`   📦 Outputs: ${result.outputs.join(", ")}`)
      }

      // Show config file if specified
      if (result.configFile) {
        lines.push(`   ⚙️  Config: ${result.configFile}`)
      }

      // Show output directory if available
      if (result.outputPath) {
        lines.push(`   📁 Output: ${result.outputPath}`)
      }

      if (result.warnings.length > 0) {
        lines.push(`   ⚠️  ${result.warnings.length} warning(s)`)
      }

      if (result.errors.length > 0) {
        lines.push(`   ❌ ${result.errors.length} error(s)`)
        result.errors.forEach((error) => {
          lines.push(`      ${error}`)
        })
      }

      // Always show output if there are errors (unless verbose already showing it)
      if (
        result.output.length > 0 &&
        (this.options.verbose || result.errors.length > 0)
      ) {
        lines.push("\n   Full Output:")
        result.output.forEach((line) => {
          lines.push(`   ${line}`)
        })
      }

      lines.push("")
    })

    lines.push("=".repeat(80))

    // Calculate total time
    const totalDuration = results.reduce((sum, r) => sum + (r.duration || 0), 0)
    const totalSeconds = (totalDuration / 1000).toFixed(2)

    lines.push(
      `Summary: ${successCount}/${totalBuilds} builds passed, ${failureCount} failed (Total: ${totalSeconds}s)`
    )
    lines.push("=".repeat(80))

    // Add debugging guidance if there are failures
    if (failureCount > 0) {
      lines.push("\n💡 Debugging Tips:")
      lines.push(
        "   To get more details, run individual builds with --verbose:"
      )
      lines.push("")

      const failedBuilds = results.filter((r) => !r.success)
      failedBuilds.forEach((result) => {
        lines.push(
          `   bin/shakapacker-config --validate-build ${result.buildName} --verbose`
        )
      })

      lines.push("")
      lines.push(
        "   Or validate all builds with full output: bin/shakapacker-config --validate --verbose"
      )
      lines.push("=".repeat(80))
    }

    lines.push("")

    return lines.join("\n")
  }
}
