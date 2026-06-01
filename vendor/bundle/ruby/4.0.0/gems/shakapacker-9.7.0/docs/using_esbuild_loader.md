# Using esbuild-loader

:warning: This feature is currently experimental. The configuration and API are subject to change during the beta release cycle.

If you face any issues, please report them at https://github.com/shakacode/shakapacker/issues.

## About esbuild

[esbuild](https://esbuild.github.io/) is a Go-based bundler tool that can offer [significant improvement](https://esbuild.github.io/faq/#benchmark-details) over other similar tools.

While esbuild is a complete bundler, through the usage of [esbuild-loader](https://github.com/privatenumber/esbuild-loader), you can still leverage esbuild's speedy transpilation and minification in your Webpack-based configs.

Please note, that unlike Babel or SWC loader, esbuild-loader has got no support for things like:

- React Hot Module reload
- ES5 as a compilation target
- Automatic polyfills for missing browser features

Those are limitations of esbuild itself and might make use of esbuild-loader in your project unfeasible. If you don't care about HMR and don't need to support older browsers, esbuild-loader might be a suitable option for you.

## Switching your Shakapacker project to esbuild-loader

To use esbuild as your transpiler today. You need to do two things:

1. Make sure you've installed `esbuild` and `esbuild-loader` packages.

```
npm install esbuild esbuild-loader
```

2. Add or change `javascript_transpiler` value in your default `shakapacker.yml` config to `esbuild`
   The default configuration of babel is done by using `package.json` to use the file within the `shakapacker` package.

```yml
default: &default
  source_path: app/javascript
  source_entry_path: /
  public_root_path: public
  public_output_path: packs
  cache_path: tmp/shakapacker
  webpack_compile_output: true

  # Additional paths webpack should look up modules
  # ['app/assets', 'engine/foo/app/assets']
  additional_paths: []

  # Reload manifest.json on all requests so we reload latest compiled packs
  cache_manifest: false

  # Select JavaScript transpiler to use, available options are 'babel' (default), 'swc' or 'esbuild'
  javascript_transpiler: "esbuild"
```

### (Optional) Replace minification with esbuild

You can gain an additional performance boost if you replace the default Terser minification with esbuild plugin.

o do so, you need to modify your webpack configuration and use `ESBuildMinifyPlugin` provided by `esbuild-loader`.

Example:

```js
const { generateWebpackConfig } = require("shakapacker")
const { ESBuildMinifyPlugin } = require("esbuild-loader")

const options = {
  optimization: {
    minimizer: [
      new ESBuildMinifyPlugin({
        target: "es2015"
      })
    ]
  }
}

module.exports = generateWebpackConfig(options)
```

For more details, see instructions at https://github.com/shakacode/shakapacker#webpack-configuration and https://github.com/privatenumber/esbuild-loader#js-minification-eg-terser.

## Usage

### React

React is supported out of the box, provided you use `.jsx` or `.tsx` file extension. Shakapacker config will correctly recognize those and tell esbuild to parse the JSX syntax correctly. If you wish to customize the likes of JSX fragment function, you can do that through customizing loader options as described below. You can see available options at https://github.com/privatenumber/esbuild-loader#%EF%B8%8F-options.

### Typescript

Typescript is supported out of the box and `.tsconfig.json` root file is automatically detected. Only a subset of `.tsconfig.json` options is supported. Please refer to the [loader docs](https://github.com/privatenumber/esbuild-loader#configuration) for additional information.

## Customizing loader options

You can see the default loader options at [esbuild/index.js](../package/esbuild/index.js).

If you wish to customize the loader defaults further, you need to create a `esbuild.config.js` file in your app config folder.

This file should have a single default export which is an object with an `options` key. Your customizations will be merged with default loader options. You can use this to override or add additional configurations.

Inside the `options` key, you can use any options available to the esbuild-loader. For the options reference, please refer to [esbuild-loader docs](https://github.com/privatenumber/esbuild-loader#%EF%B8%8F-options).

See some examples below of potential `config/babel.config.js`.

### Example: Specifying esnext target environment

```js
const customConfig = {
  options: {
    target: "esnext"
  }
}

module.exports = customConfig
```

### Example: Using custom jsxFragment and jsxFactory

```js
const { env } = require("shakapacker")

const customConfig = {
  options: {
    jsxFragment: "Fragment",
    jsxFactory: "h"
  }
}

module.exports = customConfig
```
