# frozen_string_literal: true

module Aws
  module Plugins
    module Protocols
      class RestXml < Seahorse::Client::Plugin

        option(:protocol, 'rest-xml')

        handler(Rest::Handler)
        handler(Rest::ContentTypeHandler, priority: 30)
        handler(Xml::ErrorHandler, step: :sign)

      end
    end
  end
end
