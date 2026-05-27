#!/usr/bin/env node

/**
 * Type-check script for lint-staged
 *
 * This script runs TypeScript type checking without emitting files.
 * It ignores any arguments passed by lint-staged to ensure tsc uses
 * the project's tsconfig.json rather than trying to compile individual files.
 *
 * Without this wrapper, lint-staged would pass staged file paths as arguments
 * to tsc, causing it to ignore tsconfig.json and fail type checking.
 */

const { execSync } = require("child_process")

try {
  // Run tsc with no arguments (ignoring any passed by lint-staged)
  // This ensures it uses tsconfig.json properly
  execSync("npx tsc --noEmit", {
    stdio: "inherit",
    cwd: process.cwd()
  })
  process.exit(0)
} catch {
  // Type checking failed
  process.exit(1)
}
