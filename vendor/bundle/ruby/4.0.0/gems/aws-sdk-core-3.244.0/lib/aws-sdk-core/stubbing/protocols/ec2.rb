# frozen_string_literal: true

module Aws
  module Stubbing
    module Protocols
      # @api private
      class EC2

        def stub_data(api, operation, data)
          resp = Seahorse::Client::Http::Response.new
          resp.status_code = 200
          resp.body = build_body(api, operation, data) if operation.output
          resp.headers['Content-Length'] = resp.body.size
          resp.headers['Content-Type'] = 'text/xml;charset=UTF-8'
          resp.headers['Server'] = 'AmazonEC2'
          resp
        end

        def stub_error(error_code)
          resp = Seahorse::Client::Http::Response.new
          resp.status_code = 400
          resp.body = <<~XML.strip
            <ErrorResponse>
              <Error>
                <Code>#{error_code}</Code>
                <Message>stubbed-response-error-message</Message>
              </Error>
            </ErrorResponse>
          XML
          resp
        end

        private

        def build_body(api, operation, data)
          xml = []
          Xml::Builder.new(operation.output, target:xml).to_xml(data)
          xml.shift
          xml.pop
          xmlns = "http://ec2.amazonaws.com/doc/#{api.version}/".inspect
          xml.unshift('  <requestId>stubbed-request-id</requestId>')
          xml.unshift("<#{operation.name}Response xmlns=#{xmlns}>\n")
          xml.push("</#{operation.name}Response>\n")
          xml.join
        end

      end
    end
  end
end
