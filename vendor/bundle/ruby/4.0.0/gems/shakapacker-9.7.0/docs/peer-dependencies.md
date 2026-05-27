# Shakapacker's Peer Dependencies

## Last updated for our 9.0.0 version — see lib/install/package.json

To simplify peer dependencies while supporting both webpack & rspack, we decided to document the dependencies here instead of creating two separate npm packages.

**Important Note**: Starting with v9, Babel dependencies are no longer included as peer dependencies. They will be installed automatically only if you're using Babel as your JavaScript transpiler.

## Essential for Rspack

```text
    "@rspack/cli": "^1.0.0",
    "@rspack/core": "^1.0.0",
    "rspack-manifest-plugin": "^5.0.0",
```

## Essential for Webpack

```text
    "mini-css-extract-plugin": "^2.0.0",
    "terser-webpack-plugin": "^5.3.1",
    "webpack": "^5.76.0",
    "webpack-assets-manifest": "^5.0.6 || ^6.0.0",
    "webpack-cli": "^4.9.2 || ^5.0.0 || ^6.0.0",
    "webpack-dev-server": "^4.15.2 || ^5.2.2",
    "webpack-merge": "^5.8.0 || ^6.0.0",
    "webpack-subresource-integrity": "^5.1.0"
```

## Highly recommended

```text
    "compression-webpack-plugin": "^9.0.0 || ^10.0.0|| ^11.0.0",
    "css-loader": "^6.0.0 || ^7.0.0",
    "sass-loader": "^13.0.0 || ^14.0.0 || ^15.0.0 || ^16.0.0",
    "style-loader": "^3.0.0 || ^4.0.0",
```

## Optional JavaScript Transpilers

### Babel (installed automatically when `javascript_transpiler: 'babel'`)

```text
    "@babel/core": "^7.17.9",
    "@babel/plugin-transform-runtime": "^7.17.0",
    "@babel/preset-env": "^7.16.11",
    "@babel/runtime": "^7.17.9",
    "babel-loader": "^8.2.4 || ^9.0.0 || ^10.0.0",
```

Note: These dependencies are only installed if you're using Babel as your JavaScript transpiler. Consider using SWC or esbuild for better performance.

### SWC (default - 20x faster than Babel)

```text
    "@swc/core": "latest",
    "swc-loader": "latest"
```

- **For webpack**: Installed automatically when using default configuration
- **For rspack**: Built-in, no additional installation needed (rspack includes SWC natively)
- Manual install: `npm install @swc/core swc-loader`

### esbuild

```text
    "esbuild": "latest",
    "esbuild-loader": "latest"
```

Install manually with: `npm install esbuild esbuild-loader`
