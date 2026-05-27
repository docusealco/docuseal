describe("raw", () => {
  describe("rspack bundler", () => {
    beforeEach(() => {
      jest.resetModules()
      jest.doMock("../../../package/config", () => ({
        assets_bundler: "rspack"
      }))
    })

    afterEach(() => {
      jest.dontMock("../../../package/config")
    })

    test("uses resourceQuery for any file with ?raw", () => {
      const raw = require("../../../package/rules/raw")
      expect(raw.resourceQuery).toStrictEqual(/raw/)
      expect(raw.type).toBe("asset/source")
    })
  })

  describe("webpack bundler", () => {
    beforeEach(() => {
      jest.resetModules()
      jest.doMock("../../../package/config", () => ({
        assets_bundler: "webpack"
      }))
    })

    afterEach(() => {
      jest.dontMock("../../../package/config")
    })

    test("supports ?raw query and .html fallback with oneOf", () => {
      const raw = require("../../../package/rules/raw")
      expect(raw.oneOf).toHaveLength(2)
      // First rule: any file with ?raw
      expect(raw.oneOf[0].resourceQuery).toStrictEqual(/raw/)
      expect(raw.oneOf[0].type).toBe("asset/source")
      // Second rule: .html files without query
      expect(raw.oneOf[1].test.test(".html")).toBe(true)
      expect(raw.oneOf[1].exclude.test(".js")).toBe(true)
      expect(raw.oneOf[1].type).toBe("asset/source")
    })
  })
})
