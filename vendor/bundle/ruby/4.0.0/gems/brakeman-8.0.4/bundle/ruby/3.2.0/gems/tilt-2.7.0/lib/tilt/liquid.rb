# frozen_string_literal: true

# = Liquid (<tt>liquid</tt>)
#
# Liquid is designed to be a *safe* template system and therefore
# does not provide direct access to execuatable scopes. In order to
# support a +scope+, the +scope+ must be able to represent itself
# as a hash by responding to #to_h. If the +scope+ does not respond
# to #to_h it will be ignored.
#
# LiquidTemplate does not support yield blocks.
#
# === Example
#
#     <html>
#       <head>
#         <title>{{ title }}</title>
#       </head>
#       <body>
#         <h1>Hello {{ world }}!</h1>
#       </body>
#     </html>
#
# === Usage
#
# <tt>Tilt::LiquidTemplate</tt> is registered for all files ending in <tt>.liquid</tt> by
# default. Liquid templates support locals and objects that respond to
# <tt>#to_h</tt> as scopes:
#
#     >> require 'liquid'
#     >> require 'tilt'
#     >> template = Tilt.new('hello.liquid')
#     => #<Tilt::LiquidTemplate @file='hello.liquid'>
#     >> scope = { :title => "Hello Liquid Templates" }
#     >> template.render(nil, :world => "Liquid")
#     => "
#     <html>
#       <head>
#         <title>Hello Liquid Templates</title>
#       </head>
#       <body>
#         <h1>Hello Liquid!</h1>
#       </body>
#     </html>"
#
# Or, use <tt>Tilt::LiquidTemplate</tt> directly to process strings:
#
#     >> require 'liquid'
#     >> template = Tilt::LiquidTemplate.new { "<h1>Hello Liquid!</h1>" }
#     => #<Tilt::LiquidTemplate @file=nil ...>
#     >> template.render
#     => "<h1>Hello Liquid!</h1>"
#
# __NOTE:__ It's suggested that your program <tt>require 'liquid'</tt> at load
# time when using this template engine within a threaded environment.
#
# === See also
#
# * {Liquid}[http://liquidmarkup.org]
# * {Liquid for Programmers}[https://wiki.github.com/Shopify/liquid/liquid-for-programmers]
# * {Liquid Docs}[http://liquid.rubyforge.org/]
# * GitHub: {Shopify/liquid}[https://github.com/Shopify/liquid/]
#
# === Related module
#
# * Tilt::LiquidTemplate

require_relative 'template'
require 'liquid'

module Tilt
  class LiquidTemplate < Template
    def prepare
      @options[:line_numbers] = true unless @options.has_key?(:line_numbers)
      @engine = ::Liquid::Template.parse(@data, @options)
    end

    def evaluate(scope, locs)
      locals = {}
      if scope.respond_to?(:to_h)
        scope.to_h.each{|k, v| locals[k.to_s] = v}
      end
      locs.each{|k, v| locals[k.to_s] = v}
      locals['yield'] = block_given? ? yield : ''
      locals['content'] = locals['yield']
      @engine.render(locals)
    end

    def allows_script?
      false
    end
  end
end
