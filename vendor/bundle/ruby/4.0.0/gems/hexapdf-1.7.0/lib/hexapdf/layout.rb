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

  # == Overview
  #
  # The Layout module contains advanced text and layouting facilities that are built on top of the
  # standard PDF functionality provided by the Content module.
  module Layout

    autoload(:Style, 'hexapdf/layout/style')
    autoload(:TextFragment, 'hexapdf/layout/text_fragment')
    autoload(:InlineBox, 'hexapdf/layout/inline_box')
    autoload(:Line, 'hexapdf/layout/line')
    autoload(:TextShaper, 'hexapdf/layout/text_shaper')
    autoload(:TextLayouter, 'hexapdf/layout/text_layouter')
    autoload(:Box, 'hexapdf/layout/box')
    autoload(:Frame, 'hexapdf/layout/frame')
    autoload(:BoxFitter, 'hexapdf/layout/box_fitter')
    autoload(:WidthFromPolygon, 'hexapdf/layout/width_from_polygon')
    autoload(:TextBox, 'hexapdf/layout/text_box')
    autoload(:ImageBox, 'hexapdf/layout/image_box')
    autoload(:ColumnBox, 'hexapdf/layout/column_box')
    autoload(:ListBox, 'hexapdf/layout/list_box')
    autoload(:PageStyle, 'hexapdf/layout/page_style')
    autoload(:TableBox, 'hexapdf/layout/table_box')
    autoload(:ContainerBox, 'hexapdf/layout/container_box')

  end

end
