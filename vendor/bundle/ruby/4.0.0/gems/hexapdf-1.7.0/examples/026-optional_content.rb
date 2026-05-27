# # Optional Content (a.k.a. Layers)
#
# This example shows how to create and assign optional content groups (OCGs) to
# parts of the content of a page.
#
# Four OCGs are created: Squares, Black, Blue, and Orange. The Squares one is
# applied to everything, the others to the respectively colored squares.
#
# When viewed in a compatible viewer, the "Optional Content" or "Layers" panel
# can be used to switch the layers on and off, resulting in the respective
# squares appearing or disappearing. Initially, the blue one is not shown, only
# the black and orange ones.
#
# Additionally, if supported by a viewer and if the visibility hasn't been
# manually changed, the OCGs for the squares are also configured to only be
# visible at certain zoom levels. For example, the black one is only visible up
# to a zoom level of 100%.
#
# Usage:
# : `ruby optional_content.rb`
#
require 'hexapdf'

doc = HexaPDF::Document.new

ocg = doc.optional_content.ocg('Squares')
ocg1 = doc.optional_content.ocg('Black')
ocg1.zoom(max: 1)
ocg1.add_to_ui(path: ocg)
ocg2 = doc.optional_content.ocg('Blue')
ocg2.zoom(min: 1, max: 2)
ocg2.add_to_ui(path: ocg)
ocg2.off!
ocg3 = doc.optional_content.ocg('Orange')
ocg3.zoom(min: 2, max: 20)
ocg3.add_to_ui(path: ocg)

canvas = doc.pages.add([0, 0, 200, 200]).canvas
canvas.optional_content(ocg) do
  canvas.optional_content(ocg1) do
    canvas.fill_color('black').rectangle(20, 80, 100, 100).fill
  end
  canvas.optional_content(ocg2) do
    canvas.fill_color('hp-blue').rectangle(50, 50, 100, 100).fill
  end
  canvas.optional_content(ocg3) do
    canvas.fill_color('hp-orange').rectangle(80, 20, 100, 100).fill
  end
end

doc.optional_content.default_configuration[:AS] = [
  {Event: :View, Category: [:Zoom], OCGs: [ocg1, ocg2, ocg3]}
]

doc.write('optional_content.pdf')
