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

        # The 'hmtx' (horizontal metrics) table contains information for the horizontal layout
        # of each glyph in the font.
        #
        # See: https://developer.apple.com/fonts/TrueType-Reference-Manual/RM06/Chap6hmtx.html
        class Hmtx < Table

          # Contains the horizontal layout information for one glyph, namely the :advance_width and
          # the :left_side_bearing.
          Metric = Struct.new(:advance_width, :left_side_bearing)

          # A hash of glyph ID to Metric objects mapping.
          attr_accessor :horizontal_metrics

          # Returns the Metric object for the give glyph ID.
          def [](glyph_id)
            @horizontal_metrics[glyph_id]
          end

          private

          def parse_table #:nodoc:
            nr_entries = font[:hhea].num_of_long_hor_metrics
            max_id = nr_entries + (directory_entry.length - 4 * nr_entries) / 2
            @horizontal_metrics = Hash.new do |hash, glyph_id|
              return nil if glyph_id >= max_id
              if glyph_id >= nr_entries
                with_io_pos(directory_entry.offset + 4 * nr_entries + (glyph_id - nr_entries) * 2) do
                  hash[glyph_id] = Metric.new(@horizontal_metrics[nr_entries - 1].advance_width,
                                              *read_formatted(2, 's>'))
                end
              else
                with_io_pos(directory_entry.offset + 4 * glyph_id) do
                  hash[glyph_id] = Metric.new(*read_formatted(4, 'ns>'))
                end
              end
              hash[glyph_id]
            end
          end

        end

      end
    end
  end
end
