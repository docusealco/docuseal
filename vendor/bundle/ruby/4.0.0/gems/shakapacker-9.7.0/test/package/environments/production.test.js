const { chdirTestApp, resetEnv } = require("../../helpers")

const rootPath = process.cwd()
chdirTestApp()

jest.mock("../../../package/utils/helpers", () => {
  const original = jest.requireActual("../../../package/utils/helpers")
  const moduleExists = () => false
  return {
    ...original,
    moduleExists
  }
})

describe("Production specific config", () => {
  beforeEach(() => {
    jest.resetModules()
    resetEnv()
    process.env.NODE_ENV = "production"
  })
  afterAll(() => process.chdir(rootPath))

  describe("with config.useContentHash = true", () => {
    test("sets filename to use contentHash", () => {
      const config = require("../../../package/config")
      config.useContentHash = true
      const environmentConfig = require("../../../package/environments/production")

      expect(environmentConfig.output.filename).toBe(
        "js/[name]-[contenthash].js"
      )
      expect(environmentConfig.output.chunkFilename).toBe(
        "js/[name]-[contenthash].chunk.js"
      )
    })

    test("doesn't shows any warning message", () => {
      const consoleWarnSpy = jest.spyOn(console, "warn")
      const config = require("../../../package/config")
      config.useContentHash = true

      require("../../../package/environments/production")

      expect(consoleWarnSpy).not.toHaveBeenCalledWith(
        expect.stringMatching(
          /Setting 'useContentHash' to 'false' in the production environment/
        )
      )

      consoleWarnSpy.mockRestore()
    })
  })

  describe("with config.useContentHash = false", () => {
    test("sets filename to use contentHash", () => {
      const config = require("../../../package/config")
      config.useContentHash = false
      const environmentConfig = require("../../../package/environments/production")

      expect(environmentConfig.output.filename).toBe(
        "js/[name]-[contenthash].js"
      )
      expect(environmentConfig.output.chunkFilename).toBe(
        "js/[name]-[contenthash].chunk.js"
      )
    })

    test("shows a warning message", () => {
      const consoleWarnSpy = jest.spyOn(console, "warn")
      const config = require("../../../package/config")
      config.useContentHash = false

      require("../../../package/environments/production")

      expect(consoleWarnSpy).toHaveBeenCalledWith(
        expect.stringMatching(
          /Setting 'useContentHash' to 'false' in the production environment/
        )
      )

      consoleWarnSpy.mockRestore()
    })
  })

  describe("with unset config.useContentHash", () => {
    test("sets filename to use contentHash", () => {
      const config = require("../../../package/config")
      delete config.useContentHash
      const environmentConfig = require("../../../package/environments/production")

      expect(environmentConfig.output.filename).toBe(
        "js/[name]-[contenthash].js"
      )
      expect(environmentConfig.output.chunkFilename).toBe(
        "js/[name]-[contenthash].chunk.js"
      )
    })

    test("doesn't shows any warning message", () => {
      const consoleWarnSpy = jest.spyOn(console, "warn")
      const config = require("../../../package/config")
      delete config.useContentHash

      require("../../../package/environments/production")

      expect(consoleWarnSpy).not.toHaveBeenCalledWith(
        expect.stringMatching(
          /Setting 'useContentHash' to 'false' in the production environment/
        )
      )

      consoleWarnSpy.mockRestore()
    })
  })
})
