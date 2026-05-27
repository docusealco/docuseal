# -*- encoding: utf-8; frozen_string_literal: true -*-
#
#--
# This file is part of HexaPDF.
#
# HexaPDF - A Versatile PDF Creation and Manipulation Library For Ruby
# Copyright (C) 2014-2025 Thomas Leitner
#
# HexaPDF is free software: you can redistribute it and/or modify it
# under the terms of the GNU Affero General Public License version 3 as
# published by the Free Software Foundation with the addition of the
# following permission added to Section 15 as permitted in Section 7(a):
# FOR ANY PART OF THE COVERED WORK IN WHICH THE COPYRIGHT IS OWNED BY
# THOMAS LEITNER, THOMAS LEITNER DISCLAIMS THE WARRANTY OF NON
# INFRINGEMENT OF THIRD PARTY RIGHTS.
#
# HexaPDF is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public
# License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with HexaPDF. If not, see <http://www.gnu.org/licenses/>.
#
# The interactive user interfaces in modified source and object code
# versions of HexaPDF must display Appropriate Legal Notices, as required
# under Section 5 of the GNU Affero General Public License version 3.
#
# In accordance with Section 7(b) of the GNU Affero General Public
# License, a covered work must retain the producer line in every PDF that
# is created or manipulated using HexaPDF.
#
# If the GNU Affero General Public License doesn't fit your need,
# commercial licenses are available at <https://gettalong.at/hexapdf/>.
#++

require 'time'
require 'date'
require 'hexapdf/object'
require 'hexapdf/pdf_array'
require 'hexapdf/rectangle'
require 'hexapdf/configuration'
require 'hexapdf/utils/pdf_doc_encoding'

