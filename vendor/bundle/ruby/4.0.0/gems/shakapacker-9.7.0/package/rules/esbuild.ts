const { loaderMatches } = require("../utils/helpers")
const { getEsbuildLoaderConfig } = require("../esbuild")
const { javascript_transpiler: javascriptTranspiler } = require("../config")
const jscommon = require("./jscommon")

export = loaderMatches(javascriptTranspiler, "esbuild", () => ({
  test: /\.(ts|tsx|js|jsx|mjs|coffee)?(\.erb)?$/,
  ...jscommon,
  use: ({ resource }: { resource: string }) => getEsbuildLoaderConfig(resource)
}))
