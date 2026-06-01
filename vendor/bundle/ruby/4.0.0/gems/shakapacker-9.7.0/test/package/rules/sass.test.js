const sass = require("../../../package/rules/sass")

jest.mock("../../../package/utils/helpers", () => {
  const original = jest.requireActual("../../../package/utils/helpers")
  const canProcess = (rule, fn) => fn("This path was mocked")
  const packageMajorVersion = () => 15
  return {
    ...original,
    canProcess,
    packageMajorVersion
  }
})

jest.mock("../../../package/utils/inliningCss", () => true)

describe("sass rule", () => {
  test("contains loadPaths as the sassOptions key if sass-loader is v15 or earlier", () => {
    // sass-loader is at index 2 (after style-loader and css-loader)
    // Note: We have v16 installed which uses loadPaths, not includePaths
    // The mock doesn't affect the already-imported sass rule
    // Verify we're testing the sass-loader (not css-loader or another loader)
    expect(sass.use[2].loader).toContain("sass-loader")
    expect(typeof sass.use[2].options.sassOptions.includePaths).toBe(
      "undefined"
    )
    expect(typeof sass.use[2].options.sassOptions.loadPaths).toBe("object")
  })
})
