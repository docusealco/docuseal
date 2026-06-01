const {
  isValidConfig,
  clearValidationCache
} = require("../../package/utils/typeGuards")

describe("security validation", () => {
  const originalNodeEnv = process.env.NODE_ENV
  const originalStrictValidation = process.env.SHAKAPACKER_STRICT_VALIDATION

  afterEach(() => {
    process.env.NODE_ENV = originalNodeEnv
    process.env.SHAKAPACKER_STRICT_VALIDATION = originalStrictValidation
    clearValidationCache()
  })

  describe("path traversal security checks", () => {
    const baseConfig = {
      source_path: "./app/javascript",
      source_entry_path: "./packs",
      public_root_path: "./public",
      public_output_path: "packs",
      cache_path: "tmp/shakapacker",
      javascript_transpiler: "babel",
      nested_entries: false,
      css_extract_ignore_order_warnings: false,
      webpack_compile_output: true,
      shakapacker_precompile: true,
      cache_manifest: false,
      ensure_consistent_versioning: false,
      useContentHash: true,
      compile: true,
      additional_paths: []
    }

    it("always validates path traversal in required path fields in production", () => {
      process.env.NODE_ENV = "production"
      delete process.env.SHAKAPACKER_STRICT_VALIDATION

      const unsafeConfig = {
        ...baseConfig,
        source_path: "../../../etc/passwd"
      }

      expect(isValidConfig(unsafeConfig)).toBe(false)
    })

    it("always validates path traversal in required path fields in development", () => {
      process.env.NODE_ENV = "development"

      const unsafeConfig = {
        ...baseConfig,
        public_output_path: "../../sensitive/data"
      }

      expect(isValidConfig(unsafeConfig)).toBe(false)
    })

    it("always validates path traversal in additional_paths in production", () => {
      process.env.NODE_ENV = "production"
      delete process.env.SHAKAPACKER_STRICT_VALIDATION

      const unsafeConfig = {
        ...baseConfig,
        additional_paths: ["./safe/path", "../../../etc/passwd"]
      }

      expect(isValidConfig(unsafeConfig)).toBe(false)
    })

    it("always validates path traversal in additional_paths in development", () => {
      process.env.NODE_ENV = "development"

      const unsafeConfig = {
        ...baseConfig,
        additional_paths: ["./safe/path", "../../../../root/.ssh"]
      }

      expect(isValidConfig(unsafeConfig)).toBe(false)
    })

    it("allows safe paths in production", () => {
      process.env.NODE_ENV = "production"
      delete process.env.SHAKAPACKER_STRICT_VALIDATION

      const safeConfig = {
        ...baseConfig,
        additional_paths: ["./app/assets", "./vendor/assets", "node_modules"]
      }

      expect(isValidConfig(safeConfig)).toBe(true)
    })

    it("allows safe paths in development", () => {
      process.env.NODE_ENV = "development"

      const safeConfig = {
        ...baseConfig,
        additional_paths: ["./app/components", "./lib/assets"]
      }

      expect(isValidConfig(safeConfig)).toBe(true)
    })
  })

  describe("optional field validation", () => {
    const validConfig = {
      source_path: "./app/javascript",
      source_entry_path: "./packs",
      public_root_path: "./public",
      public_output_path: "packs",
      cache_path: "tmp/shakapacker",
      javascript_transpiler: "babel",
      nested_entries: false,
      css_extract_ignore_order_warnings: false,
      webpack_compile_output: true,
      shakapacker_precompile: true,
      cache_manifest: false,
      ensure_consistent_versioning: false,
      useContentHash: true,
      compile: true,
      additional_paths: [],
      dev_server: {
        hmr: true,
        port: 3035
      },
      integrity: {
        enabled: true,
        cross_origin: "anonymous"
      }
    }

    it("skips deep validation of optional fields in production without strict mode", () => {
      process.env.NODE_ENV = "production"
      delete process.env.SHAKAPACKER_STRICT_VALIDATION

      // Invalid integrity config that would fail deep validation
      const configWithInvalidOptional = {
        ...validConfig,
        integrity: {
          enabled: "not-a-boolean", // Invalid type
          cross_origin: "anonymous"
        }
      }

      // Should pass because deep validation is skipped in production
      expect(isValidConfig(configWithInvalidOptional)).toBe(true)
    })

    it("performs deep validation of optional fields in development", () => {
      process.env.NODE_ENV = "development"

      // Invalid integrity config
      const configWithInvalidOptional = {
        ...validConfig,
        integrity: {
          enabled: "not-a-boolean", // Invalid type
          cross_origin: "anonymous"
        }
      }

      // Should fail because deep validation runs in development
      expect(isValidConfig(configWithInvalidOptional)).toBe(false)
    })

    it("performs deep validation in production with strict mode", () => {
      process.env.NODE_ENV = "production"
      process.env.SHAKAPACKER_STRICT_VALIDATION = "true"

      // Invalid integrity config
      const configWithInvalidOptional = {
        ...validConfig,
        integrity: {
          enabled: "not-a-boolean", // Invalid type
          cross_origin: "anonymous"
        }
      }

      // Should fail because strict validation is enabled
      expect(isValidConfig(configWithInvalidOptional)).toBe(false)
    })
  })
})
