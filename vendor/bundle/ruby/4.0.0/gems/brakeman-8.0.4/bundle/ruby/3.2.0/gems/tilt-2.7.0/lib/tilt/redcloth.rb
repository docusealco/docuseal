# frozen_string_literal: true

# = Textile (<tt>textile</tt>)
#
# Textile is a lightweight markup language originally developed by Dean Allen and
# billed as a "humane Web text generator". Textile converts its marked-up text
# input to valid, well-formed XHTML and also inserts character entity references
# for apostrophes, opening and closing single and double quotation marks,
# ellipses and em dashes.
#
# Textile formatted texts are converted to HTML with the {RedCloth}[http://redcloth.org]
# engine, which is a Ruby extension written in C.
#
# === Example
#
#     h1. Hello Textile Templates
#
#     Hello World. This is a paragraph.
#
# === Usage
#
# __NOTE:__ It's suggested that your program <tt>require 'redcloth'</tt> at load time
# when using this template engine in a threaded environment.
#
# === See Also
#
# * {RedCloth}[http://redcloth.org]
# * https://github.com/jgarber/redcloth

require_relative 'template'
require 'redcloth'

Tilt::RedClothTemplate = Tilt::StaticTemplate.subclass do
  engine = RedCloth.new(@data)
  @options.each  do |k, v|
    m = :"#{k}="
    engine.send(m, v) if engine.respond_to? m
  end
  engine.to_html
end
