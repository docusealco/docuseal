# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Resources

    class Importer
      DEFAULT_ENGINE = :mri

      class << self
        def requirement(name, *args)
          const_name = "#{name.to_s.capitalize}Requirement".to_sym
          requirements[name] = Requirements.const_get(const_name).new(*args)
        end

        def ruby_engine(engine)
          @ruby_engine = engine
        end

        def output_path(path)
          @output_path = if path.start_with?('/')
            path
          else
            File.join(TwitterCldr::RESOURCES_DIR, path)
          end
        end

        def locales(locs)
          @locales = locs
        end

        def parameter(key, value)
          parameters[key] = value
        end

        def default_params
          parameters.merge(
            output_path: @output_path,
            locales: get_locales,
            ruby_engine: @ruby_engine || DEFAULT_ENGINE
          )
        end

        def requirements
          @requirements ||= {}
        end

        def parameters
          @parameters ||= {}
        end

        private

        def get_locales
          if ENV.include?('LOCALES')
            ENV['LOCALES'].split(',').map { |loc| loc.strip.to_sym }
          else
            @locales
          end
        end
      end

      attr_reader :params, :requirements

      def initialize(options = {})
        @params = self.class.default_params.merge(options)
        @requirements = self.class.requirements
      end

      def can_import?
        importability_errors.empty?
      end

      def import
        if can_import?
          puts "Importing #{name}..."
          prepare
          execute
        else
          raise "Can't import #{name}: #{importability_errors.first}"
        end
      end

      def prepare
        before_prepare
        requirements.each { |_, req| req.prepare }
        after_prepare
      end

      private

      def name
        @name ||= self.class.name
          .split('::').last
          .chomp('Importer')
          .gsub(/([A-Z])([a-z])/) { " #{$1.downcase}#{$2}" }
          .strip
          .tap { |n| n << 's' unless n.end_with?('s') }
      end

      def importability_errors
        @importability_errors ||= [].tap do |errors|
          errors << 'incompatible RUBY_ENGINE' unless compatible_engine?
        end
      end

      def compatible_engine?
        case params.fetch(:ruby_engine)
          when :mri
            RUBY_ENGINE == 'ruby'
          when :jruby
            RUBY_ENGINE == 'jruby'
          else
            false
        end
      end

      def before_prepare
      end

      def after_prepare
      end
    end
  end
end
