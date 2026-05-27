const { packageMajorVersion } = require("../../package/utils/helpers")

describe("packageMajorVersion", () => {
  test("should find that sass-loader is v16", () => {
    expect(packageMajorVersion("sass-loader")).toBe(16)
  })

  test("should find that nonexistent is v12", () => {
    expect(packageMajorVersion("nonexistent")).toBe(12)
  })
})
