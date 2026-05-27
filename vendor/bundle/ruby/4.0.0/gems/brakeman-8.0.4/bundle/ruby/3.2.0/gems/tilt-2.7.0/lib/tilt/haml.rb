# frozen_string_literal: true

# = Haml (<tt>haml</tt>)
#
# {Haml}[https://haml.info] is a markup language that’s used to cleanly and simply describe
# the HTML of any web document without the use of inline code. Haml functions as
# a replacement for inline page templating systems such as PHP, ASP, and ERB, the
# templating language used in most Ruby on Rails applications. However, Haml
# avoids the need for explicitly coding HTML into the template, because it itself
# is a description of the HTML, with some code to generate dynamic content.
# ({more}[http://haml.info/about.html)]
#
# === Example
#
#     %html
#       %head
#         %title= @title
#       %body
#         %h1
#           Hello
#           = world + '!'
#
# === Usage
#
# The <tt>Tilt::HamlTemplate</tt> class is registered for all files ending in <tt>.haml</tt>
# by default. Haml templates support custom evaluation scopes and locals:
#
#     >> require 'haml'
#     >> template = Tilt.new('hello.haml')
#     => #<Tilt::HamlTemplate @file='hello.haml'>
#     >> @title = "Hello Haml!"
#     >> template.render(self, :world => 'Haml!')
#     => "
#     <html>
#       <head>
#         <title>Hello Haml!</title>
#       </head>
#       <body>
#         <h1>Hello Haml!</h1>
#       </body>
#     </html>"
#
# Or, use the <tt>Tilt::HamlTemplate</tt> class directly to process strings:
#
#     >> require 'haml'
#     >> template = Tilt::HamlTemplate.new { "%h1= 'Hello Haml!'" }
#     => #<Tilt::HamlTemplate @file=nil ...>
#     >> template.render
#     => "<h1>Hello Haml!</h1>"
#
# __NOTE:__ It's suggested that your program <tt>require 'haml'</tt> at load time when
# using this template engine within a threaded environment.
#
# === Options
#
# Please see the {Haml Reference}[http://haml.info/docs/yardoc/file.HAML_REFERENCE.html#options] for all available options.
#
# === See also
#
# * {#haml.docs}[http://haml.info/docs.html]
# * {Haml Tutorial}[http://haml.info/tutorial.html]
# * {Haml Reference}[http://haml.info/docs/yardoc/file.HAML_REFERENCE.html]
#
# === Related module
#
# * Tilt::HamlTemplate

require_relative 'template'
require 'haml'

module Tilt
  # Haml template implementation. See:
  # http://haml.hamptoncatlin.com/
  if defined?(Haml::Template) && Haml::Template < Tilt::Template
    # Haml >= 6 ships its own template, prefer it when available.
    HamlTemplate = Haml::Template
  else
    class HamlTemplate < Template
      self.default_mime_type = 'text/html'

      # <tt>Gem::Version.correct?</tt> may return false because of Haml::VERSION #=> "3.1.8 (Separated Sally)". After Haml 4, it's always correct.
      if Gem::Version.correct?(Haml::VERSION) && Gem::Version.new(Haml::VERSION) >= Gem::Version.new('5.0.0.beta.2')
        def prepare
          @options[:filename] = eval_file
          @options[:line] = @line
          if @options.include?(:outvar)
            @options[:buffer] = @options.delete(:outvar)
            @options[:save_buffer] = true
          end
          @engine = ::Haml::TempleEngine.new(@options)
          @engine.compile(@data)
        end

        def evaluate(scope, locals, &block)
          raise ArgumentError, 'invalid scope: must not be frozen' if scope.frozen?
          super
        end

        def precompiled_template(locals)
          @engine.precompiled_with_ambles(
            [],
            after_preamble: <<-RUBY
              __in_erb_template = true
              _haml_locals = locals
            RUBY
          )
        end
      else # Following definitions are for Haml <= 4 and deprecated.
        def prepare
          @options[:filename] = eval_file
          @options[:line] = @line
          @engine = ::Haml::Engine.new(@data, @options)
        end

        def evaluate(scope, locals, &block)
          raise ArgumentError, 'invalid scope: must not be frozen' if scope.frozen?

          if @engine.respond_to?(:precompiled_method_return_value, true)
            super
          else
            @engine.render(scope, locals, &block)
          end
        end

        # Precompiled Haml source. Taken from the precompiled_with_ambles
        # method in Haml::Precompiler:
        # http://github.com/nex3/haml/blob/master/lib/haml/precompiler.rb#L111-126
        def precompiled_template(locals)
          @engine.precompiled
        end

        def precompiled_preamble(locals)
          local_assigns = super
          @engine.instance_eval do
            <<-RUBY
              begin
                extend Haml::Helpers
                _hamlout = @haml_buffer = Haml::Buffer.new(haml_buffer, #{options_for_buffer.inspect})
                _erbout = _hamlout.buffer
                __in_erb_template = true
                _haml_locals = locals
                #{local_assigns}
            RUBY
          end
        end

        def precompiled_postamble(locals)
          @engine.instance_eval do
            <<-RUBY
                #{precompiled_method_return_value}
              ensure
                @haml_buffer = @haml_buffer.upper if haml_buffer
              end
            RUBY
          end
        end
      end
    end
  end
end
