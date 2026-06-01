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
require 'hexapdf/object'
require 'hexapdf/stream'
require 'hexapdf/tokenizer'
require 'hexapdf/filter'
require 'hexapdf/utils/lru_cache'

module HexaPDF

  # Knows how to serialize Ruby objects for a PDF file.
  #
  # For normal serialization purposes, the #serialize or #serialize_to_io methods should be used.
  # However, if the type of the object to be serialized is known, a specialized serialization
  # method like #serialize_float can be used.
  #
  # Additionally, an object for encrypting strings and streams while serializing can be set via the
  # #encrypter= method. The assigned object has to respond to #encrypt_string(str, ind_obj) (where
  # the string is part of the indirect object; returns the encrypted string) and
  # #encrypt_stream(stream) (returns a fiber that represents the encrypted stream).
  #
  #
  # == How This Class Works
  #
  # The main public interface consists of the #serialize and #serialize_to_io methods which accept
  # an object and return its serialized form. During serialization of this object it is accessible
  # by individual serialization methods via the @object instance variable (useful if the object is a
  # composed object).
  #
  # Internally, the #__serialize method is used for invoking the correct serialization method
  # based on the class of a given object. It is also used for serializing individual parts of a
  # composed object.
  #
  # Therefore the serializer contains one serialization method for each class it needs to
  # serialize. The naming scheme of these methods is based on the class name: The full class name
  # is converted to lowercase, the namespace separator '::' is replaced with a single underscore
  # and the string "serialize_" is then prepended.
  #
  # Examples:
  #
  #   NilClass                 => serialize_nilclass
  #   TrueClass                => serialize_trueclass
  #   HexaPDF::Object          => serialize_hexapdf_object
  #
  # If no serialization method for a specific class is found, the ancestors classes are tried.
  #
  # See: PDF2.0 s7.3
  class Serializer

    # The encrypter to use for encrypting strings and streams. If +nil+, strings and streams are not
    # encrypted.
    #
    # Default: +nil+
    attr_accessor :encrypter

    # Creates a new Serializer object.
    def initialize
      @dispatcher = {
        Hash => 'serialize_hash',
        Array => 'serialize_array',
        Symbol => 'serialize_symbol',
        String => 'serialize_string',
        Integer => 'serialize_integer',
        Float => 'serialize_float',
        Time => 'serialize_time',
        TrueClass => 'serialize_trueclass',
        FalseClass => 'serialize_falseclass',
        NilClass => 'serialize_nilclass',
        HexaPDF::Reference => 'serialize_hexapdf_reference',
        HexaPDF::Object => 'serialize_hexapdf_object',
        HexaPDF::Stream => 'serialize_hexapdf_stream',
        HexaPDF::Dictionary => 'serialize_hexapdf_object',
        HexaPDF::PDFArray => 'serialize_hexapdf_object',
        HexaPDF::Rectangle => 'serialize_hexapdf_object',
      }
      @dispatcher.default_proc = lambda do |h, klass|
        h[klass] = if klass <= HexaPDF::Stream
                     "serialize_hexapdf_stream"
                   elsif klass <= HexaPDF::Object
                     "serialize_hexapdf_object"
                   else
                     method = nil
                     klass.ancestors.each do |ancestor_klass|
                       name = ancestor_klass.name.to_s.downcase
                       name.gsub!(/::/, '_')
                       method = "serialize_#{name}"
                       break if respond_to?(method, true)
                     end
                     method
                   end
      end
      @encrypter = false
      @io = nil
      @object = nil
      @in_object = false
    end

    # Returns the serialized form of the given object.
    #
    # For developers: While the object is serialized, methods can use the instance variable
    # @object to obtain information about or use the object in case it is a composed object.
    def serialize(obj)
      @object = obj
      __serialize(obj)
    ensure
      @object = nil
    end

    # Serializes the given object and writes it to the IO.
    #
    # Also see: #serialize
    def serialize_to_io(obj, io)
      @io = io
      @io << serialize(obj).freeze
    ensure
      @io = nil
    end

    # Raises an error to provide better failure messages.
    def serialize_basicobject(obj)
      object_message = if @object.kind_of?(HexaPDF::Object)
                         "#{obj} (part of #{@object.oid},#{@object.gen})"
                       else
                         obj.inspect
                       end
      raise HexaPDF::Error, "No serialization method for #{object_message}"
    end

    # Serializes the +nil+ value.
    #
    # See: PDF2.0 s7.3.9
    def serialize_nilclass(_obj)
      "null"
    end

    # Serializes the +true+ value.
    #
    # See: PDF2.0 s7.3.2
    def serialize_trueclass(_obj)
      "true"
    end

    # Serializes the +false+ value.
    #
    # See: PDF2.0 s7.3.2
    def serialize_falseclass(_obj)
      "false"
    end

    # Serializes a Numeric object (either Integer or Float).
    #
    # This method should be used for cases where it is known that the object is either an Integer
    # or a Float.
    #
    # See: PDF2.0 s7.3.3
    def serialize_numeric(obj)
      obj.kind_of?(Integer) ? obj.to_s : serialize_float(obj)
    end

    # Serializes an Integer object.
    #
    # See: PDF2.0 s7.3.3
    def serialize_integer(obj)
      obj.to_s
    end

    # Serializes a Float object.
    #
    # See: PDF2.0 s7.3.3
    def serialize_float(obj)
      if -0.0001 < obj && obj < 0.0001 && obj != 0
        sprintf("%.6f", obj)
      elsif obj.finite?
        obj.round(6).to_s
      else
        raise HexaPDF::Error, "Can't serialize special floating point number #{obj}"
      end
    end

    # The regexp matches all characters that need to be escaped and the substs hash contains the
    # mapping from these characters to their escaped form.
    #
    # See PDF2.0 s7.3.5
    NAME_SUBSTS = {} # :nodoc:
    [0..32, 127..255, Tokenizer::DELIMITER.bytes, Tokenizer::WHITESPACE.bytes, [35]].each do |a|
      a.each {|c| NAME_SUBSTS[c.chr] = "##{c.to_s(16).rjust(2, '0')}" }
    end
    NAME_REGEXP = /[^!-~&&[^##{Regexp.escape(Tokenizer::DELIMITER)}#{Regexp.escape(Tokenizer::WHITESPACE)}]]/ # :nodoc:
    NAME_CACHE = Utils::LRUCache.new(1000) # :nodoc:

    # Serializes a Symbol object (i.e. a PDF name object).
    #
    # See: PDF2.0 s7.3.5
    def serialize_symbol(obj)
      NAME_CACHE[obj] ||=
        begin
          str = obj.to_s.dup.force_encoding(Encoding::BINARY)
          str.gsub!(NAME_REGEXP, NAME_SUBSTS)
          str.empty? ? "/ " : "/#{str}"
        end
    end

    BYTE_IS_DELIMITER = {40 => true, 47 => true, 60 => true, 91 => true, # :nodoc:
                         41 => true, 62 => true, 93 => true}.freeze

    # Serializes an Array object.
    #
    # See: PDF2.0 s7.3.6
    def serialize_array(obj)
      str = +"["
      index = 0
      while index < obj.size
        tmp = __serialize(obj[index])
        str << " " unless BYTE_IS_DELIMITER[tmp.getbyte(0)] ||
          BYTE_IS_DELIMITER[str.getbyte(-1)]
        str << tmp
        index += 1
      end
      str << "]"
    end

    # Serializes a Hash object (i.e. a PDF dictionary object).
    #
    # See: PDF2.0 s7.3.7
    def serialize_hash(obj)
      str = +"<<"
      obj.each do |k, v|
        next if v.nil? || (v.respond_to?(:null?) && v.null?)
        str << serialize_symbol(k)
        tmp = __serialize(v)
        str << " " unless BYTE_IS_DELIMITER[tmp.getbyte(0)] ||
          BYTE_IS_DELIMITER[str.getbyte(-1)]
        str << tmp
      end
      str << ">>"
    end

    STRING_ESCAPE_MAP = {"(" => "\\(", ")" => "\\)", "\\" => "\\\\", "\r" => "\\r"}.freeze # :nodoc:

    # Serializes a String object.
    #
    # See: PDF2.0 s7.3.4
    def serialize_string(obj)
      if obj.encoding != Encoding::BINARY && obj.match?(/[^ -~\t\r\n]/)
        utf16_encoded = true
        obj = "\xFE\xFF".b << obj.encode(Encoding::UTF_16BE).force_encoding(Encoding::BINARY)
      end
      obj = if @encrypter && @object.kind_of?(HexaPDF::Object) && @object.indirect?
              encrypter.encrypt_string(obj, @object)
            elsif utf16_encoded
              obj
            else
              obj.b
            end
      obj.gsub!(/[()\\\r]/n, STRING_ESCAPE_MAP)
      "(#{obj})"
    end

    # The ISO PDF specification differs in respect to the supported date format. When converting
    # to a date string, a format suitable for both is output.
    #
    # See: PDF2.0 s7.9.4, ADB1.7 3.8.3
    def serialize_time(obj)
      zone = obj.strftime("%z'")
      if zone == "+0000'"
        zone = ''
      else
        zone[3, 0] = "'"
      end
      serialize_string(obj.strftime("D:%Y%m%d%H%M%S#{zone}"))
    end

    # See: #serialize_time
    def serialize_date(obj)
      serialize_time(obj.to_time)
    end

    # See: #serialize_time
    def serialize_datetime(obj)
      serialize_time(obj.to_time)
    end

    private

    # Uses #serialize_hexapdf_reference if it is an indirect object, otherwise just serializes
    # the objects value.
    def serialize_hexapdf_object(obj)
      if obj.indirect? && (obj != @object || @in_object)
        serialize_hexapdf_reference(obj)
      else
        @in_object ||= (obj == @object)
        str = __serialize(obj.value)
        @in_object = false if obj == @object
        str
      end
    end

    # See: PDF2.0 s7.3.10
    def serialize_hexapdf_reference(obj)
      "#{obj.oid} #{obj.gen} R"
    end

    # Serializes the streams dictionary and its stream.
    #
    # See: PDF2.0 s7.3.8
    def serialize_hexapdf_stream(obj)
      if !obj.indirect?
        raise HexaPDF::Error, "Can't serialize PDF stream without object identifier"
      elsif obj != @object || @in_object
        return serialize_hexapdf_reference(obj)
      end

      @in_object = true

      fiber = if @encrypter
                encrypter.encrypt_stream(obj)
              else
                obj.stream_encoder
              end

      if @io && fiber.respond_to?(:length) && fiber.length >= 0
        obj.value[:Length] = fiber.length
        @io << serialize_hash(obj.value)
        @io << "stream\n"
        while fiber.alive? && (data = fiber.resume)
          @io << data.freeze
        end
        @io << "\nendstream"
        @in_object = false

        nil
      else
        data = Filter.string_from_source(fiber)
        obj.value[:Length] = data.size

        str = serialize_hash(obj.value)
        @in_object = false

        str << "stream\n"
        str << data
        str << "\nendstream"
      end
    end

    # Invokes the correct serialization method for the object.
    def __serialize(obj)
      send(@dispatcher[obj.class], obj)
    end

  end

end
