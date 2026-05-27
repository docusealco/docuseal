# # Frame - Text Flow
#
# This example shows how [HexaPDF::Layout::Frame] and [HexaPDF::Layout::TextBox]
# can be used to flow text around objects.
#
# While it is possible to use frames and boxes in this manual way, the preferred
# way is to use them through the [Composer class](composer.html).
#
# Three boxes are placed repeatedly onto the frame until it is filled: two
# floating boxes (one left, one right) and a text box. The text box is styled to
# flow its content around the other two boxes.
#
# Usage:
# : `ruby frame_text_flow.rb`
#

require 'hexapdf'
require 'hexapdf/utils/graphics_helpers'

include HexaPDF::Layout
include HexaPDF::Utils::GraphicsHelpers

doc = HexaPDF::Document.new

page = doc.pages.add
page_box = page.box
frame = Frame.new(page_box.left + 20, page_box.bottom + 20,
                  page_box.width - 40, page_box.height - 40)

boxes = []
boxes << doc.layout.image_box(File.join(__dir__, 'machupicchu.jpg'),
                              width: 100, margin: [10, 30], position: :float)
boxes << Box.create(width: 50, height: 50, margin: 20,
                    position: :float, align: :right,
                    background_color: "hp-blue-light2",
                    border: {width: 1, color: "hp-blue-dark"})
boxes << doc.layout.lorem_ipsum_box(count: 3, position: :flow, text_align: :justify)

i = 0
frame_filled = false
until frame_filled
  box = boxes[i]
  drawn = false
  until drawn || frame_filled
    result = frame.fit(box)
    if result.success?
      frame.draw(page.canvas, result)
      drawn = true
    else
      frame_filled = !frame.find_next_region
    end
  end
  i = (i + 1) % boxes.length
end

doc.write("frame_text_flow.pdf", optimize: true)
