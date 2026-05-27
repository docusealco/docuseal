# frozen_string_literal: true

# = Markdown (<tt>markdown</tt>, <tt>md</tt>, <tt>mkd</tt>)
#
# {Markdown}[http://daringfireball.net/projects/markdown/syntax] is a
# lightweight markup language, created by John Gruber and Aaron Swartz.
# For any markup that is not covered by Markdown’s syntax, HTML is used.
# Marking up plain text with Markdown markup is easy and Markdown
# formatted texts are readable.
#
# === Example
#
#     Hello Markdown Templates
#     ========================
#
#     Hello World. This is a paragraph.
#
# === Usage
#
# To wrap a Markdown formatted document with a layout:
#
#     layout = Tilt['erb'].new do
#       "<!doctype html><title></title><%= yield %>"
#     end
#     data = Tilt['md'].new { "# hello tilt" }
#     layout.render { data.render }
#     # => "<!doctype html><title></title><h1>hello tilt</h1>\n"
#
# === Options
#
# ==== <tt>:smartypants => true|false</tt>
#
# Set <tt>true</tt> to enable [Smarty Pants][smartypants] style punctuation replacement.
#
# ==== <tt>:escape_html => true|false</tt>
#
# Set <tt>true</tt> disallow raw HTML in Markdown contents. HTML is converted to
# literal text by escaping <tt><</tt> characters.
#
# === See also
#
# * {Markdown Syntax Documentation}[http://daringfireball.net/projects/markdown/syntax]

require_relative 'template'
require 'redcarpet'

aliases = {:escape_html => :filter_html, :smartypants => :smart}.freeze

Tilt::RedcarpetTemplate = Tilt::StaticTemplate.subclass do
  aliases.each do |opt, aka|
    if options.key?(aka) || !@options.key?(opt)
      @options[opt] = @options.delete(aka)
    end
  end

  # only raise an exception if someone is trying to enable :escape_html
  @options.delete(:escape_html) unless @options[:escape_html]

  renderer = @options.delete(:renderer) || ::Redcarpet::Render::HTML.new(@options)
  if options.delete(:smartypants) && !(renderer.is_a?(Class) && renderer <= ::Redcarpet::Render::SmartyPants)
    renderer = if renderer == ::Redcarpet::Render::XHTML
      ::Redcarpet::Render::SmartyHTML.new(:xhtml => true)
    elsif renderer == ::Redcarpet::Render::HTML
      ::Redcarpet::Render::SmartyHTML
    elsif renderer.is_a? Class
      Class.new(renderer) { include ::Redcarpet::Render::SmartyPants }
    else
      renderer.extend ::Redcarpet::Render::SmartyPants
    end
  end

  Redcarpet::Markdown.new(renderer, @options).render(@data)
end
