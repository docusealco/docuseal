# frozen_string_literal: true

module Aws
  module Plugins
    # @api private
    class StubResponses < Seahorse::Client::Plugin

      option(:stub_responses,
        default: false,
        doc_type: 'Boolean',
        rbs_type: 'untyped',
        docstring: <<-DOCS)
Causes the client to return stubbed responses. By default
fake responses are generated and returned. You can specify
the response data to return or errors to raise by calling
{ClientStubs#stub_responses}. See {ClientStubs} for more information.

** Please note ** When response stubbing is enabled, no HTTP
requests are made, and retries are disabled.
        DOCS

      option(:region) do |config|
        'us-stubbed-1' if config.stub_responses
      end

      option(:credentials) do |config|
        if config.stub_responses
          Credentials.new('stubbed-akid', 'stubbed-secret')
        end
      end

      option(:token_provider) do |config|
        if config.stub_responses
          StaticTokenProvider.new('stubbed-token')
        end
      end

      option(:stubs) { {} }
      option(:stubs_mutex) { Mutex.new }
      option(:api_requests) { [] }
      option(:api_requests_mutex) { Mutex.new }

      def add_handlers(handlers, config)
        return unless config.stub_responses

        handlers.add(ApiRequestsHandler)
        handlers.add(StubbingHandler, step: :send)
      end

      def after_initialize(client)
        if client.config.stub_responses
          client.setup_stubbing
          client.handlers.remove(RetryErrors::Handler)
          client.handlers.remove(RetryErrors::LegacyHandler)
          client.handlers.remove(ClientMetricsPlugin::Handler)
          client.handlers.remove(ClientMetricsSendPlugin::LatencyHandler)
          client.handlers.remove(ClientMetricsSendPlugin::AttemptHandler)
          client.handlers.remove(Seahorse::Client::Plugins::RequestCallback::OptionHandler)
          client.handlers.remove(Seahorse::Client::Plugins::RequestCallback::ReadCallbackHandler)
        end
      end

      class ApiRequestsHandler < Seahorse::Client::Handler
        def call(context)
          context.config.api_requests_mutex.synchronize do
            context.config.api_requests << {
              operation_name: context.operation_name,
              params: context.params,
              context: context
            }
          end
          @handler.call(context)
        end
      end

      class StubbingHandler < Seahorse::Client::Handler
        def call(context)
          span_wrapper(context) do
            stub_responses(context)
          end
        end

        private

        def stub_responses(context)
          resp = Seahorse::Client::Response.new(context: context)
          async_mode = context.client.is_a? Seahorse::Client::AsyncBase
          stub = context.client.next_stub(context)
          stub[:mutex].synchronize { apply_stub(stub, resp, async_mode) }

          if async_mode
            Seahorse::Client::AsyncResponse.new(
              context: context,
              stream: context[:input_event_stream_handler].event_emitter.stream,
              sync_queue: Queue.new
            )
          else
            resp
          end
        end

        def apply_stub(stub, response, async_mode = false)
          http_resp = response.context.http_response
          case
          when stub[:error] then signal_error(stub[:error], http_resp)
          when stub[:http] then signal_http(stub[:http], http_resp, async_mode)
          when stub[:data] then response.data = stub[:data]
          end
        end

        def signal_error(error, http_resp)
          if Exception === error
            http_resp.signal_error(error)
          else
            http_resp.signal_error(error.new)
          end
        end

        # @param [Seahorse::Client::Http::Response] stub
        # @param [Seahorse::Client::Http::Response | Seahorse::Client::Http::AsyncResponse] http_resp
        # @param [Boolean] async_mode
        def signal_http(stub, http_resp, async_mode = false)
          if async_mode
            h2_headers = stub.headers.to_h.inject([]) do |arr, (k, v)|
              arr << [k, v]
            end
            h2_headers << [":status", stub.status_code]
            http_resp.signal_headers(h2_headers)
          else
            http_resp.signal_headers(stub.status_code, stub.headers.to_h)
          end
          while chunk = stub.body.read(1024 * 1024)
            http_resp.signal_data(chunk)
          end
          stub.body.rewind
          http_resp.signal_done
        end

        def span_wrapper(context, &block)
          context.tracer.in_span(
            'Handler.StubResponses',
            attributes: Aws::Telemetry.http_request_attrs(context)
          ) do |span|
            block.call.tap do
              span.add_attributes(
                Aws::Telemetry.http_response_attrs(context)
              )
            end
          end
        end
      end
    end
  end
end
