# frozen_string_literal: true

module Aws
  module Plugins
    module Protocols
      class JsonRpc < Seahorse::Client::Plugin

        option(:protocol, 'json')

        option(:simple_json,
          default: false,
          doc_type: 'Boolean',
          docstring: <<-DOCS)
Disables request parameter conversion, validation, and formatting.
Also disables response data type conversions. The request parameters
hash must be formatted exactly as the API expects.This option is useful
when you want to ensure the highest level of performance by avoiding
overhead of walking request parameters and response data structures.
          DOCS

        option(:validate_params) { |config| !config.simple_json }

        option(:convert_params) { |config| !config.simple_json }

        handler(Json::Handler)
        handler(Json::ErrorHandler, step: :sign)

      end
    end
  end
end