module HexaPDF

  # A mixin used by Dictionary that implements the infrastructure and classes for defining fields.
  #
  # The class responsible for holding the field information is the Field class. Additionally, each
  # field object is automatically assigned a stateless converter object that knows if data read
  # from a PDF file potentially needs to be converted into a standard format before use.
  #
  # The available converter objects can be retrieved or modified via the Field.converters method.
  #
  #
  # == Converter Objects
  #
  # The methods that need to be implemented by a stateless converter objects are the following:
  #
  # usable_for?(type)::
  #   Should return +true+ if the converter is usable for the given type.
  #
  # additional_types::
  #   Should return +nil+, a single type class or an array of type classes which will additionally
  #   be allowed for the field.
  #
  # convert(data, type, document)::
  #   Should return the +converted+ data if conversion is possible and +nil+ otherwise. The +type+
  #   argument is the result of the Field#type method call and +document+ is the HexaPDF::Document
  #   for which the data should be converted.
  #
  # Since a converter usually doesn't need to store any data, it can be implemented as a module
  # using class methods. This is how it is done for the built-in converter objects.
  module DictionaryFields

    # This constant should *always* be used for boolean fields.
    #
    # See: PDF2.0 s7.3.2
    Boolean = [TrueClass, FalseClass].freeze

    # PDFByteString is used for defining fields with strings in binary encoding.
    #
    # See: PDF2.0 s7.9.2.4
    PDFByteString = Class.new { private_class_method :new }

    # PDFDate is used for defining fields which store a date object as a string.
    #
    # See: PDF2.0 s7.9.4
    PDFDate = Class.new { private_class_method :new }

    # A field contains information about one field of a structured PDF object and this information
    # comes directly from the PDF specification.
    #
    # By incorporating this field information into HexaPDF it is possible to do many things
    # automatically, like checking for the correct minimum PDF version to use or converting a date
    # from its string representation to a Time object.
    class Field

      # Returns the list of available converter objects.
      #
      # See ::converter_for for information on how this list is used.
      def self.converters
        @converters ||= []
      end

      # Returns the converter for the given +type+ specification.
      #
      # The converter list from #converters is checked for a suitable converter from the front to
      # the back. So if two converters could potentially be used for the same type, the one that
      # appears earlier is used.
      def self.converter_for(type)
        @converters.find {|converter| converter.usable_for?(type) }
      end

      # Returns +true+ if the value for this field needs to be an indirect object, +false+ if it
      # needs to be a direct object or +nil+ if it can be either.
      attr_reader :indirect

      # Returns an array with the allowed values for this field, or +nil+ if the values are not
      # constrained.
      attr_reader :allowed_values

      # Returns the PDF version that is required for this field.
      attr_reader :version

      # Create a new Field object. See Dictionary::define_field for information on the arguments.
      #
      # Depending on the +type+ entry an appropriate field converter object is chosen from the
      # available converters.
      def initialize(type, required: false, default: nil, indirect: nil, allowed_values: nil,
                     version: nil)
        @type = [type].flatten
        @type_mapped = false
        @required, @default, @indirect, @version = required, default, indirect, version
        @allowed_values = allowed_values && [allowed_values].flatten
        @converters = @type.map {|t| self.class.converter_for(t) }.compact
      end

      # Returns the array with valid types for this field.
      def type
        return @type if @type_mapped
        @type.concat(@converters.flat_map(&:additional_types).compact)
        @type.map! do |type|
          if type.kind_of?(Symbol)
            HexaPDF::GlobalConfiguration.constantize('object.type_map', type)
          else
            type
          end
        end
        @type.uniq!
        @type_mapped = true
        @type
      end

      # Returns +true+ if this field is required.
      def required?
        @required
      end

      # Returns +true+ if a default value is available.
      def default?
        !@default.nil?
      end

      # Returns a duplicated default value.
      def default
        @default.dup
      end

      # Returns +true+ if the given object is valid for this field.
      def valid_object?(obj)
        type.any? {|t| obj.kind_of?(t) } ||
          (obj.kind_of?(HexaPDF::Object) && type.any? {|t| obj.value.kind_of?(t) })
      end

      # Converts the data into a useful object if possible. Otherwise returns +nil+.
      def convert(data, document)
        @converters.each do |converter|
          result = converter.convert(data, type, document)
          return result unless result.nil?
        end
        nil
      end

    end

    # Converter module for fields of type Dictionary and its subclasses.
    #
    # The first class in the type array of the field is used for the conversion. Symbol names for
    # classes may also be used since they are automatically resolved.
    module DictionaryConverter

      # This converter is used when either a Symbol is provided as +type+ (for lazy loading) or
      # when the type is a class derived from the Dictionary class.
      def self.usable_for?(type)
        type.kind_of?(Symbol) ||
          (type.respond_to?(:ancestors) && type.ancestors.include?(HexaPDF::Dictionary))
      end

      # Dictionary fields can also contain simple hashes.
      def self.additional_types
        Hash
      end

      # Wraps the given data value in the PDF specific type class if it can be converted. Otherwise
      # returns +nil+.
      def self.convert(data, type, document)
        return if data.kind_of?(type.first) ||
          !(data.kind_of?(Hash) || data.kind_of?(HexaPDF::Dictionary)) ||
          (type.first <= HexaPDF::Stream && (data.kind_of?(Hash) || data.data.stream.nil?))
        document.wrap(data, type: type.first)
      end

    end

    # Converter module for fields of type PDFArray.
    #
    # This converter ensures that arrays are wrapped by the PDFArray class for more convenient use.
    module ArrayConverter

      # This converter is usable if the +type+ is PDFArray.
      def self.usable_for?(type)
        type == PDFArray
      end

      # PDFArray fields can also contain simple arrays.
      def self.additional_types
        Array
      end

      # Wraps a given array in the PDFArray class. Otherwise returns +nil+.
      def self.convert(data, _type, document)
        return unless data.kind_of?(Array)
        document.wrap(data, type: PDFArray)
      end

    end

    # Converter module for string fields to automatically convert a string into UTF-8 encoding.
    #
    # See: PDF2.0 s7.9.2
    module StringConverter

      # This converter is usable if the +type+ is the String class.
      def self.usable_for?(type)
        type == String
      end

      # :nodoc:
      def self.additional_types
      end

      # Converts the string into UTF-8 encoding, assuming it is a binary string (i.e. one not yet
      # converted). Otherwise returns +nil+.
      def self.convert(str, _type, document)
        return unless str.kind_of?(String) && str.encoding == Encoding::BINARY

        if str.getbyte(0) == 254 && str.getbyte(1) == 255
          str = str[2..-1].force_encoding(Encoding::UTF_16BE)
          if str.valid_encoding?
            str.encode!(Encoding::UTF_8)
          else
            document.config['document.on_invalid_string'].call(str)
          end
        else
          Utils::PDFDocEncoding.convert_to_utf8(str)
        end
      end

    end

    # Converter module for binary string fields to automatically convert a string into binary
    # encoding.
    #
    # See: PDF2.0 s7.9.2.4
    module PDFByteStringConverter

      # This converter is usable if the +type+ is PDFByteString.
      def self.usable_for?(type)
        type == PDFByteString
      end

      # :nodoc:
      def self.additional_types
        String
      end

      # Converts the string into binary encoding, assuming it is a non-binary string. Otherwise
      # returns +nil+.
      def self.convert(str, _type, _document)
        return if !str.kind_of?(String) || str.encoding == Encoding::BINARY
        str.dup.force_encoding(Encoding::BINARY)
      end

    end

    # Converter module for handling PDF date fields since they are stored as strings.
    #
    # The ISO PDF specification differs from Adobe's specification in respect to the supported
    # date format. When converting from a date string to a Time object, this is taken into
    # account.
    #
    # See: PDF2.0 s7.9.4, ADB1.7 3.8.3
    module DateConverter

      # This converter is usable if the +type+ is PDFDate.
      def self.usable_for?(type)
        type == PDFDate
      end

      # A date field may contain a string in PDF format, or a Time, Date or DateTime object.
      def self.additional_types
        [String, Time, Date, DateTime]
      end

      DATE_RE = /\AD:(\d{4})(\d\d)?(\d\d)?(\d\d)?(\d\d)?(\d\d)?([Z+-])?(?:(\d+)(?:'|'(\d+)'?'?|\z)?)?\z/n # :nodoc:

      # Checks if the given object is a string and converts into a Time object if possible.
      # Otherwise returns +nil+.
      #
      # This method takes some forms of mangled date strings into account that were found in the wild.
      def self.convert(str, _type, _document)
        return unless str.kind_of?(String) && (m = str.match(DATE_RE))

        utc_offset = if m[7].nil? || m[7] == 'Z'
                       0
                     else
                       (m[7] == '-' ? -1 : 1) * (m[8].to_i * 3600 + m[9].to_i * 60).clamp(0, 86399)
                     end
        begin
          Time.new(m[1].to_i, (m[2] ? m[2].to_i : 1), (m[3] ? m[3].to_i : 1),
                   m[4].to_i, m[5].to_i, m[6].to_i, utc_offset)
        rescue ArgumentError
          Time.new(m[1].to_i, m[2].to_i.clamp(1, 12), m[3].to_i.clamp(1, 31),
                   m[4].to_i.clamp(0, 23), m[5].to_i.clamp(0, 59), m[6].to_i.clamp(0, 59), utc_offset)
        end
      end

    end

    # Converter module for file specification fields. A file specification in string format is
    # converted to the corresponding file specification dictionary.
    #
    # See: PDF2.0 s7.11, HexaPDF::Type::FileSpecification
    module FileSpecificationConverter

      # This converter is only used for the :Filespec type.
      def self.usable_for?(type)
        type == :Filespec
      end

      # Filespecs can also be simple hashes or strings.
      def self.additional_types
        [Hash, String]
      end

      # Converts a string file specification or a hash into a full file specification. Otherwise
      # returns +nil+.
      def self.convert(data, type, document)
        return if data.kind_of?(type.first) ||
          !(data.kind_of?(Hash) || data.kind_of?(HexaPDF::Dictionary) || data.kind_of?(String))

        data = {F: data} if data.kind_of?(String)
        document.wrap(data, type: type.first)
      end

    end

    # Converter module for fields of type Rectangle.
    #
    # See: PDF2.0 s7.9.5
    module RectangleConverter

      # This converter is usable if the +type+ is Rectangle.
      def self.usable_for?(type)
        type == Rectangle
      end

      # Rectangle fields can also contain simple arrays.
      def self.additional_types
        Array
      end

      # Wraps a given array using the Rectangle class or as a Null value if the array is invalid.
      # Otherwise returns +nil+.
      def self.convert(data, _type, document)
        return unless data.kind_of?(Array) || data.kind_of?(HexaPDF::PDFArray)
        data.empty? ? document.wrap(nil) : document.wrap(data, type: Rectangle)
      end

    end

    # Converter module for fields of type Integer.
    module IntegerConverter

      # This converter is usable if the +type+ is Integer.
      def self.usable_for?(type)
        type == Integer
      end

      # :nodoc:
      def self.additional_types
      end

      # Converts a Float value into an Integer if the float is equal to its integer value. Otherwise
      # returns +nil+
      def self.convert(data, _type, _document)
        return unless data.kind_of?(Float) && data == data.to_i
        data.to_i
      end

    end

    Field.converters.replace([FileSpecificationConverter, DictionaryConverter, ArrayConverter,
                              StringConverter, PDFByteStringConverter, DateConverter,
                              RectangleConverter, IntegerConverter])

  end

end
