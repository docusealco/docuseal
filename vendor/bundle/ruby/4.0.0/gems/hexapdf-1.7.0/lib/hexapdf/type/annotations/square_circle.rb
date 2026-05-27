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

require 'hexapdf/type/annotations'

module HexaPDF
  module Type
    module Annotations

      # This is the base class for the square and circle markup annotations which display a
      # rectangle or ellipse inside the annotation rectangle.
      #
      # The styling is done through methods included by various modules:
      #
      # * Changing the line width, line dash pattern and color is done using the method
      #   BorderStyling#border_style.  While that method allows special styling of the line (like
      #   :beveled), only a simple line dash pattern is supported by the square and circle
      #   annotations.
      #
      # * The interior color can be changed through InteriorColor#interior_color.
      #
      # * The border effect can be changed through BorderEffect#border_effect. Note that cloudy
      #   borders are not supported.
      #
      # See: PDF2.0 s12.5.6.8, HexaPDF::Type::Annotations::Square,
      # HexaPDF::Type::Annotations::Circle, HexaPDF::Type::MarkupAnnotation
      class SquareCircle < MarkupAnnotation

        include BorderStyling
        include BorderEffect
        include InteriorColor

        # Field Subtype is defined in the two subclasses
        define_field :BS, type: :Border
        define_field :IC, type: PDFArray, version: '1.4'
        define_field :BE, type: :XXBorderEffect, version: '1.5'
        # Array instead of Rectangle, see https://github.com/pdf-association/pdf-issues/issues/524
        define_field :RD, type: PDFArray, version: '1.5'

      end

    end
  end
end
