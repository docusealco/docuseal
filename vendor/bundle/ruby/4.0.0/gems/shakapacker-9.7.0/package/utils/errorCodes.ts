/**
 * Error codes for programmatic error handling in Shakapacker
 * These codes allow consumers to handle specific errors programmatically
 * @module shakapacker/utils/errorCodes
 */

/**
 * Error code enumeration for Shakapacker errors
 */
export enum ErrorCode {
  // Configuration errors (1xxx)
  CONFIG_NOT_FOUND = "SHAKAPACKER_1001",
  CONFIG_INVALID_YAML = "SHAKAPACKER_1002",
  CONFIG_MISSING_REQUIRED = "SHAKAPACKER_1003",
  CONFIG_VALIDATION_FAILED = "SHAKAPACKER_1004",
  CONFIG_MERGE_FAILED = "SHAKAPACKER_1005",
  CONFIG_TYPE_MISMATCH = "SHAKAPACKER_1006",

  // File system errors (2xxx)
  FILE_NOT_FOUND = "SHAKAPACKER_2001",
  FILE_READ_ERROR = "SHAKAPACKER_2002",
  FILE_WRITE_ERROR = "SHAKAPACKER_2003",
  FILE_PERMISSION_DENIED = "SHAKAPACKER_2004",
  PATH_TRAVERSAL_DETECTED = "SHAKAPACKER_2005",
  INVALID_PATH = "SHAKAPACKER_2006",

  // Module errors (3xxx)
  MODULE_NOT_FOUND = "SHAKAPACKER_3001",
  MODULE_LOAD_FAILED = "SHAKAPACKER_3002",
  MODULE_INVALID_EXPORT = "SHAKAPACKER_3003",
  LOADER_NOT_FOUND = "SHAKAPACKER_3004",
  PLUGIN_NOT_FOUND = "SHAKAPACKER_3005",
  PLUGIN_INVALID = "SHAKAPACKER_3006",

  // Environment errors (4xxx)
  ENV_INVALID_NODE_ENV = "SHAKAPACKER_4001",
  ENV_MISSING_REQUIRED = "SHAKAPACKER_4002",
  ENV_INVALID_VALUE = "SHAKAPACKER_4003",
  ENV_SANITIZATION_REQUIRED = "SHAKAPACKER_4004",

  // Bundler errors (5xxx)
  BUNDLER_UNSUPPORTED = "SHAKAPACKER_5001",
  BUNDLER_CONFIG_INVALID = "SHAKAPACKER_5002",
  WEBPACK_CONFIG_INVALID = "SHAKAPACKER_5003",
  RSPACK_CONFIG_INVALID = "SHAKAPACKER_5004",
  TRANSPILER_NOT_FOUND = "SHAKAPACKER_5005",
  TRANSPILER_CONFIG_INVALID = "SHAKAPACKER_5006",

  // Dev server errors (6xxx)
  DEVSERVER_CONFIG_INVALID = "SHAKAPACKER_6001",
  DEVSERVER_PORT_INVALID = "SHAKAPACKER_6002",
  DEVSERVER_PORT_IN_USE = "SHAKAPACKER_6003",
  DEVSERVER_START_FAILED = "SHAKAPACKER_6004",

  // Security errors (7xxx)
  SECURITY_PATH_TRAVERSAL = "SHAKAPACKER_7001",
  SECURITY_INVALID_INPUT = "SHAKAPACKER_7002",
  SECURITY_CONTROL_CHARS = "SHAKAPACKER_7003",
  SECURITY_INJECTION_ATTEMPT = "SHAKAPACKER_7004",

  // Validation errors (8xxx)
  VALIDATION_FAILED = "SHAKAPACKER_8001",
  VALIDATION_TYPE_ERROR = "SHAKAPACKER_8002",
  VALIDATION_RANGE_ERROR = "SHAKAPACKER_8003",
  VALIDATION_FORMAT_ERROR = "SHAKAPACKER_8004",
  VALIDATION_CONSTRAINT_ERROR = "SHAKAPACKER_8005",

