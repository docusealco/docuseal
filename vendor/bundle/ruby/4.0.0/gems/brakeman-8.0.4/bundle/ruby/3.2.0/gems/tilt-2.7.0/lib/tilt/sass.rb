# frozen_string_literal: true

# = Sass / Scss
#
# Sass/Scss template implementation for generating CSS.
#
# Sass templates do not support object scopes, locals, or yield.
#
# === See also
#
# * https://sass-lang.com/
#
# === Related modules
#
# * Tilt::SassTemplate
# * Tilt::ScssTemplate

require_relative 'template'

module Tilt
  class SassTemplate < StaticTemplate
    self.default_mime_type = 'text/css'

    begin
      require 'sass-embedded'
    # :nocov:
      require 'uri'

      ALLOWED_KEYS = (defined?(::Sass::Compiler) ? ::Sass::Compiler : ::Sass::Embedded).
        instance_method(:compile_string).
        parameters.
        map{|k, v| v if k == :key}.
        compact rescue nil
      private_constant :ALLOWED_KEYS

      private

      def _prepare_output
        ::Sass.compile_string(@data, **sass_options).css
      end

      def sass_options
        path = File.absolute_path(eval_file)
        path = '/' + path unless path.start_with?('/')
        opts = @options.dup
        opts[:url] = ::URI::File.build([nil, ::URI::DEFAULT_PARSER.escape(path)]).to_s
        opts[:syntax] = :indented
        opts.delete_if{|k| !ALLOWED_KEYS.include?(k)} if ALLOWED_KEYS
        opts
      end
    rescue LoadError => err
      begin
        require 'sassc'
        Engine = ::SassC::Engine
      rescue LoadError
        begin
          require 'sass'
          Engine = ::Sass::Engine
        rescue LoadError
          raise err
        end
      end

      private

      def _prepare_output
        Engine.new(@data, sass_options).render
      end

      def sass_options
        @options[:filename] = eval_file
        @options[:line] = @line
        @options[:syntax] = :sass
        @options
      end
    # :nocov:
    end
  end

  class ScssTemplate < SassTemplate
    self.default_mime_type = 'text/css'

    private

    def sass_options
      opts = super
      opts[:syntax] = :scss
      opts
    end
  end
end
