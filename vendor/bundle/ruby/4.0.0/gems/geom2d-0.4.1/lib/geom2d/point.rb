# -*- frozen_string_literal: true -*-
#
#--
# geom2d - 2D Geometric Objects and Algorithms
# Copyright (C) 2018-2023 Thomas Leitner <t_leitner@gmx.at>
#
# This software may be modified and distributed under the terms
# of the MIT license.  See the LICENSE file for details.
#++

require 'geom2d'

module Geom2D

  # Represents a point.
  class Point

    include Utils

    # The x-coordinate.
    attr_reader :x

    # The y-coordinate.
    attr_reader :y

    # Creates a new Point from the given coordinates.
    def initialize(x, y)
      @x = x
      @y = y
    end

    # Returns the point's bounding box (i.e. a bounding box containing only the point itself).
    def bbox
      BoundingBox.new(x, y, x, y)
    end

    # Returns the distance from this point to the given point.
    def distance(point)
      Math.hypot(point.x - x, point.y - y)
    end

    # Returns self.
    def +@
      self
    end

    # Returns the point mirrored in the origin.
    def -@
      Point.new(-x, -y)
    end

    # Depending on the type of the argument, either adds a number to each coordinate or adds two
    # points.
    def +(other)
      case other
      when Point
        Point.new(x + other.x, y + other.y)
      when Numeric
        Point.new(x + other, y + other)
      when Array
        self + Geom2D::Point(other)
      else
        raise ArgumentError, "Invalid argument class, must be Numeric or Point"
      end
    end

    # Depending on the type of the argument, either subtracts a number from each coordinate or
    # subtracts the other point from this one.
    def -(other)
      case other
      when Point
        Point.new(x - other.x, y - other.y)
      when Numeric
        Point.new(x - other, y - other)
      when Array
        self - Geom2D::Point(other)
      else
        raise ArgumentError, "Invalid argument class, must be Numeric or Point"
      end
    end

    # Depending on the type of the argument, either multiplies this point with the other point (dot
    # product) or multiplies each coordinate with the given number.
    def *(other)
      case other
      when Point
        x * other.x + y * other.y
      when Numeric
        Point.new(x * other, y * other)
      when Array
        self * Geom2D::Point(other)
      else
        raise ArgumentError, "Invalid argument class, must be Numeric or Point"
      end
    end

    # Multiplies this point with the other point using the dot product.
    def dot(other)
      self * other
    end

    # Performs the wedge product of this point with the other point.
    def wedge(other)
      other = Geom2D::Point(other)
      x * other.y - other.x * y
    end

    # Divides each coordinate by the given number.
    def /(other)
      case other
      when Numeric
        Point.new(x / other.to_f, y / other.to_f)
      else
        raise ArgumentError, "Invalid argument class, must be Numeric"
      end
    end

    # Compares this point to the other point, using floating point equality.
    #
    # See Utils#float_equal.
    def ==(other)
      case other
      when Point
        float_equal(x, other.x) && float_equal(y, other.y)
      when Array
        self == Geom2D::Point(other)
      else
        false
      end
    end

    # Allows destructuring of a point into an array.
    def to_ary
      [x, y]
    end
    alias to_a to_ary

    def inspect # :nodoc:
      "(#{x}, #{y})"
    end
    alias to_s inspect

  end

end
