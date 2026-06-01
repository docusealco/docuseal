/* eslint-disable func-names */

// Mock requireOrError to prevent actual module loading
jest.mock("../../../package/utils/requireOrError", () => ({
  requireOrError: (moduleName) => {
    if (moduleName === "@rspack/core") {
      return {
        SwcJsMinimizerRspackPlugin: jest.fn(function () {
          this.name = "SwcJsMinimizerRspackPlugin"
        }),
        LightningCssMinimizerRspackPlugin: jest.fn(function () {
          this.name = "LightningCssMinimizerRspackPlugin"
        })
      }
    }
    throw new Error(`Module ${moduleName} not found`)
  }
}))

// Mock debug logger
jest.mock("../../../package/utils/debug", () => ({
  error: jest.fn(),
  warn: jest.fn(),
  info: jest.fn(),
  debug: jest.fn()
}))

describe("rspack/optimization", () => {
  let getOptimization

  beforeEach(() => {
    jest.resetModules()
    const optimizationModule = require("../../../package/optimization/rspack")
    getOptimization = optimizationModule.getOptimization
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  describe("getOptimization", () => {
    test("returns an optimization config object", () => {
      const optimization = getOptimization()

      expect(optimization).toBeDefined()
      expect(optimization).toHaveProperty("minimize")
      expect(optimization).toHaveProperty("minimizer")
    })

    test("sets minimize to true", () => {
      const optimization = getOptimization()

      expect(optimization.minimize).toBe(true)
    })

    test("includes SwcJsMinimizerRspackPlugin", () => {
      const optimization = getOptimization()

      expect(Array.isArray(optimization.minimizer)).toBe(true)
      const jsMinimizer = optimization.minimizer.find(
        (m) => m.name === "SwcJsMinimizerRspackPlugin"
      )
      expect(jsMinimizer).toBeDefined()
    })

    test("includes LightningCssMinimizerRspackPlugin", () => {
      const optimization = getOptimization()

      expect(Array.isArray(optimization.minimizer)).toBe(true)
      const cssMinimizer = optimization.minimizer.find(
        (m) => m.name === "LightningCssMinimizerRspackPlugin"
      )
      expect(cssMinimizer).toBeDefined()
    })

    test("includes both minimizers in correct order", () => {
      const optimization = getOptimization()

      expect(optimization.minimizer).toHaveLength(2)
      expect(optimization.minimizer[0].name).toBe("SwcJsMinimizerRspackPlugin")
      expect(optimization.minimizer[1].name).toBe(
        "LightningCssMinimizerRspackPlugin"
      )
    })
  })
})
