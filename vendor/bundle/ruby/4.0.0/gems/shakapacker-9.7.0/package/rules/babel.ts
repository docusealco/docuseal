const { loaderMatches } = require("../utils/helpers")
const { javascript_transpiler: javascriptTranspiler } = require("../config")
const { isProduction } = require("../env")
const jscommon = require("./jscommon")

export = loaderMatches(javascriptTranspiler, "babel", () => ({
  test: /\.(js|jsx|mjs|ts|tsx|coffee)?(\.erb)?$/,
  ...jscommon,
  use: [
    {
      loader: require.resolve("babel-loader"),
      options: {
        cacheDirectory: true,
        cacheCompression: isProduction,
        compact: isProduction
      }
    }
  ]
}))
