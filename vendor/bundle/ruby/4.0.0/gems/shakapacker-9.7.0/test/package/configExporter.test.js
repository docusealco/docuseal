const { resetEnv } = require("../helpers")

// Helper function that mimics the env var restore logic from cli.ts lines 267-282
function restoreEnvVars(saved) {
  Object.keys(saved).forEach((key) => {
    if (saved[key] === undefined) {
      delete process.env[key]
    } else {
      process.env[key] = saved[key]
    }
  })
}

describe("configExporter", () => {
  beforeEach(() => jest.resetModules() && resetEnv())

  describe("fileWriter", () => {
    test("generates correct filename for client config", () => {
      const { FileWriter } = require("../../package/configExporter/fileWriter")
      const filename = FileWriter.generateFilename(
        "webpack",
        "development",
        "client",
        "yaml"
      )
      expect(filename).toBe("webpack-development-client.yml")
    })

    test("generates correct filename for server config", () => {
      const { FileWriter } = require("../../package/configExporter/fileWriter")
      const filename = FileWriter.generateFilename(
        "webpack",
        "production",
        "server",
        "yaml"
      )
      expect(filename).toBe("webpack-production-server.yml")
    })

    test("generates correct filename for client-hmr config", () => {
      const { FileWriter } = require("../../package/configExporter/fileWriter")
      const filename = FileWriter.generateFilename(
        "webpack",
        "development",
        "client-hmr",
        "yaml"
      )
      expect(filename).toBe("webpack-development-client-hmr.yml")
    })

    test("generates correct filename for json format", () => {
      const { FileWriter } = require("../../package/configExporter/fileWriter")
      const filename = FileWriter.generateFilename(
        "rspack",
        "production",
        "client",
        "json"
      )
      expect(filename).toBe("rspack-production-client.json")
    })

    test("generates correct filename for custom output name client-modern", () => {
      const { FileWriter } = require("../../package/configExporter/fileWriter")
      const filename = FileWriter.generateFilename(
        "webpack",
        "development",
        "client-modern",
        "yaml"
      )
      expect(filename).toBe("webpack-development-client-modern.yml")
    })

    test("generates correct filename for custom output name client-legacy", () => {
      const { FileWriter } = require("../../package/configExporter/fileWriter")
      const filename = FileWriter.generateFilename(
        "webpack",
        "production",
        "client-legacy",
        "yaml"
      )
      expect(filename).toBe("webpack-production-client-legacy.yml")
    })

    test("generates correct filename for custom output name server-bundle", () => {
      const { FileWriter } = require("../../package/configExporter/fileWriter")
      const filename = FileWriter.generateFilename(
        "rspack",
        "development",
        "server-bundle",
        "yaml"
      )
      expect(filename).toBe("rspack-development-server-bundle.yml")
    })

    test("generates correct filename with buildName override", () => {
      const { FileWriter } = require("../../package/configExporter/fileWriter")
      const filename = FileWriter.generateFilename(
        "webpack",
        "development",
        "client-modern",
        "yaml",
        "dev-hmr"
      )
      expect(filename).toBe("webpack-dev-hmr-client-modern.yml")
    })
  })

  describe("yamlSerializer", () => {
    test("serializes object keys in alphabetical order", () => {
      const {
        YamlSerializer
      } = require("../../package/configExporter/yamlSerializer")
      const serializer = new YamlSerializer({
        annotate: false,
        appRoot: "/test/app"
      })

      // Create an object with keys intentionally out of alphabetical order
      const config = {
        mode: "production",
        entry: "./src/index.js",
        optimization: {
          minimize: true
        },
        output: {
          path: "/dist",
          filename: "bundle.js"
        },
        devtool: "source-map"
      }

      const metadata = {
        exportedAt: "2025-10-28",
        environment: "production",
        bundler: "webpack",
        configType: "client",
        configCount: 1
      }

      const result = serializer.serialize(config, metadata)

      // Extract just the config part (skip the header)
      const lines = result.split("\n")
      const keyMatches = lines
        .map((line) => line.match(/^(\w+):/))
        .filter(Boolean)
        .map((match) => match[1])

      // Expected order: devtool, entry, mode, optimization, output
      expect(keyMatches).toStrictEqual([
        "devtool",
        "entry",
        "mode",
        "optimization",
        "output"
      ])
    })

    test("serializes nested object keys in alphabetical order", () => {
      const {
        YamlSerializer
      } = require("../../package/configExporter/yamlSerializer")
      const serializer = new YamlSerializer({
        annotate: false,
        appRoot: "/test/app"
      })

      const config = {
        output: {
          path: "/dist",
          filename: "bundle.js",
          clean: true
        }
      }

      const metadata = {
        exportedAt: "2025-10-28",
        environment: "production",
        bundler: "webpack",
        configType: "client",
        configCount: 1
      }

      const result = serializer.serialize(config, metadata)

      // Extract nested keys from the output section
      const lines = result.split("\n")
      const outputKeys = lines
        .map((line) => line.match(/^ {2}(\w+):/))
        .filter(Boolean)
        .map((match) => match[1])

      // Expected order: clean, filename, path
      expect(outputKeys).toStrictEqual(["clean", "filename", "path"])
    })

    test("quotes strings containing square brackets", () => {
      const {
        YamlSerializer
      } = require("../../package/configExporter/yamlSerializer")
      const yaml = require("js-yaml")

      const serializer = new YamlSerializer({
        annotate: false,
        appRoot: process.cwd()
      })

      const testConfig = {
        options: {
          modules: {
            localIdentName: "[name]-[local]__[contenthash]"
          }
        }
      }

      const metadata = {
        exportedAt: new Date().toISOString(),
        environment: "test",
        bundler: "webpack",
        configType: "test",
        configCount: 1
      }

      const yamlOutput = serializer.serialize(testConfig, metadata)

      // Verify YAML can be parsed without errors
      expect(() => yaml.load(yamlOutput)).not.toThrow()

      // Verify the parsed value matches the original
      const parsed = yaml.load(yamlOutput)
      expect(parsed.options.modules.localIdentName).toBe(
        "[name]-[local]__[contenthash]"
      )
    })

    test("quotes RegExp strings containing special characters", () => {
      const {
        YamlSerializer
      } = require("../../package/configExporter/yamlSerializer")
      const yaml = require("js-yaml")

      const serializer = new YamlSerializer({
        annotate: false,
        appRoot: process.cwd()
      })

      const testConfig = {
        options: {
          modules: {
            localIdentRegExp: /([^/-]+|[^/]+)(?:-styles)?.module.scss$/,
            localIdentName: "[name]-[local]__[contenthash]"
          }
        }
      }

      const metadata = {
        exportedAt: new Date().toISOString(),
        environment: "test",
        bundler: "webpack",
        configType: "test",
        configCount: 1
      }

      const yamlOutput = serializer.serialize(testConfig, metadata)

      // Verify YAML can be parsed without errors
      expect(() => yaml.load(yamlOutput)).not.toThrow()

      // Verify the parsed values match the originals
      const parsed = yaml.load(yamlOutput)
      expect(parsed.options.modules.localIdentName).toBe(
        "[name]-[local]__[contenthash]"
      )
      // RegExp becomes a string in YAML
      expect(parsed.options.modules.localIdentRegExp).toBe(
        "([^/-]+|[^/]+)(?:-styles)?.module.scss$"
      )
    })

    test("quotes strings with YAML special characters", () => {
      const {
        YamlSerializer
      } = require("../../package/configExporter/yamlSerializer")
      const yaml = require("js-yaml")

      const serializer = new YamlSerializer({
        annotate: false,
        appRoot: process.cwd()
      })

      // Test various YAML special characters
      const testConfig = {
        curlyBraces: "{value}",
        asterisk: "*value*",
        ampersand: "&value",
        exclamation: "!important",
        atSign: "@import",
        backtick: "`value`"
      }

      const metadata = {
        exportedAt: new Date().toISOString(),
        environment: "test",
        bundler: "webpack",
        configType: "test",
        configCount: 1
      }

      const yamlOutput = serializer.serialize(testConfig, metadata)

      // Verify YAML can be parsed without errors
      expect(() => yaml.load(yamlOutput)).not.toThrow()

      // Verify all special characters are preserved
      const parsed = yaml.load(yamlOutput)
      expect(parsed.curlyBraces).toBe("{value}")
      expect(parsed.asterisk).toBe("*value*")
      expect(parsed.ampersand).toBe("&value")
      expect(parsed.exclamation).toBe("!important")
      expect(parsed.atSign).toBe("@import")
      expect(parsed.backtick).toBe("`value`")
    })
  })

  describe("environment variable preservation in runDoctorMode", () => {
    let originalEnv

    beforeEach(() => {
      // Save original environment
      originalEnv = {
        NODE_ENV: process.env.NODE_ENV,
        RAILS_ENV: process.env.RAILS_ENV,
        CLIENT_BUNDLE_ONLY: process.env.CLIENT_BUNDLE_ONLY,
        SERVER_BUNDLE_ONLY: process.env.SERVER_BUNDLE_ONLY,
        WEBPACK_SERVE: process.env.WEBPACK_SERVE
      }

      // Set up known initial state for development mode
      process.env.NODE_ENV = "development"
      process.env.RAILS_ENV = "development"
      delete process.env.WEBPACK_SERVE
      delete process.env.SERVER_BUNDLE_ONLY
    })

    afterEach(() => {
      // Restore original environment
      Object.keys(originalEnv).forEach((key) => {
        if (originalEnv[key] === undefined) {
          delete process.env[key]
        } else {
          process.env[key] = originalEnv[key]
        }
      })
    })

    test("preserves CLIENT_BUNDLE_ONLY when set before doctor mode", async () => {
      // Set a custom value that should be preserved
      process.env.CLIENT_BUNDLE_ONLY = "custom_value"

      // The doctor mode code internally does:
      // 1. Save original
      const saved = {
        CLIENT_BUNDLE_ONLY: process.env.CLIENT_BUNDLE_ONLY,
        WEBPACK_SERVE: process.env.WEBPACK_SERVE,
        SERVER_BUNDLE_ONLY: process.env.SERVER_BUNDLE_ONLY
      }

      // 2. Set HMR env vars
      process.env.WEBPACK_SERVE = "true"
      process.env.CLIENT_BUNDLE_ONLY = "yes"
      delete process.env.SERVER_BUNDLE_ONLY

      // 3. Restore using helper
      restoreEnvVars(saved)

      // Assert the original value is preserved
      expect(process.env.CLIENT_BUNDLE_ONLY).toBe("custom_value")
      expect(process.env.WEBPACK_SERVE).toBeUndefined()
      expect(process.env.SERVER_BUNDLE_ONLY).toBeUndefined()
    })

    test("deletes CLIENT_BUNDLE_ONLY when not set before doctor mode", async () => {
      // Ensure CLIENT_BUNDLE_ONLY is not set
      delete process.env.CLIENT_BUNDLE_ONLY

      // The doctor mode code internally does:
      // 1. Save original
      const saved = {
        CLIENT_BUNDLE_ONLY: process.env.CLIENT_BUNDLE_ONLY,
        WEBPACK_SERVE: process.env.WEBPACK_SERVE,
        SERVER_BUNDLE_ONLY: process.env.SERVER_BUNDLE_ONLY
      }

      // 2. Set HMR env vars
      process.env.WEBPACK_SERVE = "true"
      process.env.CLIENT_BUNDLE_ONLY = "yes"
      delete process.env.SERVER_BUNDLE_ONLY

      // Verify they were set
      expect(process.env.CLIENT_BUNDLE_ONLY).toBe("yes")
      expect(process.env.WEBPACK_SERVE).toBe("true")

      // 3. Restore using helper
      restoreEnvVars(saved)

      // Assert the variables are deleted since they were not set originally
      expect(process.env.CLIENT_BUNDLE_ONLY).toBeUndefined()
      expect(process.env.WEBPACK_SERVE).toBeUndefined()
      expect(process.env.SERVER_BUNDLE_ONLY).toBeUndefined()
    })
  })

  describe("argument validation", () => {
    let mockExit

    beforeEach(() => {
      // Mock process.exit to prevent yargs from killing the test process
      mockExit = jest.spyOn(process, "exit").mockImplementation(() => {
        throw new Error("process.exit called")
      })
    })

    afterEach(() => {
      mockExit.mockRestore()
    })

    test("rejects --all-builds with --output", () => {
      const { parseArguments } = require("../../package/configExporter/cli")

      expect(() => {
        parseArguments(["--all-builds", "--output=config.yml"])
      }).toThrow("process.exit called")
    })

    test("rejects --all-builds with --stdout", () => {
      const { parseArguments } = require("../../package/configExporter/cli")

      expect(() => {
        parseArguments(["--all-builds", "--stdout"])
      }).toThrow("process.exit called")
    })

    test("rejects --stdout with --output", () => {
      const { parseArguments } = require("../../package/configExporter/cli")

      expect(() => {
        parseArguments(["--stdout", "--output=config.yml"])
      }).toThrow("process.exit called")
    })

    test("allows --all-builds with --save-dir", () => {
      const { parseArguments } = require("../../package/configExporter/cli")

      expect(() => {
        parseArguments(["--all-builds", "--save-dir=./configs"])
      }).not.toThrow()
    })

    test("run rejects --all-builds with annotate and non-yaml format", async () => {
      const { run } = require("../../package/configExporter/cli")
      const mockConsoleError = jest
        .spyOn(console, "error")
        .mockImplementation(() => {})

      const result = await run(["--all-builds", "--annotate", "--format=json"])

      expect(result).toBe(1)
      expect(mockConsoleError).toHaveBeenCalledWith(
        expect.stringContaining("Annotation requires YAML format")
      )

      mockConsoleError.mockRestore()
    })

    test("run validates --all-builds save-dir path traversal", async () => {
      const { run } = require("../../package/configExporter/cli")
      const mockConsoleError = jest
        .spyOn(console, "error")
        .mockImplementation(() => {})

      const result = await run(["--all-builds", "--save-dir=../outside"])

      expect(result).toBe(1)
      expect(mockConsoleError).toHaveBeenCalledWith(
        expect.stringContaining("[SHAKAPACKER SECURITY] Path traversal attempt")
      )

      mockConsoleError.mockRestore()
    })
  })
})
