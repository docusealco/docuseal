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

require 'hexapdf/type/font_simple'

module HexaPDF
  module Type

    # Represents a Type 3 font.
    #
    # Note: We assume the /FontMatrix is only used for scaling, i.e. of the form [x 0 0 +/-x 0 0].
    # If it is of a different form, things won't work correctly. This will be handled once such a
    # case is found.
    #
    # See: PDF2.0 s9.6.4
    class FontType3 < FontSimple

      define_field :Subtype,    type: Symbol, required: true, default: :Type3
      define_field :FontBBox,   type: Rectangle, required: true
      define_field :FontMatrix, type: PDFArray, required: true
      define_field :CharProcs,  type: Dictionary, required: true
      define_field :Resources,  type: Dictionary, version: '1.2'

      # Returns the bounding box of the font.
      def bounding_box
        matrix = self[:FontMatrix]
        bbox = self[:FontBBox].value
        if matrix[3] < 0 # Some writers invert the y-axis
          bbox = bbox.dup
          bbox[1], bbox[3] = -bbox[3], -bbox[1]
        end
        bbox
      end

      # Returns the glyph scaling factor for transforming from glyph space to text space.
      def glyph_scaling_factor
        self[:FontMatrix][0]
      end

      private

      def perform_validation
        super
        yield("Required field Encoding is not set", false) if self[:Encoding].nil?
      end

    end

  end
end
