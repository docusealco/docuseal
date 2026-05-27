# frozen_string_literal: true

require "rexml"

module AzureBlob
  # Enumerator class to lazily iterate over a list of Blob keys.
  class BlobList
    include REXML
    include Enumerable

    # You should not instanciate this object directly,
    # but obtain one when calling relevant methods of AzureBlob::Client.
    #
    # Expects a callable object that takes an Azure API page marker as an
    # argument and returns the raw body response of a call to the list blob endpoint.
    #
    # Example:
    #
    #   fetcher = ->(marker) do
    #     uri.query = URI.encode_www_form(
    #       marker: marker,
    #       ...
    #     )
    #     response = Http.new(uri, signer:).get
    #   end
    #   AzureBlob::BlobList.new(fetcher)
    #
    def initialize(fetcher)
      @fetcher = fetcher
    end

    def size
      to_a.size
    end

    def each
      loop do
        fetch
        current_page.each do |key|
          yield key
        end

        break unless marker
      end
    end

    def to_s
      to_a.to_s
    end

    def inspect
      to_a.inspect
    end

    private

    def marker
      document && document.get_elements("//EnumerationResults/NextMarker").first.get_text()&.to_s
    end

    def current_page
      document
        .get_elements("//EnumerationResults/Blobs/Blob/Name")
        .map { |element| element.text }
    end

    def fetch
      @document = Document.new(fetcher.call(marker))
    end

    attr_reader :document, :fetcher
  end
end
