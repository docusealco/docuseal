/* eslint-env jest */
const { execSync } = require("child_process")
const { existsSync, readFileSync } = require("fs")
const { join } = require("path")

describe("typescript build", () => {
  const rootPath = join(__dirname, "..", "..")

  describe("typescript compilation", () => {
    it("should compile TypeScript files without errors", () => {
      expect(() => {
        execSync("npx tsc --noEmit", { cwd: rootPath, stdio: "pipe" })
      }).not.toThrow()
    })

    it("should generate JavaScript files from TypeScript", () => {
      // Check that key TypeScript files compile to JavaScript
      const tsFiles = ["config", "env", "index", "dev_server"]

      tsFiles.forEach((file) => {
        const jsPath = join(rootPath, "package", `${file}.js`)
        const tsPath = join(rootPath, "package", `${file}.ts`)

        expect(existsSync(tsPath)).toBe(true)
        expect(existsSync(jsPath)).toBe(true)

        // Verify JS file contains CommonJS exports (has been compiled)
        const jsContent = readFileSync(jsPath, "utf8")
        expect(jsContent).toContain("require(")
        expect(jsContent).toContain("module.exports")
      })
    })

    it("should generate type definition files", () => {
      const dtsFiles = ["config", "env", "index", "types", "dev_server"]

      dtsFiles.forEach((file) => {
        const dtsPath = join(rootPath, "package", `${file}.d.ts`)
        expect(existsSync(dtsPath)).toBe(true)
      })
    })
  })

  describe("commonJS compatibility", () => {
    it("should export modules using CommonJS format", () => {
      const config = require("../../package/config")
      const env = require("../../package/env")
      const helpers = require("../../package/utils/helpers")

      expect(config).toBeDefined()
      expect(env.railsEnv).toBeDefined()
      expect(helpers.moduleExists).toBeDefined()
    })

    it("should maintain backward compatibility", () => {
      const index = require("../../package/index")

      // Check all expected exports are present
      expect(index.config).toBeDefined()
      expect(index.env).toBeDefined()
      expect(index.generateWebpackConfig).toBeInstanceOf(Function)
      expect(index.moduleExists).toBeInstanceOf(Function)
      expect(index.canProcess).toBeInstanceOf(Function)
    })
  })

  describe("type guards", () => {
    it("should have runtime type validation functions", () => {
      const typeGuards = require("../../package/utils/typeGuards")

      expect(typeGuards.isValidConfig).toBeInstanceOf(Function)
      expect(typeGuards.isValidDevServerConfig).toBeInstanceOf(Function)
      expect(typeGuards.isValidYamlConfig).toBeInstanceOf(Function)
      expect(typeGuards.isPartialConfig).toBeInstanceOf(Function)
    })

    it("should validate config objects correctly", () => {
      const { isPartialConfig } = require("../../package/utils/typeGuards")

      const validPartial = {
        source_path: "app/javascript",
        nested_entries: true
      }

      const invalidPartial = {
        source_path: 123, // Should be string
        nested_entries: "yes" // Should be boolean
      }

      expect(isPartialConfig(validPartial)).toBe(true)
      expect(isPartialConfig(invalidPartial)).toBe(false)
    })
  })

  describe("error helpers", () => {
    it("should have error handling utilities", () => {
      const errorHelpers = require("../../package/utils/errorHelpers")

      expect(errorHelpers.isFileNotFoundError).toBeInstanceOf(Function)
      expect(errorHelpers.isModuleNotFoundError).toBeInstanceOf(Function)
      expect(errorHelpers.getErrorMessage).toBeInstanceOf(Function)
    })

    it("should correctly identify ENOENT errors", () => {
      const {
        isFileNotFoundError
      } = require("../../package/utils/errorHelpers")

      const enoentError = new Error("File not found")
      enoentError.code = "ENOENT"

      const otherError = new Error("Other error")

      expect(isFileNotFoundError(enoentError)).toBe(true)
      expect(isFileNotFoundError(otherError)).toBe(false)
    })
  })
})
