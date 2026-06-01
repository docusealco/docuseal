/**
 * Error handling utilities for consistent error management
 */

import { ErrorCode, ShakapackerError } from "./errorCodes"

/**
 * Checks if an error is a file not found error (ENOENT)
 */
export function isFileNotFoundError(error: unknown): boolean {
  return (
    error !== null &&
    typeof error === "object" &&
    "code" in error &&
    (error as NodeJS.ErrnoException).code === "ENOENT"
  )
}

/**
 * Checks if an error is a module not found error
 */
export function isModuleNotFoundError(error: unknown): boolean {
  return (
    error !== null &&
    typeof error === "object" &&
    "code" in error &&
    (error as NodeJS.ErrnoException).code === "MODULE_NOT_FOUND"
  )
}

/**
 * Creates a consistent error message for file operations
 */
export function createFileOperationError(
  operation: "read" | "write" | "delete",
  filePath: string,
  details?: string
): ShakapackerError {
  let errorCode: ErrorCode
  if (operation === "read") {
    errorCode = ErrorCode.FILE_READ_ERROR
  } else if (operation === "write") {
    errorCode = ErrorCode.FILE_WRITE_ERROR
  } else {
    errorCode = ErrorCode.FILE_NOT_FOUND
  }

  return new ShakapackerError(errorCode, {
    path: filePath,
    operation,
    details
  })
}

/**
 * Creates a consistent error message for file operations (backward compatibility)
 */
export function createFileOperationErrorLegacy(
  operation: "read" | "write" | "delete",
  filePath: string,
  details?: string
): Error {
  const baseMessage = `Failed to ${operation} file at path '${filePath}'`
  const errorDetails = details ? ` - ${details}` : ""
  let suggestion: string
  if (operation === "read") {
    suggestion = " (check if file exists and permissions are correct)"
  } else if (operation === "write") {
    suggestion = " (check write permissions and disk space)"
  } else {
    suggestion = " (check permissions)"
  }
  return new Error(`${baseMessage}${errorDetails}${suggestion}`)
}

/**
 * Safely gets error message from unknown error type
 */
export function getErrorMessage(error: unknown): string {
  if (error instanceof Error) {
    // Include stack trace for better debugging in development
    const isDev = process.env.NODE_ENV === "development"
    return isDev && error.stack
      ? `${error.message}\n${error.stack}`
      : error.message
  }
  if (typeof error === "string") {
    return error
  }
  if (error && typeof error === "object" && "message" in error) {
    return String((error as { message: unknown }).message)
  }
  // Provide more context for truly unknown errors
  return `Unknown error occurred (type: ${typeof error}, value: ${JSON.stringify(error)})`
}

/**
 * Type guard for NodeJS errors with errno
 */
export function isNodeError(error: unknown): error is NodeJS.ErrnoException {
  return (
    error instanceof Error &&
    "code" in error &&
    typeof (error as NodeJS.ErrnoException).code === "string"
  )
}

/**
 * Creates a configuration validation error
 */
export function createConfigValidationErrorWithCode(
  configPath: string,
  environment: string,
  reason: string
): ShakapackerError {
  return new ShakapackerError(ErrorCode.CONFIG_VALIDATION_FAILED, {
    path: configPath,
    environment,
    reason
  })
}

/**
 * Creates a module not found error
 */
export function createModuleNotFoundError(
  moduleName: string,
  details?: string
): ShakapackerError {
  return new ShakapackerError(ErrorCode.MODULE_NOT_FOUND, {
    module: moduleName,
    details
  })
}

/**
 * Creates a path traversal security error
 */
export function createPathTraversalError(path: string): ShakapackerError {
  return new ShakapackerError(ErrorCode.SECURITY_PATH_TRAVERSAL, {
    path
  })
}

/**
 * Creates a port validation error
 */
export function createPortValidationError(port: unknown): ShakapackerError {
  return new ShakapackerError(ErrorCode.DEVSERVER_PORT_INVALID, {
    port: String(port)
  })
}
