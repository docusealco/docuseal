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

require 'hexapdf/type/font'

module HexaPDF
  module Type

    # Represents a generic CIDFont which can only be used as a descendant font of a composite PDF
    # font.
    #
    # See: PDF2.0 s9.7.4
    class CIDFont < Font

      # Describes the CIDSystemInfo dictionary specifying the character collection assumed by the
      # CIDFont.
      #
      # See: PDF2.0 s9.7.3
      class CIDSystemInfo < Dictionary

        define_type :XXCIDSystemInfo

        define_field :Registry, type: String, required: true
        define_field :Ordering, type: String, required: true
        define_field :Supplement, type: Integer, required: true

      end

      DEFAULT_WIDTH = 1000 # :nodoc:

      define_field :Subtype,         type: Symbol, required: true,
                   allowed_values: [:CIDFontType0, :CIDFontType2]
      define_field :BaseFont,        type: Symbol, required: true
      define_field :CIDSystemInfo,   type: :XXCIDSystemInfo, required: true
      define_field :FontDescriptor,  type: :FontDescriptor, required: true
      define_field :DW,              type: Numeric, default: DEFAULT_WIDTH
      define_field :W,               type: PDFArray
      define_field :DW2,             type: PDFArray, default: [880, -1100]
      define_field :W2,              type: PDFArray
      define_field :CIDToGIDMap,     type: [Stream, Symbol]

      # Returns the unscaled width of the given CID in glyph units, or 0 if the width for the CID is
      # missing.
      #
      # Note that in contrast to other fonts, the argument must *not* be a code point but a CID!
      def width(cid)
        widths[cid] || value[:DW] || DEFAULT_WIDTH
      end

      # Sets the /W and /DW keys using the given array of [CID, width] pairs and an optional default
      # width.
      #
      # See: PDF2.0 s9.7.4.3
      def set_widths(widths, default_width: DEFAULT_WIDTH)
        if widths.empty?
          (default_width == DEFAULT_WIDTH ? delete(:DW) : self[:DW] = default_width)
          delete(:W)
        else
          self[:DW] = default_width.to_i unless default_width == DEFAULT_WIDTH
          self[:W] = w = []
          last_cid = -10
          cur_widths = nil
          widths.each do |cid, width|
            if last_cid + 1 != cid
              cur_widths = []
              w << cid << cur_widths
            end
            cur_widths << width.to_i
            last_cid = cid
          end
        end
      end

      private

      # Returns a hash mapping CIDs to their respective width.
      #
      # Note that the hash is cached internally when accessed the first time.
      #
      # See: PDF2.0 s9.7.4.3
      def widths
        cache(:widths) do
          result = {}
          index = 0
          array = self[:W] || []

          while index < array.size
            entry = array[index]
            value = array[index + 1]
            if value.kind_of?(Array)
              value.each_with_index {|width, i| result[entry + i] = width }
              index += 2
            else
              width = array[index + 2]
              entry.upto(value) {|cid| result[cid] = width }
              index += 3
            end
          end

          result
        end
      end

    end

  end
end
