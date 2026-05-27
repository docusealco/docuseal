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
require 'hexapdf/font/true_type/table/cmap_subtable'

module HexaPDF
  module Font
    module TrueType
      class Table

        # The 'cmap' table contains subtables for mapping character codes to glyph indices.
        #
        # See:
        # * CmapSubtable
        # * https://developer.apple.com/fonts/TrueType-Reference-Manual/RM06/Chap6cmap.html
        class Cmap < Table

          # The version of the cmap table.
          attr_accessor :version

          # The available cmap subtables.
          attr_accessor :tables

          # Returns the preferred of the available cmap subtables.
          #
          # A preferred table is always a table mapping Unicode characters.
          def preferred_table
            tables.select(&:unicode?).max_by(&:format)
          end

          private

          def parse_table #:nodoc:
            @version, num_tables = read_formatted(4, 'n2')
            @tables = []
            handle_unknown = font.config['font.true_type.unknown_format']

            num_tables.times { @tables << read_formatted(8, 'n2N') }
            offset_map = {}
            @tables.map! do |platform_id, encoding_id, offset|
              offset += directory_entry.offset
              if offset_map.key?(offset)
                subtable = offset_map[offset].dup
                subtable.platform_id = platform_id
                subtable.encoding_id = encoding_id
                next subtable
              end

              subtable = CmapSubtable.new(platform_id, encoding_id)
              supported = subtable.parse(io, offset)
              if supported
                offset_map[offset] = subtable
                subtable
              elsif handle_unknown == :raise
                raise HexaPDF::Error, "Unknown cmap subtable format #{subtable.format}"
              else
                nil
              end
            end.compact!
          end

        end

      end
    end
  end
end
