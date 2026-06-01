/**
 * Debug utility for Shakapacker
 * Provides conditional logging based on environment variables
 */

const isDebugMode = (): boolean => {
  // Explicitly check for debug mode being disabled
  if (process.env.SHAKAPACKER_DEBUG === "false") {
    return false
  }

  // Support both SHAKAPACKER_DEBUG (new) and DEBUG_SHAKAPACKER (legacy) for backwards compatibility
  return (
    process.env.SHAKAPACKER_DEBUG === "true" ||
    process.env.DEBUG_SHAKAPACKER === "true"
  )
}

const debug = (message: string, ...args: unknown[]): void => {
  if (isDebugMode()) {
    console.log(`[Shakapacker] ${message}`, ...args)
  }
}

const warn = (message: string, ...args: unknown[]): void => {
  console.warn(`[Shakapacker] WARNING: ${message}`, ...args)
}

const error = (message: string, ...args: unknown[]): void => {
  console.error(`[Shakapacker] ERROR: ${message}`, ...args)
}

const info = (message: string, ...args: unknown[]): void => {
  if (isDebugMode()) {
    console.info(`[Shakapacker] INFO: ${message}`, ...args)
  }
}

export = {
  debug,
  warn,
  error,
  info,
  isDebugMode
}
