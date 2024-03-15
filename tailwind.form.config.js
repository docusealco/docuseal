const baseConfigs = require('./tailwind.config.js')

module.exports = {
  ...baseConfigs,
  content: [
    './app/javascript/submission_form/**/*.vue',
    './app/views/submit_form/**/*.erb',
    './app/views/start_form/**/*.erb',
    './app/views/shared/_button_title.html.erb',
    './app/views/shared/_attribution.html.erb',
    './app/views/scripts/_autosize_field.html.erb',
    './app/views/send_submission_email/**/*.erb'
  ]
}
