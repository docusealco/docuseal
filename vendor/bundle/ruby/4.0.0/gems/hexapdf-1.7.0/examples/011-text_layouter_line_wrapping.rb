# # Text Layouter - Line Wrapping
#
# The [HexaPDF::Layout::TextLayouter] class can be used to easily lay out text,
# automatically wrapping it appropriately.
#
# It is not advised to use the `TextLayouter` class directly but instead via the
# [HexaPDF::Layout::TextBox] class and the general document layout
# functionality.
#
# Text is broken only at certain characters:
#
# * The most important break points are **spaces**.
#
# * Lines can be broken at **tabulators** which represent eight spaces.
#
# * **Newline characters** are respected when wrapping and introduce a line
#   break. They have to be removed beforehand if this is not wanted. All Unicode
#   newline separators are recognized.
#
# * **Hyphens** are used as break points, possibly breaking just after them.
#
# * In addition to hyphens, **soft-hyphens** can be used to indicate break
#   points. In contrast to hyphens, soft-hyphens won't be visible unless a line
#   is broken at its position.
#
# * **Zero-width spaces** can be used to indicate break points at any position.
#
# * **Non-breaking spaces** can be used to prohibit a break between two words.
#   It has the same appearance as a space in the PDF.
#
# This example shows all these specially handled characters in action, e.g. a
# hard line break after "Fly-fishing", soft-hyphen in "wandering", tabulator
# instead of space after "wandering", zero-width space in "fantastic" and
# non-breaking spaces in "1 0 1".
#
# Usage:
# : `ruby text_layout_line_wrapping.rb`
#

require 'hexapdf'

doc = HexaPDF::Document.new
canvas = doc.pages.add([0, 0, 180, 230]).canvas
text = "Hello! Fly-fishing\nand wand\u{00AD}ering\taround - fanta\u{200B}stic" \
  " 1\u{00A0}0\u{00A0}1"

x = 10
y = 220
frag = doc.layout.text_fragments(text, font: doc.fonts.add("Times"))
layouter = HexaPDF::Layout::TextLayouter.new
[30, 60, 100, 160].each do |width|
  result = layouter.fit(frag, width, 400)
  result.draw(canvas, x, y)
  canvas.stroke_color("hp-blue-dark").line_width(0.2)
  canvas.rectangle(x, y, width, -result.height).stroke
  y -= result.height + 5
end

doc.write("text_layouter_line_wrapping.pdf", optimize: true)
