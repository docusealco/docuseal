# # Graphics Primitives
#
# This example shows many of the operations that the canvas implementation
# allows.
#
# Note that the PDF canvas has its origin in the bottom left corner of the page.
# This means the coordinate (100, 50) is 100 PDF points from the left side and
# 50 PDF points from the bottom. One PDF point is equal to 1/72 inch.
#
# Usage:
# : `ruby graphics.rb`
#

require 'hexapdf'

doc = HexaPDF::Document.new
page = doc.pages.add
canvas = page.canvas

# Draws the shape that is used to showcase the transformations in the given
# color.
def transformation_shape(canvas, *color)
  canvas.stroke_color(*color)
  canvas.polygon(0, 0, 0, 80, 30, 50, 60, 80, 60, 0, 30, 30)
  canvas.line(-30, 0, 30, 0)
  canvas.line(0, 30, 0, -30)
  canvas.stroke
end

# Basic transformations: translate, scale, rotate, skew
canvas.translate(0, 710) do
  normal_color = "black"
  transformed_color = "hp-blue"

  canvas.translate(50, 0) do
    transformation_shape(canvas, normal_color)
    canvas.translate(40, 40) { transformation_shape(canvas, transformed_color) }
  end

  canvas.translate(180, 0) do
    transformation_shape(canvas, normal_color)
    canvas.scale(1.7, 1.3) { transformation_shape(canvas, transformed_color) }
  end

  canvas.translate(330, 0) do
    transformation_shape(canvas, normal_color)
    canvas.rotate(30) { transformation_shape(canvas, transformed_color) }
  end

  canvas.translate(430, 0) do
    transformation_shape(canvas, normal_color)
    canvas.skew(15, 30) { transformation_shape(canvas, transformed_color) }
  end
end

# Draws a thin white line over a thick black line.
def dual_lines(canvas)
  canvas.stroke_color(0)
  canvas.line_width = 15
  yield
  canvas.stroke
  canvas.stroke_color(1.0)
  canvas.line_width = 1
  yield
  canvas.stroke
end

# Graphics state: line width, line cap style, line join style, miter limit,
# line dash pattern
canvas.translate(0, 550) do
  canvas.translate(50, 0) do
    [1, 5, 10, 15].each_with_index do |i, index|
      canvas.stroke_color(0)
      canvas.line_width(i)
      canvas.line(20 * index, 0, 20 * index, 100)
      canvas.stroke
    end
  end

  canvas.translate(150, 0) do
    0.upto(2) do |i|
      canvas.line_cap_style = i
      dual_lines(canvas) { canvas.line(20 * i, 0, 20 * i, 100) }
    end
  end

  canvas.translate(230, 0) do
    0.upto(2) do |i|
      canvas.line_join_style = i
      dual_lines(canvas) { canvas.polyline(0, 30 * i, 40, 50 + 30 * i, 80, 30 * i) }
    end
  end

  canvas.translate(350, 0) do
    canvas.line_join_style = :miter
    canvas.miter_limit = 1
    dual_lines(canvas) { canvas.polyline(0, 0, 20, 80, 40, 0) }
    canvas.miter_limit = 10
    dual_lines(canvas) { canvas.polyline(60, 0, 80, 80, 100, 0) }
  end

  canvas.translate(490, 0) do
    canvas.line_width(1)
    [[[1, 1]],
     [[3, 1]],
     [[3, 3]],
     [[5, 1, 1, 1, 1, 1]],
     [[3, 5], 6]].each_with_index do |(value, phase), index|
      canvas.line_dash_pattern(value, phase || 0)
      canvas.line(20 * index, 0, 20 * index, 100)
      canvas.stroke
    end
  end
end

# Basic shapes: line, polyline, (rounded) rectangle, (rounded) polygon, circle, ellipse
canvas.translate(0, 420) do
  canvas.line(50, 0, 50, 100)
  canvas.polyline(80, 0, 80, 20, 70, 30, 90, 40, 70, 50, 90, 60, 70, 70, 80, 80, 80, 100)
  canvas.rectangle(110, 0, 50, 100)
  canvas.rectangle(180, 0, 50, 100, radius: 20)
  canvas.polygon(250, 0, 250, 100, 280, 70, 310, 100, 310, 0, 280, 30)
  canvas.polygon(330, 0, 330, 100, 360, 70, 390, 100, 390, 0, 360, 30, radius: 20)
  canvas.circle(440, 50, 30)
  canvas.ellipse(520, 50, a: 30, b: 15, inclination: 45)
  canvas.stroke
end

# Various arcs w/wo filling, using the Canvas#arc method as well as directly
# working with the arc objects
canvas.translate(0, 320) do
  canvas.arc(50, 50, a: 10, start_angle: -60, end_angle: 115)
  canvas.arc(100, 50, a: 40, b: 20, start_angle: -60, end_angle: 115)
  canvas.arc(180, 50, a: 40, b: 20, start_angle: -60, end_angle: 115, inclination: 45)
  canvas.stroke

  canvas.fill_color("hp-blue")
  canvas.arc(250, 50, a: 10, start_angle: -60, end_angle: 115)
  canvas.arc(300, 50, a: 40, b: 20, start_angle: -60, end_angle: 115)
  canvas.arc(380, 50, a: 40, b: 20, start_angle: -60, end_angle: 115, inclination: 45)
  canvas.fill

  arc = canvas.graphic_object(:arc, cx: 450, cy: 50, a: 30, b: 30,
                              start_angle: -30, end_angle: 105)
  canvas.fill_color("hp-blue")
  canvas.move_to(450, 50)
  canvas.line_to(*arc.start_point)
  arc.curves.each {|x, y, hash| canvas.curve_to(x, y, **hash)}
  canvas.fill
  arc.configure(start_angle: 105, end_angle: -30)
  canvas.fill_color("hp-orange")
  canvas.move_to(450, 50)
  canvas.line_to(*arc.start_point)
  arc.curves.each {|x, y, hash| canvas.curve_to(x, y, **hash)}
  canvas.fill

  arc = canvas.graphic_object(:arc, cx: 530, cy: 50, a: 40, b: 20,
                              start_angle: -30, end_angle: 105)
  canvas.fill_color("hp-blue")
  canvas.move_to(530, 50)
  canvas.line_to(*arc.start_point)
  arc.curves.each {|x, y, hash| canvas.curve_to(x, y, **hash)}
  canvas.fill
  arc.configure(start_angle: 105, end_angle: -30)
  canvas.fill_color("hp-orange")
  canvas.move_to(530, 50)
  canvas.line_to(*arc.start_point)
  arc.curves.each {|x, y, hash| canvas.curve_to(x, y, **hash)}
  canvas.fill
