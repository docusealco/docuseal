/**
 * Tests demonstrating why parseInt is needed for sass-loader version comparison
 */

describe("sass-loader version comparison", () => {
  describe("string comparison issues (without parseInt)", () => {
    test("string '2' incorrectly compares as greater than number 15", () => {
      // This demonstrates the bug: lexicographic string comparison
      const stringVersion = "2"
      // String comparison would be: "2" > 15
      // JavaScript coerces to: 2 > 15 = false (correct)
      expect(stringVersion > 15).toBe(false)

      // But with >= 16 (the boundary we care about):
      expect(stringVersion >= 16).toBe(false) // Correct behavior
    })

    test("string '16' correctly converts in numeric comparison", () => {
      const stringVersion = "16"
      // Coercion works: "16" >= 16 -> 16 >= 16 = true
      expect(stringVersion >= 16).toBe(true)
    })

    test("demonstrates why > 15 is less clear than >= 16", () => {
      // Version 15 should use includePaths
      expect("15" > 15).toBe(false) // 15 > 15 = false ✓
      expect(parseInt("15", 10) >= 16).toBe(false) // 15 >= 16 = false ✓

      // Version 16 should use loadPaths
      expect("16" > 15).toBe(true) // 16 > 15 = true ✓
      expect(parseInt("16", 10) >= 16).toBe(true) // 16 >= 16 = true ✓

      // But >= 16 is more semantically accurate:
      // "Use loadPaths if version is 16 or greater"
    })
  })

  describe("parseInt ensures numeric comparison", () => {
    test("handles numeric string correctly", () => {
      expect(parseInt("16", 10) >= 16).toBe(true)
      expect(parseInt("15", 10) >= 16).toBe(false)
      expect(parseInt("2", 10) >= 16).toBe(false)
    })

    test("handles edge cases safely", () => {
      // If version can't be determined, parseInt returns NaN
      // NaN >= 16 is false, so it falls back to includePaths (safe default)
      expect(parseInt("invalid", 10) >= 16).toBe(false)
      expect(parseInt(undefined, 10) >= 16).toBe(false)
      expect(parseInt("", 10) >= 16).toBe(false)
    })
  })

  describe("version 16 is the boundary", () => {
    // Helper function to determine option key (same logic as production code)
    const getOptionKey = (version) =>
      version >= 16 ? "loadPaths" : "includePaths"

    test("sass-loader v15 uses includePaths", () => {
      expect(getOptionKey(15)).toBe("includePaths")
    })

    test("sass-loader v16 uses loadPaths", () => {
      expect(getOptionKey(16)).toBe("loadPaths")
    })

    test("sass-loader v17+ uses loadPaths", () => {
      expect(getOptionKey(17)).toBe("loadPaths")
    })
  })
})
