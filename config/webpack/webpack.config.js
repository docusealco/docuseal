const { globalMutableWebpackConfig, merge } = require('shakapacker')
const BundleAnalyzerPlugin = require('webpack-bundle-analyzer').BundleAnalyzerPlugin
const { VueLoaderPlugin } = require('vue-loader')

const configs = merge(globalMutableWebpackConfig, {
  resolve: {
    extensions: ['.css', '.scss', '.vue']
  },
  performance: {
    maxEntrypointSize: 0
  },
  optimization: {
    runtimeChunk: false,
    splitChunks: {
      cacheGroups: {
        default: false,
        applicationVendors: {
          test: /\/node_modules\//,
          chunks: chunk => chunk.name === 'application'
        },
        formVendors: {
          test: /\/node_modules\//,
          chunks: chunk => chunk.name === 'form'
        }
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
