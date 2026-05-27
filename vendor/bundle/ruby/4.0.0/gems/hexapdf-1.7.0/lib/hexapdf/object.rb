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

require 'hexapdf/error'
require 'hexapdf/reference'

module HexaPDF

  # Internal value object for storing object number, generation number, object value and a
  # possible stream together. Such objects are not used directly but wrapped by Object or one of
  # its subclasses.
  class PDFData

    #:nodoc:
    attr_reader :oid, :gen

    #:nodoc:
    attr_accessor :stream, :value

    def initialize(value, oid = nil, gen = nil, stream = nil) #:nodoc:
      self.value = value
      self.oid = oid
      self.gen = gen
      self.stream = stream
    end

    def oid=(oid) #:nodoc:
      @oid = Integer(oid || 0)
    end

    def gen=(gen) #:nodoc
      @gen = Integer(gen || 0)
    end

  end

  # Objects of the PDF object system.
  #
  # == Overview
  #
  # A PDF object is like a normal object but with an additional *object identifier* consisting of
  # an object number and a generation number. If the object number is zero, then the PDF object
  # represents a direct object. Otherwise the object identifier uniquely identifies this object as
  # an indirect object and can be used for referencing it (from possibly multiple places).
  #
  # Furthermore a PDF object may have an associated stream. However, this stream is only
  # accessible if the subclass Stream is used.
  #
  # A PDF object *should* be connected to a PDF document, otherwise some methods may not work.
  #
  # Most PDF objects in a PDF document are represented by subclasses of this class that provide
  # additional functionality.
  #
  # The methods #hash and #eql? are implemented so that objects of this class can be used as hash
  # keys. Furthermore the implementation is compatible to the one of Reference, i.e. the hash of a
  # PDF Object is the same as the hash of its corresponding Reference object.
  #
  # == Allowed PDF Object Values
  #
  # The PDF specification knows of the following object types:
  #
  # * Boolean (mapped to +true+ and +false+),
  # * Integer (mapped to Integer object)
  # * Real (mapped to Float objects)
  # * String (mapped to String objects with UTF-8 or binary encoding)
  # * Names (mapped to Symbol objects)
  # * Array (mapped to Array objects)
  # * Dictionary (mapped to Hash objects)
  # * Stream (mapped to the Stream class which is a Dictionary with the associated stream data)
  # * Null (mapped to +nil+)
  # * Indirect Object (mapped to this class)
  #
  # So working with PDF objects in HexaPDF is rather straightforward since the common Ruby objects
  # can be used for most things, i.e. wrapping an plain Ruby object into an object of this class is
  # not necessary (except if it should become an indirect object).
  #
  # There are also some additional data structures built from these primitive ones. For example,
  # Time objects are represented as specially formatted string objects and conversion from and to
  # the string representation is handled automatically.
  #
  # *Important*: Users of HexaPDF may use other plain Ruby objects but then there is no guarantee
  # that everything will work correctly, especially when using other collection types than arrays
  # and hashes.
  #
  # See: HexaPDF::Dictionary, HexaPDF::Stream, HexaPDF::Reference, HexaPDF::Document
  #
  # See: PDF2.0 s7.3.10, s7.3.8
  class Object

    include Comparable

    # :call-seq:
    #   HexaPDF::Object.deep_copy(object)    -> copy
    #
    # Creates a deep copy of the given object which retains the references to indirect objects.
    def self.deep_copy(object)
      case object
      when Hash
        object.transform_values {|value| deep_copy(value) }
      when Array
        object.map {|o| deep_copy(o) }
      when HexaPDF::Object
        (object.indirect? || object.must_be_indirect? ? object : deep_copy(object.value))
      when HexaPDF::Reference
        object
      else
        object.dup
      end
    end

    # Makes sure that the object itself as well as all nested values are direct objects.
    #
    # The +document+ argument needs to contain the Document instance to which +object+ belongs so
    # that references can be correctly resolved.
    #
    # If an indirect object is found, it is turned into a direct object and the indirect object is
    # deleted from the document.
    def self.make_direct(object, document)
      if object.kind_of?(HexaPDF::Object) && object.indirect?
        raise HexaPDF::Error, "Can't make a stream object a direct object" if object.data.stream
        object_to_delete = object
        object = object.value
        object_to_delete.document.delete(object_to_delete)
      end
      case object
      when HexaPDF::Object
        object.data.value = make_direct(object.data.value, document)
      when Hash
        object.transform_values! {|val| make_direct(val, document) }
      when Array
        object.map! {|val| make_direct(val, document) }
      when Reference
        object = make_direct(document.object(object), document)
      end
      object
    end

    # Returns +nil+ to end the recursion for field searching in Dictionary.field.
    def self.field(_name)
      nil
    end

    # The wrapped HexaPDF::PDFData value.
    #
    # This attribute is not part of the public API!
    attr_reader :data

    # Sets the associated PDF document.
    attr_writer :document

    # Sets whether the object has to be an indirect object once it is written.
    attr_writer :must_be_indirect

    # Creates a new PDF object wrapping the value.
    #
    # The +value+ can either be a PDFData object in which case it is used directly. If it is a PDF
    # Object, then its data is used. Otherwise the +value+ object is used as is. In all cases, the
    # oid, gen and stream values may be overridden by the corresponding keyword arguments.
    def initialize(value, document: nil, oid: nil, gen: nil, stream: nil)
      @data = case value
              when PDFData then value
              when Object then value.data
              else PDFData.new(value)
              end
      @data.oid = oid if oid
      @data.gen = gen if gen
      @data.stream = stream if stream
      self.document = document
      self.must_be_indirect = false
      after_data_change
    end

    # Returns the object number of the PDF object.
    def oid
      data.oid
    end

    # Sets the object number of the PDF object.
    def oid=(oid)
      data.oid = oid
    end

    # Returns the generation number of the PDF object.
    def gen
      data.gen
    end

    # Sets the generation number of the PDF object.
    def gen=(gen)
      data.gen = gen
    end

    # Returns the object value.
    def value
      data.value
    end

    # Sets the object value. Unlike in #initialize the value is used as is!
    def value=(val)
      data.value = val
      after_data_change
    end

    # Returns the associated PDF document.
    #
    # If no document is associated, an error is raised.
    def document
      @document || raise(HexaPDF::Error, "No document associated with this object (#{inspect})")
    end

    # Returns +true+ if a PDF document is associated.
    def document?
      !@document.nil?
    end

    # Returns +true+ if the object is an indirect object (i.e. has an object number unequal to
    # zero).
    def indirect?
      oid != 0
    end

    # Returns +true+ if the object must be an indirect object once it is written.
    def must_be_indirect?
      @must_be_indirect
    end

    # Returns the type (symbol) of the object.
    #
    # Since the type system is implemented in such a way as to allow exchanging implementations of
    # specific types, the class of an object can't be reliably used for determining the actual
    # type.
    #
    # However, the Type and Subtype fields can easily be used for this. Subclasses for PDF objects
    # that don't have such fields may use a unique name that has to begin with XX (see PDF2.0 sE.2)
    # and therefore doesn't clash with names defined by the PDF specification.
    #
    # For basic objects this always returns +:Unknown+.
    def type
      :Unknown
    end

    # Returns +true+ if the object represents the PDF null object.
    def null?
      value.nil?
    end

    # :call-seq:
    #   obj.validate(auto_correct: true)                                    -> true or false
    #   obj.validate(auto_correct: true) {|msg, correctable, obj| block }   -> true or false
    #
    # Validates the object, optionally corrects problems when the option +auto_correct+ is set and
    # returns +true+ if the object is deemed valid and +false+ otherwise.
    #
    # If a block is given, it is called on validation problems with a problem description and
    # whether the problem is automatically correctable. The third argument to the block is usually
    # this object but may be another object if during auto-correction a new object was created and
    # validated.
    #
    # The validation routine itself has to be implemented in the #perform_validation method - see
    # its documentation for more information.
    #
    # *Note*: Even if the return value is +true+ there may be problems since HexaPDF doesn't
    # currently implement the full PDF spec. However, if the return value is +false+, there is
    # certainly a problem!
    def validate(auto_correct: true)
      result = true
      perform_validation do |msg, correctable, object|
        yield(msg, correctable, object || self) if block_given?
        result = false unless correctable
        return false unless auto_correct
      end
      result
    rescue HexaPDF::Error
      raise
    rescue StandardError => e
      yield("Unexpected error encountered: #{e.message}", false, self) if block_given?
      false
    end

    # Makes a deep copy of the source PDF object and resets the object identifier.
    #
    # Note that indirect references are *not* copied! If that is also needed, use Importer::copy.
    def deep_copy
      obj = dup
      obj.instance_variable_set(:@data, @data.dup)
      obj.data.oid = 0
      obj.data.gen = 0
      obj.data.stream = @data.stream.dup if @data.stream.kind_of?(String)
      obj.data.value = self.class.deep_copy(@data.value)
      obj
    end

    # Caches and returns the given +value+ or the value of the block under the given cache key. If
    # there is already a cached value for the key and +update+ is +false+, it is just returned.
    #
    # Set +update+ to +true+ to force an update of the cached value.
    #
    # This uses Document#cache internally.
    def cache(key, value = Document::UNSET, update: false, &block)
      document.cache(@data, key, value, update: update, &block)
    end

    # Returns +true+ if there is a cached value for the given key.
    #
    # This uses Document#cached? internally.
    def cached?(key)
      document.cached?(@data, key)
    end

    # Clears the cache for this object.
    def clear_cache
      document.clear_cache(@data)
    end

    # Compares this object to another object.
    #
    # If the other object does not respond to +oid+ or +gen+, +nil+ is returned. Otherwise objects
    # are ordered first by object number and then by generation number.
    def <=>(other)
      return nil unless other.respond_to?(:oid) && other.respond_to?(:gen)
      (oid == other.oid ? gen <=> other.gen : oid <=> other.oid)
    end

    # Returns +true+ in the following cases:
    #
    # * The other object is an Object and wraps the same #data structure.
    # * The other object is a Reference with the same oid/gen.
    # * This object is not indirect and the other object is not an Object and equal to the value of
    #   this object.
    def ==(other)
      (other.kind_of?(Object) && data == other.data) || (other.kind_of?(Reference) && other == self) ||
        (!indirect? && !other.kind_of?(Object) && other == data.value)
    end

    # Returns +true+ if the other object references the same PDF object as this object.
    def eql?(other)
      other.respond_to?(:oid) && oid == other.oid && other.respond_to?(:gen) && gen == other.gen
    end

    # Computes the hash value based on the object and generation numbers.
    def hash
      [oid, gen].hash
    end

    def inspect #:nodoc:
      "#<#{self.class.name} [#{oid}, #{gen}] value=#{value.inspect}>"
    end

    private

    # This method is called whenever the value or the stream of the wrapped PDFData structure is
    # changed.
    #
    # A subclass implementing this method has to call +super+! Otherwise things might not work
    # properly.
    def after_data_change
    end

    # Returns the configuration object of the PDF document.
    def config
      document.config
    end

    # Validates the basic object properties.
    #
    # == Implementation Hint for Subclasses
    #
    # A subclass needs to call the super method so that the validation routines of the superclasses
    # are also performed!
    #
    # When the validation routine finds that the object is invalid, it has to yield a problem
    # description and whether the problem can be corrected. An optional third argument may contain
    # the object that gets validated if it is different from this object (may happen when
    # auto-correction is used).
    #
    # After yielding, the problem has to be corrected if it is correctable. If it is not correctable
    # and not correcting would lead to exceptions the method has to return early.
    #
    # Here is a sample validation routine for a dictionary object type:
    #
    #   def perform_validation
    #     super
    #
    #     if value[:SomeKey].length != 7
    #       yield("Length of /SomeKey is invalid")
    #       # No need to return early here because following check doesn't rely on /SomeKey
    #     end
    #
    #     if value[:OtherKey] % 2 == 0
    #       yield("/OtherKey needs to contain an odd number of elements")
    #     end
    #   end
    def perform_validation
      # Validate that the object is indirect if #must_be_indirect? is +true+.
      if must_be_indirect? && !indirect?
        yield("Object must be an indirect object", true)
        document.add(self)
      end
    end

    # Validates all nested values of the object, i.e. values inside collection objects.
    def validate_nested(obj, &block)
      if obj.kind_of?(HexaPDF::Object) && !obj.indirect?
        obj.validate(&block)
      elsif obj.kind_of?(Hash)
        obj.each_value {|val| validate_nested(val, &block) }
      elsif obj.kind_of?(Array)
        obj.each {|val| validate_nested(val, &block) }
      end
    end

  end

end
