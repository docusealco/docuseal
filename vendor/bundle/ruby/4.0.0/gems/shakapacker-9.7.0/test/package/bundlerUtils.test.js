const index = require("../../package/index")

describe("bundlerUtils", () => {
  describe("isRspack and isWebpack", () => {
    test("exports isRspack as a boolean", () => {
      expect(typeof index.isRspack).toBe("boolean")
    })

    test("exports isWebpack as a boolean", () => {
      expect(typeof index.isWebpack).toBe("boolean")
    })

    test("isRspack and isWebpack are mutually exclusive", () => {
      expect(index.isRspack).not.toBe(index.isWebpack)
    })

    test("defaults to webpack (isWebpack is true, isRspack is false)", () => {
      // Default bundler is webpack
      expect(index.isWebpack).toBe(true)
      expect(index.isRspack).toBe(false)
    })
  })

  describe("getBundler", () => {
    test("exports getBundler as a function", () => {
      expect(index.getBundler).toBeInstanceOf(Function)
    })

    test("returns webpack module by default", () => {
      const bundler = index.getBundler()
      expect(bundler).toBeDefined()
      expect(bundler.DefinePlugin).toBeDefined()
      expect(bundler.EnvironmentPlugin).toBeDefined()
      expect(bundler.ProvidePlugin).toBeDefined()
    })
  })

  describe("getCssExtractPlugin", () => {
    test("exports getCssExtractPlugin as a function", () => {
      expect(index.getCssExtractPlugin).toBeInstanceOf(Function)
    })

    test("returns MiniCssExtractPlugin by default", () => {
      const CssPlugin = index.getCssExtractPlugin()
      expect(CssPlugin).toBeDefined()
      // MiniCssExtractPlugin has a loader property
      expect(CssPlugin.loader).toBeDefined()
    })
  })

  describe("getCssExtractPluginLoader", () => {
    test("exports getCssExtractPluginLoader as a function", () => {
      expect(index.getCssExtractPluginLoader).toBeInstanceOf(Function)
    })

    test("returns a string loader path", () => {
      const loader = index.getCssExtractPluginLoader()
      expect(typeof loader).toBe("string")
    })
  })

  describe("getDefinePlugin", () => {
    test("exports getDefinePlugin as a function", () => {
      expect(index.getDefinePlugin).toBeInstanceOf(Function)
    })

    test("returns webpack.DefinePlugin by default", () => {
      const DefinePlugin = index.getDefinePlugin()
      expect(DefinePlugin).toBeDefined()
      expect(DefinePlugin).toBeInstanceOf(Function)
    })
  })

  describe("getEnvironmentPlugin", () => {
    test("exports getEnvironmentPlugin as a function", () => {
      expect(index.getEnvironmentPlugin).toBeInstanceOf(Function)
    })

    test("returns webpack.EnvironmentPlugin by default", () => {
      const EnvironmentPlugin = index.getEnvironmentPlugin()
      expect(EnvironmentPlugin).toBeDefined()
      expect(EnvironmentPlugin).toBeInstanceOf(Function)
    })
  })

  describe("getProvidePlugin", () => {
    test("exports getProvidePlugin as a function", () => {
      expect(index.getProvidePlugin).toBeInstanceOf(Function)
    })

    test("returns webpack.ProvidePlugin by default", () => {
      const ProvidePlugin = index.getProvidePlugin()
      expect(ProvidePlugin).toBeDefined()
      expect(ProvidePlugin).toBeInstanceOf(Function)
    })
  })
})
