# # Text Layouter - Shapes
#
# The [HexaPDF::Layout::TextLayouter] class can be used to easily lay out text,
# not limiting the area to a rectangle but any shape. There is only one
# restriction: In the case of arbitrary shapes the vertical alignment has to be
# "top".
#
# Note that using [HexaPDF::Layout::TextBox] is preferred over
# `TextLayouter`. However, it is currently not possible to flow text into
# arbitrary shapes with `TextBox`. So if this functionality is required, the
# `TextLayouter` class needs to be used directly.
#
# Arbitrary shapes boil down to varying line widths and horizontal offsets from
# left. Imagine a circle: If text is fit in a circle, the line widths start at
# zero, getting larger and larger until the middle of the cirle. And then they
# get smaller until zero again. The x-values of the left half circle determine
# the horizontal offsets.
#
# Both, the line widths and the horizontal offsets can be calculated given a
# certain height, and this is exactly what HexaPDF uses. If the `width` argument
# to [HexaPDF::Layout::TextLayouter#fit] is an object responding to #call (e.g.
# a lambda), it is used for determining the line widths and offsets.
#
# This example shows text layed out in various shapes, using the above mentioned
# techniques.
#
# Usage:
# : `ruby text_layouter_shapes.rb`
#

require 'hexapdf'

doc = HexaPDF::Document.new
page = doc.pages.add
canvas = page.canvas
canvas.font("Times", size: 10, variant: :bold)
canvas.stroke_color("hp-blue-dark").line_width(0.2)
font = doc.fonts.add("Times")

sample_text = "Lorem ipsum dolor sit amet, con\u{00AD}sectetur
adipis\u{00AD}cing elit, sed do eiusmod tempor incididunt ut labore et
dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation
ullamco laboris nisi ut aliquip ex ea commodo consequat.
".tr("\n", ' ') * 10

items = doc.layout.text_fragments(sample_text, font: font)
layouter = HexaPDF::Layout::TextLayouter.new

########################################################################
# Circly things on the top
radius = 100
circle_top = 840
half_circle_width = lambda do |height, line_height|
  sum = height + line_height
  if sum <= radius * 2
    [Math.sqrt(radius**2 - (radius - height)**2),
     Math.sqrt([radius**2 - (radius - sum)**2, 0].max)].min
  else
    0
  end
end
circle = lambda do |height, line_height|
  w = half_circle_width.call(height, line_height)
  [radius - w, 2 * w]
end
left_half_circle = lambda do |height, line_height|
  w = half_circle_width.call(height, line_height)
  [radius - w, w]
end

# Left: right half circle
result = layouter.fit(items, half_circle_width, radius * 2)
result.draw(canvas, 0, circle_top)
canvas.circle(0, circle_top - radius, radius).stroke

# Center: full circle
layouter.style.text_align = :justify
result = layouter.fit(items, circle, radius * 2)
result.draw(canvas, page.box.width / 2.0 - radius, circle_top)
canvas.circle(page.box.width / 2.0, circle_top - radius, radius).stroke

# Right: left half circle
layouter.style.text_align = :right
result = layouter.fit(items, left_half_circle, radius * 2)
result.draw(canvas, page.box.width - radius, circle_top)
canvas.circle(page.box.width, circle_top - radius, radius).stroke


########################################################################
# Pointy, diamondy things in the middle

diamond_width = 100
diamond_top = circle_top - 2 * radius - 10
half_diamond_width = lambda do |height, line_height|
  sum = height + line_height
  if sum < diamond_width
    height
  else
    [diamond_width * 2 - sum, 0].max
  end
end
full_diamond = lambda do |height, line_height|
  w = half_diamond_width.call(height, line_height)
  [diamond_width - w, 2 * w]
end
left_half_diamond = lambda do |height, line_height|
  w = half_diamond_width.call(height, line_height)
  [diamond_width - w, w]
end

# Left: right half diamond
layouter.style.text_align = :left
result = layouter.fit(items, half_diamond_width, 2 * diamond_width)
result.draw(canvas, 0, diamond_top)
canvas.polyline(0, diamond_top, diamond_width, diamond_top - diamond_width,
                0, diamond_top - 2 * diamond_width).stroke

# Center: full diamond
layouter.style.text_align = :justify
result = layouter.fit(items, full_diamond, 2 * diamond_width)
left = page.box.width / 2.0 - diamond_width
result.draw(canvas, left, diamond_top)
canvas.polyline(left + diamond_width, diamond_top,
                left + 2 * diamond_width, diamond_top - diamond_width,
                left + diamond_width, diamond_top - 2 * diamond_width,
                left, diamond_top - diamond_width).close_subpath.stroke

# Right: left half diamond
layouter.style.text_align = :right
result = layouter.fit(items, left_half_diamond, 2 * diamond_width)
middle = page.box.width
result.draw(canvas, middle - diamond_width, diamond_top)
canvas.polyline(middle, diamond_top,
                middle - diamond_width, diamond_top - diamond_width,
                middle, diamond_top - 2 * diamond_width).stroke


########################################################################
# Sine wave thing next

sine_wave_height = 200.0
sine_wave_top = diamond_top - 2 * diamond_width - 10
sine_wave = lambda do |height, line_height|
  offset = [40 * Math.sin(2 * Math::PI * (height / sine_wave_height)),
            40 * Math.sin(2 * Math::PI * (height + line_height) / sine_wave_height)].max
  [offset, sine_wave_height + 100 + offset * -2]
end
layouter.style.text_align = :justify
result = layouter.fit(items, sine_wave, sine_wave_height)
middle = page.box.width / 2.0
result.draw(canvas, middle - (sine_wave_height + 100) / 2, sine_wave_top)

########################################################################
# And finally a house

house_top = sine_wave_top - sine_wave_height - 10
outer_width = 300.0
inner_width = 100.0
house = lambda do |height, line_height|
  sum = height + line_height
  first_part = (outer_width / 2 - inner_width / 2)
  if (0..first_part).cover?(sum)
    [-height, outer_width + height * 2]
  elsif (first_part..(first_part + inner_width)).cover?(height) ||
      (first_part..(first_part + inner_width)).cover?(sum)
    [0, first_part, inner_width, first_part]
  elsif sum <= outer_width
    outer_width
  else
    0
  end
end
layouter.style.text_align = :justify
result = layouter.fit(items, house, 200)

middle = page.box.width / 2.0
result.draw(canvas, middle - (outer_width / 2), house_top)

doc.write("text_layouter_shapes.pdf", optimize: true)
