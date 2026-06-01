const { canProcess } = require("../utils/helpers")

const runner = /^win/.test(process.platform) ? "ruby " : ""

export = canProcess("rails-erb-loader", (resolvedPath: string) => ({
  test: /\.erb$/,
  enforce: "pre",
  exclude: /node_modules/,
  use: [
    {
      loader: resolvedPath,
      options: {
        runner: `${runner}bin/rails runner`,
        env: {
          ...process.env,
          DISABLE_SPRING: 1
        }
      }
    }
  ]
}))
