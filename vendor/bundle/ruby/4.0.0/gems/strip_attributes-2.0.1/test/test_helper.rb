require "minitest/autorun"
require "minitest/reporters"
if ENV["CI"] == "true"
  Minitest::Reporters.use! Minitest::Reporters::DefaultReporter.new
else
  Minitest::Reporters.use! Minitest::Reporters::ProgressReporter.new
end

require "active_attr"
require "strip_attributes"

class Tableless
  include ActiveAttr::BasicModel
  include ActiveAttr::TypecastedAttributes
  include ActiveAttr::Serialization

  include ActiveModel::Validations::Callbacks
end

# Avoid annoying deprecation warning
I18n.enforce_available_locales = true

# Remove this after we drop support for Rails 3.2 and Minitest 4.x
Minitest::Test = Minitest::Unit::TestCase unless defined?(Minitest::Test)
