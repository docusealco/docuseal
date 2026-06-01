# # Table Box
#
# This example shows how [HexaPDF::Layout::TableBox] can be used to
# create tables.
#
# Usage:
# : `ruby table_box.rb`
#

require 'hexapdf'

image = File.join(__dir__, 'machupicchu.jpg')

HexaPDF::Composer.create("table_box.pdf") do |composer|
  # We start with the simplest table
  data = [['Hello', 'World'], ['How', 'are you?']]
  composer.table(data)

  # The width of the columns can be specified
  composer.table(data, column_widths: [100, 50])

  # Besides text a table cell can contain any other element
  l = composer.document.layout
  data = [['Text', 'Just simple text'],
          ['Image', l.image(image)],
          ['List', l.list {|list| list.text('Hello'); list.text('List')}],
          ['Columns', l.column {|c| c.lorem_ipsum(count: 4) }]]
  composer.table(data, column_widths: [50])

  # A table can be split if necessary
  composer.table([[l.lorem_ipsum(sentences: 1), l.lorem_ipsum(sentences: 1)],
                  [l.lorem_ipsum, l.lorem_ipsum]])

  # It is possible to specify headers and footers which all split parts
  # will have
  composer.column(height: 200) do |column|
    header = lambda {|table| [[l.text('Header left'), l.text('Header right')]] }
    footer = lambda {|table| [[l.text('Footer left'), l.text('Footer right')]] }
    column.table([[l.lorem_ipsum(sentences: 1), l.lorem_ipsum(sentences: 1)],
                  [l.lorem_ipsum(sentences: 1), l.lorem_ipsum(sentences: 1)],
                  [l.lorem_ipsum(sentences: 1), l.lorem_ipsum(sentences: 1)],
                  [l.lorem_ipsum(sentences: 1), l.lorem_ipsum(sentences: 1)]],
                 header: header, footer: footer)

  end
end
