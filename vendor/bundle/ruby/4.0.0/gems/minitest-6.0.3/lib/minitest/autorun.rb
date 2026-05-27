require_relative "../minitest"
require_relative "spec"
require_relative "hell" if ENV["MT_HELL"]

Minitest.autorun
