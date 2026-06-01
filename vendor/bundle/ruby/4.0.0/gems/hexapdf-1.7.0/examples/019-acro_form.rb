# # PDF Forms
#
# PDF files can be used for interactive forms, containing various types of form
# fields. HexaPDF supports the creation and processing of these forms.
#
# This example show-cases how to create the various form field types and their
# possible standard appearances.
#
# The [HexaPDF::Type::AcroForm::Form] and [HexaPDF::Type::AcroForm::Field]
# classes provide a plethora of convenience methods for working with forms, like
# for creating fields and their widgets, getting field properties like the full
# hierarchical field name or for setting the field value.
#
# Usage:
# : `ruby acro_form.rb`
#

require 'hexapdf'

doc = HexaPDF::Document.new
page = doc.pages.add
canvas = page.canvas

canvas.font("Helvetica", size: 36)
canvas.text("Form Example", at: [50, 750])
form = doc.acro_form(create: true)

canvas.font_size(16)
canvas.text("Check boxes", at: [50, 650])
[:check, :circle, :cross, :diamond, :square, :star].each_with_index do |symbol, index|
  cb = form.create_check_box("Checkbox #{index}")
  widget = cb.create_widget(page, Rect: [200 + 50 * index, 640, 240 + 50 * index, 680])
  widget.background_color(1 - 0.05 * index)
  widget.marker_style(style: symbol, color: [0.166 * index, 0, 1 - 0.166 * index],
                      size: 7 * index)
  cb.field_value = true
end

canvas.text("Radio buttons", at: [50, 550])
rb = form.create_radio_button("Radio")
[:check, :circle, :cross, :diamond, :square, :star].each_with_index do |symbol, index|
  widget = rb.create_widget(page, value: :"button#{index}",
                            Rect: [200 + 50 * index, 540, 240 + 50 * index, 580])
  widget.background_color(1 - 0.05 * index)
  widget.marker_style(style: symbol, color: [0.166 * index, 0, 1 - 0.166 * index],
                      size: 7 * index)
end
rb.field_value = :button0

canvas.text("Text fields", at: [50, 480])

canvas.text("Single line", at: [70, 450])
tx = form.create_text_field("Single Line", font_size: 16)
widget = tx.create_widget(page, Rect: [200, 445, 500, 465])
tx.field_value = "A sample test string!"

canvas.text("Multiline", at: [70, 420])
tx = form.create_multiline_text_field("Multiline", font_size: 0, align: :right)
widget = tx.create_widget(page, Rect: [200, 355, 500, 435])
widget.border_style(color: 0, width: 1)
tx.field_value = "A sample test string! " * 30 + "\nNew line\n\nAnother line"

canvas.text("Password", at: [70, 330])
tx = form.create_password_field("Password", font_size: 16)
widget = tx.create_widget(page, Rect: [200, 325, 500, 345])

canvas.text("File select", at: [70, 300])
tx = form.create_file_select_field("File Select", font_size: 16)
widget = tx.create_widget(page, Rect: [200, 295, 500, 315])
tx.field_value = "path/to/file.pdf"

canvas.text("Comb", at: [70, 270])
tx = form.create_comb_text_field("Comb field", max_chars: 10, font_size: 16, align: :center)
widget = tx.create_widget(page, Rect: [200, 250, 500, 285])
widget.border_style(color: [30, 128, 0], width: 1)
tx.field_value = 'Hello'

canvas.text("Combo Box", at: [50, 200])
cb = form.create_combo_box("Combo Box", font_size: 12, editable: true,
                           option_items: ['Value 1', 'Another value', 'Choose me!'])
widget = cb.create_widget(page, Rect: [200, 180, 500, 215])
widget.border_style(width: 1)
cb.field_value = 'Another value'

canvas.text("List Box", at: [50, 150])
lb = form.create_list_box("List Box", font_size: 15, align: :center, multi_select: true,
                         option_items: 1.upto(7).map {|i| "Value #{i}" })
widget = lb.create_widget(page, Rect: [200, 80, 500, 165])
widget.border_style(width: 1)
lb.list_box_top_index = 1
lb.field_value = ['Value 6', 'Value 2']

doc.write('acro_form.pdf', optimize: true)
