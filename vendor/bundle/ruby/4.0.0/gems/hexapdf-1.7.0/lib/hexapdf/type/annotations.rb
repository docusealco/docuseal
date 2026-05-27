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

module HexaPDF
  module Type

    autoload(:Annotation, 'hexapdf/type/annotation')

    # Namespace module for all PDF annotation dictionary types.
    #
    # See: PDF2.0 s12.5.6, Annotation
    module Annotations

      autoload(:MarkupAnnotation, 'hexapdf/type/annotations/markup_annotation')
      autoload(:Text, 'hexapdf/type/annotations/text')
      autoload(:Link, 'hexapdf/type/annotations/link')
      autoload(:Widget, 'hexapdf/type/annotations/widget')
      autoload(:BorderStyling, 'hexapdf/type/annotations/border_styling')
      autoload(:Line, 'hexapdf/type/annotations/line')
      autoload(:AppearanceGenerator, 'hexapdf/type/annotations/appearance_generator')
      autoload(:BorderEffect, 'hexapdf/type/annotations/border_effect')
      autoload(:InteriorColor, 'hexapdf/type/annotations/interior_color')
      autoload(:SquareCircle, 'hexapdf/type/annotations/square_circle')
      autoload(:Square, 'hexapdf/type/annotations/square')
      autoload(:Circle, 'hexapdf/type/annotations/circle')
      autoload(:LineEndingStyling, 'hexapdf/type/annotations/line_ending_styling')
      autoload(:PolygonPolyline, 'hexapdf/type/annotations/polygon_polyline')
      autoload(:Polygon, 'hexapdf/type/annotations/polygon')
      autoload(:Polyline, 'hexapdf/type/annotations/polyline')

    end

  end
end
