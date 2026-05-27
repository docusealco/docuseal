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

describe("Custom environment", () => {
  afterAll(() => process.chdir(rootPath))

  describe("generateWebpackConfig", () => {
    beforeEach(() => jest.resetModules())

    test("should use staging config and default development environment", () => {
      process.env.RAILS_ENV = "staging"
      delete process.env.NODE_ENV

      const { generateWebpackConfig } = require("../../package/index")

      const webpackConfig = generateWebpackConfig()

      expect(webpackConfig.output.path).toStrictEqual(
        resolve("public", "packs-staging")
      )
      expect(webpackConfig.output.publicPath).toBe("/packs-staging/")
      // With the NODE_ENV fix, staging now defaults to development environment
      // instead of production, providing better DX for staging environments
      expect(webpackConfig).toMatchObject({
        devtool: "cheap-module-source-map"
      })
    })
  })
})
