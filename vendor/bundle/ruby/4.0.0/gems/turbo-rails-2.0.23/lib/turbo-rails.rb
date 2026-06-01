require "turbo/engine"
require "active_support/core_ext/module/attribute_accessors_per_thread"

module Turbo
  extend ActiveSupport::Autoload

  mattr_accessor :draw_routes, default: true

  thread_mattr_accessor :current_request_id

  class << self
    attr_writer :signed_stream_verifier_key

    def signed_stream_verifier
      @signed_stream_verifier ||= ActiveSupport::MessageVerifier.new(signed_stream_verifier_key, digest: "SHA256", serializer: JSON)
    end

    def signed_stream_verifier_key
      @signed_stream_verifier_key or raise ArgumentError, "Turbo requires a signed_stream_verifier_key"
    end

    def with_request_id(request_id)
      old_request_id, self.current_request_id = self.current_request_id, request_id
      yield
    ensure
      self.current_request_id = old_request_id
    end
  end
end
