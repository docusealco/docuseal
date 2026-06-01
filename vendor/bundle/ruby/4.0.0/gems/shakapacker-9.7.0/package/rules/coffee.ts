const { canProcess } = require("../utils/helpers")

export = canProcess("coffee-loader", (resolvedPath: string) => ({
  test: /\.coffee(\.erb)?$/,
  use: [{ loader: resolvedPath }]
}))
