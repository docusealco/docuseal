# # Text Layouter - Styling
#
# The text used as part of a [HexaPDF::Layout::TextLayouter] class can be styled
# using [HexaPDF::Layout::Style].
#
# It is not advised to use the `TextLayouter` class directly but instead via the
# [HexaPDF::Layout::TextBox] class and the general document layout
# functionality.
#
# To style [HexaPDF::Layout::TextFragment] objects, they have to be created with
# the needed styling and then added to a text layout object. In addition, the
# style objects can be used for customizing the text layouts themselves.
#
# This example shows how to do this and shows off the various styling option,
# including using callbacks to further customize the appearance.
#
# Usage:
# : `ruby text_layouter_styling.rb [FONT_FILE]`
#

require 'hexapdf'

include HexaPDF::Layout

sample_text = "Lorem ipsum dolor sit amet, consectetur adipiscing elit,
sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut
enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut
aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit
in voluptate velit esse cillum dolore eu fugiat nulla pariatur.".tr("\n", ' ')

# Wraps the text in a TextFragment using the given style.
def fragment(text, style)
  TextFragment.create(text, style)
end

# Draws the text at the given [x, y] position onto the canvas and returns the
# new y position.
def draw_text(result, canvas, x, y)
  raise "Error" unless result.remaining_items.empty?
  result.draw(canvas, x, y)
  y - result.height
end

doc = HexaPDF::Document.new
canvas = doc.pages.add.canvas

base_font = doc.fonts.add(ARGV[0] || "Times")
base_style = {font: base_font, font_size: 12, text_indent: 20}
styles = {
  "Fonts | Font Sizes | Colors" => [
    {font: doc.fonts.add("Times", variant: :italic),
     font_size: 12, fill_color: "hp-blue-light"},
    {font: doc.fonts.add("Courier"), font_size: 14,
     fill_color: "hp-orange"},
    {font: doc.fonts.add("Helvetica", variant: :bold),
     font_size: 20, fill_alpha: 0.5},
  ],
  "Character Spacing | Word Spacing | Horizontal Scaling" => [
    {**base_style, character_spacing: 3},
    {**base_style, horizontal_scaling: 150},
    {**base_style, word_spacing: 15},
  ],
  "Text Rise" => [
    {**base_style, text_rise: 5},
    {**base_style, text_rise: -3},
  ],
  "Subscript | Superscript" => [
    {**base_style, font_size: 15, subscript: true},
    {**base_style, font_size: 15, superscript: true},
  ],
  "Underline | Strikeout" => [
    {**base_style, underline: true, strikeout: true},
    {**base_style, underline: true, strikeout: true, text_rise: 5},
    {**base_style, underline: true, strikeout: true, subscript: true},
  ],
  "Text Rendering Mode" => [
    {**base_style, text_rendering_mode: :stroke,
     stroke_width: 0.1},
    {**base_style, font_size: 20, text_rendering_mode: :fill_stroke,
     stroke_color: "hp-orange-light", stroke_width: 0.7,
     stroke_dash_pattern: [0.5, 1, 1.5], stroke_cap_style: :round},
  ],
  "Underlays | Overlays" => [
    {**base_style, underlays: [lambda do |canv, box|
       canv.fill_color("hp-orange-light2").opacity(fill_alpha: 0.5).
         rectangle(0, 0, box.width, box.height).fill
      end]},
    {**base_style, overlays: [lambda do |canv, box|
       canv.line_width(1).stroke_color("hp-teal-light2").
         line(0, -box.y_min, box.width, box.y_max - box.y_min).stroke
      end]},
  ],
  "Links" => [
    {**base_style, overlays: [
      [:link, dest: [canvas.context, :FitR, 100, 300, 200, 400]],
    ]},
    {**base_style, overlays: [
      [:link, uri: "https://hexapdf.gettalong.org",
       border: [0, 0, 2, [3, 3]], border_color: "hp-blue"],
    ]},
    {**base_style, overlays: [
      [:link, file: "text_layouter_styling.pdf", border: true],
    ]},
  ],
}

y = 800
left = 50
width = 500
layouter = TextLayouter.new(base_style)
styles.each do |desc, variations|
  items = sample_text.split(/(Lorem ipsum dolor|\b\w{2,5}\b)/).map do |str|
    if str.length >= 3 && str.length <= 5
      fragment(str, variations[str.length % variations.length])
    elsif str.length == 2
      fragment(str, variations.first)
    elsif str =~ /Lorem/
      fragment(str, variations.last)
    else
      fragment(str, base_style)
    end
  end
  items.unshift(fragment(desc + ": ", fill_color: "hp-blue-dark", **base_style))
  y = draw_text(layouter.fit(items, width, 400), canvas, left, y) - 20
end

doc.write("text_layouter_styling.pdf", optimize: true)
