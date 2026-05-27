/**
 * Documentation mapping for webpack/rspack configuration keys.
 * Used to add inline comments when exporting configs with --annotate flag.
 */

export const CONFIG_DOCS: Record<string, string> = {
  mode: "Controls webpack optimization: 'development' (fast builds, detailed errors), 'production' (optimized, minified), or 'none'",
  output: "Configuration for output bundles",
  "output.filename":
    "Bundle name template. [name]=entry name, [contenthash]=content-based hash for caching, [chunkhash]=chunk hash",
  "output.path": "Absolute directory path where bundles are written",
  "output.publicPath":
    "URL prefix for loading assets in the browser (used by webpack for code splitting and asset loading)",
  "output.chunkFilename":
    "Template for non-entry chunk files created by code splitting",
  "output.assetModuleFilename":
    "Template for asset module filenames (images, fonts, etc.)",
  "output.crossOriginLoading":
    "Cross-origin loading setting for script tags: 'anonymous', 'use-credentials', or false",
  "output.globalObject":
    "Global object reference for UMD builds (e.g., 'this', 'window', 'global')",
  devtool:
    "Source map style: 'source-map' (full, slow), 'eval-source-map' (full, fast rebuild), 'cheap-source-map' (fast, less detail), false (none)",
  optimization: "Code optimization settings",
  "optimization.minimize":
    "Enable/disable minification (true in production mode)",
  "optimization.minimizer":
    "Array of minimizer plugins (e.g., TerserPlugin, CssMinimizerPlugin)",
  "optimization.splitChunks":
    "Code splitting configuration - extracts common dependencies into separate chunks",
  "optimization.runtimeChunk":
    "Extract webpack runtime into separate chunk: 'single' (one runtime for all), true (one per entry), false (inline)",
  "optimization.moduleIds":
    "Module ID generation strategy: 'deterministic' (stable), 'named' (readable), 'natural' (numeric order)",
  "optimization.chunkIds":
    "Chunk ID generation strategy: 'deterministic', 'named', 'natural'",
  module: "Configures how different file types are processed",
  "module.rules":
    "Array of rules defining loaders and processing for different file types",
  plugins:
    "Array of webpack plugins to apply (e.g., HtmlWebpackPlugin, MiniCssExtractPlugin)",
  resolve: "Module resolution configuration",
  "resolve.extensions":
    "File extensions to try when resolving modules (e.g., ['.js', '.jsx', '.ts', '.tsx'])",
  "resolve.modules":
    "Directories to search when resolving modules (e.g., ['node_modules', 'app/javascript'])",
  "resolve.alias":
    "Create import aliases for modules (e.g., @components -> ./src/components)",
  resolveLoader: "Configuration for resolving loaders",
  "resolveLoader.modules": "Directories to search for loaders",
  entry:
    "Entry points for the application - where webpack starts building the dependency graph",
  devServer: "Webpack dev server configuration (HMR, proxying, HTTPS, etc.)",
  "devServer.port": "Port number for dev server (default: 8080)",
  "devServer.host": "Host for dev server (e.g., 'localhost', '0.0.0.0')",
  "devServer.hot": "Enable Hot Module Replacement (HMR)",
  "devServer.https": "Enable HTTPS for dev server",
  stats:
    "Controls bundle information display: 'normal', 'verbose', 'minimal', 'errors-only', 'none'",
  bail: "Fail the build on first error (true) or continue and report all errors (false)",
  performance: "Performance budget configuration",
  "performance.maxAssetSize":
    "Maximum size (in bytes) for individual assets before webpack warns",
  "performance.maxEntrypointSize":
    "Maximum size (in bytes) for entry point bundles before webpack warns",
  target:
    "Build target environment: 'web' (browser), 'node' (Node.js), 'webworker', etc.",
  externals:
    "Dependencies to exclude from bundle (assumed to be available in runtime environment)",
  cache:
    "Build caching configuration: false (disabled), { type: 'memory' }, or { type: 'filesystem' }",
  watch: "Enable watch mode - rebuild on file changes",
  watchOptions: "Watch mode configuration (polling, ignored files, etc.)"
}

/**
 * Get documentation for a specific config key path.
 * Supports nested paths like 'output.filename'.
 */
export function getDocForKey(keyPath: string): string | undefined {
  return CONFIG_DOCS[keyPath]
}

/**
 * Get documentation for a key, trying parent paths if exact match not found.
 * E.g., 'output.filename' -> tries 'output.filename', then 'output'
 */
export function getDocForKeyWithFallback(keyPath: string): string | undefined {
  // Try exact match first
  if (CONFIG_DOCS[keyPath]) {
    return CONFIG_DOCS[keyPath]
  }

  // Try parent key
  const parts = keyPath.split(".")
  if (parts.length > 1) {
    const parentKey = parts.slice(0, -1).join(".")
    return CONFIG_DOCS[parentKey]
  }

  return undefined
}
