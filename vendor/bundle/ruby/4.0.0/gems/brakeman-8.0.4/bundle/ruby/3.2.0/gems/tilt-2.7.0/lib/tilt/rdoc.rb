# frozen_string_literal: true

# = RDoc (<tt>rdoc</tt>)
#
# {RDoc}[http://rdoc.rubyforge.org] is the simple text markup system that comes with Ruby's standard
# library.
#
# === Example
#
#     = Hello RDoc Templates
#
#     Hello World. This is a paragraph.
#
# === Usage
#
# __NOTE:__ It's suggested that your program <tt>require 'rdoc'</tt>,
# <tt>require 'rdoc/markup'</tt>, and <tt>require 'rdoc/markup/to_html'</tt> at load time
# when using this template engine in a threaded environment.
#
# === See also
#
# * {RDoc}[http://rdoc.rubyforge.org]
# * {RDoc Github}[https://github.com/ruby/rdoc]

require_relative 'template'
require 'rdoc'
require 'rdoc/markup'
require 'rdoc/markup/to_html'
require 'rdoc/options'

Tilt::RDocTemplate = Tilt::StaticTemplate.subclass do
  RDoc::Markup::ToHtml.new(RDoc::Options.new, nil).convert(@data).to_s
end
