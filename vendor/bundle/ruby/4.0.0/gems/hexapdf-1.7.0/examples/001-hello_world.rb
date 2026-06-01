# # Hello World
#
# This simple example mimics the classic "hello world" examples from
# programming languages.
#
# Usage:
# : `ruby hello_world.rb`
#

require 'hexapdf'

doc = HexaPDF::Document.new
canvas = doc.pages.add.canvas
canvas.font('Helvetica', size: 100)
canvas.text("Hello World!", at: [20, 400])
doc.write("hello_world.pdf", optimize: true)
