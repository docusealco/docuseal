# # Arcs and Solid Arcs
#
# This example shows how to use the graphic objects `:arc` and `:solid_arc` to
# draw simple pie charts.
#
# Usage:
# : `ruby arcs.rb`
#

require 'hexapdf'

doc = HexaPDF::Document.new
page = doc.pages.add
canvas = page.canvas

radius = 75

# Left pie chart
center = [page.box.width * 0.25, page.box.height * 0.85]
pie = canvas.graphic_object(:solid_arc, cx: center[0], cy: center[1],
                            outer_a: radius, outer_b: radius)
canvas.fill_color("hp-orange-light")
canvas.draw(pie, start_angle: 30, end_angle: 110).fill
canvas.fill_color("hp-teal-light")
canvas.draw(pie, start_angle: 110, end_angle: 130).fill
canvas.fill_color("hp-blue-light")
canvas.draw(pie, start_angle: 130, end_angle: 30).fill

arc = canvas.graphic_object(:arc, cx: center[0], cy: center[1],
                            a: radius, b: radius)
canvas.stroke_color("hp-orange")
canvas.draw(arc, start_angle: 30, end_angle: 110).stroke
canvas.stroke_color("hp-teal")
canvas.draw(arc, start_angle: 110, end_angle: 130).stroke
canvas.stroke_color("hp-blue-dark")
canvas.draw(arc, start_angle: 130, end_angle: 30).stroke

# Right pie chart
center = [page.box.width * 0.75, page.box.height * 0.85]
canvas.stroke_color('777777')
pie = canvas.graphic_object(:solid_arc, cx: center[0], cy: center[1],
                            outer_a: radius, outer_b: radius)
canvas.fill_color("hp-orange-light")
canvas.draw(pie, start_angle: 30, end_angle: 110).fill_stroke
canvas.fill_color("hp-teal-light")
canvas.draw(pie, start_angle: 110, end_angle: 130).fill_stroke
canvas.fill_color("hp-blue-light")
canvas.draw(pie, start_angle: 130, end_angle: 30).fill_stroke

doc.write('arcs.pdf', optimize: true)
