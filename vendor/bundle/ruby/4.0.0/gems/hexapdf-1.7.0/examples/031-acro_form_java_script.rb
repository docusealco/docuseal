# # PDF Forms - JavaScript Actions
#
# Interactive PDF forms can contain JavaScript to enhance the form. For example,
# it is possible to use JavaScript to format numbers or to calculate a field
# value based on the value of other fields.
#
# While HexaPDF doesn't support all kinds of JavaScript actions, it supports
# select field format actions as well as the two most common calculate actions.
#
# Usage:
# : `ruby acro_form.rb`
#

require 'hexapdf'

doc = HexaPDF::Document.new
page = doc.pages.add
canvas = page.canvas

canvas.font("Helvetica", size: 36)
canvas.text("AcroForm JavaScript Actions ", at: [50, 750])
form = doc.acro_form(create: true)

canvas.font_size(16)

canvas.text("Value format actions", at: [50, 650])

canvas.text("Number format", at: [70, 620])
tx = form.create_text_field("Number_Format", font_size: 16)
tx.set_format_action(:number, decimals: 2, separator_style: :comma)
widget = tx.create_widget(page, Rect: [200, 615, 500, 635])
tx.field_value = "1234567.898"

canvas.text("Percent format", at: [70, 590])
tx = form.create_text_field("Percent_Format", font_size: 16)
tx.set_format_action(:percent, decimals: 2, separator_style: :comma)
widget = tx.create_widget(page, Rect: [200, 585, 500, 605])
tx.field_value = "12,45678"

canvas.text("Time format", at: [70, 560])
tx = form.create_text_field("Time_Format", font_size: 16)
tx.set_format_action(:time, format: :hh_mm_ss)
widget = tx.create_widget(page, Rect: [200, 555, 500, 575])
tx.field_value = "3:15:20 pm"

canvas.text("Calculate actions", at: [50, 510])

canvas.text("Source fields", at: [70, 480])
canvas.text("a:", at: [200, 480])
tx = form.create_text_field("a", font_size: 16)
tx.set_format_action(:number, decimals: 2)
widget = tx.create_widget(page, Rect: [220, 475, 280, 495])
tx.field_value = "10,50"
canvas.text("b:", at: [310, 480])
tx = form.create_text_field("b", font_size: 16)
tx.set_format_action(:number, decimals: 2)
widget = tx.create_widget(page, Rect: [330, 475, 390, 495])
tx.field_value = "20,60"
canvas.text("c:", at: [420, 480])
tx = form.create_text_field("c", font_size: 16)
tx.set_format_action(:number, decimals: 2)
widget = tx.create_widget(page, Rect: [440, 475, 500, 495])
tx.field_value = "30,70"

canvas.text("Predefined", at: [70, 450])
canvas.text("Sum", at: [90, 420])
tx = form.create_text_field("sum", font_size: 16)
tx.set_format_action(:number, decimals: 2)
tx.set_calculate_action(:sum, fields: ['a', 'b', 'c'])
tx.flag(:read_only)
widget = tx.create_widget(page, Rect: [310, 415, 500, 435])
canvas.text("Average", at: [90, 390])
tx = form.create_text_field("average", font_size: 16)
tx.set_format_action(:number, decimals: 2)
tx.set_calculate_action(:average, fields: ['a', 'b', 'c'])
tx.flag(:read_only)
widget = tx.create_widget(page, Rect: [310, 385, 500, 405])
canvas.text("Product", at: [90, 360])
tx = form.create_text_field("product", font_size: 16)
tx.set_format_action(:number, decimals: 2)
tx.set_calculate_action(:product, fields: ['a', 'b', 'c'])
tx.flag(:read_only)
widget = tx.create_widget(page, Rect: [310, 355, 500, 375])
canvas.text("Minimum", at: [90, 330])
tx = form.create_text_field("min", font_size: 16)
tx.set_format_action(:number, decimals: 2)
tx.set_calculate_action(:min, fields: ['a', 'b', 'c'])
tx.flag(:read_only)
widget = tx.create_widget(page, Rect: [310, 325, 500, 345])
canvas.text("Maximum", at: [90, 300])
tx = form.create_text_field("max", font_size: 16)
tx.set_format_action(:number, decimals: 2)
tx.set_calculate_action(:max, fields: ['a', 'b', 'c'])
tx.flag(:read_only)
widget = tx.create_widget(page, Rect: [310, 295, 500, 315])

canvas.text("Simplified Field Notation", at: [70, 270])
canvas.text("a + b + c", at: [90, 240])
tx = form.create_text_field("sfn1", font_size: 16)
tx.set_format_action(:number, decimals: 2)
tx.set_calculate_action(:sfn, fields: "a + b + c")
tx.flag(:read_only)
widget = tx.create_widget(page, Rect: [310, 235, 500, 255])
canvas.text("(a + b)*(c - a) / b + 3.14", at: [90, 210])
tx = form.create_text_field("sfn2", font_size: 16)
tx.set_format_action(:number, decimals: 2)
tx.set_calculate_action(:sfn, fields: "(a + b)*(c - a) / b + 3.14")
tx.flag(:read_only)
widget = tx.create_widget(page, Rect: [310, 205, 500, 225])

form.recalculate_fields

doc.write('acro_form_java_script.pdf', optimize: true)
