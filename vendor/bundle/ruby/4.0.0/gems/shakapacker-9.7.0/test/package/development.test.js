const { resolve } = require("path")
const { chdirTestApp, resetEnv } = require("../helpers")

const rootPath = process.cwd()
chdirTestApp()

jest.mock("../../package/utils/helpers", () => {
  const original = jest.requireActual("../../package/utils/helpers")
  const moduleExists = () => false
  return {
    ...original,
    moduleExists
  }
})

describe("Development environment", () => {
  beforeEach(() => jest.resetModules() && resetEnv())
  afterAll(() => process.chdir(rootPath))

  describe("generateWebpackConfig", () => {
    beforeEach(() => jest.resetModules())

    test("should use development config and environment including devServer if WEBPACK_SERVE", () => {
      process.env.RAILS_ENV = "development"
      process.env.NODE_ENV = "development"
      process.env.WEBPACK_SERVE = "true"
      const { generateWebpackConfig } = require("../../package/index")

      const webpackConfig = generateWebpackConfig()

      expect(webpackConfig.output.path).toStrictEqual(
        resolve("public", "packs")
      )
      expect(webpackConfig.output.publicPath).toBe("/packs/")
    })

    test("should use development config and environment if WEBPACK_SERVE", () => {
      process.env.RAILS_ENV = "development"
      process.env.NODE_ENV = "development"
      process.env.WEBPACK_SERVE = undefined
      const { generateWebpackConfig } = require("../../package/index")

      const webpackConfig = generateWebpackConfig()

      expect(webpackConfig.output.path).toStrictEqual(
        resolve("public", "packs")
      )
      expect(webpackConfig.output.publicPath).toBe("/packs/")
      expect(webpackConfig.devServer).toBeUndefined()
    })
  })
})
