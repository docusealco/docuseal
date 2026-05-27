const { chdirTestApp } = require("../helpers")

const rootPath = process.cwd()
chdirTestApp()

describe("Env", () => {
  beforeEach(() => jest.resetModules())
  afterAll(() => process.chdir(rootPath))

  test("with NODE_ENV and RAILS_ENV set to development", () => {
    process.env.RAILS_ENV = "development"
    process.env.NODE_ENV = "development"
    expect(require("../../package/env")).toStrictEqual({
      railsEnv: "development",
      nodeEnv: "development",
      isProduction: false,
      isDevelopment: true,
      runningWebpackDevServer: false
    })
  })

  test("with undefined NODE_ENV and RAILS_ENV set to development", () => {
    process.env.RAILS_ENV = "development"
    delete process.env.NODE_ENV
    expect(require("../../package/env")).toStrictEqual({
      railsEnv: "development",
      nodeEnv: "development",
      isProduction: false,
      isDevelopment: true,
      runningWebpackDevServer: false
    })
  })

  test("with undefined NODE_ENV and RAILS_ENV set to production", () => {
    process.env.RAILS_ENV = "production"
    delete process.env.NODE_ENV
    expect(require("../../package/env")).toStrictEqual({
      railsEnv: "production",
      nodeEnv: "production",
      isProduction: true,
      isDevelopment: false,
      runningWebpackDevServer: false
    })
  })

  test("with undefined NODE_ENV and RAILS_ENV", () => {
    delete process.env.NODE_ENV
    delete process.env.RAILS_ENV
    expect(require("../../package/env")).toStrictEqual({
      railsEnv: "development",
      nodeEnv: "development",
      isProduction: false,
      isDevelopment: true,
      runningWebpackDevServer: false
    })
  })

  test("with a non-standard environment", () => {
    process.env.RAILS_ENV = "staging"
    process.env.NODE_ENV = "staging"
    expect(require("../../package/env")).toStrictEqual({
      railsEnv: "staging",
      nodeEnv: "development",
      isProduction: false,
      isDevelopment: true,
      runningWebpackDevServer: false
    })
  })

  test("rejects malicious NODE_ENV values and uses default", () => {
    process.env.RAILS_ENV = "development"
    process.env.NODE_ENV = "../../../etc/passwd"
    expect(require("../../package/env")).toStrictEqual({
      railsEnv: "development",
      nodeEnv: "development",
      isProduction: false,
      isDevelopment: true,
      runningWebpackDevServer: false
    })
  })

  test("warns when NODE_ENV is invalid", () => {
    const consoleSpy = jest.spyOn(console, "warn").mockImplementation()
    process.env.NODE_ENV = "invalid"
    delete process.env.RAILS_ENV
    require("../../package/env")
    expect(consoleSpy).toHaveBeenCalledWith(
      expect.stringContaining("Invalid NODE_ENV value: invalid")
    )
    consoleSpy.mockRestore()
  })
})
