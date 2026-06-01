const rules = require("../../../package/rules/webpack")

jest.mock("../../../package/utils/helpers", () => {
  const original = jest.requireActual("../../../package/utils/helpers")
  const moduleExists = () => false
  return {
    ...original,
    moduleExists
  }
})

describe("index", () => {
  test("rule tests are regexes or oneOf arrays", () => {
    const rulesWithTest = rules.filter((rule) => !rule.oneOf)
    const rulesWithOneOf = rules.filter((rule) => rule.oneOf)

    // Verify all non-oneOf rules have test property
    rulesWithTest.forEach((rule) => {
      expect(rule.test).toBeInstanceOf(RegExp)
    })

    // Verify all oneOf rules are properly structured
    rulesWithOneOf.forEach((rule) => {
      expect(Array.isArray(rule.oneOf)).toBe(true)
      rule.oneOf.forEach((subRule) => {
        // Each subRule must have either a test or resourceQuery property (RegExp)
        const matchers = [
          subRule.test instanceof RegExp,
          subRule.resourceQuery instanceof RegExp
        ]
        expect(matchers.some(Boolean)).toBe(true)
      })
    })
  })
})
