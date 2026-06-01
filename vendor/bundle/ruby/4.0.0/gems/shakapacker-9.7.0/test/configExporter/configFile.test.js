/* eslint-disable no-template-curly-in-string */
const {
  writeFileSync,
  mkdirSync,
  rmSync,
  existsSync,
  symlinkSync
} = require("fs")
const { resolve, join } = require("path")
const { tmpdir } = require("os")
const {
  ConfigFileLoader,
  generateSampleConfigFile
} = require("../../package/configExporter")

describe("ConfigFileLoader", () => {
  const testDir = resolve(__dirname, "../tmp/config-file-test")
  let configPath

  beforeEach(() => {
    // Create test directory
    if (!existsSync(testDir)) {
      mkdirSync(testDir, { recursive: true })
    }
    mkdirSync(join(testDir, "config"), { recursive: true })
    configPath = join(testDir, "config/shakapacker-builds.yml")
  })

  afterEach(() => {
    // Clean up test directory
    if (existsSync(testDir)) {
      rmSync(testDir, { recursive: true, force: true })
    }
  })

  describe("validateConfigPath", () => {
    it("should reject path traversal attempts with ..", () => {
      // Use a path that's definitely outside the project
      const maliciousPath = "/etc/passwd"
      expect(() => {
        // eslint-disable-next-line no-new
        new ConfigFileLoader(maliciousPath)
      }).toThrow(/Config file must be within project directory/)
    })

    it("should reject symlink traversal to files outside project", async () => {
      const outsideFile = join(tmpdir(), `test-outside-${Date.now()}.yml`)
      const symlinkPath = join(testDir, "symlink-config.yml")

      const cleanup = () => {
        try {
          rmSync(symlinkPath, { force: true })
          // eslint-disable-next-line no-empty
        } catch {}
        try {
          rmSync(outsideFile, { force: true })
          // eslint-disable-next-line no-empty
        } catch {}
      }

      try {
        // Create a real file outside the project (in system temp dir)
        writeFileSync(
          outsideFile,
          "builds:\n  test:\n    outputs:\n      - client\n"
        )

        // Attempt to create symlink
        try {
          symlinkSync(outsideFile, symlinkPath)
        } catch (error) {
          // Skip test if symlinks aren't supported or require elevated permissions
          const skipCodes = ["EPERM", "ENOSYS", "EACCES"]
          cleanup()
          // eslint-disable-next-line jest/no-conditional-expect
          expect(skipCodes).toContain(error.code)
          return
        }

        // Verify that loading via symlink is rejected
        expect(() => {
          // eslint-disable-next-line no-new
          new ConfigFileLoader(symlinkPath)
        }).toThrow(/Config file must be within project directory/)

        cleanup()
      } catch (error) {
        cleanup()
        throw error
      }
    })

    it("should accept paths within the project directory", () => {
      expect(() => {
        // eslint-disable-next-line no-new
        new ConfigFileLoader(configPath)
      }).not.toThrow()
    })
  })

  describe("exists", () => {
    it("should return false when config file does not exist", () => {
      const loader = new ConfigFileLoader(configPath)
      expect(loader.exists()).toBe(false)
    })

    it("should return true when config file exists", () => {
      writeFileSync(configPath, "default_bundler: webpack\nbuilds: {}")
      const loader = new ConfigFileLoader(configPath)
      expect(loader.exists()).toBe(true)
    })
  })

  describe("load", () => {
    it("should load valid YAML config", () => {
      writeFileSync(
        configPath,
        `
default_bundler: rspack
builds:
  dev:
    description: Development build
    environment:
      NODE_ENV: development
    outputs:
      - client
      - server
`
      )
      const loader = new ConfigFileLoader(configPath)
      const loaded = loader.load()
      expect(loaded.default_bundler).toBe("rspack")
      expect(loaded.builds.dev).toBeDefined()
      expect(loaded.builds.dev.description).toBe("Development build")
    })

    it("should throw error for malformed YAML", () => {
      writeFileSync(configPath, "invalid: yaml: content:\n  - broken")
      const loader = new ConfigFileLoader(configPath)
      expect(() => loader.load()).toThrow(Error)
    })

    it("should throw error if builds key is missing", () => {
      writeFileSync(configPath, "default_bundler: webpack")
      const loader = new ConfigFileLoader(configPath)
      expect(() => loader.load()).toThrow(/must contain a 'builds'/)
    })

    it("should throw error if builds is not an object", () => {
      writeFileSync(configPath, "builds: []")
      const loader = new ConfigFileLoader(configPath)
      expect(() => loader.load()).toThrow(/must contain at least one build/)
    })
  })

  describe("resolveBuild", () => {
    beforeEach(() => {
      writeFileSync(
        configPath,
        `
default_bundler: rspack
builds:
  dev:
    description: Development build
    environment:
      NODE_ENV: development
      RAILS_ENV: development
    outputs:
      - client
      - server
  prod:
    description: Production build
    bundler: webpack
    environment:
      NODE_ENV: production
    outputs:
      - client
`
      )
    })

    it("should throw error for non-existent build", () => {
      const loader = new ConfigFileLoader(configPath)
      expect(() => {
        loader.resolveBuild("nonexistent", {}, "webpack")
      }).toThrow(/Build 'nonexistent' not found/)
    })

    it("should resolve build with environment variables", () => {
      const loader = new ConfigFileLoader(configPath)
      const resolved = loader.resolveBuild("dev", {}, "webpack")
      expect(resolved.name).toBe("dev")
      expect(resolved.environment.NODE_ENV).toBe("development")
      expect(resolved.environment.RAILS_ENV).toBe("development")
      expect(resolved.outputs).toStrictEqual(["client", "server"])
    })

    it("should use build-specific bundler over default", () => {
      const loader = new ConfigFileLoader(configPath)
      const resolved = loader.resolveBuild("prod", {}, "rspack")
      expect(resolved.bundler).toBe("webpack")
    })

    it("should use CLI bundler option over everything", () => {
      const loader = new ConfigFileLoader(configPath)
      const resolved = loader.resolveBuild(
        "prod",
        { bundler: "rspack" },
        "webpack"
      )
      expect(resolved.bundler).toBe("rspack")
    })
  })

  describe("edge case validation", () => {
    it("should throw error for empty outputs array", () => {
      writeFileSync(
        configPath,
        `
builds:
  bad:
    environment:
      NODE_ENV: development
    outputs: []
`
      )
      const loader = new ConfigFileLoader(configPath)
      expect(() => {
        loader.resolveBuild("bad", {}, "webpack")
      }).toThrow(/empty outputs array/)
    })

    it("should throw error for duplicate outputs", () => {
      writeFileSync(
        configPath,
        `
builds:
  bad:
    environment:
      NODE_ENV: development
    outputs:
      - client
      - client
      - server
`
      )
      const loader = new ConfigFileLoader(configPath)
      expect(() => {
        loader.resolveBuild("bad", {}, "webpack")
      }).toThrow(/duplicate output types/)
    })

    it("should throw error for invalid config file path with path traversal", () => {
      writeFileSync(
        configPath,
        `
builds:
  bad:
    environment:
      NODE_ENV: development
    config: ../../../malicious.js
    outputs:
      - client
`
      )
      const loader = new ConfigFileLoader(configPath)
      expect(() => {
        loader.resolveBuild("bad", {}, "webpack")
      }).toThrow(/Invalid config file path/)
    })
  })

  describe("environment variable expansion", () => {
    beforeEach(() => {
      process.env.TEST_VAR = "test-value"
      process.env.BUNDLER_VAR = "should-not-be-used"
    })

    afterEach(() => {
      delete process.env.TEST_VAR
      delete process.env.BUNDLER_VAR
    })

    it("should expand ${BUNDLER} variable", () => {
      writeFileSync(
        configPath,
        "builds:\n  test:\n    environment:\n      CONFIG_PATH: config/${BUNDLER}/config.js\n    outputs:\n      - client\n"
      )
      const loader = new ConfigFileLoader(configPath)
      const resolved = loader.resolveBuild("test", {}, "rspack")
      expect(resolved.environment.CONFIG_PATH).toBe("config/rspack/config.js")
    })

    it("should expand ${VAR} from environment", () => {
      writeFileSync(
        configPath,
        "builds:\n  test:\n    environment:\n      CUSTOM: ${TEST_VAR}\n    outputs:\n      - client\n"
      )
      const loader = new ConfigFileLoader(configPath)
      const resolved = loader.resolveBuild("test", {}, "webpack")
      expect(resolved.environment.CUSTOM).toBe("test-value")
    })

    it("should expand ${VAR:-default} with default value", () => {
      writeFileSync(
        configPath,
        "builds:\n  test:\n    environment:\n      WITH_DEFAULT: ${NONEXISTENT:-fallback-value}\n    outputs:\n      - client\n"
      )
      const loader = new ConfigFileLoader(configPath)
      const resolved = loader.resolveBuild("test", {}, "webpack")
      expect(resolved.environment.WITH_DEFAULT).toBe("fallback-value")
    })

    it("should use environment value over default in ${VAR:-default}", () => {
      writeFileSync(
        configPath,
        "builds:\n  test:\n    environment:\n      WITH_DEFAULT: ${TEST_VAR:-fallback-value}\n    outputs:\n      - client\n"
      )
      const loader = new ConfigFileLoader(configPath)
      const resolved = loader.resolveBuild("test", {}, "webpack")
      expect(resolved.environment.WITH_DEFAULT).toBe("test-value")
    })

    it("should reject invalid environment variable names", () => {
      writeFileSync(
        configPath,
        "builds:\n  test:\n    environment:\n      BAD: ${Invalid-Var-Name}\n    outputs:\n      - client\n"
      )
      const loader = new ConfigFileLoader(configPath)
      const resolved = loader.resolveBuild("test", {}, "webpack")
      // Should not expand invalid var names (contains hyphen)
      expect(resolved.environment.BAD).toBe("${Invalid-Var-Name}")
    })
  })

  describe("bundler_env conversion", () => {
    it("should convert bundler_env to CLI arguments", () => {
      writeFileSync(
        configPath,
        `
builds:
  test:
    environment:
      NODE_ENV: production
    bundler_env:
      target: modern
      instrumented: true
      disabled: false
    outputs:
      - client
`
      )
      const loader = new ConfigFileLoader(configPath)
      const resolved = loader.resolveBuild("test", {}, "webpack")

      // YAML parses booleans as true/false, or as strings "true"/"false"
      // The code handles both cases: true or "true" becomes a flag, false/"false" is ignored
      // Expected format: ['--env', 'target=modern', '--env', 'instrumented']
      expect(resolved.bundlerEnvArgs).toContain("--env")
      expect(resolved.bundlerEnvArgs).toContain("target=modern")

      // Boolean true becomes a flag (--env key), false is ignored
      const argsString = resolved.bundlerEnvArgs.join(" ")
      expect(argsString).toContain("--env instrumented")
      expect(argsString).not.toContain("disabled")
    })
  })
})

describe("generateSampleConfigFile", () => {
  it("should generate valid YAML string", () => {
    const content = generateSampleConfigFile()
    expect(content).toContain("builds:")
    expect(content).toContain("dev-hmr:")
    expect(content).toContain("dev_server: true")
    expect(content).toContain("dev:")
    expect(content).toContain("prod:")
  })

  it("should include documentation comments", () => {
    const content = generateSampleConfigFile()
    expect(content).toContain("# Bundler Build Configurations")
    expect(content).toContain("HMR")
    expect(content).toContain("production")
  })

  it("should escape template literal variables correctly", () => {
    const content = generateSampleConfigFile()
    // Should have ${BUNDLER} not actual 'webpack' or 'rspack'
    expect(content).toContain("${BUNDLER}")
    expect(content).toContain("${RAILS_ENV:-staging}")
  })
})
