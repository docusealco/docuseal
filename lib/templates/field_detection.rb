# frozen_string_literal: true

module Templates
  module FieldDetection
    CONFIG_DIR  = ENV.fetch('FIELD_DETECTION_CONFIG_DIR',
                            File.join(ExternalConfig::CONFIG_DIR, 'field_detection'))
    SCRIPTS_DIR = ENV.fetch('FIELD_DETECTION_SCRIPTS_DIR',
                            File.join(ExternalConfig::CONFIG_DIR, 'field_detection_scripts'))

    class << self
      def register(name, handler)
        registered_scripts[name.to_s.downcase.strip] = handler
      end

      def registered_scripts
        @registered_scripts ||= {}
      end

      def load_scripts!
        return if @scripts_loaded

        @scripts_loaded = true
        return unless Dir.exist?(SCRIPTS_DIR)

        Dir.glob(File.join(SCRIPTS_DIR, '*.rb')).each do |path|
          load(path)
        rescue StandardError => e
          Rails.logger.warn("[FieldDetection] Failed to load script #{path}: #{e.message}")
        end
      end

      def available_algorithms
        load_scripts!
        registered_scripts.merge(external_algorithms)
      end

      def profile_names
        available_algorithms.keys.sort
      end

      def call(template, algorithm, documents = nil)
        algo_key = algorithm.to_s.downcase.strip
        handler  = available_algorithms[algo_key]

        raise ArgumentError, "Unknown algorithm: '#{algorithm}'" unless handler

        if handler.is_a?(Hash)
          Templates::FieldDetection::ConfigBased.call(template, handler, documents)
        elsif handler.respond_to?(:call)
          handler.call(template, documents)
        else
          raise ArgumentError, "Invalid handler for algorithm '#{algo_key}'"
        end
      end

      def external_algorithms
        return {} unless Dir.exist?(CONFIG_DIR)

        Dir.glob(File.join(CONFIG_DIR, '*.{yml,yaml}')).each_with_object({}) do |path, hash|
          config = YAML.safe_load_file(path, permitted_classes: [Regexp])
          hash[File.basename(path, File.extname(path))] = config if config.is_a?(Hash)
        rescue StandardError
          next
        end
      end

      def reset!
        @registered_scripts = {}
        @scripts_loaded = false
      end
    end
  end
end
