const { canProcess } = require("../utils/helpers")
const { getStyleRule } = require("../utils/getStyleRule")

const {
  additional_paths: paths,
  source_path: sourcePath
} = require("../config")

export = canProcess("less-loader", (resolvedPath: string) =>
  getStyleRule(/\.(less)(\.erb)?$/i, [
    {
      loader: resolvedPath,
      options: {
        lessOptions: {
          // Additional paths for Less imports (node_modules is resolved automatically)
          paths: [sourcePath, ...paths]
        },
        sourceMap: true
      }
    }
  ])
)
