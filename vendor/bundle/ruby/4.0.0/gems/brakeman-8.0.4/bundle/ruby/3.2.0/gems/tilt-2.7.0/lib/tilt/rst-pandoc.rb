# frozen_string_literal: true

# = reStructuredText (<tt>rst</tt>)
#
# reStructuredText is a lightweight markup language originally developed by David Goodger,
# based on StructuredText and Setext. reStructuredText is primarily used for technical
# documentation in the Python programming language community, e.g. by the
# {Sphinx}[http://www.sphinx-doc.org/en/stable/rest.html] Python documentation generator.
#
# reStructuredText formatted texts are converted to HTML with {Pandoc}[http://pandoc.org/], which
# is an application written in Haskell, with a Ruby wrapper provided by the
# {pandoc-ruby}[https://github.com/alphabetum/pandoc-ruby] gem.
#
# === Example
#
#     Hello Rst Templates
#     ===================
#
#     Hello World. This is a paragraph.
#
# === See Also
#
# * {Pandoc}[http://pandoc.org/]
# * {pandoc-ruby}[https://github.com/alphabetum/pandoc-ruby]

require_relative 'template'
require_relative 'pandoc'

rst = {:f => "rst"}.freeze

Tilt::RstPandocTemplate = Tilt::StaticTemplate.subclass do
  PandocRuby.new(@data, rst).to_html.strip
end
