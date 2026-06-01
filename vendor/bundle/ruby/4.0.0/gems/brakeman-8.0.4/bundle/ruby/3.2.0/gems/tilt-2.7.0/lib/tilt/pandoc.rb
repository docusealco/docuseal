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
# * {Pandoc}[http://pandoc.org]

require_relative 'template'
require 'pandoc-ruby'

Tilt::PandocTemplate = Tilt::StaticTemplate.subclass do
  # turn options hash into an array
  # Map tilt options to pandoc options
  # Replace hash keys with value true with symbol for key
  # Remove hash keys with value false
  # Leave other hash keys untouched
  pandoc_options = []
  from = "markdown"
  smart_extension = "-smart"
  @options.each do |k,v|
    case k
    when :smartypants
      smart_extension = "+smart" if v
    when :escape_html
      from = "markdown-raw_html" if v
    when :commonmark
      from = "commonmark" if v
    when :markdown_strict
      from = "markdown_strict" if v
    else
      case v
      when true
        pandoc_options << k
      when false
        # do nothing
      else
        pandoc_options << { k => v }
      end
    end
  end
  pandoc_options << { :f => from + smart_extension }

  PandocRuby.new(@data, *pandoc_options).to_html.strip
end
