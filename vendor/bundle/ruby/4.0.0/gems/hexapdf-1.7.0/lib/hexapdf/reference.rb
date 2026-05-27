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

module HexaPDF

  # A reference to an indirect object.
  #
  # The PDF syntax allows for references to existing and non-existing indirect objects. Such
  # references are represented with objects of this class.
  #
  # Note that after initialization changing the object or generation numbers is not possible
  # anymore!
  #
  # The methods #hash and #eql? are implemented so that objects of this class can be used as hash
  # keys. Furthermore the implementation is compatible to the one of Object, i.e. the hash of a
  # Reference object is the same as the hash of an indirect Object.
  #
  # See: PDF2.0 s7.3.10, Object
  class Reference

    include Comparable

    # Returns the object number of the referenced indirect object.
    attr_reader :oid

    # Returns the generation number of the referenced indirect object.
    attr_reader :gen

    # Creates a new Reference with the given object number and, optionally, generation number.
    def initialize(oid, gen = 0)
      @oid = Integer(oid)
      @gen = Integer(gen)
    end

    # Compares this object to another object.
    #
    # If the other object does not respond to +oid+ or +gen+, +nil+ is returned. Otherwise objects
    # are ordered first by object number and then by generation number.
    def <=>(other)
      return nil unless other.respond_to?(:oid) && other.respond_to?(:gen)
      (oid == other.oid ? gen <=> other.gen : oid <=> other.oid)
    end

    # Returns +true+ if the other object references the same PDF object as this reference object.
    #
    # This is necessary so that Object and Reference objects can be used as interchangable hash
    # keys and can be compared.
    def eql?(other)
      other.respond_to?(:oid) && oid == other.oid && other.respond_to?(:gen) && gen == other.gen
    end
    alias == eql?

    # Computes the hash value based on the object and generation numbers.
    def hash
      [oid, gen].hash
    end

    # Returns the object identifier as "oid,gen".
    def to_s
      "#{oid} #{gen} R"
    end

    def inspect #:nodoc:
      "#<#{self.class.name} [#{oid}, #{gen}]>"
    end

  end

end
