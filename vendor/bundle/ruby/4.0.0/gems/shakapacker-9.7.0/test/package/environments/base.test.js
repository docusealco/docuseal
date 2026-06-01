// environment.js expects to find config/shakapacker.yml and resolved modules from
// the root of a Rails project

const { resolve } = require("path")
const { chdirTestApp, resetEnv } = require("../../helpers")

const rootPath = process.cwd()
chdirTestApp()

// Set NODE_ENV before requiring modules to ensure contenthash is enabled
// Base config tests expect production-like behavior with contenthash
process.env.NODE_ENV = "production"

const baseConfig = require("../../../package/environments/base")
const config = require("../../../package/config")

jest.mock("../../../package/utils/helpers", () => {
  const original = jest.requireActual("../../../package/utils/helpers")
  const moduleExists = () => false
  return {
    ...original,
    moduleExists
  }
})

describe("Base config", () => {
  beforeEach(() => jest.resetModules() && resetEnv())
  afterAll(() => process.chdir(rootPath))

  describe("config", () => {
    test("should return entry", () => {
      expect(baseConfig.entry.application).toStrictEqual(
        resolve("app", "javascript", "entrypoints", "application.js")
      )
    })

    test("should return false for css_extract_ignore_order_warnings when using default config", () => {
      expect(config.css_extract_ignore_order_warnings).toBe(false)
    })

    test("should return true for css_extract_ignore_order_warnings when configured", () => {
      process.env.SHAKAPACKER_CONFIG =
        "config/shakapacker_css_extract_ignore_order_warnings.yml"
      const config2 = require("../../../package/config")

      expect(config2.css_extract_ignore_order_warnings).toBe(true)
    })

    test("should return only 2 entry points with config.nested_entries == false", () => {
      expect(config.nested_entries).toBe(false)

      expect(baseConfig.entry.multi_entry.sort()).toStrictEqual([
        resolve("app", "javascript", "entrypoints", "multi_entry.css"),
        resolve("app", "javascript", "entrypoints", "multi_entry.js")
      ])
      expect(baseConfig.entry["generated/something"]).toBeUndefined()
      expect(baseConfig.entry[".hidden"]).toBeUndefined()
    })

    test("should returns top level and nested entry points with config.nested_entries == true", () => {
      process.env.SHAKAPACKER_CONFIG = "config/shakapacker_nested_entries.yml"
      const config2 = require("../../../package/config")
      const baseConfig2 = require("../../../package/environments/base")

      expect(config2.nested_entries).toBe(true)

      expect(baseConfig2.entry.application).toStrictEqual(
        resolve("app", "javascript", "entrypoints", "application.js")
      )
      expect(baseConfig2.entry.multi_entry.sort()).toStrictEqual([
        resolve("app", "javascript", "entrypoints", "multi_entry.css"),
        resolve("app", "javascript", "entrypoints", "multi_entry.js")
      ])
      expect(baseConfig2.entry["generated/something"]).toStrictEqual(
        resolve("app", "javascript", "entrypoints", "generated", "something.js")
      )
      expect(baseConfig2.entry[".hidden"]).toBeUndefined()
      expect(baseConfig2.entry[".hidden_dir/hidden_nested"]).toBeUndefined()
    })

    test("should return output", () => {
      expect(baseConfig.output.filename).toBe("js/[name]-[contenthash].js")
      expect(baseConfig.output.chunkFilename).toBe(
        "js/[name]-[contenthash].chunk.js"
      )
    })

    test("should return default loader rules for each file in config/loaders", () => {
      const rules = require("../../../package/rules/webpack")

      // rules is an array, not an object anymore
      const defaultRules = rules
      const configRules = baseConfig.module.rules

      // moduleExists is mocked to return false, so rules loaded inside the test have only 3
      // But baseConfig was loaded before the mock was applied, so it has all 5 rules
      expect(defaultRules).toHaveLength(3)
      expect(configRules).toHaveLength(5)
    })

    test("should return default plugins", () => {
      expect(baseConfig.plugins).toHaveLength(3)
    })

    test("should return default resolveLoader", () => {
      expect(baseConfig.resolveLoader.modules).toStrictEqual(["node_modules"])
    })

    test("should return default resolve.modules with additions", () => {
      expect(baseConfig.resolve.modules).toStrictEqual([
        resolve("app", "javascript"),
        resolve("app/assets"),
        resolve("/etc/yarn"),
        resolve("some.config.js"),
        resolve("app/elm"),
        "node_modules"
      ])
    })

    test("returns plugins property as Array", () => {
      expect(baseConfig.plugins).toBeInstanceOf(Array)
    })
  })
})
