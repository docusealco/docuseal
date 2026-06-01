# # TrueType Fonts
#
# This example displays all glyphs of a TrueType font and shows that using a
# TrueType font with HexaPDF is very similar to using one of the standard PDF
# fonts.
#
# Before a TrueType font can be used, HexaPDF needs to be made aware of it. This
# is done by setting the configuration option 'font.map'. For one-off usage of a
# font file, the file name itself can also be used.
#
# Once that is done the [HexaPDF::Content::Canvas#font] method can be used as
# usual.
#
# Usage:
# : `ruby truetype.rb [FONT_FILE]`
#

require 'hexapdf'

doc = HexaPDF::Document.new
font_file = ARGV.shift || File.join(__dir__, '../test/data/fonts/Ubuntu-Title.ttf')
wrapper = doc.fonts.add(font_file)
max_gid = wrapper.wrapped_font[:maxp].num_glyphs

255.times do |page|
  break unless page * 256 < max_gid
  canvas = doc.pages.add.canvas
  canvas.font("Helvetica", size: 10)
  canvas.text("Font: #{wrapper.wrapped_font.full_name}", at: [50, 825])

  canvas.font(font_file, size: 15)
  16.times do |y|
    canvas.move_text_cursor(offset: [50, 800 - y * 50], absolute: true)
    canvas.show_glyphs((0..15).map do |i|
      gid = page * 256 + y * 16 + i
      glyph = wrapper.glyph(gid)
      gid >= max_gid ? [] : [glyph, -(2000 - glyph.width)]
    end.flatten!)
  end
end

doc.write("truetype.pdf", optimize: true)
