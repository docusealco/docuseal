const { webpackConfig, merge } = require('shakapacker')
const BundleAnalyzerPlugin = require('webpack-bundle-analyzer').BundleAnalyzerPlugin
const { VueLoaderPlugin } = require('vue-loader')

const configs = merge(webpackConfig, {
  resolve: {
    extensions: ['.css', '.scss', '.vue']
  },
  optimization: {
    runtimeChunk: false,
    splitChunks: {
      cacheGroups: {
        default: false
      }
    }
  },
  plugins: [
    process.env.BUNDLE_ANALYZE && new BundleAnalyzerPlugin(),
    new VueLoaderPlugin()
  ].filter(Boolean)
})

configs.module = merge({
  rules: [
    {
      test: /\.vue$/,
      use: [{
        loader: 'vue-loader',
        options: {
          compilerOptions: {
            isCustomElement: tag => tag.includes('-')
          }
        }
      }]
    }
  ]
}, configs.module)

module.exports = configs
