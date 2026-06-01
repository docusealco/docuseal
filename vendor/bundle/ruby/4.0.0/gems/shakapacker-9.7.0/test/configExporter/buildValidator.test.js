const { existsSync, writeFileSync, mkdirSync, rmSync } = require("fs")
const { resolve, join } = require("path")

// Mock child_process.spawn before importing BuildValidator
const mockSpawn = jest.fn()
jest.mock("child_process", () => ({
  spawn: mockSpawn
}))

const { BuildValidator } = require("../../package/configExporter")

// Helper to wait for async operations to start
const waitForAsync = () =>
  new Promise((r) => {
    setImmediate(r)
  })

describe("BuildValidator", () => {
  const testDir = resolve(__dirname, "../tmp/build-validator-test")
  let validator

  beforeEach(() => {
    jest.clearAllMocks()
    mockSpawn.mockClear()
    if (!existsSync(testDir)) {
      mkdirSync(testDir, { recursive: true })
    }
    validator = new BuildValidator({ verbose: false, timeout: 5000 })

    // Mock findBinary to return a path (prevents early return in validateHMRBuild)
    // This will be overridden by tests that specifically test findBinary behavior
    jest
      .spyOn(BuildValidator.prototype, "findBinary")
      .mockReturnValue("/usr/local/bin/webpack")
  })

  afterEach(() => {
    // Restore all mocks to prevent test pollution
    jest.restoreAllMocks()

    if (existsSync(testDir)) {
      rmSync(testDir, { recursive: true, force: true })
    }
  })

  describe("constructor", () => {
    it("should accept verbose and timeout options", () => {
      const v = new BuildValidator({ verbose: true, timeout: 10000 })
      expect(v).toBeDefined()
    })

    it("should use default timeout of 120000ms if not specified", () => {
      const v = new BuildValidator({ verbose: false })
      expect(v).toBeDefined()
    })
  })

  describe("environment variable filtering", () => {
    it("should only include whitelisted environment variables", async () => {
      const configPath = join(testDir, "webpack.config.js")
      writeFileSync(configPath, "module.exports = {}")

      const mockChild = {
        stdout: { on: jest.fn(), removeAllListeners: jest.fn() },
        stderr: { on: jest.fn(), removeAllListeners: jest.fn() },
        on: jest.fn(),
        once: jest.fn(),
        kill: jest.fn(),
        removeAllListeners: jest.fn()
      }

      mockSpawn.mockReturnValue(mockChild)

      const build = {
        name: "test",
        bundler: "webpack",
        environment: {
          NODE_ENV: "production",
          PATH: "/usr/bin",
          MALICIOUS_VAR: "should-be-filtered"
        },
        configFile: configPath,
        outputs: ["client"]
      }

      // Start the validation
      const validationPromise = validator.validateBuild(build, testDir)

      // Simulate exit
      const exitHandler = mockChild.on.mock.calls.find(
        ([event]) => event === "exit"
      )[1]
      exitHandler(0)

      await validationPromise

      // Verify spawn was called with filtered environment
      const spawnCall = mockSpawn.mock.calls[0]
      const { env } = spawnCall[2]
      expect(env.NODE_ENV).toBe("production")
      expect(env.PATH).toBe("/usr/bin")
      expect(env.MALICIOUS_VAR).toBeUndefined()
    })

    it("should warn about suspicious patterns in environment variables", async () => {
      const configPath = join(testDir, "webpack.config.js")
      writeFileSync(configPath, "module.exports = {}")

      const mockChild = {
        stdout: { on: jest.fn(), removeAllListeners: jest.fn() },
        stderr: { on: jest.fn(), removeAllListeners: jest.fn() },
        on: jest.fn(),
        once: jest.fn(),
        kill: jest.fn(),
        removeAllListeners: jest.fn()
      }

      mockSpawn.mockReturnValue(mockChild)

      // Use verbose validator to see security warnings
      const verboseValidator = new BuildValidator({ verbose: true })
      const consoleWarnSpy = jest.spyOn(console, "warn").mockImplementation()

      const build = {
        name: "test",
        bundler: "webpack",
        environment: {
          NODE_ENV: "production; echo hacked",
          PATH: "/usr/bin"
        },
        configFile: configPath,
        outputs: ["client"]
      }

      const validationPromise = verboseValidator.validateBuild(build, testDir)

      const exitHandler = mockChild.on.mock.calls.find(
        ([event]) => event === "exit"
      )[1]
      exitHandler(0)

      await validationPromise

      // Should have warned about suspicious pattern
      expect(consoleWarnSpy).toHaveBeenCalledWith(
        expect.stringContaining("Suspicious pattern")
      )

      consoleWarnSpy.mockRestore()
    })

    it("should include PATH from process.env for binary resolution", async () => {
      const configPath = join(testDir, "webpack.config.js")
      writeFileSync(configPath, "module.exports = {}")

      const originalPath = process.env.PATH

      try {
        process.env.PATH = "/test/path"

        const mockChild = {
          stdout: { on: jest.fn(), removeAllListeners: jest.fn() },
          stderr: { on: jest.fn(), removeAllListeners: jest.fn() },
          on: jest.fn(),
          once: jest.fn(),
          kill: jest.fn(),
          removeAllListeners: jest.fn()
        }

        mockSpawn.mockReturnValue(mockChild)

        const build = {
          name: "test",
          bundler: "webpack",
          environment: { NODE_ENV: "production" },
          configFile: configPath,
          outputs: ["client"]
        }

        const validationPromise = validator.validateBuild(build, testDir)

        const exitHandler = mockChild.on.mock.calls.find(
          ([event]) => event === "exit"
        )[1]
        exitHandler(0)

        await validationPromise

        const spawnCall = mockSpawn.mock.calls[0]
        const { env } = spawnCall[2]
        expect(env.PATH).toBe("/test/path")
      } finally {
        process.env.PATH = originalPath
      }
    })
  })

  describe("validateBuild - static builds", () => {
    it("should successfully validate a static build with JSON output", async () => {
      const configPath = join(testDir, "webpack.config.js")
      writeFileSync(configPath, "module.exports = {}")

      const mockChild = {
        stdout: { on: jest.fn(), removeAllListeners: jest.fn() },
        stderr: { on: jest.fn(), removeAllListeners: jest.fn() },
        on: jest.fn(),
        once: jest.fn(),
        kill: jest.fn(),
        removeAllListeners: jest.fn()
      }

      mockSpawn.mockReturnValue(mockChild)

      const build = {
        name: "prod",
        bundler: "webpack",
        environment: { NODE_ENV: "production" },
        configFile: configPath,
        outputs: ["client"]
      }

      // Start validation (don't await yet, we need to trigger events)
      const validationPromise = validator.validateBuild(build, testDir)

      // Simulate stdout data with valid JSON
      const stdoutHandler = mockChild.stdout.on.mock.calls.find(
        ([event]) => event === "data"
      )[1]
      stdoutHandler(Buffer.from(JSON.stringify({ hash: "abc123", errors: [] })))

      // Simulate successful exit
      const exitHandler = mockChild.on.mock.calls.find(
        ([event]) => event === "exit"
      )[1]
      exitHandler(0)

      // Now await the result
      const result = await validationPromise

      expect(result.success).toBe(true)
      expect(result.buildName).toBe("prod")
      expect(result.errors).toHaveLength(0)
    })

    it("should capture errors from webpack JSON output", async () => {
      const configPath = join(testDir, "webpack.config.js")
      writeFileSync(configPath, "module.exports = {}")

      const mockChild = {
        stdout: { on: jest.fn(), removeAllListeners: jest.fn() },
        stderr: { on: jest.fn(), removeAllListeners: jest.fn() },
        on: jest.fn(),
        once: jest.fn(),
        kill: jest.fn(),
        removeAllListeners: jest.fn()
      }

      mockSpawn.mockReturnValue(mockChild)

      const build = {
        name: "prod",
        bundler: "webpack",
        environment: { NODE_ENV: "production" },
        configFile: configPath,
        outputs: ["client"]
      }

      // Start validation (don't await yet, we need to trigger events)
      const validationPromise = validator.validateBuild(build, testDir)

      // Simulate stdout with errors
      const stdoutHandler = mockChild.stdout.on.mock.calls.find(
        ([event]) => event === "data"
      )[1]
      const errorOutput = JSON.stringify({
        errors: [
          { message: "Module not found: Error: Can't resolve './missing'" },
          "SyntaxError: Unexpected token"
        ]
      })
      stdoutHandler(Buffer.from(errorOutput))

      // Simulate exit with error code
      const exitHandler = mockChild.on.mock.calls.find(
        ([event]) => event === "exit"
      )[1]
      exitHandler(1)

      const result = await validationPromise

      expect(result.success).toBe(false)
      expect(result.errors.length).toBeGreaterThan(0)
      expect(result.errors[0]).toContain("Module not found")
      expect(result.errors[1]).toBe("SyntaxError: Unexpected token")
    })

    it("should handle timeout for static builds", async () => {
      const configPath = join(testDir, "webpack.config.js")
      writeFileSync(configPath, "module.exports = {}")

      const mockChild = {
        stdout: { on: jest.fn(), removeAllListeners: jest.fn() },
        stderr: { on: jest.fn(), removeAllListeners: jest.fn() },
        on: jest.fn(),
        once: jest.fn(),
        kill: jest.fn(),
        removeAllListeners: jest.fn()
      }

      mockSpawn.mockReturnValue(mockChild)

      const build = {
        name: "prod",
        bundler: "webpack",
        environment: { NODE_ENV: "production" },
        configFile: configPath,
        outputs: ["client"]
      }

      const shortTimeoutValidator = new BuildValidator({
        verbose: false,
        timeout: 100
      })

      const validationPromise = shortTimeoutValidator.validateBuild(
        build,
        testDir
      )

      // Wait for timeout to trigger
      await new Promise((r) => {
        setTimeout(r, 150)
      })

      // Timeout should kill the child
      expect(mockChild.kill).toHaveBeenCalledWith("SIGTERM")

      // Simulate exit after kill
      const exitHandler = mockChild.on.mock.calls.find(
        ([event]) => event === "exit"
      )[1]
      exitHandler(143) // SIGTERM exit code

      const result = await validationPromise

      expect(result.success).toBe(false)
      expect(result.errors.some((e) => e.includes("Timeout"))).toBe(true)
    })

    it("should handle buffer overflow with warning", async () => {
      const configPath = join(testDir, "webpack.config.js")
      writeFileSync(configPath, "module.exports = {}")

      const mockChild = {
        stdout: { on: jest.fn(), removeAllListeners: jest.fn() },
        stderr: { on: jest.fn(), removeAllListeners: jest.fn() },
        on: jest.fn(),
        once: jest.fn(),
        kill: jest.fn(),
        removeAllListeners: jest.fn()
      }

      mockSpawn.mockReturnValue(mockChild)

      const build = {
        name: "prod",
        bundler: "webpack",
        environment: { NODE_ENV: "production" },
        configFile: configPath,
        outputs: ["client"]
      }

      // Start validation (don't await yet)
      const validationPromise = validator.validateBuild(build, testDir)

      // Simulate large stdout data (11MB exceeds 10MB limit)
      const stdoutHandler = mockChild.stdout.on.mock.calls.find(
        ([event]) => event === "data"
      )[1]
      const largeBuffer = Buffer.alloc(11 * 1024 * 1024, "a")
      stdoutHandler(largeBuffer)

      // Simulate exit
      const exitHandler = mockChild.on.mock.calls.find(
        ([event]) => event === "exit"
      )[1]
      exitHandler(0)

      const result = await validationPromise

      expect(result.warnings.length).toBeGreaterThan(0)
      expect(
        result.warnings.some((w) => w.includes("buffer limit exceeded"))
      ).toBe(true)
    })

    it("should fallback to stderr parsing when JSON parsing fails", async () => {
      const configPath = join(testDir, "webpack.config.js")
      writeFileSync(configPath, "module.exports = {}")

      const mockChild = {
        stdout: { on: jest.fn(), removeAllListeners: jest.fn() },
        stderr: { on: jest.fn(), removeAllListeners: jest.fn() },
        on: jest.fn(),
        once: jest.fn(),
        kill: jest.fn(),
        removeAllListeners: jest.fn()
      }

      mockSpawn.mockReturnValue(mockChild)

      const build = {
        name: "prod",
        bundler: "webpack",
        environment: { NODE_ENV: "production" },
        configFile: configPath,
        outputs: ["client"]
      }

      // Start validation (don't await yet)
      const validationPromise = validator.validateBuild(build, testDir)

      // Simulate invalid JSON in stdout
      const stdoutHandler = mockChild.stdout.on.mock.calls.find(
        ([event]) => event === "data"
      )[1]
      stdoutHandler(Buffer.from("invalid json output"))

      // Simulate stderr with error
      const stderrHandler = mockChild.stderr.on.mock.calls.find(
        ([event]) => event === "data"
      )[1]
      stderrHandler(Buffer.from("ERROR: Module build failed"))

      // Simulate exit with error code
      const exitHandler = mockChild.on.mock.calls.find(
        ([event]) => event === "exit"
      )[1]
      exitHandler(1)

      const result = await validationPromise

      expect(result.success).toBe(false)
      expect(result.errors.length).toBeGreaterThan(0)
      expect(result.errors.some((e) => e.includes("ERROR"))).toBe(true)
    })

    it("should return error if config file does not exist", async () => {
      const nonExistentPath = join(testDir, "nonexistent.config.js")

      const build = {
        name: "prod",
        bundler: "webpack",
        environment: { NODE_ENV: "production" },
        configFile: nonExistentPath,
        outputs: ["client"]
      }

      const result = await validator.validateBuild(build, testDir)

      expect(result.success).toBe(false)
      expect(result.errors.length).toBeGreaterThan(0)
      expect(result.errors[0]).toContain("Config file not found")
    })

    it("should reject path traversal attacks in config path", async () => {
      // Attempt to access a file outside the appRoot using path traversal
      const maliciousPath = "../../../etc/passwd"

      const build = {
        name: "malicious",
        bundler: "webpack",
        environment: { NODE_ENV: "production" },
        configFile: maliciousPath,
        outputs: ["client"]
      }

      const result = await validator.validateBuild(build, testDir)

      expect(result.success).toBe(false)
      expect(result.errors.length).toBeGreaterThan(0)
      expect(result.errors[0]).toContain(
        "Path must be within project directory"
      )
    })
  })

  describe("validateBuild - HMR builds", () => {
    it("should successfully validate an HMR build", async () => {
      const configPath = join(testDir, "webpack.config.js")
      writeFileSync(configPath, "module.exports = {}")

      const mockChild = {
        stdout: { on: jest.fn(), removeAllListeners: jest.fn() },
        stderr: { on: jest.fn(), removeAllListeners: jest.fn() },
        on: jest.fn(),
        once: jest.fn(),
        kill: jest.fn(),
        removeAllListeners: jest.fn()
      }

      mockSpawn.mockReturnValue(mockChild)

      const build = {
        name: "dev-hmr",
        bundler: "webpack",
        environment: {
          NODE_ENV: "development",
          WEBPACK_SERVE: "true"
        },
        configFile: configPath,
        outputs: ["client"]
      }

      const validationPromise = validator.validateBuild(build, testDir)

      // Wait for spawn to be called
      await waitForAsync()

      // Simulate stdout with success pattern
      const stdoutHandler = mockChild.stdout.on.mock.calls.find(
        ([event]) => event === "data"
      )[1]
      stdoutHandler(Buffer.from("webpack compiled successfully\n"))

      // Wait for the success handler to process and kill the child
      await new Promise((r) => {
        setTimeout(r, 50)
      })

      // Verify kill was called
      expect(mockChild.kill).toHaveBeenCalledWith("SIGTERM")

      // Now simulate exit event (which the success handler triggers via kill)
      const exitHandler = mockChild.on.mock.calls.find(
        ([event]) => event === "exit"
      )[1]
      exitHandler(143) // SIGTERM exit code

      const result = await validationPromise

      expect(result.success).toBe(true)
      expect(result.buildName).toBe("dev-hmr")
    })

    it("should detect HMR from HMR environment variable", async () => {
      const configPath = join(testDir, "webpack.config.js")
      writeFileSync(configPath, "module.exports = {}")

      const mockChild = {
        stdout: { on: jest.fn(), removeAllListeners: jest.fn() },
        stderr: { on: jest.fn(), removeAllListeners: jest.fn() },
        on: jest.fn(),
        once: jest.fn(),
        kill: jest.fn(),
        removeAllListeners: jest.fn()
      }

      mockSpawn.mockReturnValue(mockChild)

      const build = {
        name: "dev-hmr",
        bundler: "webpack",
        environment: {
          NODE_ENV: "development",
          HMR: "true"
        },
        configFile: configPath,
        outputs: ["client"]
      }

      const validationPromise = validator.validateBuild(build, testDir)

      // Wait for spawn to be called
      await waitForAsync()

      // Simulate success
      const stdoutHandler = mockChild.stdout.on.mock.calls.find(
        ([event]) => event === "data"
      )[1]
      stdoutHandler(Buffer.from("Compiled successfully\n"))

      await new Promise((r) => {
        setTimeout(r, 50)
      })

      // Simulate exit event after kill
      const exitHandler = mockChild.on.mock.calls.find(
        ([event]) => event === "exit"
      )[1]
      exitHandler(143) // SIGTERM exit code

      const result = await validationPromise

      expect(result.success).toBe(true)
    })

    it("should capture errors in HMR builds", async () => {
      const configPath = join(testDir, "webpack.config.js")
      writeFileSync(configPath, "module.exports = {}")

      const mockChild = {
        stdout: { on: jest.fn(), removeAllListeners: jest.fn() },
        stderr: { on: jest.fn(), removeAllListeners: jest.fn() },
        on: jest.fn(),
        once: jest.fn(),
        kill: jest.fn(),
        removeAllListeners: jest.fn()
      }

      mockSpawn.mockReturnValue(mockChild)

      const build = {
        name: "dev-hmr",
        bundler: "webpack",
        environment: {
          NODE_ENV: "development",
          WEBPACK_SERVE: "true"
        },
        configFile: configPath,
        outputs: ["client"]
      }

      const validationPromise = validator.validateBuild(build, testDir)

      // Wait for spawn to be called
      await waitForAsync()

      // Simulate error output
      const stderrHandler = mockChild.stderr.on.mock.calls.find(
        ([event]) => event === "data"
      )[1]
      stderrHandler(Buffer.from("ERROR: Failed to compile\n"))
      stderrHandler(
        Buffer.from("Module not found: Can't resolve './component'\n")
      )

      // Simulate exit with error
      const exitHandler = mockChild.on.mock.calls.find(
        ([event]) => event === "exit"
      )[1]
      exitHandler(1)

      const result = await validationPromise

      expect(result.success).toBe(false)
      expect(result.errors.length).toBeGreaterThan(0)
      expect(result.errors.some((e) => e.includes("Failed to compile"))).toBe(
        true
      )
    })

    it("should handle timeout for HMR builds", async () => {
      const configPath = join(testDir, "webpack.config.js")
      writeFileSync(configPath, "module.exports = {}")

      const mockChild = {
        stdout: { on: jest.fn(), removeAllListeners: jest.fn() },
        stderr: { on: jest.fn(), removeAllListeners: jest.fn() },
        on: jest.fn(),
        once: jest.fn(),
        kill: jest.fn(),
        removeAllListeners: jest.fn()
      }

      mockSpawn.mockReturnValue(mockChild)

      const build = {
        name: "dev-hmr",
        bundler: "webpack",
        environment: {
          NODE_ENV: "development",
          WEBPACK_SERVE: "true"
        },
        configFile: configPath,
        outputs: ["client"]
      }

      const shortTimeoutValidator = new BuildValidator({
        verbose: false,
        timeout: 100
      })

      const validationPromise = shortTimeoutValidator.validateBuild(
        build,
        testDir
      )

      // Wait for timeout
      await new Promise((r) => {
        setTimeout(r, 150)
      })

      const result = await validationPromise

      expect(result.success).toBe(false)
      expect(result.errors.some((e) => e.includes("Timeout"))).toBe(true)
      expect(mockChild.kill).toHaveBeenCalledWith("SIGTERM")
      expect(mockChild.stdout.removeAllListeners).toHaveBeenCalledWith()
      expect(mockChild.stderr.removeAllListeners).toHaveBeenCalledWith()
      expect(mockChild.removeAllListeners).toHaveBeenCalledWith()
    })

    it("should cleanup listeners properly after success", async () => {
      const configPath = join(testDir, "webpack.config.js")
      writeFileSync(configPath, "module.exports = {}")

      const mockChild = {
        stdout: { on: jest.fn(), removeAllListeners: jest.fn() },
        stderr: { on: jest.fn(), removeAllListeners: jest.fn() },
        on: jest.fn(),
        once: jest.fn(),
        kill: jest.fn(),
        removeAllListeners: jest.fn()
      }

      mockSpawn.mockReturnValue(mockChild)

      const build = {
        name: "dev-hmr",
        bundler: "webpack",
        environment: {
          NODE_ENV: "development",
          WEBPACK_SERVE: "true"
        },
        configFile: configPath,
        outputs: ["client"]
      }

      const validationPromise = validator.validateBuild(build, testDir)

      // Simulate success
      const stdoutHandler = mockChild.stdout.on.mock.calls.find(
        ([event]) => event === "data"
      )[1]
      stdoutHandler(Buffer.from("webpack compiled successfully\n"))

      // Wait for cleanup
      await new Promise((r) => {
        setTimeout(r, 50)
      })

      // Simulate exit event after kill
      const exitHandler = mockChild.on.mock.calls.find(
        ([event]) => event === "exit"
      )[1]
      exitHandler(143) // SIGTERM exit code

      await validationPromise

      // Verify cleanup was called after exit
      expect(mockChild.stdout.removeAllListeners).toHaveBeenCalledWith()
      expect(mockChild.stderr.removeAllListeners).toHaveBeenCalledWith()
      expect(mockChild.removeAllListeners).toHaveBeenCalledWith()
    })

    it("should handle delayed exit after SIGTERM gracefully", async () => {
      const configPath = join(testDir, "webpack.config.js")
      writeFileSync(configPath, "module.exports = {}")

      const mockChild = {
        stdout: { on: jest.fn(), removeAllListeners: jest.fn() },
        stderr: { on: jest.fn(), removeAllListeners: jest.fn() },
        on: jest.fn(),
        once: jest.fn(),
        kill: jest.fn(),
        removeAllListeners: jest.fn()
      }

      mockSpawn.mockReturnValue(mockChild)

      const build = {
        name: "dev-hmr",
        bundler: "webpack",
        environment: {
          NODE_ENV: "development",
          WEBPACK_SERVE: "true"
        },
        configFile: configPath,
        outputs: ["client"]
      }

      const validationPromise = validator.validateBuild(build, testDir)

      // Simulate success pattern
      const stdoutHandler = mockChild.stdout.on.mock.calls.find(
        ([event]) => event === "data"
      )[1]
      stdoutHandler(Buffer.from("webpack compiled successfully\n"))

      // Wait for kill to be called
      await new Promise((r) => {
        setTimeout(r, 50)
      })
      expect(mockChild.kill).toHaveBeenCalledWith("SIGTERM")

      // Simulate delayed exit (process takes time to clean up)
      await new Promise((r) => {
        setTimeout(r, 200)
      })

      const exitHandler = mockChild.on.mock.calls.find(
        ([event]) => event === "exit"
      )[1]
      exitHandler(143) // SIGTERM exit code

      const result = await validationPromise

      // Should still successfully complete
      expect(result.success).toBe(true)
      expect(result.buildName).toBe("dev-hmr")
    })

    it("should handle multiple rapid success patterns without duplicate resolution", async () => {
      const configPath = join(testDir, "webpack.config.js")
      writeFileSync(configPath, "module.exports = {}")

      const mockChild = {
        stdout: { on: jest.fn(), removeAllListeners: jest.fn() },
        stderr: { on: jest.fn(), removeAllListeners: jest.fn() },
        on: jest.fn(),
        once: jest.fn(),
        kill: jest.fn(),
        removeAllListeners: jest.fn()
      }

      mockSpawn.mockReturnValue(mockChild)

      const build = {
        name: "dev-hmr",
        bundler: "webpack",
        environment: {
          NODE_ENV: "development",
          WEBPACK_SERVE: "true"
        },
        configFile: configPath,
        outputs: ["client"]
      }

      const validationPromise = validator.validateBuild(build, testDir)

      // Simulate multiple success patterns in rapid succession
      const stdoutHandler = mockChild.stdout.on.mock.calls.find(
        ([event]) => event === "data"
      )[1]
      stdoutHandler(Buffer.from("webpack compiled successfully\n"))
      stdoutHandler(Buffer.from("Compiled successfully\n"))
      stdoutHandler(Buffer.from("webpack: Compiled successfully\n"))

      await new Promise((r) => {
        setTimeout(r, 50)
      })

      // Should only kill once
      expect(mockChild.kill).toHaveBeenCalledTimes(1)

      const exitHandler = mockChild.on.mock.calls.find(
        ([event]) => event === "exit"
      )[1]
      exitHandler(143)

      const result = await validationPromise
      expect(result.success).toBe(true)
    })

    it("should return error if webpack-dev-server binary not found", async () => {
      // Create a validator that will fail to find binary
      const build = {
        name: "dev-hmr",
        bundler: "webpack",
        environment: {
          NODE_ENV: "development",
          WEBPACK_SERVE: "true"
        },
        configFile: join(testDir, "webpack.config.js"),
        outputs: ["client"]
      }

      // Override findBinary to return null
      const findBinarySpy = jest
        .spyOn(BuildValidator.prototype, "findBinary")
        .mockImplementation()
        .mockReturnValue(null)

      try {
        const result = await validator.validateBuild(build, testDir)

        expect(result.success).toBe(false)
        expect(result.errors.length).toBeGreaterThan(0)
        expect(result.errors[0]).toContain("Could not find")
        expect(result.errors[0]).toContain("webpack-dev-server")
      } finally {
        // Always restore the spy
        findBinarySpy.mockRestore()
      }
    })

    it("should use strict binary resolution in CI environments", async () => {
      // Save original env
      const originalCI = process.env.CI

      // Set CI=true
      process.env.CI = "true"

      // Mock findBinary to simulate not finding binary locally
      const findBinarySpy = jest
        .spyOn(BuildValidator.prototype, "findBinary")
        .mockImplementation()
        .mockReturnValue(null)

      try {
        // Create validator (should auto-enable strict mode)
        const ciValidator = new BuildValidator({ verbose: false })

        const build = {
          name: "dev-hmr",
          bundler: "webpack",
          environment: {
            NODE_ENV: "development",
            WEBPACK_SERVE: "true"
          },
          configFile: join(testDir, "webpack.config.js"),
          outputs: ["client"]
        }

        const result = await ciValidator.validateBuild(build, testDir)

        expect(result.success).toBe(false)
        expect(result.errors[0]).toContain("Could not find")
      } finally {
        // Always restore the spy and env var
        findBinarySpy.mockRestore()
        process.env.CI = originalCI
      }
    })
  })

  describe("formatResults", () => {
    it("should format successful results correctly", () => {
      const results = [
        {
          buildName: "prod",
          success: true,
          errors: [],
          warnings: [],
          output: []
        },
        {
          buildName: "dev",
          success: true,
          errors: [],
          warnings: ["Deprecation warning"],
          output: []
        }
      ]

      const formatted = validator.formatResults(results)

      expect(formatted).toContain("Build Validation Results")
      expect(formatted).toContain("✅ Build: prod")
      expect(formatted).toContain("✅ Build: dev")
      expect(formatted).toContain("2/2 builds passed")
      expect(formatted).toContain("1 warning(s)")
    })

    it("should format failed results correctly", () => {
      const results = [
        {
          buildName: "prod",
          success: false,
          errors: ["Module not found", "Syntax error"],
          warnings: [],
          output: ["error line 1", "error line 2"]
        }
      ]

      const formatted = validator.formatResults(results)

      expect(formatted).toContain("❌ Build: prod")
      expect(formatted).toContain("2 error(s)")
      expect(formatted).toContain("Module not found")
      expect(formatted).toContain("Syntax error")
      expect(formatted).toContain("0/1 builds passed, 1 failed")
    })

    it("should show output section for errors", () => {
      const results = [
        {
          buildName: "prod",
          success: false,
          errors: ["Build failed"],
          warnings: [],
          output: ["detailed error output"]
        }
      ]

      const formatted = validator.formatResults(results)

      expect(formatted).toContain("Full Output:")
      expect(formatted).toContain("detailed error output")
    })

    it("should handle mixed success and failure", () => {
      const results = [
        {
          buildName: "prod",
          success: true,
          errors: [],
          warnings: [],
          output: []
        },
        {
          buildName: "dev",
          success: false,
          errors: ["Failed"],
          warnings: [],
          output: []
        }
      ]

      const formatted = validator.formatResults(results)

      expect(formatted).toContain("✅ Build: prod")
      expect(formatted).toContain("❌ Build: dev")
      expect(formatted).toContain("1/2 builds passed, 1 failed")
    })
  })

  describe("success pattern detection", () => {
    it("should not false-positive on success patterns in error messages", async () => {
      const configPath = join(testDir, "webpack.config.js")
      writeFileSync(configPath, "module.exports = {}")

      const mockChild = {
        stdout: { on: jest.fn(), removeAllListeners: jest.fn() },
        stderr: { on: jest.fn(), removeAllListeners: jest.fn() },
        on: jest.fn(),
        once: jest.fn(),
        kill: jest.fn(),
        removeAllListeners: jest.fn()
      }

      mockSpawn.mockReturnValue(mockChild)

      const build = {
        name: "dev-hmr",
        bundler: "webpack",
        environment: {
          NODE_ENV: "development",
          WEBPACK_SERVE: "true"
        },
        configFile: configPath,
        outputs: ["client"]
      }

      // Start validation (don't await yet)
      const validationPromise = validator.validateBuild(build, testDir)

      // Wait for spawn to be called
      await waitForAsync()

      // Simulate output with success pattern in error context
      const stdoutHandler = mockChild.stdout.on.mock.calls.find(
        ([event]) => event === "data"
      )[1]
      stdoutHandler(
        Buffer.from(
          "ERROR: Expected 'Built at:' timestamp but found invalid format\n"
        )
      )

      // Simulate actual error exit
      const exitHandler = mockChild.on.mock.calls.find(
        ([event]) => event === "exit"
      )[1]
      exitHandler(1)

      const result = await validationPromise

      // Should recognize as error, not success
      expect(result.errors.length).toBeGreaterThan(0)
    })

    it("should detect modern webpack 5.x compiled messages", async () => {
      const configPath = join(testDir, "webpack.config.js")
      writeFileSync(configPath, "module.exports = {}")

      const mockChild = {
        stdout: { on: jest.fn(), removeAllListeners: jest.fn() },
        stderr: { on: jest.fn(), removeAllListeners: jest.fn() },
        on: jest.fn(),
        once: jest.fn(),
        kill: jest.fn(),
        removeAllListeners: jest.fn()
      }

      mockSpawn.mockReturnValue(mockChild)

      const build = {
        name: "dev-hmr",
        bundler: "webpack",
        environment: {
          NODE_ENV: "development",
          WEBPACK_SERVE: "true"
        },
        configFile: configPath,
        outputs: ["client"]
      }

      const validationPromise = validator.validateBuild(build, testDir)

      // Wait for spawn to be called
      await waitForAsync()

      const stdoutHandler = mockChild.stdout.on.mock.calls.find(
        ([event]) => event === "data"
      )[1]
      // Simulate webpack 5.x.x compiled message
      stdoutHandler(Buffer.from("webpack 5.95.0 compiled successfully\n"))

      await new Promise((r) => {
        setTimeout(r, 50)
      })

      const exitHandler = mockChild.on.mock.calls.find(
        ([event]) => event === "exit"
      )[1]
      exitHandler(143)

      const result = await validationPromise
      expect(result.success).toBe(true)
    })

    it("should detect modern rspack 0.x compiled messages", async () => {
      const configPath = join(testDir, "rspack.config.js")
      writeFileSync(configPath, "module.exports = {}")

      const mockChild = {
        stdout: { on: jest.fn(), removeAllListeners: jest.fn() },
        stderr: { on: jest.fn(), removeAllListeners: jest.fn() },
        on: jest.fn(),
        once: jest.fn(),
        kill: jest.fn(),
        removeAllListeners: jest.fn()
      }

      mockSpawn.mockReturnValue(mockChild)

      const build = {
        name: "dev-hmr",
        bundler: "rspack",
        environment: {
          NODE_ENV: "development",
          HMR: "true"
        },
        configFile: configPath,
        outputs: ["client"]
      }

      const validationPromise = validator.validateBuild(build, testDir)

      // Wait for spawn to be called
      await waitForAsync()

      const stdoutHandler = mockChild.stdout.on.mock.calls.find(
        ([event]) => event === "data"
      )[1]
      // Simulate rspack 0.x.x compiled message
      stdoutHandler(Buffer.from("rspack 0.7.5 compiled successfully\n"))

      await new Promise((r) => {
        setTimeout(r, 50)
      })

      const exitHandler = mockChild.on.mock.calls.find(
        ([event]) => event === "exit"
      )[1]
      exitHandler(143)

      const result = await validationPromise
      expect(result.success).toBe(true)
    })

    it("should not match incomplete version patterns", async () => {
      const configPath = join(testDir, "webpack.config.js")
      writeFileSync(configPath, "module.exports = {}")

      const mockChild = {
        stdout: { on: jest.fn(), removeAllListeners: jest.fn() },
        stderr: { on: jest.fn(), removeAllListeners: jest.fn() },
        on: jest.fn(),
        once: jest.fn(),
        kill: jest.fn(),
        removeAllListeners: jest.fn()
      }

      mockSpawn.mockReturnValue(mockChild)

      const build = {
        name: "dev-hmr",
        bundler: "webpack",
        environment: {
          NODE_ENV: "development",
          WEBPACK_SERVE: "true"
        },
        configFile: configPath,
        outputs: ["client"]
      }

      const shortTimeoutValidator = new BuildValidator({
        verbose: false,
        timeout: 100
      })

      const validationPromise = shortTimeoutValidator.validateBuild(
        build,
        testDir
      )

      // Wait for spawn to be called
      await waitForAsync()

      const stdoutHandler = mockChild.stdout.on.mock.calls.find(
        ([event]) => event === "data"
      )[1]
      // These should NOT match the success patterns - they're warnings/errors about versions
      stdoutHandler(Buffer.from("WARNING: webpack 5.x may have issues\n"))
      stdoutHandler(Buffer.from("ERROR: rspack 0.x requires node 18+\n"))

      // Wait for timeout (since no success pattern was matched)
      await new Promise((r) => {
        setTimeout(r, 150)
      })

      expect(mockChild.kill).toHaveBeenCalledWith("SIGTERM")

      const exitHandler = mockChild.on.mock.calls.find(
        ([event]) => event === "exit"
      )[1]
      exitHandler(143) // SIGTERM exit

      const result = await validationPromise

      // Should have timed out, not succeeded
      expect(result.success).toBe(false)
      // Should have captured the warning and error
      expect(result.warnings.some((w) => w.includes("webpack 5.x"))).toBe(true)
      expect(result.errors.some((e) => e.includes("rspack 0.x"))).toBe(true)
      // Should have timeout error
      expect(result.errors.some((e) => e.includes("Timeout"))).toBe(true)
    })
  })

  describe("error spawn handling", () => {
    it("should handle spawn error gracefully", async () => {
      const configPath = join(testDir, "webpack.config.js")
      writeFileSync(configPath, "module.exports = {}")

      const mockChild = {
        stdout: { on: jest.fn(), removeAllListeners: jest.fn() },
        stderr: { on: jest.fn(), removeAllListeners: jest.fn() },
        on: jest.fn(),
        once: jest.fn(),
        kill: jest.fn(),
        removeAllListeners: jest.fn()
      }

      mockSpawn.mockReturnValue(mockChild)

      const build = {
        name: "prod",
        bundler: "webpack",
        environment: { NODE_ENV: "production" },
        configFile: configPath,
        outputs: ["client"]
      }

      // Start validation (don't await yet)
      const validationPromise = validator.validateBuild(build, testDir)

      // Simulate spawn error
      const errorHandler = mockChild.on.mock.calls.find(
        ([event]) => event === "error"
      )[1]
      errorHandler(new Error("ENOENT: command not found"))

      // Now await the result
      const result = await validationPromise

      expect(result.success).toBe(false)
      expect(result.errors.length).toBeGreaterThan(0)
      expect(result.errors[0]).toContain("Failed to start")
    })
  })
})
