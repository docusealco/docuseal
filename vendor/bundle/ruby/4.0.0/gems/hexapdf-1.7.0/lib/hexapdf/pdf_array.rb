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

require 'hexapdf/object'

module HexaPDF

  # Implementation of the PDF array type.
  #
  # This is mainly done to provide automatic resolution of indirect object references when using the
  # #[] method. Therefore not all Array methods are implemented - use the #value directly if other
  # methods are needed.
  #
  # See: PDF2.0 s7.3.6
  class PDFArray < HexaPDF::Object

    include Enumerable

    # :call-seq:
    #   array[index]             -> obj or nil
    #   array[start, length]     -> new_array or nil
    #   array[range]             -> new_array or nil
    #
    # Returns the value at the given index, or a subarray using the given +start+ and +length+, or a
    # subarray specified by +range+.
    #
    # This method should be used instead of direct access to a value because it provides some
    # advantages:
    #
    # * References are automatically resolved.
    #
    # * Returns the native Ruby object for values with class HexaPDF::Object. However, all
    #   subclasses of HexaPDF::Object are returned as is (it makes no sense, for example, to return
    #   the hash that describes the Catalog instead of the Catalog object).
    #
    # Note: Hash or Array values will always be returned as-is, i.e. not wrapped with Dictionary or
    # PDFArray.
    def [](arg1, arg2 = nil)
      data = arg2 ? value[arg1, arg2] : value[arg1]
      return if data.nil?

      if arg2 || arg1.kind_of?(Range)
        index = (arg2 ? arg1 : arg1.begin)
        data.map! {|item| process_entry(item, index).tap { index += 1 } }
      else
        process_entry(data, arg1)
      end
    end

    # Stores the data under the given index in the array.
    #
    # If the current value for this index has the class HexaPDF::Object (and only this, no
    # subclasses) and the given data has not (including subclasses), the data is stored inside the
    # HexaPDF::Object.
    def []=(index, data)
      if value[index].instance_of?(HexaPDF::Object) && !data.kind_of?(HexaPDF::Object) &&
          !data.kind_of?(HexaPDF::Reference)
        value[index].value = data
      else
        value[index] = data
      end
    end

    # Returns the values at the given indices.
    #
    # See #[] for details
    def values_at(*indices)
      indices.map! {|index| self[index] }
    end

    # Append a value to the array.
    def <<(data)
      value << data
    end

    # Insert one or more values into the array at the given index.
    def insert(index, *objects)
      value.insert(index, *objects)
    end

    # Deletes the value at the given index.
    def delete_at(index)
      value.delete_at(index)
    end

    # Deletes all values from the PDFArray that are equal to the given object.
    #
    # Returns the last deleted item, or +nil+ if no matching item is found.
    def delete(object)
      value.delete(object)
    end

    # :call-seq:
    #   array.slice!(index)             -> obj or nil
    #   array.slice!(start, length)     -> new_array or nil
    #   array.slice!(range)             -> new_array or nil
    #
    # Deletes the element(s) given by an index (and optionally a length) or by a range, and returns
    # them or +nil+ if the index is out of range.
    def slice!(arg1, arg2 = nil)
      data = value.slice!(arg1, *arg2)
      if arg2 || arg1.kind_of?(Range)
        data.map! {|item| process_entry(item) }
      else
        process_entry(data)
      end
    end

    # :call-seq:
    #   array.reject! {|item| block }   -> array or nil
    #   array.reject!                   -> Enumerator
    #
    # Deletes all elements from the array for which the block returns +true+ and returns +self+. If
    # no changes were done, returns +nil+.
    def reject!
      return to_enum(__method__) unless block_given?
      value.reject! {|item| yield(process_entry(item)) } && self
    end

    # :call-seq:
    #   array.map! {|item| block }   -> array
    #   array.map!                   -> Enumerator
    #
    # Maps all elements from the array in-place to the respective return value of the block+ and
    # returns +self+.
    def map!
      return to_enum(__method__) unless block_given?
      value.map! {|item| yield(process_entry(item)) }
      self
    end

    # :call-seq:
    #   array.compact!   -> array or nil
    #
    # Removes all +nil+ elements from the array. Returns +self+ if any elements were removed, +nil+
    # otherwise.
    def compact!
      value.compact! && self
    end

    # :call-seq:
    #   array.index(obj)              -> int or nil
    #   array.index {|item| block }   -> int or nil
    #   array.index                   -> Enumerator
    #
    # Returns the index of the first object such that object is == to +obj+, or, if a block is
    # given, the index of the first object for which the block returns +true+.
    def index(*obj, &block)
      find_index(*obj, &block)
    end

    # Returns the number of elements in the array.
    def length
      value.length
    end
    alias size length

    # Returns +true+ if the array has no elements.
    def empty?
      value.empty?
    end

    # :call-seq:
    #   array.each {|value| block}    -> array
    #   array.each                    -> Enumerator
    #
    # Calls the given block once for every value of the array.
    #
    # Note that the yielded value is already preprocessed like in #[].
    def each
      return to_enum(__method__) unless block_given?
      value.each_index {|index| yield(self[index]) }
      self
    end

    # Returns an array containing the preprocessed values (like in #[]).
    def to_ary
      each.to_a
    end

    private

    # Ensures that the value is useful for a PDFArray.
    def after_data_change # :nodoc:
      super
      data.value ||= []
      unless value.kind_of?(Array)
        raise ArgumentError, "A PDF array object needs an array value, not a #{value.class}"
      end
    end

    # Processes the given array entry with index +index+.
    def process_entry(data, index = nil)
      if data.kind_of?(HexaPDF::Reference)
        data = document.deref(data)
        value[index] = data if index
      end
      if data.instance_of?(HexaPDF::Object) || (data.kind_of?(HexaPDF::Object) && data.value.nil?)
        data = data.value
      end
      data
    end

    def perform_validation(&block) # :nodoc:
      super
      each {|element| validate_nested(element, &block) }
    end

  end

end
