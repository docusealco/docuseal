// Tests for requireOrError utility
const { requireOrError } = require("../../package/utils/requireOrError")

describe("requireOrError", () => {
  describe("successful require", () => {
    it("returns the required module", () => {
      const result = requireOrError("path")
      expect(result).toBeDefined()
      expect(typeof result.join).toBe("function")
    })
  })

  describe("failed require", () => {
    it("throws error with helpful message when module not found", () => {
      expect(() => {
        requireOrError("nonexistent-module-that-does-not-exist")
      }).toThrow("[SHAKAPACKER]")
      expect(() => {
        requireOrError("nonexistent-module-that-does-not-exist")
      }).toThrow("is required for")
    })

    it("includes original error as cause for debugging", () => {
      let caughtError
      try {
        requireOrError("nonexistent-module-that-does-not-exist")
      } catch (error) {
        caughtError = error
      }

      expect(caughtError).toBeDefined()
      expect(caughtError.cause).toBeDefined()
      expect(caughtError.cause.code).toBe("MODULE_NOT_FOUND")
    })

    it("preserves original error stack in cause", () => {
      let caughtError
      try {
        requireOrError("another-nonexistent-module")
      } catch (error) {
        caughtError = error
      }

      expect(caughtError.cause).toBeDefined()
      expect(caughtError.cause.stack).toBeDefined()
      expect(typeof caughtError.cause.stack).toBe("string")
    })
  })
})
