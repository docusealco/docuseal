/**
 * Shared environment variable filtering logic for webpack and rspack plugins.
 *
 * SECURITY: This module ensures only allowlisted environment variables are
 * exposed to client-side JavaScript bundles, preventing accidental leakage
 * of secrets like DATABASE_URL, API keys, etc.
 */

/**
 * Allowlist of environment variables that are safe to expose to client-side JavaScript.
 *
 * SECURITY: Never add sensitive variables like DATABASE_URL, API keys, or secrets.
 * These values are embedded directly into the JavaScript bundle and are publicly visible.
 *
 * Users can extend this list via:
 * 1. SHAKAPACKER_PUBLIC_* prefix (auto-exposed, similar to Next.js/Vite conventions)
 * 2. SHAKAPACKER_ENV_VARS environment variable (comma-separated list)
 * 3. Customizing their webpack/rspack config
 */
export const DEFAULT_ALLOWED_ENV_VARS = [
  "NODE_ENV",
  "RAILS_ENV",
  "WEBPACK_SERVE"
] as const

/**
 * Prefix for environment variables that are automatically exposed to client-side code.
 * Similar to Next.js's NEXT_PUBLIC_ and Vite's VITE_ prefixes.
 *
 * Example: SHAKAPACKER_PUBLIC_API_URL will be available as process.env.SHAKAPACKER_PUBLIC_API_URL
 */
export const PUBLIC_ENV_PREFIX = "SHAKAPACKER_PUBLIC_"

/**
 * Gets the list of environment variables to expose to client-side code.
 * Combines:
 * 1. Default allowed vars (NODE_ENV, RAILS_ENV, WEBPACK_SERVE)
 * 2. Any vars with SHAKAPACKER_PUBLIC_ prefix (auto-exposed)
 * 3. Any user-specified vars from SHAKAPACKER_ENV_VARS
 */
export const getAllowedEnvVars = (): string[] => {
  const allowed: string[] = [...DEFAULT_ALLOWED_ENV_VARS]

  // Auto-expose any SHAKAPACKER_PUBLIC_* variables (similar to Next.js/Vite convention)
  Object.keys(process.env).forEach((key) => {
    if (key.startsWith(PUBLIC_ENV_PREFIX)) {
      allowed.push(key)
    }
  })

  // Allow users to specify additional env vars via SHAKAPACKER_ENV_VARS
  const userVars = process.env.SHAKAPACKER_ENV_VARS
  if (userVars) {
    const additionalVars = userVars
      .split(",")
      .map((v) => v.trim())
      .filter(Boolean)

    allowed.push(...additionalVars)
  }

  // Remove duplicates (can occur if same var is in multiple sources)
  return [...new Set(allowed)]
}

/**
 * Builds a filtered environment object containing only allowed variables.
 * Returns an object with variable names as keys and their values.
 * Uses null as default for missing variables (webpack/rspack treat null as optional).
 */
export const getFilteredEnv = (): Record<string, string | null> => {
  const allowedVars = getAllowedEnvVars()
  const filtered: Record<string, string | null> = {}

  for (const varName of allowedVars) {
    // Use null as default for missing vars - webpack/rspack treat null as optional
    // (undefined would cause them to throw if the var is used but not set)
    filtered[varName] = process.env[varName] ?? null
  }

  return filtered
}
