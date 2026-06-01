require_relative "base_strategy"

module Shakapacker
  class MtimeStrategy < BaseStrategy
    # Returns true if manifest file mtime is newer than the timestamp of the last modified watched file
    def fresh?
      manifest_mtime > latest_modified_timestamp
    end

    # Returns true if manifest file mtime is older than the timestamp of the last modified watched file
    def stale?
      !fresh?
    end

    private

      def manifest_mtime
        config.manifest_path.exist? ? File.mtime(config.manifest_path).to_i : 0
      end

      def latest_modified_timestamp
        if Rails.env.development?
          warn <<~MSG.strip
          Shakapacker::Compiler - Slow setup for development

          Prepare JS assets with either:
          1. Running `bin/shakapacker-dev-server`
          2. Set `compile` to false in shakapacker.yml and run `bin/shakapacker -w`
        MSG
        end

        root_path = Pathname.new(File.expand_path(config.root_path))
        expanded_paths = [*default_watched_paths].map do |path|
          root_path.join(path)
        end
        latest_modified = Dir[*expanded_paths].max_by { |f| File.mtime(f) }
        File.mtime(latest_modified).to_i
      end
  end
end
