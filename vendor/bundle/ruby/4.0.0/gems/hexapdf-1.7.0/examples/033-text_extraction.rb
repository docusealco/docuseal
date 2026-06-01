# # Text Extraction
#
# This example shows how to extract layouted text from a page.
#
# It uses the provided input PDF or creates a small sample PDF as input. Then it
# extracts the text for each page and creates new pages with the extracted text
# in a fixed-width font.
#
# Usage:
# : `ruby text_extraction.rb [INPUT.PDF]`
#

require 'hexapdf'

# Use the input PDF or create a sample PDF.
if ARGV.length > 0
  doc = HexaPDF::Document.open(ARGV[0])
else
  composer = HexaPDF::Composer.new do |pdf|
    pdf.lorem_ipsum(count: 3, padding: [0, 0, 20])
    pdf.lorem_ipsum(padding: [0, 50, 20], text_indent: 40)
    pdf.lorem_ipsum(count: 2)
  end
  doc = composer.document
end

# Extract the existing pages and add new ones with the extracted text
doc.pages.count.times do |index|
  text = doc.pages[index].extract_text
  doc.pages.add.canvas.font('/usr/share/fonts/truetype/freefont/FreeMono.ttf', size: 6).
    text(text, at: [10, 820])
end

doc.write('text_extraction.pdf', optimize: true)
