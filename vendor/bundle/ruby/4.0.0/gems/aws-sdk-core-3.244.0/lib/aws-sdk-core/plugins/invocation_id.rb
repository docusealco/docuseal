# frozen_string_literal: true

require 'securerandom'

module Aws
  module Plugins

    # @api private
    class InvocationId < Seahorse::Client::Plugin

      # @api private
      class Handler < Seahorse::Client::Handler

        def call(context)
          context.http_request.headers['amz-sdk-invocation-id'] = SecureRandom.uuid
          @handler.call(context)
        end

      end

      handler(Handler, step: :initialize)

    end
  end
end
