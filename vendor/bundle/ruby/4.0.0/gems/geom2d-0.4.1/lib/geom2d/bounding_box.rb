# -*- frozen_string_literal: true -*-
#
#--
# geom2d - 2D Geometric Objects and Algorithms
# Copyright (C) 2018-2023 Thomas Leitner <t_leitner@gmx.at>
#
# This software may be modified and distributed under the terms
# of the MIT license.  See the LICENSE file for details.
#++

module Geom2D

  # Represents an axis aligned bounding box.
  #
  # An empty bounding box contains just the point at origin.
  class BoundingBox

    # The minimum x-coordinate.
    attr_reader :min_x

    # The minimum y-coordinate.
    attr_reader :min_y

    # The maximum x-coordinate.
    attr_reader :max_x

    # The maximum y-coordinate.
    attr_reader :max_y

    # Creates a new BoundingBox.
    def initialize(min_x = 0, min_y = 0, max_x = 0, max_y = 0)
      @min_x = min_x
      @min_y = min_y
      @max_x = max_x
      @max_y = max_y
    end

    # Updates this bounding box to also contain the given bounding box or point.
    def add!(other)
      case other
      when BoundingBox
        @min_x = [min_x, other.min_x].min
        @min_y = [min_y, other.min_y].min
        @max_x = [max_x, other.max_x].max
        @max_y = [max_y, other.max_y].max
      when Point
        @min_x = [min_x, other.x].min
        @min_y = [min_y, other.y].min
        @max_x = [max_x, other.x].max
        @max_y = [max_y, other.y].max
      else
        raise ArgumentError, "Can only use another BoundingBox or Point"
      end
      self
    end

    # Returns the width of the bounding box.
    def width
      @max_x - @min_x
    end

    # Returns the height of the bounding box.
    def height
      @max_y - @min_y
    end

    # Returns a bounding box containing this bounding box and the argument.
    def add(other)
      dup.add!(other)
    end
    alias + add

    # Returns the bounding box as an array of the form [min_x, min_y, max_x, max_y].
    def to_a
      [@min_x, @min_y, @max_x, @max_y]
    end

    def inspect # :nodoc:
      "BBox[#{min_x}, #{min_y}, #{max_x}, #{max_y}]"
    end

  end

end
