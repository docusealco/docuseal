module AzureBlob
  class Metadata # :nodoc:
    def initialize(metadata = nil)
      @metadata = metadata || {}
      @headers = @metadata.map do |key, value|
        [ :"x-ms-meta-#{key}", value.to_s ]
      end.to_h
    end

    attr_reader :headers
  end
end
