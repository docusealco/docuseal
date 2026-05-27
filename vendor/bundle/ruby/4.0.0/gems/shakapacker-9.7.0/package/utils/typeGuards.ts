import { Config, DevServerConfig, YamlConfig } from "../types"
import { isPathTraversalSafe, validatePort } from "./pathValidation"

// Cache for validated configs with TTL
interface CacheEntry {
  result: boolean
  timestamp: number
  configHash?: string
}

let validatedConfigs = new WeakMap<object, CacheEntry>()

// Cache computed values to avoid repeated checks
let cachedIsWatchMode: boolean | null = null
let cachedCacheTTL: number | null = null

/**
 * Detect if running in watch mode (cached)
 */
function isWatchMode(): boolean {
  if (cachedIsWatchMode === null) {
    cachedIsWatchMode =
      process.argv.includes("--watch") || process.env.WEBPACK_WATCH === "true"
  }
  return cachedIsWatchMode
}

/**
 * Get cache TTL based on environment (cached)
 */
function getCacheTTL(): number {
  if (cachedCacheTTL === null) {
    if (process.env.SHAKAPACKER_CACHE_TTL) {
      cachedCacheTTL = parseInt(process.env.SHAKAPACKER_CACHE_TTL, 10)
    } else if (process.env.NODE_ENV === "production" && !isWatchMode()) {
      cachedCacheTTL = Infinity
    } else if (isWatchMode()) {
      cachedCacheTTL = 5000 // 5 seconds in watch mode
    } else {
      cachedCacheTTL = 60000 // 1 minute in dev
    }
  }
  return cachedCacheTTL
}

// Only validate in development or when explicitly enabled
function shouldValidate(): boolean {
  return (
    process.env.NODE_ENV !== "production" ||
    process.env.SHAKAPACKER_STRICT_VALIDATION === "true"
  )
}

// Debug logging for cache operations
const debugCache = process.env.SHAKAPACKER_DEBUG_CACHE === "true"

/**
 * Clear the validation cache
 * Useful for testing or when config files change
 */
export function clearValidationCache(): void {
  // Reassign to a new WeakMap to clear all entries
  validatedConfigs = new WeakMap<object, CacheEntry>()
  if (debugCache) {
    console.log("[SHAKAPACKER DEBUG] Validation cache cleared")
  }
}

/**
 * Type guard to validate DevServerConfig object at runtime
 * In production, performs minimal validation for performance
 */
export function isValidDevServerConfig(obj: unknown): obj is DevServerConfig {
  if (typeof obj !== "object" || obj === null) {
    return false
  }

  // In production, skip deep validation unless explicitly enabled
  if (!shouldValidate()) {
    return true
  }

  const config = obj as Record<string, unknown>

  // All fields are optional, just check types if present
  if (
    config.hmr !== undefined &&
    typeof config.hmr !== "boolean" &&
    config.hmr !== "only"
  ) {
    return false
  }

  if (config.port !== undefined && !validatePort(config.port)) {
    return false
  }

  return true
}

/**
 * Type guard to validate Config object at runtime
 * In production, caches results for performance unless SHAKAPACKER_STRICT_VALIDATION is set
 *
 * IMPORTANT: Path traversal security checks ALWAYS run regardless of environment or validation mode.
 * This ensures application security is never compromised for performance.
 */
