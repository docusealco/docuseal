import { DevServerConfig } from "./types"

const snakeToCamelCase = require("./utils/snakeToCamelCase")

const shakapackerDevServerYamlConfig =
  require("./dev_server") as DevServerConfig
const { outputPath: contentBase, publicPath } = require("./config") as {
  outputPath: string
  publicPath: string
}

interface WebpackDevServerConfig {
  devMiddleware?: {
    publicPath?: string
  }
  hot?: boolean | string
  liveReload?: boolean
  historyApiFallback?:
    | boolean
    | {
        disableDotRule?: boolean
      }
  static?: {
    publicPath?: string
    [key: string]: unknown
  }
  client?: Record<string, unknown>
  allowedHosts?: string | string[]
  bonjour?: boolean | Record<string, unknown>
  compress?: boolean
  headers?: Record<string, unknown> | (() => Record<string, unknown>)
  host?: string
  http2?: boolean
  https?: boolean | Record<string, unknown>
  ipc?: boolean | string
  magicHtml?: boolean
  onAfterSetupMiddleware?: (devServer: unknown) => void
  onBeforeSetupMiddleware?: (devServer: unknown) => void
  open?:
    | boolean
    | string
    | string[]
    | Record<string, unknown>
    | Record<string, unknown>[]
  port?: string | number
  proxy?: unknown
  server?: string | boolean | Record<string, unknown>
  setupExitSignals?: boolean
  setupMiddlewares?: (middlewares: unknown[], devServer: unknown) => unknown[]
  watchFiles?: unknown
  webSocketServer?: string | boolean | Record<string, unknown>
  [key: string]: unknown
}

const webpackDevServerMappedKeys = new Set([
  // client, server, liveReload, devMiddleware are handled separately
  "allowedHosts",
  "bonjour",
  "compress",
  "headers",
  "historyApiFallback",
  "host",
  "hot",
  "http2",
  "https",
  "ipc",
  "magicHtml",
  "onAfterSetupMiddleware",
  "onBeforeSetupMiddleware",
  "open",
  "port",
  "proxy",
  "server",
  "setupExitSignals",
  "setupMiddlewares",
  "watchFiles",
  "webSocketServer"
])

function createDevServerConfig(): WebpackDevServerConfig {
  const devServerYamlConfig = {
    ...shakapackerDevServerYamlConfig
  } as DevServerConfig & Record<string, unknown>
  const liveReload =
    devServerYamlConfig.live_reload !== undefined
      ? devServerYamlConfig.live_reload
      : !devServerYamlConfig.hmr
  delete devServerYamlConfig.live_reload

  const config: WebpackDevServerConfig = {
    devMiddleware: {
      publicPath
    },
    hot: devServerYamlConfig.hmr,
    liveReload,
    historyApiFallback: {
      disableDotRule: true
    },
    static: {
      publicPath: contentBase
    }
  }
  delete devServerYamlConfig.hmr

  if (devServerYamlConfig.static) {
    config.static = {
      ...config.static,
      ...(typeof devServerYamlConfig.static === "object"
        ? (devServerYamlConfig.static as Record<string, unknown>)
        : {})
    }
    delete devServerYamlConfig.static
  }

  if (devServerYamlConfig.client) {
    config.client = devServerYamlConfig.client
    delete devServerYamlConfig.client
  }

  Object.keys(devServerYamlConfig).forEach((yamlKey) => {
    const camelYamlKey = snakeToCamelCase(yamlKey)
    if (webpackDevServerMappedKeys.has(camelYamlKey)) {
      config[camelYamlKey] = devServerYamlConfig[yamlKey]
    }
  })

  return config
}

export = createDevServerConfig
