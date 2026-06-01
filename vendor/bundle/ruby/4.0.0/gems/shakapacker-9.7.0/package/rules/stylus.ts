const { canProcess } = require("../utils/helpers")
const { getStyleRule } = require("../utils/getStyleRule")

const {
  additional_paths: paths,
  source_path: sourcePath
} = require("../config")

export = canProcess("stylus-loader", (resolvedPath: string) =>
  getStyleRule(/\.(styl(us)?)(\.erb)?$/i, [
    {
      loader: resolvedPath,
      options: {
        stylusOptions: {
          // Additional paths for Stylus imports (node_modules is resolved automatically)
          include: [sourcePath, ...paths]
        },
        sourceMap: true
      }
    }
  ])
)
