module Shakapacker
  class BaseStrategy
    def initialize
      @config = Shakapacker.config
    end

    def after_compile_hook
      nil
    end

    private

      attr_reader :config

      def default_watched_paths
        [
          *config.additional_paths.map { |path| "#{path}{,/**/*}" },
          "#{config.source_path}{,/**/*}",
          "package.json", "package-lock.json", "yarn.lock",
          "pnpm-lock.yaml", "bun.lockb",
          "config/webpack{,/**/*}"
        ].freeze
      end
  end
end
