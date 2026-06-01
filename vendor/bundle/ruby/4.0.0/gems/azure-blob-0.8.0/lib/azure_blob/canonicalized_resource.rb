require "cgi"

module AzureBlob
  class CanonicalizedResource # :nodoc:
    def initialize(uri, account_name, service_name: nil, url_safe: true)
      # This next line is needed because CanonicalizedResource
      # need to be escaped for auhthorization headers, but not SAS tokens
      path = url_safe ? uri.path : URI::RFC2396_PARSER.unescape(uri.path)
      resource = "/#{account_name}#{path.empty? ? "/" : path}"
      resource = "/#{service_name}#{resource}" if service_name
      params = CGI.parse(uri.query.to_s)
        .transform_keys(&:downcase)
        .sort
        .map { |param, value| "#{param}:#{value.map(&:strip).sort.join(",")}" }

      @canonicalized_resource = [ resource, *params ].join("\n")
    end

    def to_s
      @canonicalized_resource
    end
  end
end
