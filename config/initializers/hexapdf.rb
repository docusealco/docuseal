# frozen_string_literal: true

# fix NoMethodError: undefined method `field_value' for #<HexaPDF::Type::AcroForm::Field
module HexaPDF
  module Type
    module AcroForm
      class Field
        def field_value
          ''
        end
      end
    end
  end
end
