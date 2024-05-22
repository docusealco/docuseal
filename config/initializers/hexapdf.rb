# frozen_string_literal: true

module HexaPDF
  module Encryption
    class SecurityHandler
      def encrypt_string(str, obj)
        return str.dup if str.empty? || obj == document.trailer[:Encrypt] || obj.type == :XRef ||
                          (obj.type == :Sig && obj[:Contents].equal?(str))

        key = object_key(obj.oid, obj.gen, string_algorithm)
        string_algorithm.encrypt(key, str).dup
      end
    end
  end

  module Type
    class Page
      # fix NoMethodError (undefined method `color_space' for an instance of HexaPDF::Type::Page)
      def color_space(name)
        GlobalConfiguration.constantize('color_space.map', name).new
      end
    end

    # fix NoMethodError: undefined method `field_value' for #<HexaPDF::Type::AcroForm::Field
    module AcroForm
      class Field
        def field_value
          ''
        end

        def terminal_field?
          kids = self[:Kids]

          # rubocop:disable Rails/Blank
          kids.nil? || kids.empty? || kids.none? { |kid| kid&.key?(:T) }
          # rubocop:enable Rails/Blank
        end
      end
    end

    # comparison of Integer with HexaPDF::PDFArray failed
    class CIDFont < Font
      private

      def widths
        cache(:widths) do
          result = {}
          index = 0
          array = self[:W] || []

          while index < array.size
            entry = array[index]
            value = array[index + 1]

            if value.is_a?(Array) || value.is_a?(HexaPDF::PDFArray)
              value.each_with_index { |width, i| result[entry + i] = width }
              index += 2
            else
              width = array[index + 2]
              entry.upto(value) { |cid| result[cid] = width }
              index += 3
            end
          end

          result
        end
      end
    end
  end
end
