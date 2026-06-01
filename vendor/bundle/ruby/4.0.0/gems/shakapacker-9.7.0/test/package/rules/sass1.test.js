const sass = require("../../../package/rules/sass")

jest.mock("../../../package/utils/helpers", () => {
  const original = jest.requireActual("../../../package/utils/helpers")
  const canProcess = (rule, fn) => fn("This path was mocked")
  return {
    ...original,
    canProcess
  }
})

jest.mock("../../../package/utils/inliningCss", () => true)

describe("sass rule", () => {
  test("contains loadPaths as the sassOptions key if sass-loader is v15 or earlier", () => {
    // sass-loader is at index 2 (after style-loader and css-loader)
    expect(typeof sass.use[2].options.sassOptions.includePaths).toBe(
      "undefined"
    )
    expect(typeof sass.use[2].options.sassOptions.loadPaths).toBe("object")
  })

  test("uses modern API for better compatibility with sass plugins", () => {
    expect(sass.use[2].options.api).toBe("modern")
  })
})
