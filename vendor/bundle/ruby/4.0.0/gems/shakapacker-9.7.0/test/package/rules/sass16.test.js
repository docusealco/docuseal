const sass = require("../../../package/rules/sass")

jest.mock("../../../package/utils/helpers", () => {
  const original = jest.requireActual("../../../package/utils/helpers")
  const canProcess = (rule, fn) => fn("This path was mocked")
  const packageMajorVersion = () => 16
  return {
    ...original,
    canProcess,
    packageMajorVersion
  }
})

jest.mock("../../../package/utils/inliningCss", () => true)

describe("sass rule", () => {
  test("contains loadPaths as the sassOptions key if sass-loader is v16 or later", () => {
    // sass-loader is at index 2 (after style-loader and css-loader)
    expect(typeof sass.use[2].options.sassOptions.includePaths).toBe(
      "undefined"
    )
    expect(typeof sass.use[2].options.sassOptions.loadPaths).toBe("object")
  })
})
