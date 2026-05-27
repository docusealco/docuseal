# # Show Character Bounding Boxes
#
# This examples shows how to process the contents of a page. It finds all
# characters on a page and surrounds them with their bounding box. Additionally,
# all consecutive text runs are also surrounded by a box.
#
# The code provides two ways of generating the boxes. The commented part of
# `ShowTextProcessor#show_text` uses a polyline since some characters may be
# transforemd (rotated or skewed). The un-commented part uses rectangles which
# is faster and correct for most but not all cases.
#
# Usage:
# : `ruby show_char_boxes.rb INPUT.PDF`
#

require 'hexapdf'

class ShowTextProcessor < HexaPDF::Content::Processor

  def initialize(page)
    super()
    @canvas = page.canvas(type: :overlay)
  end

  def show_text(str)
    boxes = decode_text_with_positioning(str)
    return if boxes.string.empty?

    @canvas.line_width = 1
    @canvas.stroke_color(224, 0, 0)
    # Polyline for transformed characters
    #boxes.each {|box| @canvas.polyline(*box.points).close_subpath.stroke}
    # Using rectangles is faster but not 100% correct
    boxes.each do |box|
      x, y = *box.lower_left
      tx, ty = *box.upper_right
      @canvas.rectangle(x, y, tx - x, ty - y).stroke
    end

    @canvas.line_width = 0.5
    @canvas.stroke_color(0, 224, 0)
    @canvas.polyline(*boxes.lower_left, *boxes.lower_right,
                     *boxes.upper_right, *boxes.upper_left).close_subpath.stroke
  end
  alias :show_text_with_positioning :show_text

end

doc = HexaPDF::Document.open(ARGV.shift)
doc.pages.each_with_index do |page, index|
  puts "Processing page #{index + 1}"
  processor = ShowTextProcessor.new(page)
  page.process_contents(processor)
end
doc.write('show_char_boxes.pdf', optimize: true)
