# # Composer
#
# This example shows how [HexaPDF::Composer] simplifies the creation of PDF
# documents by providing a high-level interface to the box layouting engine.
#
# Basic style properties can be set using the [HexaPDF::Composer#style] method
# and the style name `:base`. These properties are reused by every box and can
# be adjusted on a box-by-box basis. Newly defined styles also inherit the
# properties from the `:base` style.
#
# Various methods allow the easy creation of boxes, for example, text and image
# boxes. All these boxes are automatically drawn on the page. If the page has
# not enough room left for a box, the box is split across pages (which are
# automatically created) if possible or just drawn on the new page.
#
# Usage:
# : `ruby composer.rb`
#

require 'hexapdf'

lorem_ipsum = "Lorem ipsum dolor sit amet, con\u{00AD}sectetur
adipis\u{00AD}cing elit, sed do eiusmod tempor incidi\u{00AD}dunt ut labore et
dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exer\u{00AD}citation
ullamco laboris nisi ut aliquip ex ea commodo consequat. ".tr("\n", " ")

HexaPDF::Composer.create('composer.pdf') do |pdf|
  pdf.style(:base, line_spacing: 1.5, last_line_gap: true, text_align: :justify)
  pdf.style(:image, border: {width: 1}, padding: 5, margin: 10)
  pdf.style(:link, fill_color: "hp-blue-dark", underline: true)
  image = File.join(__dir__, 'machupicchu.jpg')

  pdf.text(lorem_ipsum * 2)
  pdf.image(image, style: :image, width: 200, position: :float)
  pdf.image(image, style: :image, width: 200, position: [200, 300])
  pdf.text(lorem_ipsum * 20, position: :flow)

  pdf.formatted_text(["Produced by ",
                      {link: "https://hexapdf.gettalong.org", text: "HexaPDF",
                       style: :link},
                      " via HexaPDF::Composer"],
                      font_size: 15, text_align: :center, padding: 15)
end
