const webpack = require("webpack")
const MemoryFS = require("memory-fs")
const thenify = require("thenify")
const path = require("path")

const createTrackLoader = () => {
  const filesTracked = {}
  return [
    filesTracked,
    (source) => {
      filesTracked[source.resource] = true
      return "" // Fix #567
    }
  ]
}

const pathToNodeModules = path.resolve("node_modules")
const pathToNodeModulesIncluded = path.resolve("node_modules/included")
const pathToAppJavascript = path.resolve("app/javascript")

const createInMemoryFs = () => {
  const fs = new MemoryFS()

  fs.mkdirpSync(pathToNodeModules)
  fs.mkdirpSync(pathToNodeModulesIncluded)
  fs.mkdirpSync(pathToAppJavascript)

  return fs
}

const createTestCompiler = (config, fs = createInMemoryFs()) => {
  Object.values(config.entry).forEach((file) => {
    fs.writeFileSync(file, "console.log(1);")
  })

  const compiler = webpack(config)
  compiler.run = thenify(compiler.run)
  compiler.inputFileSystem = fs
  compiler.outputFileSystem = fs
  return compiler
}

const chdirTestApp = () => {
  try {
    return process.chdir("spec/shakapacker/test_app")
  } catch {
    return null
  }
}

const chdirCwd = () => process.chdir(process.cwd())

const resetEnv = () => {
  process.env = {}
}

module.exports = {
  chdirTestApp,
  chdirCwd,
  resetEnv,
  createTrackLoader,
  pathToNodeModules,
  pathToNodeModulesIncluded,
  pathToAppJavascript,
  createInMemoryFs,
  createTestCompiler
}
