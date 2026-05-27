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

require 'hexapdf/pdf_array'

module HexaPDF

  # Implementation of the PDF rectangle data structure.
  #
  # Rectangles are used for describing page and bounding boxes. They are represented by arrays of
  # four numbers specifying the (x,y) coordinates of *any* diagonally opposite corners.
  #
  # This class simplifies the usage of rectangles by automatically normalizing the coordinates so
  # that they are in the order:
  #
  #   [left, bottom, right, top]
  #
  # where +left+ is the bottom-left x-coordinate, +bottom+ is the bottom-left y-coordinate, +right+
  # is the top-right x-coordinate and +top+ is the top-right y-coordinate.
  #
  # See: PDF2.0 s7.9.5
  class Rectangle < HexaPDF::PDFArray

    # Returns the x-coordinate of the bottom-left corner.
    def left
      self[0]
    end

    # Sets the x-coordinate of the bottom-left corner to the given value.
    def left=(x)
      value[0] = x
    end

    # Returns the x-coordinate of the top-right corner.
    def right
      self[2]
    end

    # Sets the x-coordinate of the top-right corner to the given value.
    def right=(x)
      value[2] = x
    end

    # Returns the y-coordinate of the bottom-left corner.
    def bottom
      self[1]
    end

    # Sets the y-coordinate of the bottom-left corner to the given value.
    def bottom=(y)
      value[1] = y
    end

    # Returns the y-coordinate of the top-right corner.
    def top
      self[3]
    end

    # Sets the y-coordinate of the top-right corner to the given value.
    def top=(y)
      value[3] = y
    end

    # Returns the width of the rectangle.
    def width
      self[2] - self[0]
    end

    # Sets the width of the rectangle to the given value.
    def width=(val)
      self[2] = self[0] + val
    end

    # Returns the height of the rectangle.
    def height
      self[3] - self[1]
    end

    # Sets the height of the rectangle to the given value.
    def height=(val)
      self[3] = self[1] + val
    end

    private

    #:nodoc:
    RECTANGLE_ERROR_MSG = "A PDF rectangle structure must contain an array of four numbers"

    # Ensures that the value is an array containing four numbers that specify the bottom-left and
    # top-right corners.
    def after_data_change
      super
      unless value.size == 4 && all? {|v| v.kind_of?(Numeric) }
        if !document? ||
            document.config['parser.on_correctable_error'].call(document, RECTANGLE_ERROR_MSG, 0)
          raise ArgumentError, RECTANGLE_ERROR_MSG
        end
        value.replace([0, 0, 0, 0])
      end
      self[0], self[2] = self[2], self[0] if self[0] > self[2]
      self[1], self[3] = self[3], self[1] if self[1] > self[3]
    end

    def perform_validation #:nodoc:
      super
      unless value.size == 4 && all? {|v| v.kind_of?(Numeric) }
        yield("A PDF rectangle structure must contain an array of four numbers; replacing " \
          "it with [0, 0, 0, 0]", true)
        value.replace([0, 0, 0, 0])
      end
    end

  end

end
