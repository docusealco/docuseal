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
  module Font
    module TrueType

      # Implementation of a generic table inside a sfnt-formatted font file.
      #
      # See: https://developer.apple.com/fonts/TrueType-Reference-Manual/RM06/Chap6.html
      class Table

        autoload(:Directory, 'hexapdf/font/true_type/table/directory')
        autoload(:Head, 'hexapdf/font/true_type/table/head')
        autoload(:Cmap, 'hexapdf/font/true_type/table/cmap')
        autoload(:Hhea, 'hexapdf/font/true_type/table/hhea')
        autoload(:Hmtx, 'hexapdf/font/true_type/table/hmtx')
        autoload(:Loca, 'hexapdf/font/true_type/table/loca')
        autoload(:Maxp, 'hexapdf/font/true_type/table/maxp')
        autoload(:Name, 'hexapdf/font/true_type/table/name')
        autoload(:Post, 'hexapdf/font/true_type/table/post')
        autoload(:Glyf, 'hexapdf/font/true_type/table/glyf')
        autoload(:OS2,  'hexapdf/font/true_type/table/os2')
        autoload(:Kern, 'hexapdf/font/true_type/table/kern')

        # The time Epoch used in sfnt-formatted font files.
        TIME_EPOCH = Time.new(1904, 1, 1)

        # Calculates the checksum for the given data.
        def self.calculate_checksum(data)
          checksum = 0
          if (remainder_length = data.length % 4) != 0
            checksum = (data[-remainder_length, remainder_length] << "\0" * (4 - remainder_length)).
              unpack1('N')
          end
          checksum + data.unpack('N*').inject(0) {|sum, long| sum + long } % 2**32
        end

        # The TrueType font object associated with this table.
        attr_reader :font

        # Creates a new Table object for the given font and initializes it by reading the
        # data from the font's associated IO stream
        #
        # See: #parse_table
        def initialize(font, entry)
          @font = font
          @directory_entry = entry
          load_from_io
        end

        # Returns the directory entry for this table.
        #
        # See: Directory
        def directory_entry
          @directory_entry
        end

        # Returns +true+ if the checksum stored in the directory entry of the table matches the
        # tables data.
        def checksum_valid?
          directory_entry.checksum == self.class.calculate_checksum(raw_data)
        end

        # Returns the raw table data.
        def raw_data
          with_io_pos(directory_entry.offset) { io.read(directory_entry.length) }
        end

        private

        # The IO stream of the associated font object.
        def io
          @font.io
        end

        # Loads the data for this table from the IO stream of the associated font object into this
        # object.
        #
        # See #parse_table for more information.
        def load_from_io
          with_io_pos(directory_entry.offset) { parse_table }
        end

        # Parses the table with the IO position already at the correct offset.
        #
        # This method does the actual work of parsing a table entry and must be implemented by
        # subclasses.
        #
        # See: #load_from_io
        def parse_table
          # noop for unsupported tables
        end

        # Sets the IO cursor to the given position while yielding to the block and returns the
        # block's return value.
        def with_io_pos(pos)
          old_pos = io.pos
          io.pos = pos
          yield
        ensure
          io.pos = old_pos
        end

        # Reads +count+ bytes from the current position of the font's associated IO stream, unpacks
        # them using the provided format specifier and returns the result.
        def read_formatted(count, format)
          io.read(count).unpack(format)
        end

        # Reads a 16.16-bit signed fixed-point integer and returns a Rational as result.
        def read_fixed
          Rational(io.read(4).unpack1('i>'), 65536)
        end

      end

    end
  end
end
