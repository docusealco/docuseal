/**
 * Security tests for environment variable filtering in EnvironmentPlugin.
 *
 * These tests verify that only allowlisted environment variables are exposed
 * to client-side JavaScript bundles, preventing accidental leakage of secrets.
 *
 * CVE: Environment variables leak via EnvironmentPlugin(process.env)
 * See: https://github.com/shakacode/shakapacker/security/advisories
 */

const fs = require("fs")
const path = require("path")

const pluginsDir = path.resolve(__dirname, "../../../package/plugins")

describe("environment variable filtering security", () => {
  const originalEnv = { ...process.env }

  beforeEach(() => {
    // Set up test environment with sensitive variables
    process.env.NODE_ENV = "production"
    process.env.RAILS_ENV = "production"
    process.env.WEBPACK_SERVE = "false"

    // Simulate sensitive build environment variables
    process.env.DATABASE_URL = "postgres://user:password@host/db"
    process.env.AWS_ACCESS_KEY_ID = "AKIAIOSFODNN7EXAMPLE"
    process.env.AWS_SECRET_ACCESS_KEY =
      "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
    process.env.RAILS_MASTER_KEY = "abc123secretmasterkey456"
    process.env.STRIPE_SECRET_KEY = "sk_live_secretkey123"
    process.env.SESSION_SECRET = "supersecrettoken"

    // Clear any cached modules
    jest.resetModules()
  })

  afterEach(() => {
    // Restore original environment
    Object.keys(process.env).forEach((key) => {
      if (!(key in originalEnv)) {
        delete process.env[key]
      }
    })
    Object.assign(process.env, originalEnv)
    delete process.env.SHAKAPACKER_ENV_VARS
  })

  describe("shared envFilter module", () => {
    it("exists and exports the filtering functions", () => {
      const envFilterSource = fs.readFileSync(
        path.join(pluginsDir, "envFilter.ts"),
        "utf8"
      )

      // Verify exports
      expect(envFilterSource).toContain("export const DEFAULT_ALLOWED_ENV_VARS")
      expect(envFilterSource).toContain("export const getAllowedEnvVars")
      expect(envFilterSource).toContain("export const getFilteredEnv")
    })

    it("has the default allowlist with only safe variables", () => {
      const envFilterSource = fs.readFileSync(
        path.join(pluginsDir, "envFilter.ts"),
        "utf8"
      )

      // Extract the DEFAULT_ALLOWED_ENV_VARS array from source
      const allowlistMatch = envFilterSource.match(
        /DEFAULT_ALLOWED_ENV_VARS\s*=\s*\[([\s\S]*?)\]\s*as const/
      )
      expect(allowlistMatch).toBeTruthy()

      const allowlistContent = allowlistMatch[1]

      // These patterns should NEVER appear in the allowlist
      const sensitivePatterns = [
        "DATABASE",
        "SECRET",
        "PASSWORD",
        "CREDENTIAL",
        "AWS_",
        "STRIPE",
        "MASTER"
      ]

      sensitivePatterns.forEach((pattern) => {
        expect(allowlistContent.toUpperCase()).not.toContain(pattern)
      })

      // Verify expected safe vars are present
      expect(allowlistContent).toContain("NODE_ENV")
      expect(allowlistContent).toContain("RAILS_ENV")
      expect(allowlistContent).toContain("WEBPACK_SERVE")
    })

    it("includes SHAKAPACKER_ENV_VARS extension support", () => {
      const envFilterSource = fs.readFileSync(
        path.join(pluginsDir, "envFilter.ts"),
        "utf8"
      )

      expect(envFilterSource).toContain("SHAKAPACKER_ENV_VARS")
      expect(envFilterSource).toContain('split(",")')
    })

    it("exports PUBLIC_ENV_PREFIX constant", () => {
      const envFilterSource = fs.readFileSync(
        path.join(pluginsDir, "envFilter.ts"),
        "utf8"
      )

      expect(envFilterSource).toContain("export const PUBLIC_ENV_PREFIX")
      expect(envFilterSource).toContain('SHAKAPACKER_PUBLIC_"')
    })

    it("auto-exposes SHAKAPACKER_PUBLIC_* variables", () => {
      const envFilterSource = fs.readFileSync(
        path.join(pluginsDir, "envFilter.ts"),
        "utf8"
      )

      // Verify the prefix check is present
      expect(envFilterSource).toContain("startsWith(PUBLIC_ENV_PREFIX)")
      expect(envFilterSource).toContain("Object.keys(process.env)")
    })

    it("uses SHAKAPACKER_PUBLIC_ prefix (with trailing underscore) to prevent system var exposure", () => {
      const envFilterSource = fs.readFileSync(
        path.join(pluginsDir, "envFilter.ts"),
        "utf8"
      )

      // SECURITY: The prefix MUST include the trailing underscore to ensure
      // Shakapacker system variables like SHAKAPACKER_CONFIG, SHAKAPACKER_ENV_VARS,
      // SHAKAPACKER_PRECOMPILE, etc. are NOT accidentally exposed.
      // Only SHAKAPACKER_PUBLIC_* variables should be auto-exposed.
      const prefixMatch = envFilterSource.match(
        /PUBLIC_ENV_PREFIX\s*=\s*["']([^"']+)["']/
      )
      expect(prefixMatch).toBeTruthy()
      expect(prefixMatch[1]).toBe("SHAKAPACKER_PUBLIC_")

      // Verify the trailing underscore is present - this is critical for security
      expect(prefixMatch[1]).toMatch(/_$/)
    })

    it("handles whitespace and empty values in CSV", () => {
      const envFilterSource = fs.readFileSync(
        path.join(pluginsDir, "envFilter.ts"),
        "utf8"
      )

      // Verify trim() is called on each value
      expect(envFilterSource).toMatch(/\.map\(\s*\(?v\)?\s*=>\s*v\.trim\(\)/)
      // Verify filter(Boolean) is called to remove empty strings
      expect(envFilterSource).toMatch(/\.filter\(Boolean\)/)
    })
  })

  describe("webpack plugin", () => {
    it("imports from shared envFilter module", () => {
      const webpackPluginSource = fs.readFileSync(
        path.join(pluginsDir, "webpack.ts"),
        "utf8"
      )

      expect(webpackPluginSource).toContain(
        'import { getFilteredEnv } from "./envFilter"'
      )
    })

    it("uses getFilteredEnv() not process.env", () => {
      const webpackPluginSource = fs.readFileSync(
        path.join(pluginsDir, "webpack.ts"),
        "utf8"
      )

      // SECURITY: Verify the dangerous pattern is NOT present
      expect(webpackPluginSource).not.toMatch(
        /new webpack\.EnvironmentPlugin\(process\.env\)/
      )

      // Verify the safe pattern IS present
      expect(webpackPluginSource).toMatch(/getFilteredEnv\(\)/)
    })

    it("does not duplicate the filtering logic", () => {
      const webpackPluginSource = fs.readFileSync(
        path.join(pluginsDir, "webpack.ts"),
        "utf8"
      )

      // Should NOT have its own copy of these
      expect(webpackPluginSource).not.toContain("DEFAULT_ALLOWED_ENV_VARS")
      expect(webpackPluginSource).not.toContain("PUBLIC_ENV_PREFIX")
      expect(webpackPluginSource).not.toContain("getAllowedEnvVars")
    })
  })

  describe("rspack plugin", () => {
    it("imports from shared envFilter module", () => {
      const rspackPluginSource = fs.readFileSync(
        path.join(pluginsDir, "rspack.ts"),
        "utf8"
      )

      expect(rspackPluginSource).toContain(
        'import { getFilteredEnv } from "./envFilter"'
      )
    })

    it("uses getFilteredEnv() not process.env", () => {
      const rspackPluginSource = fs.readFileSync(
        path.join(pluginsDir, "rspack.ts"),
        "utf8"
      )

      // SECURITY: Verify the dangerous pattern is NOT present
      expect(rspackPluginSource).not.toMatch(
        /new rspack\.EnvironmentPlugin\(process\.env\)/
      )

      // Verify the safe pattern IS present
      expect(rspackPluginSource).toMatch(/getFilteredEnv\(\)/)
    })

    it("does not duplicate the filtering logic", () => {
      const rspackPluginSource = fs.readFileSync(
        path.join(pluginsDir, "rspack.ts"),
        "utf8"
      )

      // Should NOT have its own copy of these
      expect(rspackPluginSource).not.toContain("DEFAULT_ALLOWED_ENV_VARS")
      expect(rspackPluginSource).not.toContain("PUBLIC_ENV_PREFIX")
      expect(rspackPluginSource).not.toContain("getAllowedEnvVars")
    })
  })

  describe("consistency", () => {
    it("both plugins use the same shared module", () => {
      const webpackPluginSource = fs.readFileSync(
        path.join(pluginsDir, "webpack.ts"),
        "utf8"
      )
      const rspackPluginSource = fs.readFileSync(
        path.join(pluginsDir, "rspack.ts"),
        "utf8"
      )

      // Both should import from the same source
      const webpackImport = webpackPluginSource.match(
        /import\s*{[^}]*getFilteredEnv[^}]*}\s*from\s*["']([^"']+)["']/
      )
      const rspackImport = rspackPluginSource.match(
        /import\s*{[^}]*getFilteredEnv[^}]*}\s*from\s*["']([^"']+)["']/
      )

      expect(webpackImport).toBeTruthy()
      expect(rspackImport).toBeTruthy()
      expect(webpackImport[1]).toBe(rspackImport[1])
    })
  })

  /**
   * Runtime behavioral tests that actually call the filtering functions.
   * These complement the static source analysis tests above.
   */
  describe("runtime behavior", () => {
    // Helper to get fresh module instance (avoiding caching issues)
    const getEnvFilter = () => {
      jest.resetModules()
      return require("../../../package/plugins/envFilter")
    }

    describe("getAllowedEnvVars", () => {
      it("returns default allowed vars when SHAKAPACKER_ENV_VARS is unset", () => {
        delete process.env.SHAKAPACKER_ENV_VARS
        // Remove any SHAKAPACKER_PUBLIC_* vars from test setup
        const publicVars = Object.keys(process.env).filter((key) =>
          key.startsWith("SHAKAPACKER_PUBLIC_")
        )
        publicVars.forEach((key) => {
          delete process.env[key]
        })

        const { getAllowedEnvVars } = getEnvFilter()
        const allowed = getAllowedEnvVars()

        expect(allowed).toContain("NODE_ENV")
        expect(allowed).toContain("RAILS_ENV")
        expect(allowed).toContain("WEBPACK_SERVE")
        expect(allowed).toHaveLength(3)
      })

      it("includes SHAKAPACKER_PUBLIC_* variables when present", () => {
        delete process.env.SHAKAPACKER_ENV_VARS
        process.env.SHAKAPACKER_PUBLIC_API_URL = "https://api.example.com"
        process.env.SHAKAPACKER_PUBLIC_ANALYTICS_ID = "UA-12345"

        const { getAllowedEnvVars } = getEnvFilter()
        const allowed = getAllowedEnvVars()

        expect(allowed).toContain("NODE_ENV")
        expect(allowed).toContain("RAILS_ENV")
        expect(allowed).toContain("WEBPACK_SERVE")
        expect(allowed).toContain("SHAKAPACKER_PUBLIC_API_URL")
        expect(allowed).toContain("SHAKAPACKER_PUBLIC_ANALYTICS_ID")

        // Cleanup
        delete process.env.SHAKAPACKER_PUBLIC_API_URL
        delete process.env.SHAKAPACKER_PUBLIC_ANALYTICS_ID
      })

      it("does NOT include SHAKAPACKER_* system variables (without PUBLIC_)", () => {
        process.env.SHAKAPACKER_CONFIG = "/custom/path"
        process.env.SHAKAPACKER_PRECOMPILE = "true"
        delete process.env.SHAKAPACKER_ENV_VARS

        const { getAllowedEnvVars } = getEnvFilter()
        const allowed = getAllowedEnvVars()

        expect(allowed).not.toContain("SHAKAPACKER_CONFIG")
        expect(allowed).not.toContain("SHAKAPACKER_PRECOMPILE")

        // Cleanup
        delete process.env.SHAKAPACKER_CONFIG
        delete process.env.SHAKAPACKER_PRECOMPILE
      })

      it("parses SHAKAPACKER_ENV_VARS CSV and includes those variables", () => {
        process.env.SHAKAPACKER_ENV_VARS = "CUSTOM_VAR1,CUSTOM_VAR2,ANOTHER_VAR"

        const { getAllowedEnvVars } = getEnvFilter()
        const allowed = getAllowedEnvVars()

        expect(allowed).toContain("CUSTOM_VAR1")
        expect(allowed).toContain("CUSTOM_VAR2")
        expect(allowed).toContain("ANOTHER_VAR")
      })

      it("handles whitespace in SHAKAPACKER_ENV_VARS CSV", () => {
        process.env.SHAKAPACKER_ENV_VARS = " VAR1 , VAR2 ,  VAR3  "

        const { getAllowedEnvVars } = getEnvFilter()
        const allowed = getAllowedEnvVars()

        expect(allowed).toContain("VAR1")
        expect(allowed).toContain("VAR2")
        expect(allowed).toContain("VAR3")
      })

      it("ignores empty entries in SHAKAPACKER_ENV_VARS CSV", () => {
        process.env.SHAKAPACKER_ENV_VARS = "VAR1,,VAR2,,,VAR3,"

        const { getAllowedEnvVars } = getEnvFilter()
        const allowed = getAllowedEnvVars()

        expect(allowed).toContain("VAR1")
        expect(allowed).toContain("VAR2")
        expect(allowed).toContain("VAR3")
        // Should not contain empty strings
        expect(allowed.filter((v) => v === "")).toHaveLength(0)
      })

      it("deduplicates variables from multiple sources", () => {
        process.env.SHAKAPACKER_ENV_VARS = "NODE_ENV,CUSTOM_VAR"

        const { getAllowedEnvVars } = getEnvFilter()
        const allowed = getAllowedEnvVars()

        // NODE_ENV should only appear once (from defaults, not duplicated from CSV)
        const nodeEnvCount = allowed.filter((v) => v === "NODE_ENV").length
        expect(nodeEnvCount).toBe(1)
      })
    })

    describe("getFilteredEnv", () => {
      it("exposes allowed variables with their values", () => {
        delete process.env.SHAKAPACKER_ENV_VARS
        process.env.NODE_ENV = "production"
        process.env.RAILS_ENV = "staging"

        const { getFilteredEnv } = getEnvFilter()
        const filtered = getFilteredEnv()

        expect(filtered).toHaveProperty("NODE_ENV", "production")
        expect(filtered).toHaveProperty("RAILS_ENV", "staging")
      })

      it("omits sensitive variables that are not in allowlist", () => {
        delete process.env.SHAKAPACKER_ENV_VARS
        // Sensitive vars are set in beforeEach

        const { getFilteredEnv } = getEnvFilter()
        const filtered = getFilteredEnv()

        // SECURITY: These must NOT be present
        expect(filtered).not.toHaveProperty("DATABASE_URL")
        expect(filtered).not.toHaveProperty("AWS_ACCESS_KEY_ID")
        expect(filtered).not.toHaveProperty("AWS_SECRET_ACCESS_KEY")
        expect(filtered).not.toHaveProperty("RAILS_MASTER_KEY")
        expect(filtered).not.toHaveProperty("STRIPE_SECRET_KEY")
        expect(filtered).not.toHaveProperty("SESSION_SECRET")
      })

      it("exposes SHAKAPACKER_PUBLIC_* variables with their values", () => {
        delete process.env.SHAKAPACKER_ENV_VARS
        process.env.SHAKAPACKER_PUBLIC_API_URL = "https://api.example.com"

        const { getFilteredEnv } = getEnvFilter()
        const filtered = getFilteredEnv()

        expect(filtered).toHaveProperty(
          "SHAKAPACKER_PUBLIC_API_URL",
          "https://api.example.com"
        )

        // Cleanup
        delete process.env.SHAKAPACKER_PUBLIC_API_URL
      })

      it("uses null for missing variables from SHAKAPACKER_ENV_VARS", () => {
        process.env.SHAKAPACKER_ENV_VARS = "MISSING_VAR,ANOTHER_MISSING"
        delete process.env.MISSING_VAR
        delete process.env.ANOTHER_MISSING

        const { getFilteredEnv } = getEnvFilter()
        const filtered = getFilteredEnv()

        expect(filtered).toHaveProperty("MISSING_VAR", null)
        expect(filtered).toHaveProperty("ANOTHER_MISSING", null)
      })

      it("includes variables from SHAKAPACKER_ENV_VARS with their values", () => {
        process.env.SHAKAPACKER_ENV_VARS = "CUSTOM_API_URL"
        process.env.CUSTOM_API_URL = "https://custom.example.com"

        const { getFilteredEnv } = getEnvFilter()
        const filtered = getFilteredEnv()

        expect(filtered).toHaveProperty(
          "CUSTOM_API_URL",
          "https://custom.example.com"
        )

        // Cleanup
        delete process.env.CUSTOM_API_URL
      })
    })
  })
})
