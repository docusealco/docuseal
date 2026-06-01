# frozen_string_literal: true

require 'aws-sigv4'

module Aws
  module Plugins
    # @api private
    class Sign < Seahorse::Client::Plugin
      # These once had defaults. But now they are used as overrides to
      # new endpoint and auth resolution.
      option(:sigv4_signer)
      option(:sigv4_name)
      option(:sigv4_region)
      option(:unsigned_operations, default: [])

      def add_handlers(handlers, cfg)
        operations = cfg.api.operation_names - cfg.unsigned_operations
        handlers.add(Handler, step: :sign, operations: operations)
      end

      # @api private
      # Return a signer with the `sign(context)` method
      def self.signer_for(auth_scheme, config, sigv4_region_override = nil, sigv4_credentials_override = nil)
        case auth_scheme['name']
        when 'sigv4', 'sigv4a', 'sigv4-s3express'
          sigv4_overrides = {
            region: sigv4_region_override,
            credentials: sigv4_credentials_override
          }
          SignatureV4.new(auth_scheme, config, sigv4_overrides)
        when 'bearer'
          Bearer.new(config)
        else
          NullSigner.new
        end
      end

      class Handler < Seahorse::Client::Handler
        def call(context)
          # Skip signing if using sigv2 signing from s3_signer in S3
          unless v2_signing?(context.config)
            signer = Sign.signer_for(
              context[:auth_scheme],
              context.config,
              context[:sigv4_region],
              context[:sigv4_credentials]
            )
            signer.sign(context)
          end
          with_metrics(signer) { @handler.call(context) }
        end

        private

        def with_metrics(signer, &block)
          case signer
          when SignatureV4
            Aws::Plugins::UserAgent.metric(*signer.credentials.metrics, &block)
          when Bearer
            Aws::Plugins::UserAgent.metric(*signer.token_provider.metrics, &block)
          else
            block.call
          end
        end

        def v2_signing?(config)
          # 's3' is legacy signing, 'v4' is default
          config.respond_to?(:signature_version) &&
            config.signature_version == 's3'
        end
      end

      # @api private
      class Bearer
        def initialize(config)
          @token_provider = config.token_provider
        end

        attr_reader :token_provider

        def sign(context)
          if context.http_request.endpoint.scheme != 'https'
            raise ArgumentError, 'Unable to use bearer authorization on non https endpoint.'
          end
          raise Errors::MissingBearerTokenError unless @token_provider && @token_provider.set?

          context.http_request.headers['Authorization'] = "Bearer #{@token_provider.token.token}"
        end

        def presign_url(*args)
          raise ArgumentError, 'Bearer auth does not support presigned urls'
        end

        def sign_event(*args)
          raise ArgumentError, 'Bearer auth does not support event signing'
        end
      end

      # @api private
      class SignatureV4
        def initialize(auth_scheme, config, sigv4_overrides = {})
          scheme_name = auth_scheme['name']
          unless %w[sigv4 sigv4a sigv4-s3express].include?(scheme_name)
            raise ArgumentError, "Expected sigv4, sigv4a, or sigv4-s3express auth scheme, got #{scheme_name}"
          end
          region = if scheme_name == 'sigv4a'
                     auth_scheme['signingRegionSet'].join(',')
                   else
                     auth_scheme['signingRegion']
                   end
          begin
            @signer = config.sigv4_signer || Aws::Sigv4::Signer.new(
              service: config.sigv4_name || auth_scheme['signingName'],
              region: sigv4_overrides[:region] || config.sigv4_region || region,
              credentials_provider: sigv4_overrides[:credentials] || config.credentials,
              signing_algorithm: scheme_name.to_sym,
              uri_escape_path: !auth_scheme['disableDoubleEncoding'],
              normalize_path: !auth_scheme['disableNormalizePath'],
              unsigned_headers: %w[content-length user-agent x-amzn-trace-id expect transfer-encoding connection]
            )
          rescue Aws::Sigv4::Errors::MissingCredentialsError
            raise Aws::Errors::MissingCredentialsError
          end
        end

        attr_reader :signer

        def sign(context)
          req = context.http_request

          apply_authtype(context, req)
          reset_signature(req)
          apply_clock_skew(context, req)

          # compute the signature
          begin
            signature = @signer.sign_request(
              http_method: req.http_method,
              url: req.endpoint,
              headers: req.headers,
              body: req.body
            )
          rescue Aws::Sigv4::Errors::MissingCredentialsError
            # Necessary for when credentials is explicitly set to nil
            raise Aws::Errors::MissingCredentialsError
          end
          # apply signature headers
          req.headers.update(signature.headers)

          # add request metadata with signature components for debugging
          context[:canonical_request] = signature.canonical_request
          context[:string_to_sign] = signature.string_to_sign
        end

        def presign_url(*args)
          @signer.presign_url(*args)
        end

        def sign_event(*args)
          @signer.sign_event(*args)
        end

        def credentials
          @signer.credentials_provider
        end

        private

        def apply_authtype(context, req)
          # only used for event streaming at input
          if context[:input_event_emitter]
            req.headers['X-Amz-Content-Sha256'] = 'STREAMING-AWS4-HMAC-SHA256-EVENTS'
          elsif unsigned_payload?(context, req)
            req.headers['X-Amz-Content-Sha256'] ||= 'UNSIGNED-PAYLOAD'
          end
        end

        def unsigned_payload?(context, req)
          (context.operation['unsignedPayload'] ||
            context.operation['authtype'] == 'v4-unsigned-body') &&
            req.endpoint.scheme == 'https'
        end

        def reset_signature(req)
          # in case this request is being re-signed
          req.headers.delete('Authorization')
          req.headers.delete('X-Amz-Security-Token')
          req.headers.delete('X-Amz-Date')
          req.headers.delete('x-Amz-Region-Set')
        end

        def apply_clock_skew(context, req)
          if context.config.respond_to?(:clock_skew) &&
             context.config.clock_skew &&
             context.config.correct_clock_skew

            endpoint = context.http_request.endpoint
            skew = context.config.clock_skew.clock_correction(endpoint)
            if skew.abs.positive?
              req.headers['X-Amz-Date'] =
                (Time.now.utc + skew).strftime('%Y%m%dT%H%M%SZ')
            end
          end
        end

      end

      # @api private
      class NullSigner

        def sign(context)
        end

        def presign_url(*args)
        end

        def sign_event(*args)
        end
      end
    end
  end
end
