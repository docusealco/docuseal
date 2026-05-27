const { resolve } = require("path")
const { chdirTestApp } = require("../helpers")

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

describe("Test environment", () => {
  afterAll(() => process.chdir(rootPath))

  describe("generateWebpackConfig", () => {
    beforeEach(() => jest.resetModules())

    test("should use test config and production environment", () => {
      process.env.RAILS_ENV = "test"
      process.env.NODE_ENV = "test"

      const { generateWebpackConfig } = require("../../package/index")

      const webpackConfig = generateWebpackConfig()

      expect(webpackConfig.output.path).toStrictEqual(
        resolve("public", "packs-test")
      )
      expect(webpackConfig.output.publicPath).toBe("/packs-test/")
      expect(webpackConfig.devServer).toBeUndefined()
    })
  })
})
