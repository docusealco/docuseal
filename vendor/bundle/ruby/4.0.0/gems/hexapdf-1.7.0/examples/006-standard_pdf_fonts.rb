# # Standard PDF Fonts
#
# This example shows all characters that are available in the standard 14 PDF
# fonts.
#
# The standard 14 PDF fonts are those fonts that all PDF reading/viewing
# applications need to support. They only provide a limited set of glyphs but
# have the advantage that they don't need to be embedded.
#
# Usage:
# : `ruby standard_pdf_fonts.rb`
#

require 'hexapdf'

def base_encoding_for_font(font)
  case font.font_name
  when 'Symbol', 'ZapfDingbats'
    font.encoding
  else
    HexaPDF::Font::Encoding.for_name(:WinAnsiEncoding)
  end
end

doc = HexaPDF::Document.new

HexaPDF::FontLoader::Standard14::MAPPING.each do |font_name, mapping|
  mapping.each_key do |variant|
    canvas = doc.pages.add.canvas
    canvas.font("Helvetica", size: 14)
    canvas.text("#{font_name} #{variant != :none ? variant : ''}", at: [100, 800])

    canvas.font(font_name, size: 14, variant: variant)
    canvas.leading = 20
    font = canvas.font
    encoding = base_encoding_for_font(font.wrapped_font)
    used_glyphs = []

    # Showing the glyphs of the WinAnsi or built-in encoding
    canvas.move_text_cursor(offset: [100, 750])
    (2..15).each do |y|
      data = []
      (0..15).each do |x|
        code = y * 16 + x
        glyph = font.glyph(encoding.name(code))
        glyph = font.glyph(:space) if glyph.id == font.wrapped_font.missing_glyph_id
        used_glyphs << glyph.name
        data << glyph << -(2000 - glyph.width)
      end
      canvas.show_glyphs(data)
      canvas.move_text_cursor
    end

    # Showing the remaining glyphs
    canvas.move_text_cursor(offset: [0, -40], absolute: false)
    glyphs = font.wrapped_font.metrics.character_metrics.keys.select do |k|
      Symbol === k
    end.sort - used_glyphs
    canvas.font(font_name, size: 14, variant: variant, custom_encoding: true)
    font = canvas.font
    glyphs.each_slice(16).with_index do |slice, index|
      data = []
      slice.each do |name|
        glyph = font.glyph(name)
        data << glyph << -(2000 - glyph.width)
      end
      canvas.show_glyphs(data)
      canvas.move_text_cursor
    end
  end
end

doc.write("standard_pdf_fonts.pdf", optimize: true)