end

# Draws a circle and two half circles inside with different directions.
def shapes_to_paint(canvas)
  canvas.line_width = 2
  canvas.arc(50, 50, a: 50)
  canvas.arc(50, 60, a: 25, end_angle: 180, clockwise: false)
  canvas.arc(50, 40, a: 25, end_angle: 180, clockwise: true)
end

# Draws arrows showing the direction of the #shapes_to_paint
def arrows(canvas)
  canvas.line_width = 1
  canvas.polyline(95, 45, 100, 50, 105, 45)
  canvas.polyline(55, 105, 50, 100, 55, 95)
  canvas.polyline(-5, 55, 0, 50, 5, 55)
  canvas.polyline(45, 5, 50, 0, 45, -5)
  canvas.polyline(55, 90, 50, 85, 55, 80)
  canvas.polyline(55, 20, 50, 15, 55, 10)
  canvas.stroke
end

# Path painting and clipping operations: stroke, close and stroke, fill nonzero,
# fill even-odd, fill nonzero and stroke, fill even-odd and stroke, close and
# fill nonzero and stroke, close fill even-odd and stroke, clip even-odd, clip
# nonzero
canvas.translate(0, 190) do
  canvas.fill_color("hp-blue")

  [
    [:stroke], [:close_stroke], [:fill, :nonzero], [:fill, :even_odd],
    [:fill_stroke, :nonzero], [:fill_stroke, :even_odd],
    [:close_fill_stroke, :nonzero], [:close_fill_stroke, :even_odd]
  ].each_with_index do |op, index|
    row = (1 - (index / 4))
    column = index % 4
    x = 50 + 80 * column
    y = 80 * row
    canvas.transform(0.6, 0, 0, 0.6, x, y) do
      shapes_to_paint(canvas)
      canvas.send(*op)
      arrows(canvas)
    end
  end

  [:even_odd, :nonzero].each_with_index do |op, index|
    canvas.translate(370 + 110 * index, 20) do
      canvas.circle(50, 50, 50)
      canvas.circle(50, 50, 20)
      canvas.clip_path(op)
      canvas.end_path
      canvas.rectangle(0, 0, 100, 100, radius: 100)
      canvas.fill_stroke
    end
  end
end

# Some composite shapes, an image and a form XObject
canvas.translate(0, 80) do
  canvas.fill_color("hp-blue")
  canvas.rectangle(50, 0, 80, 80, radius: 80)
  canvas.fill

  solid = canvas.graphic_object(:solid_arc, cx: 190, cy: 40, inner_a: 20, inner_b: 15,
                                outer_a: 40, outer_b: 30, start_angle: 10, end_angle: 130)

  canvas.line_width(0.5)
  canvas.opacity(fill_alpha: 0.5, stroke_alpha: 0.2) do
    canvas.fill_color("hp-blue").draw(solid).fill_stroke
    canvas.fill_color("hp-orange").draw(solid, start_angle: 130, end_angle: 220).fill_stroke
    canvas.fill_color("hp-teal").draw(solid, start_angle: 220, end_angle: 10).fill_stroke

    solid.configure(inner_a: 0, inner_b: 0, outer_a: 40, outer_b: 40, cx: 290)
    canvas.fill_color("hp-blue").draw(solid, start_angle: 10, end_angle: 130).fill_stroke
    canvas.fill_color("hp-orange").draw(solid, start_angle: 130, end_angle: 220).fill_stroke
    canvas.fill_color("hp-teal").draw(solid, start_angle: 220, end_angle: 10).fill_stroke

    canvas.image(File.join(__dir__, 'machupicchu.jpg'), at: [350, 0], height: 80)
  end
end

# A simple rainbow color band
canvas.translate(0, 20) do
  canvas.line_width = 6
  freq = 0.1
  0.upto(100) do |i|
    r = Math.sin(freq * i) * 127 + 128
    g = Math.sin(freq * i + 2) * 127 + 128
    b = Math.sin(freq * i + 4) * 127 + 128
    canvas.stroke_color(r.to_i, g.to_i, b.to_i)
    canvas.line(50 + i * 5, 0, 50 + i * 5, 40)
    canvas.stroke
  end
end

# Reusing the already draw graphics for an XObject
# Note that converting the page to a form XObject automatically closes all open
# graphics states, therefore this can't be inside the above Canvas#translate
# call
form = doc.add(page.to_form_xobject(reference: false))
canvas.rectangle(480, 80, form.box.width * (100 / form.box.height.to_f), 100).stroke
canvas.xobject(form, at: [480, 80], height: 100)

doc.write('graphics.pdf', optimize: true)
