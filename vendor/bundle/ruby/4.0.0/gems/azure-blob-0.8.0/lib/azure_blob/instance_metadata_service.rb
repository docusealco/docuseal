module AzureBlob
  class InstanceMetadataService # :nodoc:
    IDENTITY_ENDPOINT = ENV["IDENTITY_ENDPOINT"] || "http://169.254.169.254/metadata/identity/oauth2/token"
    API_VERSION = ENV["IDENTITY_ENDPOINT"] ? "2019-08-01" : "2018-02-01"
    RESOURCE_URI = "https://storage.azure.com/"

    def initialize(principal_id: nil)
      @identity_uri = URI.parse(IDENTITY_ENDPOINT)
      params = {
        'api-version': API_VERSION,
        resource: RESOURCE_URI,
      }
      params[:principal_id] = principal_id if principal_id
      @identity_uri.query = URI.encode_www_form(params)
    end

    def request
      headers =  { "Metadata" => "true" }
      headers["X-IDENTITY-HEADER"] = ENV["IDENTITY_HEADER"] if ENV["IDENTITY_HEADER"]

      AzureBlob::Http.new(@identity_uri, headers).get
    end

    def expiration(response)
      Time.at(response["expires_on"].to_i)
    end
  end
end
