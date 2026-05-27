const {
  pathToAppJavascript,
  pathToNodeModules,
  pathToNodeModulesIncluded,
  createTestCompiler,
  createTrackLoader
} = require("../../helpers")
// Mock config before importing esbuild rule
jest.mock("../../../package/config", () => {
  const original = jest.requireActual("../../../package/config")
  return {
    ...original,
    javascript_transpiler: "esbuild",
    additional_paths: [...original.additional_paths, "node_modules/included"]
  }
})

const esbuildConfig = require("../../../package/rules/esbuild")

const createWebpackConfig = (file, use) => ({
  entry: { file },
  module: {
    rules: [
      {
        ...esbuildConfig,
        use
      }
    ]
  },
  output: {
    path: "/",
    filename: "scripts-bundled.js"
  }
})

describe("esbuild", () => {
  // Skip tests if esbuild is not configured as the transpiler
  if (!esbuildConfig) {
    test.todo(
      "esbuild rule is not active (javascript_transpiler is not 'esbuild')"
    )
    return
  }

  test("process source path", async () => {
    const normalPath = `${pathToAppJavascript}/a.js`
    const [tracked, loader] = createTrackLoader()
    const compiler = createTestCompiler(createWebpackConfig(normalPath, loader))
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
