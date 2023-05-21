const baseConfigs = require('./tailwind.config.js')

module.exports = {
  ...baseConfigs,
  content: [
    './app/javascript/**/*.{js,vue}',
    './app/views/**/*.erb'
  ]
}
