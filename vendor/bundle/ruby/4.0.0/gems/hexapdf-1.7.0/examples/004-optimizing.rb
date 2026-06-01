# # Optimizing a PDF File
#
# This example shows how to read a PDF file, optimize it and write it
# out again.
#
# The heavy work is done by the `:optimize` task which allows control
# over which aspects should be optimized. See [HexaPDF::Task::Optimize]
# for detailed information.
#
# The hexapdf binary provides an optimization command which does some
# additional operations like optimizing the page tree.
#
# Usage:
# : `ruby optimizing.rb INPUT.PDF`
#

require 'hexapdf'

HexaPDF::Document.open(ARGV.shift) do |doc|
  doc.task(:optimize, compact: true, object_streams: :generate,
           compress_pages: false)
  doc.write('optimizing.pdf')
end