  // Generic errors (9xxx)
  UNKNOWN_ERROR = "SHAKAPACKER_9000",
  INTERNAL_ERROR = "SHAKAPACKER_9001",
  DEPRECATED_FEATURE = "SHAKAPACKER_9002",
  NOT_IMPLEMENTED = "SHAKAPACKER_9003",
  OPERATION_FAILED = "SHAKAPACKER_9004"
}

/**
 * Error message templates for each error code
 */
export const ErrorMessages: Record<ErrorCode, string> = {
  // Configuration errors
  [ErrorCode.CONFIG_NOT_FOUND]: "Configuration file not found: {path}",
  [ErrorCode.CONFIG_INVALID_YAML]: "Invalid YAML in configuration file: {path}",
  [ErrorCode.CONFIG_MISSING_REQUIRED]:
    "Missing required configuration field: {field}",
  [ErrorCode.CONFIG_VALIDATION_FAILED]:
    "Configuration validation failed: {reason}",
  [ErrorCode.CONFIG_MERGE_FAILED]: "Failed to merge configurations: {reason}",
  [ErrorCode.CONFIG_TYPE_MISMATCH]:
    "Configuration type mismatch for {field}: expected {expected}, got {actual}",

  // File system errors
  [ErrorCode.FILE_NOT_FOUND]: "File not found: {path}",
  [ErrorCode.FILE_READ_ERROR]: "Error reading file: {path}",
  [ErrorCode.FILE_WRITE_ERROR]: "Error writing file: {path}",
  [ErrorCode.FILE_PERMISSION_DENIED]: "Permission denied accessing: {path}",
  [ErrorCode.PATH_TRAVERSAL_DETECTED]:
    "Path traversal attempt detected: {path}",
  [ErrorCode.INVALID_PATH]: "Invalid path: {path}",

  // Module errors
  [ErrorCode.MODULE_NOT_FOUND]: "Module not found: {module}",
  [ErrorCode.MODULE_LOAD_FAILED]: "Failed to load module: {module}",
  [ErrorCode.MODULE_INVALID_EXPORT]: "Invalid export from module: {module}",
  [ErrorCode.LOADER_NOT_FOUND]: "Loader not found: {loader}",
  [ErrorCode.PLUGIN_NOT_FOUND]: "Plugin not found: {plugin}",
  [ErrorCode.PLUGIN_INVALID]: "Invalid plugin: {plugin}",

  // Environment errors
  [ErrorCode.ENV_INVALID_NODE_ENV]:
    "Invalid NODE_ENV value: {value}. Valid values are: {valid}",
  [ErrorCode.ENV_MISSING_REQUIRED]:
    "Missing required environment variable: {variable}",
  [ErrorCode.ENV_INVALID_VALUE]:
    "Invalid value for environment variable {variable}: {value}",
  [ErrorCode.ENV_SANITIZATION_REQUIRED]:
    "Environment variable {variable} contained unsafe characters and was sanitized",

  // Bundler errors
  [ErrorCode.BUNDLER_UNSUPPORTED]: "Unsupported bundler: {bundler}",
  [ErrorCode.BUNDLER_CONFIG_INVALID]: "Invalid bundler configuration: {reason}",
  [ErrorCode.WEBPACK_CONFIG_INVALID]: "Invalid webpack configuration: {reason}",
  [ErrorCode.RSPACK_CONFIG_INVALID]: "Invalid rspack configuration: {reason}",
  [ErrorCode.TRANSPILER_NOT_FOUND]: "Transpiler not found: {transpiler}",
  [ErrorCode.TRANSPILER_CONFIG_INVALID]:
    "Invalid transpiler configuration: {reason}",

  // Dev server errors
  [ErrorCode.DEVSERVER_CONFIG_INVALID]:
    "Invalid dev server configuration: {reason}",
  [ErrorCode.DEVSERVER_PORT_INVALID]: "Invalid port: {port}",
  [ErrorCode.DEVSERVER_PORT_IN_USE]: "Port {port} is already in use",
  [ErrorCode.DEVSERVER_START_FAILED]: "Failed to start dev server: {reason}",

  // Security errors
  [ErrorCode.SECURITY_PATH_TRAVERSAL]:
    "Security: Path traversal attempt blocked: {path}",
  [ErrorCode.SECURITY_INVALID_INPUT]:
    "Security: Invalid input detected: {input}",
  [ErrorCode.SECURITY_CONTROL_CHARS]:
    "Security: Control characters detected and removed from: {field}",
  [ErrorCode.SECURITY_INJECTION_ATTEMPT]:
    "Security: Potential injection attempt blocked: {details}",

  // Validation errors
  [ErrorCode.VALIDATION_FAILED]: "Validation failed: {reason}",
  [ErrorCode.VALIDATION_TYPE_ERROR]:
    "Type validation error: {field} should be {type}",
  [ErrorCode.VALIDATION_RANGE_ERROR]:
    "Value out of range: {field} must be between {min} and {max}",
  [ErrorCode.VALIDATION_FORMAT_ERROR]:
    "Format error: {field} does not match expected format",
  [ErrorCode.VALIDATION_CONSTRAINT_ERROR]: "Constraint violation: {constraint}",

  // Generic errors
  [ErrorCode.UNKNOWN_ERROR]: "An unknown error occurred",
  [ErrorCode.INTERNAL_ERROR]: "Internal error: {details}",
  [ErrorCode.DEPRECATED_FEATURE]:
    "Deprecated feature: {feature}. Use {alternative} instead",
  [ErrorCode.NOT_IMPLEMENTED]: "Feature not yet implemented: {feature}",
  [ErrorCode.OPERATION_FAILED]: "Operation failed: {operation}"
}

