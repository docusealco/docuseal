module.exports = {
  roots: ["<rootDir>/test"],
  testPathIgnorePatterns: ["/__fixtures__/", "/__utils__/"],
  resolver: "<rootDir>/test/resolver",
  preset: "ts-jest",
  testEnvironment: "node",
  moduleFileExtensions: ["ts", "tsx", "js", "jsx", "json", "node"],
  transform: {
    "^.+\\.tsx?$": "ts-jest"
  },
  transformIgnorePatterns: ["node_modules/(?!(.*\\.mjs$))"]
}
