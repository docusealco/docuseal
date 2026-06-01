# # Column Box
#
# This example shows how [HexaPDF::Layout::ColumnBox] can be used to place
# contents into columns.
#
# Three boxes are placed repeatedly onto the frame until it is filled: two
# floating boxes (one left, one right) and a text box. The text box is styled to
# flow its content around the other two boxes.
#
# Usage:
# : `ruby column_box.rb`
#

require 'hexapdf'

doc = HexaPDF::Document.new
page = doc.pages.add
page_box = page.box
frame = HexaPDF::Layout::Frame.new(page_box.left + 20, page_box.bottom + 20,
                                   page_box.width - 40, page_box.height - 40)

polygon = Geom2D::Polygon([200, 350], [400, 350], [400, 450], [200, 450])
frame.remove_area(polygon)
page.canvas.draw(:geom2d, object: polygon)

columns = doc.layout.column(columns: 2, style: {position: :flow}) do |column|
  5.times do
    column.image(File.join(__dir__, 'machupicchu.jpg'), width: 100,
                 style: {margin: [10, 30], position: :float})
    column.box(:base, width: 50, height: 50,
               style: {margin: 20, position: :float, align: :right,
                       background_color: "hp-blue-light2",
                       border: {width: 1, color: "hp-blue-dark"}})
    column.lorem_ipsum(count: 2, position: :flow, text_align: :justify)
  end
end
result = frame.fit(columns)
frame.draw(page.canvas, result)

doc.write("column_box.pdf", optimize: true)
