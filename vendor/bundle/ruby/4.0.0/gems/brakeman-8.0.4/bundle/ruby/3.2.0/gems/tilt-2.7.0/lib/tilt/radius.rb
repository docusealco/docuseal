# frozen_string_literal: true

# = Radius (<tt>radius</tt>)
#
# {Radius}[http://radius.rubyforge.org] is the template language used by {Radiant CMS}[http://radiantcms.org]. It is
# a tag language designed to be valid XML/HTML.
#
# === Example
#
#     <html>
#     <body>
#       <h1><r:title /></h1>
#       <ul class="<r:type />">
#       <r:repeat times="3">
#         <li><r:hello />!</li>
#       </r:repeat>
#       </ul>
#       <r:yield />
#     </body>
#     </html>
#
# === Usage
#
# To render a template such as the one above.
#
#     scope = OpenStruct.new
#     scope.title = "Radius Example"
#     scope.hello = "Hello, World!"
#
#     require 'radius'
#     template = Tilt::RadiusTemplate.new('example.radius', :tag_prefix=>'r')
#     template.render(scope, :type=>'hlist'){ "Jackpot!" }
#
# The result will be:
#
#     <html>
#     <body>
#       <h1>Radius Example</h1>
#       <ul class="hlist">
#         <li>Hello, World!</li>
#         <li>Hello, World!</li>
#         <li>Hello, World!</li>
#       </ul>
#       Jackpot!
#     </body>
#     </html>
#
# === See also
#
# * {Radius}[http://radius.rubyforge.org]
# * {Radiant CMS}[http://radiantcms.org]
#
# === Related module
#
# * Tilt::RadiusTemplate

require_relative 'template'
require 'radius'

module Tilt
  # Radius Template
  # http://github.com/jlong/radius/
  class RadiusTemplate < Template
    class ContextClass < Radius::Context
      attr_accessor :tilt_scope

      def tag_missing(name, attributes)
        tilt_scope.__send__(name)
      end

      def dup
        i = super
        i.tilt_scope = tilt_scope
        i
      end
    end

    def evaluate(scope, locals, &block)
      context = ContextClass.new
      context.tilt_scope = scope
      context.define_tag("yield", &block) if block
      locals.each do |tag, value|
        context.define_tag(tag) do
          value
        end
      end

      @options[:tag_prefix] = 'r' unless @options.has_key?(:tag_prefix)
      Radius::Parser.new(context, @options).parse(@data)
    end

    def allows_script?
      false
    end
  end
end
