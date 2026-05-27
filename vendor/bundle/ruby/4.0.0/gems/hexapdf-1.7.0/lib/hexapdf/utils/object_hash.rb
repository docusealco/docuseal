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

module HexaPDF
  module Utils

    # There are some structures in a PDF file, for example cross reference tables, that index data
    # based on object and generation numbers. However, there is a restriction that in such
    # structures the object numbers must be unique, e.g. there may not be entries for [1, 0] and
    # \[1, 1] at the same time.
    #
    # This class can be used for storing/retrieving data for such structures.
    class ObjectHash

      include Enumerable

      # The biggest object number that is stored in the object hash or zero if no objects are
      # stored.
      attr_reader :max_oid

      # Creates a new object hash.
      def initialize
        @table = {}
        @oids = {}
        @max_oid = 0
      end

      # :call-seq:
      #   objhash[oid, gen] = data
      #
      # Sets the data for the given object and generation numbers.
      #
      # If there is already an entry for the given object number (even if the generation number is
      # different), this entry will be removed.
      def []=(oid, gen, data)
        @table[oid] = data
        @oids[oid] = gen
        @max_oid = oid if oid > @max_oid
      end

      # :call-seq:
      #   objhash[oid]        -> data or nil
      #   objhash[oid, gen]   -> data or nil
      #
      # Returns the data for the given object number, or for the given object and generation
      # numbers.
      #
      # If there is no such data, +nil+ is returned.
      def [](oid, gen = nil)
        (gen.nil? || gen_for_oid(oid) == gen || nil) && @table[oid]
      end

      # :call-seq:
      #   objhash.gen_for_oid(oid)    -> Integer or nil
      #
      # Returns the generation number that is stored along the given object number, or +nil+ if
      # the object number is not used.
      def gen_for_oid(oid)
        @oids[oid]
      end

      # :call-seq:
      #   objhash.entry?(oid)        -> true or false
      #   objhash.entry?(oid, gen)   -> true or false
      #
      # Returns +true+ if there is an entry for the given object number, or for the given object
      # and generation numbers.
      def entry?(oid, gen = nil)
        (gen ? gen_for_oid(oid) == gen : @oids.key?(oid))
      end

      # Deletes the entry for the given object number.
      def delete(oid)
        @table.delete(oid)
        @oids.delete(oid)
        @max_oid = oids.max || 0 if oid == @max_oid
      end

      # :call-seq:
      #   objhash.each {|oid, gen, data| block }   -> objhash
      #   objhash.each                             -> Enumerator
      #
      # Calls the given block once for every entry, passing an array consisting of the object and
      # generation number and the associated data as arguments.
      def each
        return to_enum(__method__) unless block_given?
        @oids.keys.each {|oid| yield(oid, @oids[oid], @table[oid]) if @table.key?(oid) }
        self
      end

      # Returns all used object numbers as an array.
      def oids
        @oids.keys
      end

    end

  end
end
