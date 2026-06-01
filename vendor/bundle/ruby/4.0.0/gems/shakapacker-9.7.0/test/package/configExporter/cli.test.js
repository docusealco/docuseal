const { resetEnv } = require("../../helpers")

describe("configExporter/cli", () => {
  let mockExit

  beforeEach(() => {
    jest.resetModules()
    resetEnv()
    // Mock process.exit to prevent yargs from killing the test process
    mockExit = jest.spyOn(process, "exit").mockImplementation(() => {
      throw new Error("process.exit called")
    })
  })

  afterEach(() => {
    mockExit.mockRestore()
  })

  describe("parseArguments", () => {
    test("parses basic CLI options", () => {
      const { parseArguments } = require("../../../package/configExporter/cli")
      const options = parseArguments(["--env=production", "--bundler=webpack"])

      expect(options.env).toBe("production")
      expect(options.bundler).toBe("webpack")
    })

    test("parses --init flag", () => {
      const { parseArguments } = require("../../../package/configExporter/cli")
      const options = parseArguments(["--init"])

      expect(options.init).toBe(true)
    })

    test("parses --ssr flag with --init", () => {
      const { parseArguments } = require("../../../package/configExporter/cli")
      const options = parseArguments(["--init", "--ssr"])

      expect(options.init).toBe(true)
      expect(options.ssr).toBe(true)
    })

    test("parses --doctor flag", () => {
      const { parseArguments } = require("../../../package/configExporter/cli")
      const options = parseArguments(["--doctor"])

      expect(options.doctor).toBe(true)
    })

    test("parses --stdout flag", () => {
      const { parseArguments } = require("../../../package/configExporter/cli")
      const options = parseArguments(["--stdout"])

      expect(options.stdout).toBe(true)
    })

    test("parses --output flag", () => {
      const { parseArguments } = require("../../../package/configExporter/cli")
      const options = parseArguments(["--output=config.yml"])

      expect(options.output).toBe("config.yml")
    })

    test("parses --save-dir flag", () => {
      const { parseArguments } = require("../../../package/configExporter/cli")
      const options = parseArguments(["--save-dir=./configs"])

      expect(options.saveDir).toBe("./configs")
    })

    test("parses --format=yaml", () => {
      const { parseArguments } = require("../../../package/configExporter/cli")
      const options = parseArguments(["--format=yaml"])

      expect(options.format).toBe("yaml")
    })

    test("parses --format=json", () => {
      const { parseArguments } = require("../../../package/configExporter/cli")
      const options = parseArguments(["--format=json"])

      expect(options.format).toBe("json")
    })

    test("parses --format=inspect", () => {
      const { parseArguments } = require("../../../package/configExporter/cli")
      const options = parseArguments(["--format=inspect"])

      expect(options.format).toBe("inspect")
    })

    test("parses --annotate flag", () => {
      const { parseArguments } = require("../../../package/configExporter/cli")
      const options = parseArguments(["--annotate"])

      expect(options.annotate).toBe(true)
    })

    test("parses --no-annotate flag", () => {
      const { parseArguments } = require("../../../package/configExporter/cli")
      const options = parseArguments(["--no-annotate"])

      expect(options.annotate).toBe(false)
    })

    test("parses --depth with number", () => {
      const { parseArguments } = require("../../../package/configExporter/cli")
      const options = parseArguments(["--depth=10"])

      expect(options.depth).toBe(10)
    })

    test("parses --depth=null to return null", () => {
      const { parseArguments } = require("../../../package/configExporter/cli")
      const options = parseArguments(["--depth=null"])

      expect(options.depth).toBeNull()
    })

    test("parses --verbose flag", () => {
      const { parseArguments } = require("../../../package/configExporter/cli")
      const options = parseArguments(["--verbose"])

      expect(options.verbose).toBe(true)
    })

    test("parses --client-only flag", () => {
      const { parseArguments } = require("../../../package/configExporter/cli")
      const options = parseArguments(["--client-only"])

      expect(options.clientOnly).toBe(true)
    })

    test("parses --server-only flag", () => {
      const { parseArguments } = require("../../../package/configExporter/cli")
      const options = parseArguments(["--server-only"])

      expect(options.serverOnly).toBe(true)
    })

    test("parses --webpack flag", () => {
      const { parseArguments } = require("../../../package/configExporter/cli")
      const options = parseArguments(["--webpack"])

      expect(options.bundler).toBe("webpack")
    })

    test("parses --rspack flag", () => {
      const { parseArguments } = require("../../../package/configExporter/cli")
      const options = parseArguments(["--rspack"])

      expect(options.bundler).toBe("rspack")
    })

    test("parses --build flag", () => {
      const { parseArguments } = require("../../../package/configExporter/cli")
      const options = parseArguments(["--build=dev"])

      expect(options.build).toBe("dev")
    })

    test("parses --all-builds flag", () => {
      const { parseArguments } = require("../../../package/configExporter/cli")
      const options = parseArguments(["--all-builds"])

      expect(options.allBuilds).toBe(true)
    })

    test("parses --list-builds flag", () => {
      const { parseArguments } = require("../../../package/configExporter/cli")
      const options = parseArguments(["--list-builds"])

      expect(options.listBuilds).toBe(true)
    })

    test("parses --validate flag", () => {
      const { parseArguments } = require("../../../package/configExporter/cli")
      const options = parseArguments(["--validate"])

      expect(options.validate).toBe(true)
    })

    test("parses --validate-build flag", () => {
      const { parseArguments } = require("../../../package/configExporter/cli")
      const options = parseArguments(["--validate-build=dev"])

      expect(options.validateBuild).toBe("dev")
    })

    test("parses --config-file flag", () => {
      const { parseArguments } = require("../../../package/configExporter/cli")
      const options = parseArguments(["--config-file=custom-config.yml"])

      expect(options.configFile).toBe("custom-config.yml")
    })

    test("parses combination of flags", () => {
      const { parseArguments } = require("../../../package/configExporter/cli")
      const options = parseArguments([
        "--env=production",
        "--bundler=rspack",
        "--format=yaml",
        "--verbose"
      ])

      expect(options.env).toBe("production")
      expect(options.bundler).toBe("rspack")
      expect(options.format).toBe("yaml")
      expect(options.verbose).toBe(true)
    })
  })

  describe("parseArguments - validation", () => {
    test("throws error when both --webpack and --rspack are provided", () => {
      const { parseArguments } = require("../../../package/configExporter/cli")

      expect(() => {
        parseArguments(["--webpack", "--rspack"])
      }).toThrow("process.exit called") // yargs calls process.exit on validation failure
    })

    test("throws error when both --client-only and --server-only are provided", () => {
      const { parseArguments } = require("../../../package/configExporter/cli")

      expect(() => {
        parseArguments(["--client-only", "--server-only"])
      }).toThrow("process.exit called")
    })

    test("throws error when both --output and --save-dir are provided", () => {
      const { parseArguments } = require("../../../package/configExporter/cli")

      expect(() => {
        parseArguments(["--output=file.yml", "--save-dir=./configs"])
      }).toThrow("process.exit called")
    })

    test("throws error when both --stdout and --save-dir are provided", () => {
      const { parseArguments } = require("../../../package/configExporter/cli")

      expect(() => {
        parseArguments(["--stdout", "--save-dir=./configs"])
      }).toThrow("process.exit called")
    })

    test("throws error when both --build and --all-builds are provided", () => {
      const { parseArguments } = require("../../../package/configExporter/cli")

      expect(() => {
        parseArguments(["--build=dev", "--all-builds"])
      }).toThrow("process.exit called")
    })

    test("throws error when both --validate and --validate-build are provided", () => {
      const { parseArguments } = require("../../../package/configExporter/cli")

      expect(() => {
        parseArguments(["--validate", "--validate-build=dev"])
      }).toThrow("process.exit called")
    })

    test("throws error when --validate is used with --build", () => {
      const { parseArguments } = require("../../../package/configExporter/cli")

      expect(() => {
        parseArguments(["--validate", "--build=dev"])
      }).toThrow("process.exit called")
    })

    test("throws error when --validate is used with --all-builds", () => {
      const { parseArguments } = require("../../../package/configExporter/cli")

      expect(() => {
        parseArguments(["--validate", "--all-builds"])
      }).toThrow("process.exit called")
    })

    test("throws error when --ssr is used without --init", () => {
      const { parseArguments } = require("../../../package/configExporter/cli")

      expect(() => {
        parseArguments(["--ssr"])
      }).toThrow("process.exit called")
    })
  })

  describe("parseArguments - type coercion", () => {
    test("coerces string depth to number", () => {
      const { parseArguments } = require("../../../package/configExporter/cli")
      const options = parseArguments(["--depth=15"])

      expect(options.depth).toBe(15)
      expect(typeof options.depth).toBe("number")
    })

    test("handles null string for depth", () => {
      const { parseArguments } = require("../../../package/configExporter/cli")
      const options = parseArguments(["--depth=null"])

      expect(options.depth).toBeNull()
    })

    test("uses default depth when not provided", () => {
      const { parseArguments } = require("../../../package/configExporter/cli")
      const options = parseArguments([])

      expect(options.depth).toBe(20)
    })
  })

  describe("parseArguments - edge cases", () => {
    test("handles empty arguments array", () => {
      const { parseArguments } = require("../../../package/configExporter/cli")
      const options = parseArguments([])

      expect(options).toBeDefined()
      expect(options.doctor).toBe(false)
      expect(options.init).toBe(false)
    })

    test("handles unknown environment value", () => {
      const { parseArguments } = require("../../../package/configExporter/cli")

      // yargs validates choices, so invalid env should throw
      expect(() => {
        parseArguments(["--env=invalid"])
      }).toThrow("process.exit called")
    })

    test("handles unknown format value", () => {
      const { parseArguments } = require("../../../package/configExporter/cli")

      // yargs validates choices, so invalid format should throw
      expect(() => {
        parseArguments(["--format=invalid"])
      }).toThrow("process.exit called")
    })

    test("handles unknown bundler value", () => {
      const { parseArguments } = require("../../../package/configExporter/cli")

      // yargs validates choices, so invalid bundler should throw
      expect(() => {
        parseArguments(["--bundler=invalid"])
      }).toThrow("process.exit called")
    })

    test("throws error for invalid depth value (NaN)", () => {
      const { parseArguments } = require("../../../package/configExporter/cli")

      expect(() => {
        parseArguments(["--depth=abc"])
      }).toThrow("process.exit called") // yargs calls process.exit on coercion failure
    })

    test("throws error for depth with invalid string", () => {
      const { parseArguments } = require("../../../package/configExporter/cli")

      expect(() => {
        parseArguments(["--depth=invalid"])
      }).toThrow("process.exit called")
    })
  })

  describe("parseArguments - path validation", () => {
    // Note: Path validation tests are separate from other validation tests because
    // they use a different validation mechanism. Other validations (mutual exclusivity,
    // required combinations) happen in yargs .check() hook during parsing.
    // Path validation happens later in run() after applyDefaults() to ensure
    // default paths are also validated. These tests verify parseArguments() accepts
    // all paths (validation is deferred to run()).

    test("accepts output path within cwd", () => {
      const { parseArguments } = require("../../../package/configExporter/cli")
      const relativePath = "./output/config.yml"

      expect(() => {
        parseArguments([`--output=${relativePath}`])
      }).not.toThrow()
    })

    test("accepts save-dir path within cwd", () => {
      const { parseArguments } = require("../../../package/configExporter/cli")
      const relativePath = "./configs"

      expect(() => {
        parseArguments([`--save-dir=${relativePath}`])
      }).not.toThrow()
    })

    test("accepts output path outside cwd during parsing", () => {
      const { parseArguments } = require("../../../package/configExporter/cli")
      // Path validation happens later in run(), not during parsing
      const maliciousPath = "../../etc/passwd"

      expect(() => {
        parseArguments([`--output=${maliciousPath}`])
      }).not.toThrow()
    })

    test("accepts save-dir path outside cwd during parsing", () => {
      const { parseArguments } = require("../../../package/configExporter/cli")
      // Path validation happens later in run(), not during parsing
      const maliciousPath = "../../etc"

      expect(() => {
        parseArguments([`--save-dir=${maliciousPath}`])
      }).not.toThrow()
    })

    test("accepts absolute paths during parsing", () => {
      const { parseArguments } = require("../../../package/configExporter/cli")
      // Path validation happens later in run(), not during parsing
      const outsidePath = "/tmp/config.yml"

      expect(() => {
        parseArguments([`--output=${outsidePath}`])
      }).not.toThrow()
    })

    test("accepts various paths including those that would fail validation in run()", () => {
      const { parseArguments } = require("../../../package/configExporter/cli")
      // These paths would be rejected during run() but parseArguments() accepts them
      // Testing multiple scenarios to ensure parsing is permissive
      const testPaths = [
        "./output.yml", // Valid relative path
        "./subdir/output.yml", // Valid nested path
        "../../etc/passwd", // Path traversal (would fail in run())
        "/etc/passwd", // Absolute path outside cwd (would fail in run() on Unix)
        "/tmp/output.yml" // Another absolute path (would fail in run())
      ]

      testPaths.forEach((path) => {
        expect(() => {
          parseArguments([`--output=${path}`])
        }).not.toThrow()
      })
    })
  })
})
