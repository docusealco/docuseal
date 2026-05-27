require_relative "instance_metadata_service"
require_relative "workload_identity"
require "json"

module AzureBlob
  class IdentityToken
    EXPIRATION_BUFFER = 600 # 10 minutes

    def initialize(principal_id: nil)
      @service = AzureBlob::WorkloadIdentity.federated_token? ?
                   AzureBlob::WorkloadIdentity.new : AzureBlob::InstanceMetadataService.new(principal_id: principal_id)
    end

    def to_s
      refresh
      token
    end

    private

    def expired?
      token.nil? || Time.now >= (expiration - EXPIRATION_BUFFER)
    end

    def refresh
      return unless expired?

      attempt = 0
      begin
        attempt += 1
        response = JSON.parse(service.request)
      rescue AzureBlob::Http::Error => error
        if should_retry?(error, attempt)
          attempt = 1 if error.status == 410
          delay = exponential_backoff(error, attempt)
          Kernel.sleep(delay)
          retry
        end
        raise
      end
      @token = response["access_token"]
      @expiration = service.expiration(response)
    end

    def should_retry?(error, attempt)
      is_500 = error.status/500 == 1
      (is_500 || [ 404, 408, 410, 429 ].include?(error.status)) && attempt < 5
    end

    def exponential_backoff(error, attempt)
      EXPONENTIAL_BACKOFF[attempt -1] || raise(AzureBlob::Error.new("Exponential backoff out of bounds!"))
    end
    EXPONENTIAL_BACKOFF = [ 2, 6, 14, 30 ]

    attr_reader :service, :expiration, :token
  end
end
