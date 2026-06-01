# # Boxes
#
# The [HexaPDF::Layout::Box] class is used as the basis for all document layout
# features.
#
# While it is possible to use boxes in this manual way, the preferred way is to
# use them through the [Composer class](composer.html).
#
# This example shows the basic properties that are available for all boxes, like
# paddings, borders and and background color. It is also possible to use the
# underlay and overlay callbacks with boxes.
#
# Usage:
# : `ruby boxes.rb`
#

require 'hexapdf'

doc = HexaPDF::Document.new

annotate_box = lambda do |canvas, box|
  text = ""
  canvas.font("Times", size: 6).leading(7)

  if (data = box.style.padding)
    text << "Padding (TRBL): #{data.top}, #{data.right}, #{data.bottom}, #{data.left}\n"
  end
  unless box.style.border.none?
    data = box.style.border.width
    text << "Border Width (TRBL): #{data.top}, #{data.right}, #{data.bottom}, #{data.left}\n"
    data = box.style.border.color
    text << "Border Color (TRBL):\n* #{data.top}\n* #{data.right}\n* #{data.bottom}\n* #{data.left}\n"
    data = box.style.border.style
    text << "Border Style (TRBL):\n* #{data.top}\n* #{data.right}\n* #{data.bottom}\n* #{data.left}\n"
  end

  canvas.line_width(0.1).rectangle(0, 0, box.content_width, box.content_height).stroke
  canvas.text(text, at: [0, box.content_height - 10])
end

canvas = doc.pages.add.canvas

[[1, "hp-blue-light"], [5, "hp-teal-light"],
 [15, "hp-orange-light"]].each_with_index do |(width, color), row|
  color = canvas.color_from_specification([color])
  [:solid, :dashed, :dashed_round, :dotted].each_with_index do |style, column|
    box = HexaPDF::Layout::Box.create(
      width: 100, height: 100, content_box: true,
      border: {width: width, style: style},
      background_color: color.components.map {|c| c + 0.2 * column },
      &annotate_box)
    box.draw(canvas, 20 + 140 * column, 700 - 150 * row)
  end
end

# The whole kitchen sink
box = HexaPDF::Layout::Box.create(
  width: 470, height: 200, content_box: true,
  padding: [20, 5, 10, 15],
  border: {width: [20, 40, 30, 15],
           color: ["hp-blue", "hp-orange", "hp-teal", "hp-blue-light"],
           style: [:solid, :dashed, :dashed_round, :dotted]},
  background_color: "hp-orange-light2",
  underlays: [
    lambda do |canv, _|
      canv.stroke_color([255, 0, 0]).line_width(10).line_cap_style(:butt).
        line(0, 0, box.width, box.height).line(0, box.height, box.width, 0).
        stroke
    end
  ],
  overlays: [
    lambda do |canv, _|
      canv.stroke_color("hp-blue-dark").line_width(5).
        rectangle(10, 10, box.width - 20, box.height - 20).stroke
    end
  ],
  &annotate_box)
box.draw(canvas, 20, 100)

doc.write("boxes.pdf", optimize: true)
