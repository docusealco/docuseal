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

describe("Production environment", () => {
  afterAll(() => process.chdir(rootPath))

  describe("generateWebpackConfig", () => {
    beforeEach(() => jest.resetModules())

    test("should use production config and environment", () => {
      process.env.RAILS_ENV = "production"
      process.env.NODE_ENV = "production"

      const { generateWebpackConfig } = require("../../package/index")

      const webpackConfig = generateWebpackConfig()

      expect(webpackConfig.output.path).toStrictEqual(
        resolve("public", "packs")
      )
      expect(webpackConfig.output.publicPath).toBe("/packs/")

      expect(webpackConfig).toMatchObject({
        devtool: "source-map",
        stats: "normal"
      })
    })
  })
})
