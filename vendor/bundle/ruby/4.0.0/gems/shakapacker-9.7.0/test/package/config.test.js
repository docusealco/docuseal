const { resolve } = require("path")
const { chdirTestApp, resetEnv } = require("../helpers")

const rootPath = process.cwd()
chdirTestApp()

describe("Config", () => {
  beforeEach(() => jest.resetModules() && resetEnv())
  afterAll(() => process.chdir(rootPath))

  test("public path", () => {
    process.env.RAILS_ENV = "development"
    const config = require("../../package/config")
    expect(config.publicPath).toBe("/packs/")
  })

  test("public path with asset host", () => {
    process.env.RAILS_ENV = "development"
    process.env.SHAKAPACKER_ASSET_HOST = "http://foo.com/"
    const config = require("../../package/config")
    expect(config.publicPath).toBe("http://foo.com/packs/")
  })

  test("public path without CDN is not affected by the asset host", () => {
    process.env.RAILS_ENV = "development"
    process.env.SHAKAPACKER_ASSET_HOST = "http://foo.com/"
    const config = require("../../package/config")
    expect(config.publicPathWithoutCDN).toBe("/packs/")
  })

  test("should return additional paths as listed in app config, with resolved paths", () => {
    const config = require("../../package/config")

    expect(config.additional_paths).toStrictEqual([
      "app/assets",
      "/etc/yarn",
      "some.config.js",
      "app/elm"
    ])
  })

  test("should default manifestPath to the public dir", () => {
    const config = require("../../package/config")

    expect(config.manifestPath).toStrictEqual(
      resolve("public/packs/manifest.json")
    )
  })

  test("should allow overriding manifestPath", () => {
    process.env.SHAKAPACKER_CONFIG = "config/shakapacker_manifest_path.yml"
    const config = require("../../package/config")
    expect(config.manifestPath).toStrictEqual(
      resolve("app/javascript/manifest.json")
    )
  })

  test("should return privateOutputPath as absolute path", () => {
    const config = require("../../package/config")
    expect(config.privateOutputPath).toStrictEqual(resolve("ssr-generated"))
  })

  test("should not set privateOutputPath when not configured", () => {
    process.env.SHAKAPACKER_CONFIG = "config/shakapacker_manifest_path.yml"
    const config = require("../../package/config")
    expect(config.privateOutputPath).toBeUndefined()
  })

  test("should have integrity disabled by default", () => {
    const config = require("../../package/config")
    expect(config.integrity.enabled).toBe(false)
  })

  test("should have sha384 as default hash function", () => {
    const config = require("../../package/config")
    expect(config.integrity.hash_functions).toStrictEqual(["sha384"])
  })

  test("should have anonymous as default crossorigin", () => {
    const config = require("../../package/config")
    expect(config.integrity.cross_origin).toBe("anonymous")
  })

  test("should allow enabling integrity", () => {
    process.env.RAILS_ENV = "production"
    process.env.SHAKAPACKER_CONFIG = "config/shakapacker_integrity.yml"
    const config = require("../../package/config")

    expect(config.integrity.enabled).toBe(true)
  })

  test("should allow configuring hash functions", () => {
    process.env.RAILS_ENV = "production"
    process.env.SHAKAPACKER_CONFIG = "config/shakapacker_integrity.yml"
    const config = require("../../package/config")

    expect(config.integrity.hash_functions).toStrictEqual([
      "sha384",
      "sha256",
      "sha512"
    ])
  })

  test("should allow configuring crossorigin", () => {
    process.env.RAILS_ENV = "production"
    process.env.SHAKAPACKER_CONFIG = "config/shakapacker_integrity.yml"
    const config = require("../../package/config")

    expect(config.integrity.cross_origin).toBe("use-credentials")
  })
})
