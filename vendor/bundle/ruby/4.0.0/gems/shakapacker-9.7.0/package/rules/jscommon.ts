import { resolve } from "path"
import { realpathSync } from "fs"

const {
  source_path: sourcePath,
  additional_paths: additionalPaths
} = require("../config")

const inclusions = [sourcePath, ...additionalPaths].map((p: string) => {
  try {
    return realpathSync(p)
  } catch (e) {
    return resolve(p)
  }
})

export = {
  include: inclusions,
  exclude: [
    {
      // exclude all node_modules from running through babel-loader
      and: [resolve("node_modules")],
      // Do not exclude inclusions, as otherwise these won't be transpiled
      not: [...inclusions]
    }
  ]
}
