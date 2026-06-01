# -*- frozen_string_literal: true -*-
#
#--
# geom2d - 2D Geometric Objects and Algorithms
# Copyright (C) 2018-2023 Thomas Leitner <t_leitner@gmx.at>
#
# This software may be modified and distributed under the terms
# of the MIT license.  See the LICENSE file for details.
#++

require 'geom2d/polygon'

module Geom2D

  # Represents a set of polygons.
  class PolygonSet

    # The array of polygons.
    attr_reader :polygons

    # Creates a new PolygonSet with the given polygons.
    def initialize(polygons = [])
      @polygons = polygons
    end

    # Adds a polygon to this set.
    def add(polygon)
      @polygons << polygon
      self
    end
    alias << add

    # Creates a new polygon set by combining the polygons from this set and the other one.
    def join(other)
      PolygonSet.new(@polygons + other.polygons)
    end
    alias + join

    # Calls the given block once for each segment of each polygon in the set.
    #
    # If no block is given, an Enumerator is returned.
    def each_segment(&block)
      return to_enum(__method__) unless block_given?
      @polygons.each {|polygon| polygon.each_segment(&block) }
    end

    # Returns the number of polygons in this set.
    def nr_of_contours
      @polygons.size
    end

    # Returns the BoundingBox of all polygons in the set, or +nil+ if it contains no polygon.
    def bbox
      return BoundingBox.new if @polygons.empty?
      result = @polygons.first.bbox
      @polygons[1..-1].each {|v| result.add!(v.bbox) }
      result
    end

    def inspect # :nodoc:
      "PolygonSet#{@polygons}"
    end
    alias to_s inspect

  end

end
