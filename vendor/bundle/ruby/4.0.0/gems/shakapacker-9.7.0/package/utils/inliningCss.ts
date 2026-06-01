const { runningWebpackDevServer } = require("../env")
const devServer = require("../dev_server")

// This logic is tied to lib/shakapacker/instance.rb
const inliningCss: boolean =
  runningWebpackDevServer && !!devServer.hmr && devServer.inline_css !== false

export = inliningCss
