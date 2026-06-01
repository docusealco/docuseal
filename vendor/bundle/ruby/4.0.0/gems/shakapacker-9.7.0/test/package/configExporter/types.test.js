const {
  isBuildEnvVar,
  isDangerousEnvVar,
  BUILD_ENV_VARS,
  DANGEROUS_ENV_VARS
} = require("../../../package/configExporter/types")

describe("configExporter/types", () => {
  describe("isBuildEnvVar", () => {
    test("returns true for whitelisted NODE_ENV", () => {
      expect(isBuildEnvVar("NODE_ENV")).toBe(true)
    })

    test("returns true for whitelisted RAILS_ENV", () => {
      expect(isBuildEnvVar("RAILS_ENV")).toBe(true)
    })

    test("returns true for whitelisted WEBPACK_SERVE", () => {
      expect(isBuildEnvVar("WEBPACK_SERVE")).toBe(true)
    })

    test("returns true for whitelisted CLIENT_BUNDLE_ONLY", () => {
      expect(isBuildEnvVar("CLIENT_BUNDLE_ONLY")).toBe(true)
    })

    test("returns true for whitelisted SERVER_BUNDLE_ONLY", () => {
      expect(isBuildEnvVar("SERVER_BUNDLE_ONLY")).toBe(true)
    })

    test("returns true for whitelisted NODE_OPTIONS", () => {
      expect(isBuildEnvVar("NODE_OPTIONS")).toBe(true)
    })

    test("returns true for whitelisted BABEL_ENV", () => {
      expect(isBuildEnvVar("BABEL_ENV")).toBe(true)
    })

    test("returns false for dangerous PATH", () => {
      expect(isBuildEnvVar("PATH")).toBe(false)
    })

    test("returns false for dangerous LD_PRELOAD", () => {
      expect(isBuildEnvVar("LD_PRELOAD")).toBe(false)
    })

    test("returns false for arbitrary custom variable", () => {
      expect(isBuildEnvVar("CUSTOM_VAR")).toBe(false)
      expect(isBuildEnvVar("MY_SECRET_KEY")).toBe(false)
    })

    test("returns false for empty string", () => {
      expect(isBuildEnvVar("")).toBe(false)
    })

    test("is case sensitive", () => {
      expect(isBuildEnvVar("node_env")).toBe(false)
      expect(isBuildEnvVar("Node_Env")).toBe(false)
    })
  })

  describe("isDangerousEnvVar", () => {
    test("returns true for dangerous PATH", () => {
      expect(isDangerousEnvVar("PATH")).toBe(true)
    })

    test("returns true for dangerous HOME", () => {
      expect(isDangerousEnvVar("HOME")).toBe(true)
    })

    test("returns true for dangerous LD_PRELOAD", () => {
      expect(isDangerousEnvVar("LD_PRELOAD")).toBe(true)
    })

    test("returns true for dangerous LD_LIBRARY_PATH", () => {
      expect(isDangerousEnvVar("LD_LIBRARY_PATH")).toBe(true)
    })

    test("returns true for dangerous DYLD_LIBRARY_PATH", () => {
      expect(isDangerousEnvVar("DYLD_LIBRARY_PATH")).toBe(true)
    })

    test("returns true for dangerous DYLD_INSERT_LIBRARIES", () => {
      expect(isDangerousEnvVar("DYLD_INSERT_LIBRARIES")).toBe(true)
    })

    test("returns false for safe NODE_ENV", () => {
      expect(isDangerousEnvVar("NODE_ENV")).toBe(false)
    })

    test("returns false for safe RAILS_ENV", () => {
      expect(isDangerousEnvVar("RAILS_ENV")).toBe(false)
    })

    test("returns false for arbitrary custom variable", () => {
      expect(isDangerousEnvVar("CUSTOM_VAR")).toBe(false)
    })

    test("returns false for empty string", () => {
      expect(isDangerousEnvVar("")).toBe(false)
    })

    test("is case sensitive", () => {
      expect(isDangerousEnvVar("path")).toBe(false)
      expect(isDangerousEnvVar("Path")).toBe(false)
    })
  })

  describe("constant values", () => {
    test("contains expected BUILD_ENV_VARS variables", () => {
      expect(BUILD_ENV_VARS).toContain("NODE_ENV")
      expect(BUILD_ENV_VARS).toContain("RAILS_ENV")
      expect(BUILD_ENV_VARS).toContain("NODE_OPTIONS")
      expect(BUILD_ENV_VARS).toContain("BABEL_ENV")
      expect(BUILD_ENV_VARS).toContain("WEBPACK_SERVE")
      expect(BUILD_ENV_VARS).toContain("CLIENT_BUNDLE_ONLY")
      expect(BUILD_ENV_VARS).toContain("SERVER_BUNDLE_ONLY")
    })

    test("has expected length for BUILD_ENV_VARS", () => {
      expect(BUILD_ENV_VARS).toHaveLength(7)
    })

    test("contains expected DANGEROUS_ENV_VARS variables", () => {
      expect(DANGEROUS_ENV_VARS).toContain("PATH")
      expect(DANGEROUS_ENV_VARS).toContain("HOME")
      expect(DANGEROUS_ENV_VARS).toContain("LD_PRELOAD")
      expect(DANGEROUS_ENV_VARS).toContain("LD_LIBRARY_PATH")
      expect(DANGEROUS_ENV_VARS).toContain("DYLD_LIBRARY_PATH")
      expect(DANGEROUS_ENV_VARS).toContain("DYLD_INSERT_LIBRARIES")
    })

    test("has expected length for DANGEROUS_ENV_VARS", () => {
      expect(DANGEROUS_ENV_VARS).toHaveLength(6)
    })

    test("ensures no overlap between BUILD_ENV_VARS and DANGEROUS_ENV_VARS", () => {
      const buildSet = new Set(BUILD_ENV_VARS)
      const dangerousSet = new Set(DANGEROUS_ENV_VARS)

      BUILD_ENV_VARS.forEach((v) => {
        expect(dangerousSet.has(v)).toBe(false)
      })

      DANGEROUS_ENV_VARS.forEach((v) => {
        expect(buildSet.has(v)).toBe(false)
      })
    })
  })

  describe("type predicate behavior", () => {
    test("isBuildEnvVar returns true for valid key", () => {
      const key = "NODE_ENV"
      // Test that the predicate returns true for a valid key
      expect(isBuildEnvVar(key)).toBe(true)
    })

    test("isDangerousEnvVar returns true for dangerous key", () => {
      const key = "PATH"
      // Test that the predicate returns true for a dangerous key
      expect(isDangerousEnvVar(key)).toBe(true)
    })
  })
})
