# frozen_string_literal: true

require 'json'

module Aws
  module Json
    module JsonEngine
      class << self
        def load(json)
          JSON.parse(json)
        rescue JSON::ParserError => e
          raise ParseError.new(e)
        end

        def dump(value)
          JSON.dump(value)
        end
      end
    end
  end
end
