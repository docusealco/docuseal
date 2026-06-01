#--
# geom2d - 2D Geometric Objects and Algorithms
# Copyright (C) 2018-2023 Thomas Leitner <t_leitner@gmx.at>
#
# This software may be modified and distributed under the terms
# of the MIT license.  See the LICENSE file for details.
#++
# -*- frozen_string_literal: true -*-
#
#--
# geom2d - 2D Geometric Objects and Algorithms
# Copyright (C) 2018 Thomas Leitner <t_leitner@gmx.at>
#
# This software may be modified and distributed under the terms
# of the MIT license.  See the LICENSE file for details.
#++

require 'geom2d'

module Geom2D

  # Represents an axis aligned rectangle.
  class Rectangle

    # The x-coordinate of the bottom-left corner of the rectangle.
    attr_reader :x

    # The y-coordinate of the bottom-left corner of the rectangle.
    attr_reader :y

    # The width of the rectangle.
    attr_reader :width

    # The height of the rectangle.
    attr_reader :height

    # Creates a new Rectangle object, with (x, y) specifying the bottom-left corner of the rectangle.
    def initialize(x, y, width, height)
      @x = x
      @y = y
      @width = width
      @height = height
    end

    # Returns one since a rectangle object is a single polygon.
    def nr_of_contours
      1
    end

    # Returns four since a rectangle has four vertices.
    def nr_of_vertices
      4
    end

    # Calls the given block once for each corner of the rectangle.
    #
    # If no block is given, an Enumerator is returned.
    def each_vertex(&block)
      return to_enum(__method__) unless block_given?
      vertices.each(&block)
    end

    # Calls the given block once for each segment of the rectangle.
    #
    # If no block is given, an Enumerator is returned.
    def each_segment
      return to_enum(__method__) unless block_given?

      v = vertices
      v.each_cons(2) {|v1, v2| yield(Geom2D::Segment.new(v1, v2)) }
      yield(Geom2D::Segment.new(v[-1], v[0]))
    end

    # Returns the BoundingBox of this rectangle.
    def bbox
      BoundingBox.new(x, y, x + width, y + height)
    end

    # Returns +true+ since the vertices of the rectangle are always ordered in a counterclockwise
    # fashion.
    def ccw?
      true
    end

    def inspect # :nodoc:
      "Rectangle[(#{@x},#{@y}),width=#{@width},height=#{@height}]"
    end
    alias to_s inspect

    # Returns an array with the vertices of the rectangle.
    def to_ary
      vertices
    end
    alias to_a to_ary

    private

    # Returns an array with the four corners of the rectangle.
    def vertices
      [Geom2D::Point(x, y), Geom2D::Point(x + width, y),
       Geom2D::Point(x + width, y + height), Geom2D::Point(x, y + height)]
    end

  end

end
