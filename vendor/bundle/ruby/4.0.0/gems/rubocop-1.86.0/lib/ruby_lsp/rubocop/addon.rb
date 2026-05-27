# frozen_string_literal: true

require_relative '../../rubocop'
require_relative '../../rubocop/lsp/logger'
require_relative 'runtime_adapter'

module RubyLsp
  module RuboCop
    # A Ruby LSP add-on for RuboCop.
    class Addon < RubyLsp::Addon
      RESTART_WATCHERS = %w[.rubocop.yml .rubocop_todo.yml .rubocop].freeze

      def initialize
        super
        @runtime_adapter = nil
      end

      def name
        'RuboCop'
      end

      def version
        ::RuboCop::Version::STRING
      end

      def activate(global_state, message_queue)
        ::RuboCop::LSP::Logger.log(
          "Activating RuboCop LSP addon #{::RuboCop::Version::STRING}.", prefix: '[RuboCop]'
        )

        @runtime_adapter = RuntimeAdapter.new(message_queue)
        global_state.register_formatter('rubocop', @runtime_adapter)
        register_additional_file_watchers(global_state, message_queue)

        ::RuboCop::LSP::Logger.log(
          "Initialized RuboCop LSP addon #{::RuboCop::Version::STRING}.", prefix: '[RuboCop]'
        )
      end

      def deactivate
        @runtime_adapter = nil
      end

      # rubocop:disable Metrics/MethodLength
      def register_additional_file_watchers(global_state, message_queue)
        return unless global_state.supports_watching_files

        message_queue << Request.new(
          id: 'rubocop-file-watcher',
          method: 'client/registerCapability',
          params: Interface::RegistrationParams.new(
            registrations: [
              Interface::Registration.new(
                id: 'workspace/didChangeWatchedFilesRuboCop',
                method: 'workspace/didChangeWatchedFiles',
                register_options: Interface::DidChangeWatchedFilesRegistrationOptions.new(
                  watchers: [
                    Interface::FileSystemWatcher.new(
                      glob_pattern: "**/{#{RESTART_WATCHERS.join(',')}}",
                      kind: Constant::WatchKind::CREATE | Constant::WatchKind::CHANGE | Constant::WatchKind::DELETE
                    )
                  ]
                )
              )
            ]
          )
        )
      end
      # rubocop:enable Metrics/MethodLength

      def workspace_did_change_watched_files(changes)
        if (changed_config_file = changed_config_file(changes))
          @runtime_adapter.reload_config

          ::RuboCop::LSP::Logger.log(<<~MESSAGE, prefix: '[RuboCop]')
            Re-initialized RuboCop LSP addon #{::RuboCop::Version::STRING} due to #{changed_config_file} change.
          MESSAGE
        end
      end

      private

      def changed_config_file(changes)
        RESTART_WATCHERS.find do |file_name|
          changes.any? { |change| change[:uri].end_with?(file_name) }
        end
      end
    end
  end
end
