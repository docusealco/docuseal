# frozen_string_literal: true

module Aws
  # setup autoloading for Resources module
  module Resources
    autoload :Collection, 'aws-sdk-core/resources/collection'
  end
end