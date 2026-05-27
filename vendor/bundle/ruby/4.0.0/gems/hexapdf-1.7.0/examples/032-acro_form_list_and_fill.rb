# # PDF Forms - List and fill fields
#
# This example shows how to list the form fields of an interactive PDF form and
# how to fill out the form.
#
# The output file from the [PDF forms](acro_form.html) example can be used as
# input.
#
# One way to list and fill a PDF form is to use the [HexaPDF CLI with the 'form'
# command](/documentation/hexapdf.1.html#form). Here, however, we are doing it
# with the HexaPDF API.
#
# Usage:
# : `ruby acro_form_list_and_fill.rb [INPUT.PDF]`
#

require 'base64'
require 'hexapdf'

doc = HexaPDF::Document.open(ARGV[0] || 'acro_form.pdf')
exit unless doc.acro_form

puts "Listing all form fields:"
doc.acro_form.each_field do |field|
  puts "#{field.full_field_name} (#{field.concrete_field_type})"
end

# We are using this to generate some values for existing text fields. In the
# real world one would be getting the values from the user.
puts "\nFilling in the text fields with random values:"
values = {}
doc.acro_form.each_field do |field|
  next unless field.field_type == :Tx
  value = Base64.encode64(field.full_field_name).strip
  value = if field.key?(:MaxLen)
            value[0, field[:MaxLen]]
          else
            "Value #{field.field_type} #{value}"
          end
  values[field.full_field_name] = value
  puts "#{field.full_field_name}: #{value}"
end

# Now actually fill out the form the values
doc.acro_form.fill(values)

doc.write('acro_form_list_and_fill.pdf', optimize: true)
