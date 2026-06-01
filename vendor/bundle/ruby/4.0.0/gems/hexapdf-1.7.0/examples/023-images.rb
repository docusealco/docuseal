# # Images
#
# This example shows how to embed images into a PDF document, directly on a
# page's canvas and through the high-level [HexaPDF::Composer].
#
# Usage:
# : `ruby images.rb`
#

require 'hexapdf'

file = File.join(__dir__, 'machupicchu.jpg')

doc = HexaPDF::Document.new
# Image only added to PDF once though used multiple times
canvas = doc.pages.add.canvas
canvas.image(file, at: [100, 500]) # auto-size based on image size
canvas.image(file, at: [100, 300], width: 100) # height based on w/h ratio
canvas.image(file, at: [300, 300], height: 100) # width based on w/h ratio
canvas.image(file, at: [100, 100], width: 300, height: 100)

HexaPDF::Composer.create('images.pdf') do |composer|
  composer.image(file) # fill current rectangular region
  composer.image(file, width: 100)  # height based on w/h ratio
  composer.image(file, height: 100) # width based on w/h ratio
  composer.image(file, width: 300, height: 100)

  # Add the page created above as second page
  composer.document.pages << composer.document.import(doc.pages[0])
end
