module AzureBlob
  class WorkloadIdentity # :nodoc:
    IDENTITY_ENDPOINT = "https://login.microsoftonline.com/#{ENV['AZURE_TENANT_ID']}/oauth2/v2.0/token"
    CLIENT_ID = ENV["AZURE_CLIENT_ID"]
    SCOPE = "https://storage.azure.com/.default"
    GRANT_TYPE = "client_credentials"
    CLIENT_ASSERTION_TYPE = "urn:ietf:params:oauth:client-assertion-type:jwt-bearer"

    FEDERATED_TOKEN_FILE = ENV["AZURE_FEDERATED_TOKEN_FILE"].to_s

    def self.federated_token?
      !FEDERATED_TOKEN_FILE.empty?
    end

    def initialize
      @identity_uri = URI.parse(IDENTITY_ENDPOINT)
    end

    def request
      AzureBlob::Http.new(@identity_uri).post(
        URI.encode_www_form(
          client_id: CLIENT_ID,
          scope: SCOPE,
          client_assertion_type: CLIENT_ASSERTION_TYPE,
          client_assertion: federated_token,
          grant_type: GRANT_TYPE
        )
      )
    end

    def expiration(response)
      Time.now + response["expires_in"].to_i
    end

    private

    def federated_token
      File.read(FEDERATED_TOKEN_FILE).strip
    end
  end
end
