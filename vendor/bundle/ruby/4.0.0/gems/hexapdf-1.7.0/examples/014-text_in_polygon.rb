# # Text in Polygon
#
# While creating width specifications for the [HexaPDF::Layout::TextLayouter]
# class by hand is possible, the [HexaPDF::Layout::WidthFromPolygon] class
# provides an easier way by using polygons.
#
# Most of the times text is laid out within polygonal shapes, so direct support
# for these makes text layout in HexaPDF easier.
#
# This example shows how much easier text layout is by re-doing the "house"
# example from the [Text Layouter - Shapes example](text_layouter_shapes.html).
# Additionally, there is an example using a complex polygon with a hole inside.
#
# Usage:
# : `ruby text_in_polygon.rb`
#

require 'hexapdf'
require 'geom2d'

include HexaPDF::Layout

doc = HexaPDF::Document.new
canvas = doc.pages.add.canvas

sample_text = "Lorem ipsum dolor sit amet, con\u{00AD}sectetur
adipis\u{00AD}cing elit, sed do eiusmod tempor incididunt ut labore et
dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation
ullamco laboris nisi ut aliquip ex ea commodo consequat.
".tr("\n", ' ') * 12
items = doc.layout.text_fragments(sample_text, font: doc.fonts.add("Times"))
layouter = TextLayouter.new
layouter.style.text_align = :justify

# The house example
house = Geom2D::Polygon([100, 200], [400, 200], [500, 100], [400, 100], [400, 0],
                        [300, 0], [300, 100], [200, 100], [200, 0], [100, 0],
                        [100, 100], [0, 100])
width_spec = WidthFromPolygon.new(house)
result = layouter.fit(items, width_spec, house.bbox.height)
result.draw(canvas, 50, 750)

# A more complex example
polygon = Geom2D::PolygonSet(
  Geom2D::Polygon([150, 450], [145, 198], [160, 196],
                  [200, 220], [200, 300], [300, 300], [400, 0],
                  [200, 0], [200, 100], [100, 100], [100, 0],
                  [-100, 0], [0, 300], [-50, 300], [100, 330]),
  Geom2D::Polygon([50, 120], [250, 120], [250, 180], [50, 180]),
  Geom2D::Polygon([60, 130], [240, 130], [240, 170], [60, 170])
)
width_spec = WidthFromPolygon.new(polygon)
result = layouter.fit(items, width_spec, polygon.bbox.height)
result.draw(canvas, 150, 550)
canvas.translate(150, 100).
  stroke_color("hp-blue-dark").
  line_width(0.5).
  draw(:geom2d, object: polygon)

doc.write("text_in_polygon.pdf", optimize: true)
