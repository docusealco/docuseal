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

  # Represents a polygon.
  class Polygon

    # Creates a new Polygon object. The +vertices+ argument has to be an array of point-like
    # objects.
    def initialize(vertices = [])
      @vertices = []
      vertices.each {|value| @vertices << Geom2D::Point(value) }
    end

    # Returns one since a polygon object represents a single polygon.
    def nr_of_contours
      1
    end

    # Returns the number of vertices in the polygon.
    def nr_of_vertices
      @vertices.size
    end

    # Returns the i-th vertex of the polygon.
    def [](i)
      @vertices[i]
    end

    # Adds a new vertex to the end of the polygon.
    def add(x, y = nil)
      @vertices << Geom2D::Point(x, y)
      self
    end
    alias << add

    # Removes the last vertex of the polygon.
    def pop
      @vertices.pop
    end

    # Calls the given block once for each vertex of the polygon.
    #
    # If no block is given, an Enumerator is returned.
    def each_vertex(&block)
      return to_enum(__method__) unless block_given?
      @vertices.each(&block)
    end

    # Calls the given block once for each segment in the polygon.
    #
    # If no block is given, an Enumerator is returned.
    def each_segment
      return to_enum(__method__) unless block_given?
      return unless @vertices.size > 1

      @vertices.each_cons(2) {|v1, v2| yield(Geom2D::Segment.new(v1, v2)) }
      yield(Geom2D::Segment.new(@vertices[-1], @vertices[0]))
    end

    # Returns the BoundingBox of this polygon, or an empty BoundingBox if the polygon has no
    # vertices.
    def bbox
      return BoundingBox.new if @vertices.empty?
      result = @vertices.first.bbox
      @vertices[1..-1].each {|v| result.add!(v) }
      result
    end

    # Returns +true+ if the vertices of the polygon are ordered in a counterclockwise fashion.
    def ccw?
      return true if @vertices.empty?
      area = @vertices[-1].wedge(@vertices[0])
      0.upto(@vertices.size - 2) {|i| area += @vertices[i].wedge(@vertices[i + 1]) }
      area >= 0
    end

    # Reverses the direction of the vertices (and therefore the segments).
    def reverse!
      @vertices.reverse!
    end

    # Returns an array with the vertices of the polygon.
    def to_ary
      @vertices.dup
    end
    alias to_a to_ary

    def inspect # :nodoc:
      "Polygon#{@vertices}"
    end
    alias to_s inspect

  end

end
