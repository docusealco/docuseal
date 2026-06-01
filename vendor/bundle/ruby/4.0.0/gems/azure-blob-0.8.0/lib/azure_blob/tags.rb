require "rexml/document"

module AzureBlob
  class Tags # :nodoc:
    def self.from_response(response)
      document = REXML::Document.new(response)
      tags = {}
      document.elements.each("Tags/TagSet/Tag") do |tag|
        key = tag.elements["Key"].text
        value = tag.elements["Value"].text
        tags[key] = value
      end
      new(tags)
    end

    def initialize(tags = nil)
      @tags = tags || {}
    end

    def headers
      return {} if @tags.empty?

      {
        "x-ms-tags":
        @tags.map do |key, value|
          %(#{key}=#{value})
        end.join("&"),
      }
    end

    def to_h
      @tags
    end
  end
end
