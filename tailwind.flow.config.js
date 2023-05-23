const baseConfigs = require('./tailwind.config.js')

module.exports = {
  ...baseConfigs,
  content: [
    './app/views/submit_flow/**/*.erb',
    './app/views/start_flow/**/*.erb',
    './app/views/send_submission_copy/**/*.erb'
  ]
}
