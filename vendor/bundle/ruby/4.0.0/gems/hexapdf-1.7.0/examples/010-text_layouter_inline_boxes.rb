# # Text Layouter - Inline Boxes
#
# The [HexaPDF::Layout::TextLayouter] class can be used to easily lay out text
# mixed with inline boxes.
#
# It is not advised to use the `TextLayouter` class directly but instead via the
# [HexaPDF::Layout::TextBox] class and the general document layout
# functionality.
#
# Inline boxes are used for showing graphics that follow the flow of the text.
# This means that their horizontal and their general vertical position is
# determined by the text layout functionality. However, inline boxes may be
# vertically aligned to various positions, like the baseline, the top/bottom of
# the text and the top/bottom of the line.
#
# This example shows some text containing emoticons that are replaced with their
# graphical representation, with normal smileys being aligned to the baseline
# and winking smileys to the top of the line.
#
# An inline box is a simple wrapper around a generic box that adheres to the
# necessary interface. Therefore they don't do any drawing operations themselves
# but delegate to their wrapped box. This means, for example, that inline boxes
# can use background colors or borders without doing anything special.
#
# Usage:
# : `ruby text_layouter_inline_boxes.rb`
#

require 'hexapdf'

include HexaPDF::Layout

sample_text = "Lorem ipsum :-) dolor sit amet, consectetur adipiscing
;-) elit, sed do eiusmod tempor incididunt :-) ut labore et dolore magna
aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco
laboris nisi ut aliquip ex ea commodo consequat ;-). Duis aute irure
dolor in reprehenderit in voluptate velit esse cillum :-) dolore eu
fugiat nulla pariatur. ".tr("\n", ' ') * 4

doc = HexaPDF::Document.new
emoji_smile = doc.images.add(File.join(__dir__, "emoji-smile.png"))
emoji_wink = doc.images.add(File.join(__dir__, "emoji-wink.png"))
size = 10

items = sample_text.split(/(:-\)|;-\))/).map do |part|
  case part
  when ':-)'
    InlineBox.create(width: size * 2, height: size * 2, content_box: true,
                     background_color: "hp-blue-light", padding: 2) do |canvas, box|
      canvas.image(emoji_smile, at: [0, 0], width: box.content_width)
    end
  when ';-)'
    InlineBox.create(width: size, height: size, content_box: true,
                     valign: :top, padding: 5, margin: [0, 10],
                     border: {width: [1, 2], color: "hp-blue"}) do |canvas, box|
      canvas.image(emoji_wink, at: [0, 0], width: box.content_width)
    end
  else
    TextFragment.create(part, font: doc.fonts.add("Times"), font_size: 18)
  end
end

layouter = TextLayouter.new
layouter.style.text_align = :justify
layouter.style.line_spacing(:proportional, 1.5)
layouter.fit(items, 500, 700).draw(doc.pages.add.canvas, 50, 800)

doc.write("text_layouter_inline_boxes.pdf")
