const baseConfigs = require('./tailwind.config.js')

module.exports = {
  ...baseConfigs,
  content: [
    './app/javascript/submission_form/**/*.vue',
    './app/views/submit_form/**/*.erb',
    './app/views/start_form/**/*.erb',
    './app/views/send_submission_copy/**/*.erb'
  ]
}
