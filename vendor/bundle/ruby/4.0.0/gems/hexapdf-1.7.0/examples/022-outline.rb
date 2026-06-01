# # Document Outline (Bookmarks)
#
# This example shows how to add a document outline, also known as
# bookmarks, to a PDF document.
#
# Usage:
# : `ruby outline.rb`
#

require 'hexapdf'

doc = HexaPDF::Document.new
6.times do |i|
  doc.pages.add.canvas.
    font("Helvetica", size: 150).
    text("Page #{i + 1}", at: [10, 660])
end

doc.outline.add_item("Main") do |main|
  main.add_item("Page 1", destination: 0)
  main.add_item("Page 2", destination: 1)
  main.add_item("Sub", flags: [:bold], text_color: "red", open: false) do |sub|
    sub.add_item("Page 3", destination: {type: :fit_page_horizontal, page: doc.pages[2], top: 480})
    sub.add_item("Page 4", destination: 3)
  end
  main.add_item("Page 5", destination: 4)
end
doc.outline.add_item("Appendix") do |appendix|
  dest = doc.destinations.use_or_create(5)
  appendix.add_item("Page 6", action: {S: :GoTo, D: dest})
end

doc.catalog[:PageMode] = :UseOutlines
doc.write('outline.pdf', optimize: true)
