# frozen_string_literal: true
require 'haml'
require 'thor'

module Haml
  class CLI < Thor
    class_option :escape_html, type: :boolean, default: true
    class_option :escape_attrs, type: :boolean, default: true

    desc 'render HAML', 'Render haml template'
    option :load_path, type: :string, aliases: %w[-I]
    option :require, type: :string, aliases: %w[-r]
    def render(file)
      process_load_options
      code = generate_code(file)
      puts eval(code, binding, file)
    end

    desc 'compile HAML', 'Show compile result'
    option :actionview, type: :boolean, default: false, aliases: %w[-a]
    option :color, type: :boolean, default: true
    option :check, type: :boolean, default: false, aliases: %w[-c]
    def compile(file)
      code = generate_code(file)
      if options[:check]
        if error = validate_ruby(code, file)
          abort error.message.split("\n").first
        end
        puts "Syntax OK"
        return
      end
      puts_code(code, color: options[:color])
    end

    desc 'temple HAML', 'Show temple intermediate expression'
    option :color, type: :boolean, default: true
    def temple(file)
      pp_object(generate_temple(file), color: options[:color])
    end

    desc 'parse HAML', 'Show parse result'
    option :color, type: :boolean, default: true
    def parse(file)
      pp_object(generate_ast(file), color: options[:color])
    end

    desc 'version', 'Show the used haml version'
    def version
      puts Haml::VERSION
    end

    private

    def process_load_options
      if options[:load_path]
        options[:load_path].split(':').each do |dir|
          $LOAD_PATH.unshift(dir) unless $LOAD_PATH.include?(dir)
        end
      end

      if options[:require]
        require options[:require]
      end
    end

    def read_file(file)
      if file == '-'
        STDIN.read
      else
        File.read(file)
      end
    end

    def generate_code(file)
      template = read_file(file)
      if options[:actionview]
        require 'action_view'
        require 'action_view/base'
        require 'haml/rails_template'
        handler = Haml::RailsTemplate.new
        template = ActionView::Template.new(template, 'inline template', handler, { locals: [] })
        code = handler.call(template)
        <<-end_src
          def _inline_template___2144273726781623612_70327218547300(local_assigns, output_buffer)
            _old_virtual_path, @virtual_path = @virtual_path, nil;_old_output_buffer = @output_buffer;;#{code}
          ensure
            @virtual_path, @output_buffer = _old_virtual_path, _old_output_buffer
          end
        end_src
      else
        Haml::Engine.new(engine_options).call(template)
      end
    end

    def generate_ast(file)
      template = read_file(file)
      Haml::Parser.new(engine_options).call(template)
    end

    def generate_temple(file)
      ast = generate_ast(file)
      Haml::Compiler.new(engine_options).call(ast)
    end

    def engine_options
      Haml::Engine.options.to_h.merge(
        escape_attrs: options[:escape_attrs],
        escape_html:  options[:escape_html],
      )
    end

    # Flexible default_task, compatible with haml's CLI
    def method_missing(*args)
      return super(*args) if args.length > 1
      render(args.first.to_s)
    end

    def puts_code(code, color: true)
      begin
        require 'irb/color'
      rescue LoadError
        color = false
      end
      if color
        puts IRB::Color.colorize_code(code)
      else
        puts code
      end
    end

    # Enable colored pretty printing only for development environment.
    def pp_object(arg, color: true)
      begin
        require 'irb/color_printer'
      rescue LoadError
        color = false
      end
      if color
        IRB::ColorPrinter.pp(arg)
      else
        require 'pp'
        pp(arg)
      end
    end

    def validate_ruby(code, file)
      begin
        eval("BEGIN {return nil}; #{code}", binding, file)
      rescue ::SyntaxError # Not to be confused with Haml::SyntaxError
        $!
      end
    end
  end
end
