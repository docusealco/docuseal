# frozen_string_literal: true

module AzureBlob
  # AzureBlob::Container holds the metadata for a given Container.
  class Container
    # You should not instanciate this object directly,
    # but obtain one when calling relevant methods of AzureBlob::Client.
    #
    # Expects a Net::HTTPResponse object from a
    # HEAD or GET request to a container uri.
    def initialize(response)
      @response = response
    end


    def present?
      response.code == "200"
    end

    # Returns the custom Azure metadata tagged on the container.
    def metadata
      @metadata || response
        .to_hash
        .select { |key, _| key.start_with?("x-ms-meta") }
        .transform_values(&:first)
        .transform_keys { |key| key.delete_prefix("x-ms-meta-").to_sym }
    end

    private

    attr_reader :response
  end
end
