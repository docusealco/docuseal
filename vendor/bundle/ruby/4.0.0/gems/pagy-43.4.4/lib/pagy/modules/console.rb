# frozen_string_literal: true

class Pagy
  # Provide a ready to use pagy environment when included in irb/rails console
  module Console
    class Collection < Array
      def initialize(arr = Array(1..1000))
        super
        @collection = clone
      end

      def offset(value)
        tap { @collection = self[value..] }
      end

      def limit(value)
        @collection[0, value]
      end

      def count(*) = size
    end

    include Method

    def request
      @request ||= { base_url: 'http://www.example.com', path: '/path', params: { example: '123' } }
    end

    def params = request[:params]

    def collection = Collection
  end
end