/**
 * Shakapacker error class with error code support
 */
export class ShakapackerError extends Error {
  public readonly code: ErrorCode

  public readonly details?: Record<string, any>

  constructor(
    code: ErrorCode,
    details?: Record<string, any>,
    customMessage?: string
  ) {
    const template = ErrorMessages[code] || "An error occurred"
    const message =
      customMessage || ShakapackerError.formatMessage(template, details)

    super(message)
    this.name = "ShakapackerError"
    this.code = code
    this.details = details

    // Maintain proper stack trace for where error was thrown
    if (Error.captureStackTrace) {
      Error.captureStackTrace(this, ShakapackerError)
    }
  }

  /**
   * Format error message with template values
   */
  private static formatMessage(
    template: string,
    details?: Record<string, any>
  ): string {
    if (!details) return template

    return template.replace(/{(\w+)}/g, (match, key) => {
      const value = details[key]
      if (value === undefined) return match
      if (typeof value === "object") {
        return JSON.stringify(value)
      }
      return String(value)
    })
  }

  /**
   * Convert error to JSON for logging or API responses
   */
  toJSON(): Record<string, any> {
    return {
      name: this.name,
      code: this.code,
      message: this.message,
      details: this.details,
      stack: this.stack
    }
  }
}

/**
 * Helper function to create a Shakapacker error
 */
export function createError(
  code: ErrorCode,
  details?: Record<string, any>
): ShakapackerError {
  return new ShakapackerError(code, details)
}

/**
 * Helper function to check if an error is a Shakapacker error
 */
export function isShakapackerError(error: unknown): error is ShakapackerError {
  return error instanceof ShakapackerError
}

/**
 * Helper function to get error code from any error
 */
export function getErrorCode(error: unknown): ErrorCode | null {
  if (isShakapackerError(error)) {
    return error.code
  }
  return null
}
