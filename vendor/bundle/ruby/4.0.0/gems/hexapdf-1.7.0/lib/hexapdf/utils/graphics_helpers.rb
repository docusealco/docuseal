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
  module Utils

    # This module provides some helper functions for graphics.
    module GraphicsHelpers

      module_function

      # Calculates and returns the requested dimensions for the rectangular object with the given
      # +width+ and +height+ based on the following: options:
      #
      # +rwidth+::
      #     The requested width. If +rheight+ is not specified, it is chosen so that the aspect
      #     ratio is maintained. In case of +width+ begin zero, +height+ is used for the height.
      #
      # +rheight+::
      #     The requested height. If +rwidth+ is not specified, it is chosen so that the aspect
      #     ratio is maintained. In case of +height+ begin zero, +width+ is used for the width.
      def calculate_dimensions(width, height, rwidth: nil, rheight: nil)
        if rwidth && rheight
          [rwidth, rheight]
        elsif rwidth
          [rwidth, width == 0 ? height : height * rwidth / width.to_f]
        elsif rheight
          [height == 0 ? width : width * rheight / height.to_f, rheight]
        else
          [width, height]
        end
      end

      # Given two points p0 = (x0, y0) and p1 = (x1, y1), returns the point on the line through
      # these points that is +distance+ units away from p0.
      #
      #   v = p1 - p0
      #   result = p0 + distance * v/norm(v)
      def point_on_line(x0, y0, x1, y1, distance:)
        norm = Math.sqrt((x1 - x0)**2 + (y1 - y0)**2)
        [x0 + distance / norm * (x1 - x0), y0 + distance / norm * (y1 - y0)]
      end

    end

  end
end
