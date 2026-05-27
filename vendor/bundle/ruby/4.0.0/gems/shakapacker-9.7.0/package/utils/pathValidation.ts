import * as path from "path"
import * as fs from "fs"

/**
 * Security utilities for validating and sanitizing file paths
 */

/**
 * Validates a path doesn't contain traversal patterns
 */
export function isPathTraversalSafe(inputPath: string): boolean {
  // Check for common traversal patterns
  // Null byte short-circuit (avoid regex with control chars)
  if (inputPath.includes("\0")) return false

  const dangerousPatterns = [
    /\.\.[/\\]/, // ../ or ..\
    /^\//, // POSIX absolute
    /^[A-Za-z]:[/\\]/, // Windows absolute (C:\ or C:/)
    /^\\\\/, // Windows UNC (\\server\share)
    /~[/\\]/, // Home directory expansion
    /%2e%2e/i // URL encoded traversal
  ]

  return !dangerousPatterns.some((pattern) => pattern.test(inputPath))
}

/**
 * Resolves and validates a path within a base directory
 * Prevents directory traversal attacks by ensuring the resolved path
 * stays within the base directory.
 * Also resolves symlinks to prevent symlink-based path traversal attacks.
 *
 * @param basePath - The base directory to validate against
 * @param userPath - The user-provided path to validate
 * @param resolveSymlinks - Whether to resolve symlinks (default: true for security)
 * @returns The validated absolute path
 * @throws Error if path is outside base directory
 */
export function safeResolvePath(
  basePath: string,
  userPath: string,
  resolveSymlinks = true
): string {
  // Resolve the base path through symlinks if enabled
  let normalizedBase: string
  try {
    normalizedBase = resolveSymlinks
      ? fs.realpathSync(basePath)
      : path.resolve(basePath)
  } catch (error: unknown) {
    // If basePath doesn't exist (ENOENT), fall back to path.resolve
    // Rethrow other errors (e.g., permission issues) as they indicate real problems
    const nodeError = error as NodeJS.ErrnoException
    if (nodeError?.code === "ENOENT") {
      normalizedBase = path.resolve(basePath)
    } else {
      throw error
    }
  }

  // For paths that may not exist yet, validate the parent directory
  const absolutePath = path.resolve(basePath, userPath)
  const parentDir = path.dirname(absolutePath)
  const fileName = path.basename(absolutePath)

  // Resolve parent directory through symlinks if it exists and symlink resolution is enabled
  let resolvedParent: string
  try {
    resolvedParent = resolveSymlinks
      ? fs.realpathSync(parentDir)
      : path.resolve(parentDir)
  } catch (error: unknown) {
    // If parent doesn't exist (ENOENT), validate the absolute path as-is
    // Rethrow other errors (e.g., permission issues) as they indicate real problems
    const nodeError = error as NodeJS.ErrnoException
    if (nodeError?.code === "ENOENT") {
      if (
        !absolutePath.startsWith(normalizedBase + path.sep) &&
        absolutePath !== normalizedBase
      ) {
        throw new Error(
          `[SHAKAPACKER SECURITY] Path traversal attempt detected.\n` +
            `Requested path would resolve outside of allowed directory.\n` +
            `Base: ${normalizedBase}\n` +
            `Attempted: ${userPath}\n` +
            `Resolved to: ${absolutePath}`
        )
      }
      return absolutePath
    }
    throw error
  }

  // Reconstruct the full path with the resolved (symlink-free) parent
  const resolved = path.resolve(resolvedParent, fileName)

  // Ensure the resolved path is within the base directory
  if (
    !resolved.startsWith(normalizedBase + path.sep) &&
    resolved !== normalizedBase
  ) {
    const symlinkNote = resolveSymlinks
      ? ` (symlink-resolved from ${userPath})`
      : ""
    throw new Error(
      `[SHAKAPACKER SECURITY] Path traversal attempt detected.\n` +
        `Requested path would resolve outside of allowed directory.\n` +
        `Base: ${normalizedBase}\n` +
        `Attempted: ${userPath}\n` +
        `Resolved to: ${resolved}${symlinkNote}`
    )
  }

  return resolved
}

/**
 * Validates that a path exists and is accessible
 */
export function validatePathExists(filePath: string): boolean {
  try {
    fs.accessSync(filePath, fs.constants.R_OK)
    return true
  } catch {
    return false
  }
}

/**
 * Validates an array of paths for security issues
 */
export function validatePaths(paths: string[], basePath: string): string[] {
  const validatedPaths: string[] = []

  for (const userPath of paths) {
    if (!isPathTraversalSafe(userPath)) {
      console.warn(
        `[SHAKAPACKER WARNING] Skipping potentially unsafe path: ${userPath}`
      )
    } else {
      try {
        const safePath = safeResolvePath(basePath, userPath)
        validatedPaths.push(safePath)
      } catch (error) {
        console.warn(
          `[SHAKAPACKER WARNING] Invalid path configuration: ${userPath}\n` +
            `Error: ${error instanceof Error ? error.message : String(error)}`
        )
      }
    }
  }

  return validatedPaths
}

/**
 * Sanitizes environment variable values to prevent injection
 */
export function sanitizeEnvValue(
  value: string | undefined
): string | undefined {
  if (!value) return value

  // Remove control characters and null bytes
  // Filter by character code to avoid control character regex (Biome compliance)
  const sanitized = value
    .split("")
    .filter((char) => {
      const code = char.charCodeAt(0)
      // Keep chars with code > 31 (after control chars) and not 127 (DEL)
      return code > 31 && code !== 127
    })
    .join("")

  // Warn if sanitization changed the value
  if (sanitized !== value) {
    console.warn(
      `[SHAKAPACKER SECURITY] Environment variable value contained control characters that were removed`
    )
  }

  return sanitized
}

/**
 * Validates a port number or string
 */
export function validatePort(port: unknown): boolean {
  if (port === "auto") return true

  if (typeof port === "number") {
    return port > 0 && port <= 65535 && Number.isInteger(port)
  }

  if (typeof port === "string") {
    // First check if the string contains only digits
    if (!/^\d+$/.test(port)) {
      return false
    }
    // Only then parse and validate range
    const num = parseInt(port, 10)
    return num > 0 && num <= 65535
  }

  return false
}
