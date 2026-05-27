# frozen_string_literal: true
require 'temple/static_analyzer'
require 'haml/ruby_expression'
require 'haml/string_splitter'

module Haml
  class Compiler
    class ScriptCompiler
      def self.find_and_preserve(input, tags)
        tags = tags.map { |tag| Regexp.escape(tag) }.join('|')
        re = /<(#{tags})([^>]*)>(.*?)(<\/\1>)/im
        input.to_s.gsub(re) do |s|
          s =~ re # Can't rely on $1, etc. existing since Rails' SafeBuffer#gsub is incompatible
          "<#{$1}#{$2}>#{Haml::Helpers.preserve($3)}</#{$1}>"
        end
      end

      def initialize(identity, options)
        @identity = identity
        @disable_capture = options[:disable_capture]
      end

      def compile(node, &block)
        unless Ripper.respond_to?(:lex) # No Ripper.lex in truffleruby
          return dynamic_compile(node, &block)
        end

        no_children = node.children.empty?
        case
        when no_children && node.value[:escape_interpolation]
          compile_interpolated_plain(node)
        when no_children && RubyExpression.string_literal?(node.value[:text])
          delegate_optimization(node)
        when no_children && Temple::StaticAnalyzer.static?(node.value[:text])
          static_compile(node)
        else
          dynamic_compile(node, &block)
        end
      end

      private

      # String-interpolated plain text must be compiled with this method
      # because we have to escape only interpolated values.
      def compile_interpolated_plain(node)
        temple = [:multi]
        StringSplitter.compile(node.value[:text]).each do |type, value|
          case type
          when :static
            temple << [:static, value]
          when :dynamic
            temple << [:escape, node.value[:escape_interpolation], [:dynamic, value]]
          end
        end
        temple << [:newline]
      end

      # :dynamic is optimized in other filter: StringSplitter
      def delegate_optimization(node)
        [:multi,
         [:escape, node.value[:escape_html], [:dynamic, node.value[:text]]],
         [:newline],
        ]
      end

      def static_compile(node)
        str = eval(node.value[:text]).to_s
        if node.value[:escape_html]
          str = Haml::Util.escape_html(str)
        elsif node.value[:preserve]
          str = ScriptCompiler.find_and_preserve(str, %w(textarea pre code))
        end
        [:multi, [:static, str], [:newline]]
      end

      def dynamic_compile(node, &block)
        var = @identity.generate
        temple = compile_script_assign(var, node, &block)
        temple << compile_script_result(var, node)
      end

      def compile_script_assign(var, node, &block)
        if node.children.empty?
          [:multi,
           [:code, "#{var} = (#{node.value[:text]}"],
           [:newline],
           [:code, ')'],
          ]
        else
          [:multi,
           [:block, "#{var} = #{node.value[:text]}",
            [:multi, [:newline], @disable_capture ? yield(node) : [:capture, Temple::Utils.unique_name, yield(node)]]
           ],
          ]
        end
      end

      def compile_script_result(result, node)
        if !node.value[:escape_html] && node.value[:preserve]
          result = find_and_preserve(result)
        end
        [:escapeany, node.value[:escape_html], [:dynamic, result]]
      end

      def find_and_preserve(code)
        %Q[::Haml::Compiler::ScriptCompiler.find_and_preserve(#{code}, %w(textarea pre code))]
      end

      def escape_html(temple)
        [:escape, true, temple]
      end
    end
  end
end
