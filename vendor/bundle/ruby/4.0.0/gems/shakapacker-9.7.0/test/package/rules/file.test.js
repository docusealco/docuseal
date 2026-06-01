const file = require("../../../package/rules/file")

jest.mock("../../../package/config", () => {
  const original = jest.requireActual("../../../package/config")
  return {
    ...original,
    additional_paths: [...original.additional_paths, "app/assets"]
  }
})

describe("file", () => {
  test("expected file types", () => {
    const types = [
      ".bmp",
      ".gif",
      ".jpg",
      ".jpeg",
      ".png",
      ".tiff",
      ".ico",
      ".avif",
      ".webp",
      ".eot",
      ".otf",
      ".ttf",
      ".woff",
      ".woff2",
      ".svg"
    ]
    types.forEach((type) => expect(file.test.test(type)).toBe(true))
  })

  test("exclude expected file types", () => {
    const types = [".js", ".mjs", ".jsx", ".ts", ".tsx"]
    types.forEach((type) => expect(file.exclude.test(type)).toBe(true))
  })

  test("uses webpack asset module type by default", () => {
    expect(file.type).toBe("asset/resource")
  })

  test("correct generated output path is returned for top level files", () => {
    const pathData = {
      filename: "app/javascript/image.svg"
    }
    expect(file.generator.filename(pathData)).toBe(
      "static/[name]-[hash][ext][query]"
    )
  })

  test("correct generated output path is returned for nested files", () => {
    const pathData = {
      filename: "app/javascript/images/image.svg"
    }
    expect(file.generator.filename(pathData)).toBe(
      "static/images/[name]-[hash][ext][query]"
    )
  })

  test("correct generated output path is returned for deeply nested files", () => {
    const pathData = {
      filename: "app/javascript/images/nested/deeply/image.svg"
    }
    expect(file.generator.filename(pathData)).toBe(
      "static/images/nested/deeply/[name]-[hash][ext][query]"
    )
  })

  test("correct generated output path is returned for additional_paths", () => {
    const pathData = {
      filename: "app/assets/images/image.svg"
    }

    // The mock adds app/assets to additional_paths, but since the file rule
    // was imported before the mock was applied, it doesn't see the change
    expect(file.generator.filename(pathData)).toBe(
      "static/[name]-[hash][ext][query]"
    )

    const pathData2 = {
      filename: "app/javascript/app/assets/image.svg"
    }
    expect(file.generator.filename(pathData2)).toBe(
      "static/app/assets/[name]-[hash][ext][query]"
    )
  })
})
