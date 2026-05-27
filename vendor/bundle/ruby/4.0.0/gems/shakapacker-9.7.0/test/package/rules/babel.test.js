const {
  pathToAppJavascript,
  pathToNodeModules,
  pathToNodeModulesIncluded,
  createTestCompiler,
  createTrackLoader
} = require("../../helpers")
// Mock config before importing babel rule
jest.mock("../../../package/config", () => {
  const original = jest.requireActual("../../../package/config")
  return {
    ...original,
    javascript_transpiler: "babel", // Force babel for this test
    additional_paths: [...original.additional_paths, "node_modules/included"]
  }
})

const babelConfig = require("../../../package/rules/babel")

// Skip tests if babel config is not available (not the active transpiler)
if (!babelConfig) {
  // eslint-disable-next-line jest/no-disabled-tests
  describe.skip("babel - skipped", () => {
    test.todo("skipped because babel is not the active transpiler")
  })
} else {
  const createWebpackConfig = (file, use) => ({
    entry: { file },
    module: {
      rules: [
        {
          ...babelConfig,
          use
        }
      ]
    },
    output: {
      path: "/",
      filename: "scripts-bundled.js"
    }
  })

  describe("babel", () => {
    // Mock validateBabelDependencies to avoid actual dependency checking in tests
    beforeAll(() => {
      jest.mock("../../../package/utils/helpers", () => {
        const original = jest.requireActual("../../../package/utils/helpers")
        return {
          ...original,
          validateBabelDependencies: jest.fn() // Mock to do nothing
        }
      })
    })

    afterAll(() => {
      jest.unmock("../../../package/utils/helpers")
    })

    test("process source path", async () => {
      const normalPath = `${pathToAppJavascript}/a.js`
      const [tracked, loader] = createTrackLoader()
      const compiler = createTestCompiler(
        createWebpackConfig(normalPath, loader)
      )
      await compiler.run()
      expect(tracked[normalPath]).toBeTruthy()
    })

    test("exclude node_modules", async () => {
      const ignored = `${pathToNodeModules}/a.js`
      const [tracked, loader] = createTrackLoader()
      const compiler = createTestCompiler(createWebpackConfig(ignored, loader))
      await compiler.run()
      expect(tracked[ignored]).toBeUndefined()
    })

    test("explicitly included node_modules should be transpiled", async () => {
      const included = `${pathToNodeModulesIncluded}/a.js`
      const [tracked, loader] = createTrackLoader()
      const compiler = createTestCompiler(createWebpackConfig(included, loader))
      await compiler.run()
      expect(tracked[included]).toBeTruthy()
    })
  })
} // end of else block for babelConfig check
