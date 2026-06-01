# frozen_string_literal: true

# = RDiscount (<tt>markdown</tt>, <tt>md</tt>, <tt>mkd</tt>)
#
# Markdown is a lightweight markup language, created by John Gruber
# and Aaron Swartz. For any markup that is not covered by Markdown’s syntax, HTML
# is used.  Marking up plain text with Markdown markup is easy and Markdown
# formatted texts are readable.
#
# RDiscount is a simple text filter. It does not support +scope+ or
# +locals+. The +:smart+ and +:filter_html+ options may be set true
# to enable those flags on the underlying RDiscount object.
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
#  * {Markdown Syntax Documentation}[http://daringfireball.net/projects/markdown/syntax]
#  * [Discount][discount]
#  * {RDiscount}[http://github.com/rtomayko/rdiscount]
#
# -----------------------------------
#
# [Discount][discount] is an implementation of the Markdown markup language in C.
# [RDiscount][rdiscount] is a Ruby wrapper around Discount.
#
# All the documentation of {Markdown}[#markdown] applies in addition to the following:
#
# === Usage
#
# The <tt>Tilt::RDiscountTemplate</tt> class is registered for all files ending in
# <tt>.markdown</tt>, <tt>.md</tt> or <tt>.mkd</tt> by default with the highest priority. If you
# specifically want to use RDiscount, it's recommended to use <tt>#prefer</tt>:
#
#     Tilt.prefer Tilt::RDiscountTemplate
#
# __NOTE:__ It's suggested that your program <tt>require 'rdiscount'</tt> at load time when
# using this template engine within a threaded environment.

require_relative 'template'
require 'rdiscount'

aliases = {
  :escape_html => :filter_html,
  :smartypants => :smart
}.freeze

_flags = [:smart, :filter_html, :smartypants, :escape_html].freeze

Tilt::RDiscountTemplate = Tilt::StaticTemplate.subclass do
  flags = _flags.select { |flag| @options[flag] }.
    map! { |flag| aliases[flag] || flag }

  RDiscount.new(@data, *flags).to_html
end
