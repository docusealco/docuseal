# frozen_string_literal: true

require_relative '../../rubocop/lsp/runtime'

module RubyLsp
  module RuboCop
    # Provides an adapter to bridge RuboCop's built-in LSP runtime with Ruby LSP's add-on.
    # @api private
    class RuntimeAdapter
      def initialize(message_queue)
        @message_queue = message_queue
        reload_config
      end

      def reload_config
        @runtime = nil
        options, _paths = ::RuboCop::Options.new.parse([])

        config_store = ::RuboCop::ConfigStore.new
        config_store.apply_options!(options)
        @runtime = ::RuboCop::LSP::Runtime.new(config_store)
      rescue ::RuboCop::Error => e
        @message_queue << Notification.window_show_message(
          "RuboCop configuration error: #{e.message}. Formatting will not be available.",
          type: Constant::MessageType::ERROR
        )
      end

      def run_diagnostic(uri, document)
        with_error_handling do
          @runtime.offenses(
            uri_to_path(uri),
            document.source,
            document.encoding,
            prism_result: prism_result(document)
          )
        end
      end

      def run_formatting(uri, document)
        with_error_handling do
          @runtime.format(
            uri_to_path(uri),
            document.source,
            command: 'rubocop.formatAutocorrects',
            prism_result: prism_result(document)
          )
        end
      end

      def run_range_formatting(_uri, _partial_source, _base_indentation)
        # Not yet supported. Should return the formatted version of `partial_source` which is
        # a partial selection of the entire document. For example, it should not try to add
        # a frozen_string_literal magic comment and all style corrections should start from
        # the `base_indentation`.
        nil
      end

      private

      def with_error_handling
        return unless @runtime

        yield
      rescue StandardError => e
        ::RuboCop::LSP::Logger.log(e.full_message, prefix: '[RuboCop]')

        message = if e.is_a?(::RuboCop::ErrorWithAnalyzedFileLocation)
                    "for the #{e.cop.name} cop"
                  else
                    "- #{e.message}"
                  end
        raise Requests::Formatting::Error, <<~MSG
          An internal error occurred #{message}.
          Updating to a newer version of RuboCop may solve this.
          For more details, run RuboCop on the command line.
        MSG
      end

      # duplicated from: lib/standard/lsp/routes.rb
      # modified to incorporate Ruby LSP's to_standardized_path method
      def uri_to_path(uri)
        if uri.respond_to?(:to_standardized_path) && (standardized_path = uri.to_standardized_path)
          standardized_path
        else
          uri.to_s.delete_prefix('file://')
        end
      end

      def prism_result(document)
        prism_result = document.parse_result

        # NOTE: `prism_result` must be `Prism::ParseLexResult` compatible object.
        # This is for compatibility parsed result unsupported.
        prism_result.is_a?(Prism::ParseLexResult) ? prism_result : nil
      end
    end
  end
end
