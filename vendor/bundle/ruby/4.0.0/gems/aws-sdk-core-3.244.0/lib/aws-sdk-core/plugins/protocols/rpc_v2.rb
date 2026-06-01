# frozen_string_literal: true

module Aws
  module Plugins
    module Protocols
      class RpcV2 < Seahorse::Client::Plugin

        option(:protocol, 'smithy-rpc-v2-cbor')

        handler(Aws::RpcV2::Handler)
        handler(Aws::RpcV2::ContentTypeHandler, priority: 30)
        handler(Aws::RpcV2::ErrorHandler, step: :sign)

      end
    end
  end
end
