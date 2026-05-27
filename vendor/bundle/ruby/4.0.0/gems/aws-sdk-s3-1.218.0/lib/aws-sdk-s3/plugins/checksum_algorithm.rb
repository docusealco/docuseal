# frozen_string_literal: true

module Aws
  module S3
    module Plugins
      # @api private
      class ChecksumAlgorithm < Seahorse::Client::Plugin

        # S3 GetObject results for whole Multipart Objects contain a checksum
        # that cannot be validated. These should be skipped by the
        # ChecksumAlgorithm plugin.
        class SkipWholeMultipartGetChecksumsHandler < Seahorse::Client::Handler
          def call(context)
            context[:http_checksum] ||= {}
            context[:http_checksum][:skip_on_suffix] = true

            @handler.call(context)
          end
        end

        # Handler to disable trailer checksums for S3-compatible services
        # that don't support STREAMING-UNSIGNED-PAYLOAD-TRAILER
        # See: https://github.com/aws/aws-sdk-ruby/issues/3338
        class SkipTrailerChecksumsHandler < Seahorse::Client::Handler
          def call(context)
            context[:skip_trailer_checksums] = true if custom_endpoint?(context.config)
            @handler.call(context)
          end

          private

          def custom_endpoint?(config)
            !config.regional_endpoint || !config.endpoint_provider.instance_of?(Aws::S3::EndpointProvider)
          end
        end

        def add_handlers(handlers, _config)
          handlers.add(SkipWholeMultipartGetChecksumsHandler, step: :initialize, operations: [:get_object])
          handlers.add(SkipTrailerChecksumsHandler, step: :build, priority: 16, operations: %i[put_object upload_part])
        end
      end
    end
  end
end
