module AzureBlob
  class CanonicalizedHeaders # :nodoc:
    STANDARD_HEADERS = [
      :"x-ms-version",
    ]

    def initialize(headers)
      @cannonicalized_headers = headers
        .transform_keys(&:downcase)
        .select { |key, value| key.start_with? "x-ms-" }
        .sort
        .map { |header, value| "#{header}:#{value}" }
    end

    def to_s
      @cannonicalized_headers.join("\n")
    end
  end
end
