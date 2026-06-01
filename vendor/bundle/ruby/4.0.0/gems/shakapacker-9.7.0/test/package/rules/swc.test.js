const {
  pathToAppJavascript,
  pathToNodeModules,
  pathToNodeModulesIncluded,
  createTestCompiler,
  createTrackLoader
} = require("../../helpers")
// Mock config before importing swc rule
jest.mock("../../../package/config", () => {
  const original = jest.requireActual("../../../package/config")
  return {
    ...original,
    javascript_transpiler: "swc",
    additional_paths: [...original.additional_paths, "node_modules/included"]
  }
})

const swcConfig = require("../../../package/rules/swc")

// Skip tests if swc config is not available (not the active transpiler)
if (!swcConfig) {
  // eslint-disable-next-line jest/no-disabled-tests
  describe.skip("swc - skipped", () => {
    test.todo("skipped because swc is not the active transpiler")
  })
} else {
  const createWebpackConfig = (file, use) => ({
    entry: { file },
    module: {
      rules: [
        {
          ...swcConfig,
          use
        }
      ]
    },
    output: {
      path: "/",
      filename: "scripts-bundled.js"
    }
  })

  describe("swc", () => {
    test("process files in source_path", async () => {
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
} // end of else block for swcConfig check
