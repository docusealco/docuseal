# frozen_string_literal: true

module Aws
  module Endpoints
    class Endpoint
      def initialize(url:, properties: {}, headers: {}, metadata: {})
        @url = url
        @properties = properties
        @headers = headers
        @metadata = metadata
      end

      attr_reader :url
      attr_reader :properties
      attr_reader :headers
      attr_reader :metadata
    end
  end
end
