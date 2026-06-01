require_relative "parse_error"
require "crack/xml"

module WebMock
  module Util
    module Parsers
      class XML
        def self.parse(xml)
          ::Crack::XML.parse(xml)
        rescue ::REXML::ParseException => e
          raise ParseError, "Invalid XML string: #{xml}, Error: #{e.inspect}"
        end
      end
    end
  end
end
