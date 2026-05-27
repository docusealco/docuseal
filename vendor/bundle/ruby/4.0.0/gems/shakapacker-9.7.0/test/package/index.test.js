const index = require("../../package/index")

jest.mock("../../package/utils/helpers", () => {
  const original = jest.requireActual("../../package/utils/helpers")
  const moduleExists = () => false
  return {
    ...original,
    moduleExists
  }
})

describe("index", () => {
  test("exports webpack-merge v5 functions", () => {
    expect(index.merge).toBeInstanceOf(Function)
    expect(index.mergeWithRules).toBeInstanceOf(Function)
    expect(index.mergeWithCustomize).toBeInstanceOf(Function)
  })

  test("webpackConfig returns an immutable object", () => {
    const { generateWebpackConfig } = require("../../package/index")

    const webpackConfig1 = generateWebpackConfig()
    const webpackConfig2 = generateWebpackConfig()

    webpackConfig1.newKey = "new value"
    webpackConfig1.output.path = "new path"

    expect(webpackConfig2).not.toHaveProperty("newKey")
    expect(webpackConfig2.output.path).not.toBe("new value")
  })

  test("webpackConfig merges extra config", () => {
    const { generateWebpackConfig } = require("../../package/index")

    const webpackConfig = generateWebpackConfig({
      newKey: "new value",
      output: {
        path: "new path"
      }
    })

    expect(webpackConfig).toHaveProperty("newKey", "new value")
    expect(webpackConfig).toHaveProperty("output.path", "new path")
    expect(webpackConfig).toHaveProperty("output.publicPath", "/packs/")
  })

  test("webpackConfig errors if multiple configs are provided", () => {
    const { generateWebpackConfig } = require("../../package/index")

    expect(() => generateWebpackConfig({}, {})).toThrow(
      "use webpack-merge to merge configs before passing them to Shakapacker"
    )
  })
})
