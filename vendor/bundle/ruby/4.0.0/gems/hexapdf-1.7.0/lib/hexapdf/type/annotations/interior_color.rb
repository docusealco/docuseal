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

      # This module provides a convenience method for getting and setting the interior color for
      # various annotations.
      #
      # See: PDF2.0 s12.5
      module InteriorColor

        # :call-seq:
        #   line.interior_color           => color or nil
        #   line.interior_color(*color)   => line
        #
        # Returns the interior color or +nil+ (in case the interior color should be transparent)
        # when no argument is given. Otherwise sets the interior color and returns self.
        #
        # How the interior color is used depends on the concrete annotation type. For line
        # annotations, for example, it is the color to fill the line endings
        #
        # +color+:: The interior color. See
        #           HexaPDF::Content::ColorSpace.device_color_from_specification for information on
        #           the allowed arguments.
        #
        #           If the special value +:transparent+ is used when setting the color, no color is
        #           used for filling.
        def interior_color(*color)
          if color.empty?
            color = self[:IC]
            color && !color.empty? ?  Content::ColorSpace.prenormalized_device_color(color.value) : nil
          else
            color = if color.length == 1 && color.first == :transparent
                      []
                    else
                      Content::ColorSpace.device_color_from_specification(color).components
                    end
            self[:IC] = color
            self
          end
        end

      end

    end
  end
end