export function isValidConfig(obj: unknown): obj is Config {
  if (typeof obj !== "object" || obj === null) {
    return false
  }

  // Check cache with TTL
  const cached = validatedConfigs.get(obj)
  if (cached && Date.now() - cached.timestamp < getCacheTTL()) {
    if (debugCache) {
      console.log(
        `[SHAKAPACKER DEBUG] Config validation cache hit (result: ${cached.result})`
      )
    }
    return cached.result
  }

  const config = obj as Record<string, unknown>

  // Check required string fields
  const requiredStringFields = [
    "source_path",
    "source_entry_path",
    "public_root_path",
    "public_output_path",
    "cache_path",
    "javascript_transpiler"
  ]

  for (const field of requiredStringFields) {
    if (typeof config[field] !== "string") {
      // Cache negative result
      validatedConfigs.set(obj, {
        result: false,
        timestamp: Date.now()
      })
      return false
    }
    // SECURITY: Path traversal validation ALWAYS runs (not subject to shouldValidate)
    // This ensures paths are safe regardless of environment or validation mode
    if (field.includes("path") && !isPathTraversalSafe(config[field])) {
      console.warn(
        `[SHAKAPACKER SECURITY] Invalid path in ${field}: ${config[field]}`
      )
      validatedConfigs.set(obj, {
        result: false,
        timestamp: Date.now()
      })
      return false
    }
  }

  // Check required boolean fields
  const requiredBooleanFields = [
    "nested_entries",
    "css_extract_ignore_order_warnings",
    "webpack_compile_output",
    "shakapacker_precompile",
    "cache_manifest",
    "ensure_consistent_versioning",
    "useContentHash",
    "compile"
  ]

  for (const field of requiredBooleanFields) {
    if (typeof config[field] !== "boolean") {
      // Cache negative result
      validatedConfigs.set(obj, {
        result: false,
        timestamp: Date.now()
      })
      return false
    }
  }

  // Check arrays
  if (!Array.isArray(config.additional_paths)) {
    // Cache negative result
    validatedConfigs.set(obj, {
      result: false,
      timestamp: Date.now()
    })
    return false
  }

  // SECURITY: Path traversal validation for additional_paths ALWAYS runs (not subject to shouldValidate)
  // This critical security check ensures user-provided paths cannot escape the project directory
  for (const additionalPath of config.additional_paths as string[]) {
    if (!isPathTraversalSafe(additionalPath)) {
      console.warn(
        `[SHAKAPACKER SECURITY] Invalid additional_path: ${additionalPath}`
      )
      validatedConfigs.set(obj, {
        result: false,
        timestamp: Date.now()
      })
      return false
    }
  }

  // In production, skip deep validation of optional fields unless explicitly enabled
  // Security checks above still run regardless of this flag
  if (!shouldValidate()) {
    // Cache positive result - basic structure and security validated
    validatedConfigs.set(obj, { result: true, timestamp: Date.now() })
    return true
  }

  // Deep validation of optional fields (only in development or with SHAKAPACKER_STRICT_VALIDATION=true)
  if (
    config.dev_server !== undefined &&
    !isValidDevServerConfig(config.dev_server)
  ) {
    // Cache negative result
    validatedConfigs.set(obj, {
      result: false,
      timestamp: Date.now()
    })
    return false
  }

  if (config.integrity !== undefined) {
    const integrity = config.integrity as Record<string, unknown>
    if (
      typeof integrity.enabled !== "boolean" ||
      typeof integrity.cross_origin !== "string"
    ) {
      // Cache negative result
      validatedConfigs.set(obj, {
        result: false,
        timestamp: Date.now()
      })
      return false
    }
  }

  // Cache positive result
  validatedConfigs.set(obj, { result: true, timestamp: Date.now() })

  return true
}

/**
 * Type guard to validate Rspack plugin instance
 * Checks if an object looks like a valid Rspack plugin
 */
export function isValidRspackPlugin(obj: unknown): boolean {
  if (typeof obj !== "object" || obj === null) {
    return false
  }

  const plugin = obj as Record<string, unknown>

  // Check for common plugin patterns
  // Most rspack plugins should have an apply method
  if (typeof plugin.apply === "function") {
    return true
  }

  // Check for constructor name pattern (e.g., HtmlRspackPlugin)
  const constructorName = plugin.constructor?.name || ""
  if (
    constructorName.includes("Plugin") ||
    constructorName.includes("Rspack")
  ) {
    return true
  }

  // Check for common plugin properties
  if ("name" in plugin && typeof plugin.name === "string") {
    return true
  }

  return false
}

/**
 * Type guard to validate array of Rspack plugins
 * Ensures all items in the array are valid plugin instances
 */
export function isValidRspackPluginArray(arr: unknown): boolean {
  if (!Array.isArray(arr)) {
    return false
  }

  return arr.every((item) => isValidRspackPlugin(item))
}

/**
 * Type guard to validate YamlConfig structure
 * In production, performs minimal validation for performance
 */
export function isValidYamlConfig(obj: unknown): obj is YamlConfig {
  if (typeof obj !== "object" || obj === null) {
    return false
  }

  // In production, skip deep validation unless explicitly enabled
  if (!shouldValidate()) {
    return true
  }

  const config = obj as Record<string, unknown>

  // Each key should map to an object
  for (const env of Object.keys(config)) {
    if (typeof config[env] !== "object" || config[env] === null) {
      return false
    }
  }

  return true
}

/**
 * Validates partial config used for merging
 * Ensures that if fields are present, they have the correct types
 * In production, performs minimal validation for performance
 */
export function isPartialConfig(obj: unknown): obj is Partial<Config> {
  if (typeof obj !== "object" || obj === null) {
    return false
  }

  // In production, skip deep validation unless explicitly enabled
  if (!shouldValidate()) {
    return true
  }

  const config = obj as Record<string, unknown>

  // Check string fields if present
  const stringFields = [
    "source_path",
    "source_entry_path",
    "public_root_path",
    "public_output_path",
    "cache_path",
    "javascript_transpiler"
  ]

  for (const field of stringFields) {
    if (field in config && typeof config[field] !== "string") {
      return false
    }
  }

  // Check boolean fields if present
  const booleanFields = [
    "nested_entries",
    "css_extract_ignore_order_warnings",
    "webpack_compile_output",
    "shakapacker_precompile",
    "cache_manifest",
    "ensure_consistent_versioning"
  ]

  for (const field of booleanFields) {
    if (field in config && typeof config[field] !== "boolean") {
      return false
    }
  }

  // Check arrays if present
  if ("additional_paths" in config && !Array.isArray(config.additional_paths)) {
    return false
  }

  return true
}

/**
 * Creates a validation error with helpful context
 */
export function createConfigValidationError(
  configPath: string,
  environment: string,
  details?: string
): Error {
  const message = `Invalid configuration in ${configPath} for environment '${environment}'`
  return new Error(details ? `${message}: ${details}` : message)
}
