# frozen_string_literal: true

module Aws
  module Stubbing
    module Protocols
      # @api private
      class RestXml < Rest

        def body_for(api, operation, rules, data)
          if eventstream?(rules)
            encode_eventstream_response(rules, data, Xml::Builder)
          else
            xml = []
            rules.location_name = "#{operation.name}Result"
            rules['xmlNamespace'] = { 'uri' => api.metadata['xmlNamespace'] }
            Xml::Builder.new(rules, target:xml).to_xml(data)
            xml.join
          end
        end

        def stub_error(error_code)
          resp = Seahorse::Client::Http::Response.new
          resp.status_code = 400
          resp.body = XmlError.new(error_code).to_xml
          resp
        end

        def xmlns(api)
          api.metadata['xmlNamespace']
        end

      end
    end
  end
end
