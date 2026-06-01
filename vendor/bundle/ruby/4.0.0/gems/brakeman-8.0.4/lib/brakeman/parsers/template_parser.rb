module Brakeman
  class TemplateParser
    include Brakeman::Util
    attr_reader :tracker
    KNOWN_TEMPLATE_EXTENSIONS = /.*\.(erb|haml|rhtml|slim)$/

    TemplateFile = Struct.new(:path, :ast, :name, :type)

    def initialize tracker, file_parser
      @tracker = tracker
      @file_parser = file_parser
      @slim_smart = nil # Load slim/smart ?
    end

    def parse_template path, text
      type = path.relative.match(KNOWN_TEMPLATE_EXTENSIONS)[1].to_sym
      type = :erb if type == :rhtml
      name = template_path_to_name path
      Brakeman.debug "Parsing #{path}"

      begin
        src = case type
              when :erb
                type = :erubi if erubi?
                parse_erb path, text
              when :haml
                type = :haml6 if haml6?
                parse_haml path, text
              when :slim
                parse_slim path, text
              else
                tracker.error "Unknown template type in #{path}"
                nil
              end

        if src and ast = @file_parser.parse_ruby(src, path)
          @file_parser.file_list << TemplateFile.new(path, ast, name, type)
        end
      rescue Racc::ParseError => e
        tracker.error e, "Could not parse #{path}"
      rescue StandardError, LoadError => e
        tracker.error e.exception(e.message + "\nWhile processing #{path}"), e.backtrace
      end

      nil
    end

    def parse_erb path, text
      if erubi?
        require 'brakeman/parsers/rails_erubi'
        Brakeman::Erubi.new(text, :filename => path).src
      else
        require 'erb'
        src = if ERB.instance_method(:initialize).parameters.assoc(:key) # Ruby 2.6+
          ERB.new(text, trim_mode: '-').src
        else
          ERB.new(text, nil, '-').src
        end
        src.sub!(/^#.*\n/, '')
        src
      end
    end

    def erubi?
      tracker.config.escape_html? or
        tracker.config.erubi?
    end

    def parse_haml path, text
      if haml6?
        require_relative 'haml6_embedded'

        Haml::Template.new(filename: path.relative,
                           :escape_html => tracker.config.escape_html?,
                           generator: Temple::Generators::RailsOutputBuffer,
                           use_html_safe: true,
                           buffer_class: 'ActionView::OutputBuffer',
                           disable_capture: true,
                          ) { text }.precompiled_template
      else
        require_relative 'haml_embedded'

        Haml::Engine.new(text,
                         :filename => path,
                         :escape_html => tracker.config.escape_html?,
                         :escape_filter_interpolations => tracker.config.escape_filter_interpolations?
                        ).precompiled.gsub(/([^\\])\\n/, '\1')
      end
    rescue Haml::Error => e
      tracker.error e, ["While compiling HAML in #{path}"] << e.backtrace
      nil
    end

    def haml6?
      return @haml6 unless @haml6.nil?

      Brakeman.load_brakeman_dependency 'haml'
      major_version = Haml::VERSION.split('.').first.to_i

      if major_version >= 6
        @haml6 = true
      else
        @haml6 = false
      end
    end

    def parse_slim path, text
      Brakeman.load_brakeman_dependency 'slim'

      if @slim_smart.nil? and load_slim_smart?
        @slim_smart = true
        Brakeman.load_brakeman_dependency 'slim/smart'
      else
        @slim_smart = false
      end

      require_relative 'slim_embedded'

      Slim::Template.new(path,
                         :disable_capture => true,
                         :generator => Temple::Generators::RailsOutputBuffer) { text }.precompiled_template
    end

    def load_slim_smart?
      return !@slim_smart unless @slim_smart.nil?

      # Terrible hack to find
      #   gem "slim", "~> 3.0.1", require: ["slim", "slim/smart"]
      if tracker.app_tree.exists? 'Gemfile'
        gemfile_contents = tracker.app_tree.file_path('Gemfile').read
        if gemfile_contents.include? 'slim/smart'
          return true
        end
      end

      false
    end

    def self.parse_inline_erb tracker, text
      fp = Brakeman::FileParser.new(tracker.app_tree, tracker.options[:parser_timeout])
      tp = self.new(tracker, fp)
      src = tp.parse_erb '_inline_', text
      type = tp.erubi? ? :erubi : :erb

      return type, fp.parse_ruby(src, "_inline_")
    end
  end
end
