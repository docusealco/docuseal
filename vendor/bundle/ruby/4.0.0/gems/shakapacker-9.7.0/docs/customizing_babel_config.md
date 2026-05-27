# Customizing Babel Config

## Default Configuration

The default configuration of babel is done by using `package.json` to use the file within the `shakapacker` package.

```json
{
  "babel": {
    "presets": ["./node_modules/shakapacker/package/babel/preset.js"]
  }
}
```

## Customizing the Babel Config

### Basic Configuration

This is a very basic skeleton that you can use that includes the Shakapacker preset, and makes it easy to add new plugins and presents:

```js
// babel.config.js
module.exports = function (api) {
  const defaultConfigFunc = require("shakapacker/package/babel/preset.js")
  const resultConfig = defaultConfigFunc(api)

  const changesOnDefault = {
    presets: [
      // put custom presets here
    ].filter(Boolean),
    plugins: [
      // put custom plugins here
    ].filter(Boolean)
  }

  resultConfig.presets = [...resultConfig.presets, ...changesOnDefault.presets]
  resultConfig.plugins = [...resultConfig.plugins, ...changesOnDefault.plugins]

  return resultConfig
}
```

### React Configuration

This shows how you can add to the above skeleton to support React - to use this, install the following dependencies:

```bash
npm install react react-dom @babel/preset-react
npm install --dev @pmmmwh/react-refresh-webpack-plugin react-refresh
```

And then update the configuration:

```js
// babel.config.js
module.exports = function (api) {
  const defaultConfigFunc = require("shakapacker/package/babel/preset.js")
  const resultConfig = defaultConfigFunc(api)
  const isDevelopmentEnv = api.env("development")
  const isProductionEnv = api.env("production")
  const isTestEnv = api.env("test")

  const changesOnDefault = {
    presets: [
      [
        "@babel/preset-react",
        {
          development: isDevelopmentEnv || isTestEnv,
          useBuiltIns: true
        }
      ]
    ].filter(Boolean),
    plugins: [
      isProductionEnv && [
        "babel-plugin-transform-react-remove-prop-types",
        {
          removeImport: true
        }
      ],
      process.env.WEBPACK_SERVE && "react-refresh/babel"
    ].filter(Boolean)
  }

  resultConfig.presets = [...resultConfig.presets, ...changesOnDefault.presets]
  resultConfig.plugins = [...resultConfig.plugins, ...changesOnDefault.plugins]

  return resultConfig
}
```
