# frozen_string_literal: true

module Aws
  module S3
    module Plugins
      # @api private
      class AccessGrants < Seahorse::Client::Plugin
        @s3control =
          begin
            require 'aws-sdk-s3control'
            true
          rescue LoadError
            false
          end

        option(
          :access_grants,
          default: false,
          doc_type: 'Boolean',
          docstring: <<-DOCS)
When `true`, the S3 client will use the S3 Access Grants feature to
authenticate requests. Bucket credentials will be fetched from S3
Control using the `get_data_access` API.
          DOCS

        option(:access_grants_credentials_provider,
          doc_type: 'Aws::S3::AccessGrantsCredentialsProvider',
          rbs_type: 'untyped',
          docstring: <<-DOCS) do |_cfg|
When `access_grants` is `true`, this option can be used to provide
additional options to the credentials provider, including a privilege
setting, caching, and fallback behavior.
          DOCS
          Aws::S3::AccessGrantsCredentialsProvider.new
        end

        # @api private
        class Handler < Seahorse::Client::Handler
          PERMISSION_MAP = {
            head_object: 'READ',
            get_object: 'READ',
            get_object_acl: 'READ',
            list_multipart_uploads: 'READ',
            list_objects_v2: 'READ',
            list_object_versions: 'READ',
            list_parts: 'READ',
            head_bucket: 'READ',
            get_object_attributes: 'READ',
            put_object: 'WRITE',
            put_object_acl: 'WRITE',
            delete_object: 'WRITE',
            abort_multipart_upload: 'WRITE',
            create_multipart_upload: 'WRITE',
            upload_part: 'WRITE',
            complete_multipart_upload: 'WRITE',
            delete_objects: 'WRITE',
            copy_object: 'READWRITE'
          }.freeze

          def call(context)
            provider = context.config.access_grants_credentials_provider

            if access_grants_operation?(context) &&
               !s3_express_endpoint?(context) &&
               !credentials_head_bucket_call?(provider)
              params = context[:endpoint_params]
              permission = PERMISSION_MAP[context.operation_name]

              key =
                case context.operation_name
                when :delete_objects
                  delete_params = context.params[:delete]
                  common_prefixes(delete_params[:objects].map { |o| o[:key] })
                when :copy_object
                  source_bucket, source_key = params[:copy_source].split('/', 2)
                  if params[:bucket] != source_bucket
                    raise ArgumentError,
                          'source and destination bucket must be the same'
                  end
                  common_prefixes([params[:key], source_key])
                else
                  params[:key]
                end

              credentials = provider.access_grants_credentials_for(
                bucket: params[:bucket],
                key: key,
                prefix: params[:prefix],
                permission: permission
              )
              context[:sigv4_credentials] = credentials # Sign will use this
            end

            with_metric(credentials) { @handler.call(context) }
          end

          private

          def with_metric(credentials, &block)
            return block.call unless credentials

            Aws::Plugins::UserAgent.metric('S3_ACCESS_GRANTS', &block)
          end

          # HeadBucket is a supported call. When fetching credentials,
          # this plugin is executed again, and becomes recursive.
          def credentials_head_bucket_call?(provider)
            provider.instance_variable_get(:@head_bucket_call)
          end

          def access_grants_operation?(context)
            params = context[:endpoint_params]
            params[:bucket] && PERMISSION_MAP[context.operation_name]
          end

          def s3_express_endpoint?(context)
            context[:endpoint_properties]['backend'] == 'S3Express'
          end

          # Return the common prefix of the keys, regardless of the delimiter.
          # For example, given keys ['foo/bar', 'foo/baz'], the common prefix
          # is 'foo/ba'.
          def common_prefixes(keys)
            return '' if keys.empty?

            first_key = keys[0]
            common_ancestor = first_key
            last_prefix = ''
            keys.each do |k|
              until common_ancestor.empty?
                break if k.start_with?(common_ancestor)

                last_index = common_ancestor.rindex('/')
                return '' if last_index.nil?

                last_prefix = common_ancestor[(last_index + 1)..-1]
                common_ancestor = common_ancestor[0...last_index]
              end
            end
            new_common_ancestor = "#{common_ancestor}/#{last_prefix}"
            keys.each do |k|
              until last_prefix.empty?
                break if k.start_with?(new_common_ancestor)

                last_prefix = last_prefix[0...-1]
                new_common_ancestor = "#{common_ancestor}/#{last_prefix}"
              end
            end
            if new_common_ancestor == "#{first_key}/"
              first_key
            else
              new_common_ancestor
            end
          end
        end

        def add_handlers(handlers, config)
          return unless AccessGrants.s3control? && config.access_grants

          handlers.add(Handler)
        end

        def after_initialize(client)
          return unless AccessGrants.s3control? && client.config.access_grants

          provider = client.config.access_grants_credentials_provider
          provider.s3_client = client unless provider.s3_client
        end

        class << self
          def s3control?
            @s3control
          end
        end
      end
    end
  end
end
