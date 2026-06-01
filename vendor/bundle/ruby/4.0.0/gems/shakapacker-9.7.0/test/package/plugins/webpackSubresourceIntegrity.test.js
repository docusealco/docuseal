const loadPluginsWithSriModule = (sriModule) => {
  let getPlugins

  jest.isolateModules(() => {
    jest.doMock("../../../package/config", () => ({
      manifestPath: "public/packs/manifest.json",
      publicPathWithoutCDN: "/packs/",
      integrity: {
        enabled: true,
        hash_functions: ["sha256"]
      },
      css_extract_ignore_order_warnings: false,
      useContentHash: false
    }))

    jest.doMock("../../../package/env", () => ({
      isProduction: true
    }))

    jest.doMock("../../../package/utils/helpers", () => ({
      moduleExists: (moduleName) =>
        moduleName === "webpack-subresource-integrity"
    }))

    jest.doMock("../../../package/utils/ensureManifestExists", () => ({
      __esModule: true,
      default: jest.fn()
    }))

    jest.doMock("../../../package/utils/requireOrError", () => ({
      requireOrError: (moduleName) => {
        if (moduleName === "webpack-assets-manifest") {
          return function WebpackAssetsManifest() {}
        }
        if (moduleName === "webpack") {
          return {
            EnvironmentPlugin: function EnvironmentPlugin() {}
          }
        }
        if (moduleName === "webpack-subresource-integrity") {
          return sriModule
        }

        throw new Error(`Unexpected module request: ${moduleName}`)
      }
    }))
    ;({ getPlugins } = require("../../../package/plugins/webpack"))
  })

  return getPlugins
}

describe("webpack plugins - webpack-subresource-integrity compatibility", () => {
  afterEach(() => {
    jest.clearAllMocks()
  })

  test("supports webpack-subresource-integrity v5 named export", () => {
    const SubresourceIntegrityPlugin = jest.fn(
      function SubresourceIntegrityPluginMock(options) {
        this.options = options
      }
    )
    const getPlugins = loadPluginsWithSriModule({ SubresourceIntegrityPlugin })

    getPlugins()

    expect(SubresourceIntegrityPlugin).toHaveBeenCalledWith({
      hashFuncNames: ["sha256"],
      enabled: true
    })
  })

  test("supports webpack-subresource-integrity default export", () => {
    const SubresourceIntegrityPlugin = jest.fn(
      function SubresourceIntegrityPluginMock(options) {
        this.options = options
      }
    )
    const getPlugins = loadPluginsWithSriModule(SubresourceIntegrityPlugin)

    getPlugins()

    expect(SubresourceIntegrityPlugin).toHaveBeenCalledWith({
      hashFuncNames: ["sha256"],
      enabled: true
    })
  })
})
