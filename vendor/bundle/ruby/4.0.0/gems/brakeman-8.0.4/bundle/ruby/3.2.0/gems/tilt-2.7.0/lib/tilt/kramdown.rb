# frozen_string_literal: true

# = Markdown (<tt>markdown</tt>, <tt>md</tt>, <tt>mkd</tt>)
#
# Markdown is a lightweight markup language, created by John Gruber
# and Aaron Swartz. For any markup that is not covered by Markdown’s syntax, HTML
# is used.  Marking up plain text with Markdown markup is easy and Markdown
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
# Every implementation of Markdown *should* support these options, but there are
# some known problems with the Kramdown engine.
#
# ==== <tt>:smartypants => true|false</tt>
#
# Set <tt>true</tt> to enable [Smarty Pants][smartypants] style punctuation replacement.
#
# In Kramdown this option only applies to smart quotes. It will apply a
# subset of Smarty Pants (e.g. <tt>...</tt> to <tt>…</tt>) regardless of any option.
#
# ==== <tt>:escape_html => true|false</tt>
#
# Kramdown doesn't support this option.
#
# === See also
#
# * {Markdown Syntax Documentation}[http://daringfireball.net/projects/markdown/syntax]
# * {Kramdown Markdown implementation}[https://kramdown.gettalong.org]

require_relative 'template'
require 'kramdown'

dumb_quotes = [39, 39, 34, 34].freeze

Tilt::KramdownTemplate = Tilt::StaticTemplate.subclass do
  # dup as Krawmdown modifies the passed option with map!
  @options[:smart_quotes] = dumb_quotes.dup unless @options[:smartypants]

  Kramdown::Document.new(@data, @options).to_html
end
