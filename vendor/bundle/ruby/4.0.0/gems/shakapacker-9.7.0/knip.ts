import type { KnipConfig } from "knip"

const config: KnipConfig = {
  project: ["package/**/*.{ts,js}", "test/**/*.{ts,js}", "scripts/**/*.js"],
  ignore: [
    "package/**/*.d.ts",
    "package/**/*.js",
    "package/**/*.js.map",
    "package/**/*.d.ts.map",
    "test/fixtures/**",
    "test/helpers.js", // Test utility file used by jest
    "spec/**",
    "gemfiles/**"
  ],
  ignoreBinaries: ["sed"],
  ignoreDependencies: [
    // These are peer dependencies that may not be directly imported
    "@babel/core",
    "@types/babel__core",
    "@types/webpack",
    "webpack-dev-server",
    // Test/build tooling
    "memory-fs",
    "thenify",
    // Used in type tests but not directly imported
    "@rspack/plugin-react-refresh",
    // CLI tools used by developers
    "@rspack/cli",
    "webpack-cli",
    "husky",
    // Optional dependencies used in webpack/rspack configs
    "mini-css-extract-plugin",
    "webpack-assets-manifest",
    "webpack-subresource-integrity",
    "rspack-manifest-plugin",
    "sass-loader",
    // Package merger utility
    "@types/webpack-merge",
    // Optional runtime dependencies
    "ts-node",
    "@pmmmwh/react-refresh-webpack-plugin",
    // Optional peer dependencies referenced in code
    "@rspack/core",
    "@swc/core",
    "babel-loader",
    "compression-webpack-plugin",
    "css-loader",
    "esbuild-loader",
    "swc-loader",
    "webpack",
    // eslint-config-airbnb isn't detected because it's used by compat.extends("airbnb"),
    // the rest are its peerDependencies
    "eslint-config-airbnb",
    "eslint-plugin-import",
    "eslint-plugin-jsx-a11y",
    "eslint-plugin-react",
    "eslint-plugin-react-hooks"
  ]
}

export default config
