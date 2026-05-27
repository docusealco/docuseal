# frozen_string_literal: true

module Aws
  module Plugins
    module Protocols
      class RestJson < Seahorse::Client::Plugin

        option(:protocol, 'rest-json')

        handler(Rest::Handler)
        handler(Rest::ContentTypeHandler, priority: 30)
        handler(Json::ErrorHandler, step: :sign)

      end
    end
  end
end
