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

require 'hexapdf/utils/object_hash'

module HexaPDF

  # Manages the indirect objects of one cross-reference section or stream.
  #
  # A PDF file can have more than one cross-reference section or stream which are all
  # daisy-chained together. This allows later sections to override entries in prior ones. This is
  # automatically and transparently done by HexaPDF.
  #
  # Note that a cross-reference section may contain a single object number only once.
  #
  # See: HexaPDF::Revision, PDF2.0 s7.5.4, s7.5.8
  class XRefSection < Utils::ObjectHash

    # One entry of a cross-reference section or stream.
    #
    # An entry has the attributes +type+, +oid+, +gen+, +pos+ and +objstm+ and can be created like
    # this:
    #
    #   Entry.new(type, oid, gen, pos, objstm)   -> entry
    #
    # The +type+ attribute can be:
    #
    # :free:: Denotes a free entry.
    #
    # :in_use:: A used entry that resides in the body of the PDF file. The +pos+ attribute defines
    #           the position in the file at which the object can be found.
    #
    # :compressed:: A used entry that resides in an object stream. The +objstm+ attribute contains
    #               the reference to the object stream in which the object can be found and the
    #               +pos+ attribute contains the index into the object stream.
    #
    #               Objects in an object stream always have a generation number of 0!
    #
    # See: PDF2.0 s7.5.4, s7.5.8
    Entry = Struct.new(:type, :oid, :gen, :pos, :objstm) do
      def free?
        type == :free
      end

      def in_use?
        type == :in_use
      end

      def compressed?
        type == :compressed
      end

      def to_s
        case type
        when :free then "xref #{oid},#{gen} type=free"
        when :in_use then "xref #{oid},#{gen} type=normal pos=#{pos}"
        when :compressed then "xref #{oid},#{gen} type=compressed objstm=#{objstm},0 index=#{pos}"
        end
      end
    end

    # Creates an in-use cross-reference entry. See Entry for details on the arguments.
    def self.in_use_entry(oid, gen, pos)
      Entry.new(:in_use, oid, gen, pos)
    end

    # Creates a free cross-reference entry. See Entry for details on the arguments.
    def self.free_entry(oid, gen)
      Entry.new(:free, oid, gen)
    end

    # Creates a compressed cross-reference entry. See Entry for details on the arguments.
    def self.compressed_entry(oid, objstm, pos)
      Entry.new(:compressed, oid, 0, pos, objstm)
    end

    # Make the assignment method private so that only the provided convenience methods can be
    # used.
    private :'[]='

    # Marks this XRefSection object as being the first cross-reference section in a PDF file.
    #
    # This has the consequence that only a single sub-section starting a zero is created.
    def mark_as_initial_section!
      @initial_section = true
      add_free_entry(0, 65535)
    end

    # Adds an in-use entry to the cross-reference section.
    #
    # See: ::in_use_entry
    def add_in_use_entry(oid, gen, pos)
      self[oid, gen] = self.class.in_use_entry(oid, gen, pos)
    end

    # Adds a free entry to the cross-reference section.
    #
    # See: ::free_entry
    def add_free_entry(oid, gen)
      self[oid, gen] = self.class.free_entry(oid, gen)
    end

    # Adds a compressed entry to the cross-reference section.
    #
    # See: ::compressed_entry
    def add_compressed_entry(oid, objstm, pos)
      self[oid, 0] = self.class.compressed_entry(oid, objstm, pos)
    end

    # Merges the entries from the given cross-reference section into this one.
    def merge!(xref_section)
      xref_section.each {|oid, gen, data| self[oid, gen] = data }
    end

    # :call-seq:
    #   xref_section.each_subsection {|sub| block }   -> xref_section
    #   xref_section.each_subsection                  -> Enumerator
    #
    # Calls the given block once for every subsection of this cross-reference section. Each
    # yielded subsection is a sorted array of cross-reference entries.
    #
    # If this section contains no objects, a single empty array is yielded (corresponding to a
    # subsection with zero elements).
    #
    # The subsections are dynamically generated based on the object numbers in this section. In case
    # the section was marked as the initial section (see #mark_as_initial_section!) only a single
    # subsection is yielded.
    def each_subsection
      return to_enum(__method__) unless block_given?

      temp = []
      sorted_oids = oids.sort
      expected_next_oid = sorted_oids[0]
      sorted_oids.each do |oid|
        if expected_next_oid != oid
          if @initial_section
            expected_next_oid.upto(oid - 1) do |free_oid|
              temp << self.class.free_entry(free_oid, 0)
            end
          else
            yield(temp)
            temp = []
          end
        end
        temp << self[oid]
        expected_next_oid = oid + 1
      end
      yield(temp)
      self
    end

  end

end
