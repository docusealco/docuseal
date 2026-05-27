# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

require 'yaml'

module TwitterCldr
  module Resources

    class ResourceLoadError < StandardError; end

    class Loader

      class << self
        def load_yaml(yaml, permitted_classes: [])
          if Psych::VERSION >= '4'
            YAML.safe_load(yaml, permitted_classes: permitted_classes)
          else
            YAML.safe_load(yaml, permitted_classes)
          end
        end
      end

      VALID_EXTS = %w(.yml .dump).freeze
      PERMITTED_YAML_CLASSES = [Range, Regexp, Symbol, Time].freeze

      def get_resource(*path)
        resources_cache[resource_file_path(path)]
      end

      def resource_exists?(*path)
        File.exist?(absolute_resource_path(resource_file_path(path)))
      end

      def locale_resource_exists?(locale, resource_name)
        resource_exists?(*locale_resource_path(locale, resource_name))
      end

      def absolute_resource_path(path)
        File.join(TwitterCldr::RESOURCES_DIR, path)
      end

      def get_locale_resource(locale, resource_name)
        get_resource(*locale_resource_path(locale, resource_name))
      end

      def resource_loaded?(*path)
        resources_cache.include?(resource_file_path(path))
      end

      def locale_resource_loaded?(locale, resource_name)
        resource_loaded?(*locale_resource_path(locale, resource_name))
      end

      def resource_types_for(locale)
        Dir.glob(File.join(RESOURCES_DIR, 'locales', locale.to_s, '*')).map do |file|
          File.basename(file).chomp(File.extname(file)).to_sym
        end
      end

      def preload_resources_for_locale(locale, *resources)
        if resources.size > 0
          resources = resource_types_for(locale) if resources.first == :all
          resources.each { |res| get_locale_resource(locale, res) }
        end
        nil
      end

      def preload_resource_for_locales(resource, *locales)
        locales.each do |locale|
          preload_resources_for_locale(locale, resource)
        end
        nil
      end

      def preload_resources_for_all_locales(*resources)
        TwitterCldr.supported_locales.each do |locale|
          preload_resources_for_locale(locale, *resources)
        end
        nil
      end

      def preload_all_resources
        TwitterCldr.supported_locales.each do |locale|
          preload_resources_for_locale(locale, :all)
        end
        nil
      end

      def resource_file_path(path)
        file = File.join(*path.map(&:to_s))
        file << '.yml' unless VALID_EXTS.include?(File.extname(file))
        file
      end

      private

      def locale_resource_path(locale, resource_name)
        [:locales, TwitterCldr.convert_locale(locale), resource_name]
      end

      def resources_cache
        @resources_cache ||= Hash.new do |hash, path|
          hash[path] = load_resource(path)
        end
      end

      def load_resource(path, merge_custom = true)
        case File.extname(path)
          when '.yml'
            load_yaml_resource(path, merge_custom)
          when '.dump'
            load_marshalled_resource(path, merge_custom)
          else
            load_raw_resource(path, merge_custom)
        end
      end

      def load_yaml_resource(path, merge_custom = true)
        base = load_yaml(read_resource_file(path), permitted_classes: PERMITTED_YAML_CLASSES)
        custom_path = File.join("custom", path)

        if merge_custom && custom_resource_exists?(custom_path) && !TwitterCldr.disable_custom_locale_resources
          TwitterCldr::Utils.deep_merge!(base, load_resource(custom_path, false))
        end

        base
      end

      def load_yaml(yaml, permitted_classes: [])
        self.class.load_yaml(yaml, permitted_classes: permitted_classes)
      end

      def load_marshalled_resource(path, _merge_custom = :unused)
        Marshal.load(read_resource_file(path))
      end

      def load_raw_resource(path, _merge_custom = :unused)
        read_resource_file(path)
      end

      def custom_resource_exists?(custom_path)
        File.exist?(
          File.join(TwitterCldr::RESOURCES_DIR, custom_path)
        )
      end

      def read_resource_file(path)
        file_path = absolute_resource_path(path)

        if File.file?(file_path)
          File.open(file_path, "r:UTF-8", &:read)
        else
          raise ResourceLoadError,
            "Resource '#{path}' not found."
        end
      end
    end

  end
end
