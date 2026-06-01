# -*- frozen_string_literal: true -*-
#
#--
# geom2d - 2D Geometric Objects and Algorithms
# Copyright (C) 2018-2023 Thomas Leitner <t_leitner@gmx.at>
#
# This software may be modified and distributed under the terms
# of the MIT license.  See the LICENSE file for details.
#++

# = Geom2D - Objects and Algorithms for 2D Geometry in Ruby
#
# This library implements objects for 2D geometry, like points, line segments, arcs, curves and so
# on, as well as algorithms for these objects, like line-line intersections and arc approximation by
# Bezier curves.
module Geom2D

  autoload(:Point, 'geom2d/point')
  autoload(:Segment, 'geom2d/segment')
  autoload(:Polygon, 'geom2d/polygon')
  autoload(:PolygonSet, 'geom2d/polygon_set')
  autoload(:Rectangle, 'geom2d/rectangle')

  autoload(:BoundingBox, 'geom2d/bounding_box')
  autoload(:Algorithms, 'geom2d/algorithms')

  autoload(:Utils, 'geom2d/utils')
  autoload(:VERSION, 'geom2d/version')

  # Creates a new Point object from the given coordinates.
  #
  # See: Point.new
  def self.Point(x, y = nil)
    if x.kind_of?(Point)
      x
    elsif y
      Point.new(x, y)
    else
      Point.new(*x)
    end
  end

  # Creates a new Segment from +start_point+ to +end_point+ or, if +vector+ is given, from
  # +start_point+ to +start_point+ + +vector+.
  #
  # See: Segment.new
  def self.Segment(start_point, end_point = nil, vector: nil)
    if end_point
      Segment.new(start_point, end_point)
    elsif vector
      Segment.new(start_point, start_point + vector)
    else
      raise ArgumentError, "Either end_point or a vector must be given"
    end
  end

  # Creates a new Polygon object from the given vertices.
  #
  # See: Polygon.new
  def self.Polygon(*vertices)
    Polygon.new(vertices)
  end

  # Creates a PolygonSet from the given array of Polygon instances.
  #
  # See: PolygonSet.new
  def self.PolygonSet(*polygons)
    PolygonSet.new(polygons)
  end

  # Creates a Rectangle from the given bottom-left point (x, y) and the provided +width+ and
  # +height+.
  #
  # See: Rectangle.new
  def self.Rectangle(x, y, width, height)
    Rectangle.new(x, y, width, height)
  end

end
