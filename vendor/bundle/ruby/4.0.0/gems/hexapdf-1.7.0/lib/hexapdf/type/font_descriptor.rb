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

require 'hexapdf/dictionary'
require 'hexapdf/stream'
require 'hexapdf/utils/bit_field'

module HexaPDF
  module Type

    # This class specifies metrics and other attributes of a simple font or a CID font as a
    # whole.
    #
    # See: PDF2.0 s9.8
    class FontDescriptor < Dictionary

      extend Utils::BitField

      define_type :FontDescriptor

      define_field :Type,         type: Symbol, required: true, default: type
      define_field :FontName,     type: Symbol, required: true
      define_field :FontFamily,   type: PDFByteString, version: '1.5'
      define_field :FontStretch,  type: Symbol, version: '1.5',
        allowed_values: [:UltraCondensed, :ExtraCondensed, :Condensed, :SemiCondensed,
                         :Normal, :SemiExpanded, :Expanded, :ExtraExpanded, :UltraExpanded]
      define_field :FontWeight,   type: Integer, version: '1.5' # also see validation
      define_field :Flags,        type: Integer, required: true
      define_field :FontBBox,     type: Rectangle
      define_field :ItalicAngle,  type: Numeric, required: true
      define_field :Ascent,       type: Numeric
      define_field :Descent,      type: Numeric
      define_field :Leading,      type: Numeric, default: 0
      define_field :CapHeight,    type: Numeric
      define_field :XHeight,      type: Numeric, default: 0
      define_field :StemV,        type: Numeric
      define_field :StemH,        type: Numeric, default: 0
      define_field :AvgWidth,     type: Numeric, default: 0
      define_field :MaxWidth,     type: Numeric, default: 0
      define_field :MissingWidth, type: Numeric, default: 0
      define_field :FontFile,     type: Stream
      define_field :FontFile2,    type: Stream, version: '1.1'
      define_field :FontFile3,    type: Stream, version: '1.2'
      define_field :CharSet,      type: [PDFByteString, String], version: '1.1'

      # From PDF2.0 s9.8.3.1
      define_field :Style,        type: Dictionary
      define_field :Lang,         type: Symbol, version: '1.5'
      define_field :FD,           type: Dictionary
      define_field :CIDSet,       type: Stream

      bit_field(:flags, {fixed_pitch: 0, serif: 1, symbolic: 2, script: 3, nonsymbolic: 5,
                         italic: 6, all_cap: 16, small_cap: 17, force_bold: 18},
                lister: "flags", getter: "flagged?", setter: "flag", unsetter: 'unflag',
                value_getter: "self[:Flags]", value_setter: "self[:Flags]")

      private

      ALLOWED_FONT_WEIGHTS = [100, 200, 300, 400, 500, 600, 700, 800, 900] #:nodoc:

      def perform_validation #:nodoc:
        super
        if [self[:FontFile], self[:FontFile2], self[:FontFile3]].compact.size > 1
          yield("Only one of /FontFile, /FontFile2 or /FontFile3 may be set", false)
        end

        font_weight = self[:FontWeight]
        if font_weight && !ALLOWED_FONT_WEIGHTS.include?(font_weight)
          yield("Field FontWeight contains the disallowed value #{font_weight}", true)
          delete(:FontWeight)
        end

        descent = self[:Descent]
        if descent && descent > 0
          yield("The /Descent value needs to be zero or negative", true)
          self[:Descent] = -descent
        end
      end

    end

  end
end
