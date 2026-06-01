# frozen_string_literal: true
require 'haml/filters/base'
require 'haml/filters/text_base'
require 'haml/filters/tilt_base'
require 'haml/filters/coffee'
require 'haml/filters/css'
require 'haml/filters/erb'
require 'haml/filters/escaped'
require 'haml/filters/javascript'
require 'haml/filters/less'
require 'haml/filters/markdown'
require 'haml/filters/plain'
require 'haml/filters/preserve'
require 'haml/filters/ruby'
require 'haml/filters/sass'
require 'haml/filters/scss'
require 'haml/filters/cdata'

module Haml
  class Filters
    @registered = {}

    class << self
      attr_reader :registered

      def remove_filter(name)
        registered.delete(name.to_s.downcase.to_sym)
        if constants.map(&:to_s).include?(name.to_s)
          remove_const name.to_sym
        end
      end

      private

      def register(name, compiler)
        registered[name] = compiler
      end
    end

    register :coffee,       Coffee
    register :coffeescript, CoffeeScript
    register :css,          Css
    register :erb,          Erb
    register :escaped,      Escaped
    register :javascript,   Javascript
    register :less,         Less
    register :markdown,     Markdown
    register :plain,        Plain
    register :preserve,     Preserve
    register :ruby,         Ruby
    register :sass,         Sass
    register :scss,         Scss
    register :cdata,        Cdata

    def initialize(options = {})
      @options = options
      @compilers = {}
    end

    def compile(node)
      node.value[:text] ||= ''
      find_compiler(node).compile(node)
    end

    private

    def find_compiler(node)
      name = node.value[:name].to_sym
      compiler = Filters.registered[name]
      raise FilterNotFound.new("FilterCompiler for '#{name}' was not found", node.line.to_i - 1) unless compiler

      @compilers[name] ||= compiler.new(@options)
    end
  end
end
