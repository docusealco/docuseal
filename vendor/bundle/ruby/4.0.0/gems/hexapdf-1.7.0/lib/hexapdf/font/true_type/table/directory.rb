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

require 'hexapdf/font/true_type/table'

module HexaPDF
  module Font
    module TrueType
      class Table

        # The main table of an sfnt-housed font file, providing the table directory which contains
        # information for loading all other tables.
        #
        # See: https://developer.apple.com/fonts/TrueType-Reference-Manual/RM06/Chap6.html
        class Directory < Table

          # A single entry in the table directory.
          #
          # Accessors:
          #
          # tag::      The 4 byte name of the table as binary string.
          # checksum:: Checksum of the table.
          # offset::   Offset from the beginning of the file where the table can be found.
          # length::   The length of the table in bytes (without the padding).
          Entry = Struct.new(:tag, :checksum, :offset, :length)

          # The fixed entry that represents the table directory itself.
          SELF_ENTRY = Entry.new('DUMMY', 0, 0, 12)

          # The type of file housed by the snft wrapper as a binary string. Two possible values are
          # 'true' or 0x00010000 for a TrueType font and 'OTTO' for an OpenType font.
          attr_reader :tag

          # Returns the directory entry for the given tag or +nil+ if no such table exists.
          def entry(tag)
            @tables[tag]
          end

          # Returns an array with all the table names (in string form) in the directory.
          def table_names
            @tables.keys
          end

          private

          def load_from_io #:nodoc:
            with_io_pos(0) do
              @tag, num_tables = read_formatted(12, "a4n") # ignore 3 fields
              @tables = {}
              num_tables.times do
                entry = Entry.new(*read_formatted(16, "a4NNN"))
                @tables[entry.tag] = entry
              end
            end
          end

        end

      end
    end
  end
end
