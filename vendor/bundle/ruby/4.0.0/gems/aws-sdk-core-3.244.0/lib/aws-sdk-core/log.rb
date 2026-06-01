# frozen_string_literal: true

module Aws
  # setup autoloading for Log module
  module Log
    autoload :Formatter, 'aws-sdk-core/log/formatter'
    autoload :ParamFilter, 'aws-sdk-core/log/param_filter'
    autoload :ParamFormatter, 'aws-sdk-core/log/param_formatter'
  end
end