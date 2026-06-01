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

  # Represents a line segment.
  class Segment

    include Utils

    # The start point of the segment.
    attr_reader :start_point

    # The end point of the segment.
    attr_reader :end_point

    # Creates a new Segment from the start to the end point. The arguments are converted to proper
    # Geom2D::Point objects if needed.
    def initialize(start_point, end_point)
      @start_point = Geom2D::Point(start_point)
      @end_point = Geom2D::Point(end_point)
    end

    # Returns +true+ if the segment is degenerate, i.e. if it consists only of a point.
    def degenerate?
      @start_point == @end_point
    end

    # Returns +true+ if the segment is vertical.
    def vertical?
      float_equal(start_point.x, end_point.x)
    end

    # Returns +true+ if the segment is horizontal.
    def horizontal?
      float_equal(start_point.y, end_point.y)
    end

    # Returns the left-most bottom-most point of the segment (either the start or the end point).
    def min
      if start_point.x < end_point.x ||
          (float_equal(start_point.x, end_point.x) && start_point.y < end_point.y)
        start_point
      else
        end_point
      end
    end

    # Returns the right-most top-most point of the segment (either the start or the end point).
    def max
      if start_point.x > end_point.x ||
          (float_equal(start_point.x, end_point.x) && start_point.y > end_point.y)
        start_point
      else
        end_point
      end
    end

    # Returns the length of the segment.
    def length
      start_point.distance(end_point)
    end

    # Returns the direction vector of the segment as Geom2D::Point object.
    def direction
      end_point - start_point
    end

    # Returns the slope of the segment.
    #
    # If the segment is vertical, Float::INFINITY is returned.
    def slope
      if float_equal(start_point.x, end_point.x)
        Float::INFINITY
      else
        (end_point.y - start_point.y).to_f / (end_point.x - start_point.x)
      end
    end

    # Returns the y-intercept, i.e. the point on the y-axis where the segment does/would intercept
    # it.
    def y_intercept
      slope = self.slope
      if slope == Float::INFINITY
        nil
      else
        -start_point.x * slope + start_point.y
      end
    end

    # Reverses the start and end point.
    def reverse!
      @start_point, @end_point = @end_point, @start_point
    end

    # Returns the intersection of this segment with the given one:
    #
    # +nil+:: No intersections
    # Geom2D::Point:: Exactly one point
    # Geom2D::Segment:: The segment overlapping both other segments.
    def intersect(segment)
      p0 = start_point
      p1 = segment.start_point
      d0x = end_point.x - start_point.x
      d0y = end_point.y - start_point.y
      d1x = segment.end_point.x - segment.start_point.x
      d1y = segment.end_point.y - segment.start_point.y
      ex = p1.x - p0.x
      ey = p1.y - p0.y

      cross = (d0x * d1y - d1x * d0y).to_f # cross product of direction vectors

      if cross.abs > Utils.precision # segments are not parallel
        s = (ex * d1y - d1x * ey) / cross
        return nil if s < 0 || s > 1
        t = (ex * d0y - d0x * ey) / cross
        return nil if t < 0 || t > 1

        result = p0 + Point.new(s * d0x, s * d0y)
        return case result
               when start_point then start_point
               when end_point then end_point
               when segment.start_point then segment.start_point
               when segment.end_point then segment.end_point
               else result
               end
      end

      return nil if (ex * d0y - d0x * ey).abs > Utils.precision # non-intersecting parallel segment lines

      e0 = end_point
      e1 = segment.end_point

      # sort segment points by x-value
      p0, e0 = e0, p0 if float_compare(p0.x, e0.x) > 0
      p1, e1 = e1, p1 if float_compare(p1.x, e1.x) > 0
      if float_compare(p0.x, p1.x) > 0
        _p0, p1, e0, e1 = p1, p0, e1, e0
      end

      # p0 before or equal to p1
      if float_compare(e0.x, p1.x) < 0     # e0 before p1
        nil                                # no common point
      elsif float_compare(e1.x, e0.x) <= 0 # e1 before or equal to e0
        self.class.new(p1, e1)             # p1-e1 inside p0-e0
      elsif float_compare(p1.x, e0.x) == 0 # common endpoint p1=e0
        p1
      else
        self.class.new(p1, e0)             # s1 overlaps end of s0
      end
    end

    # Returns self.
    def +@
      self
    end

    # Returns the segment mirrored in the origin.
    def -@
      Segment.new(-start_point, -end_point)
    end

    # Adds the given vector (given as array or Geom2D::Point) to the segment, i.e. performs a
    # translation.
    def +(other)
      case other
      when Point, Array
        Segment.new(start_point + other, end_point + other)
      else
        raise ArgumentError, "Invalid argument class, must be Point"
      end
    end

    # Subtracts the given vector (given as array or Geom2D::Point) from the segment, i.e. performs a
    # translation.
    def -(other)
      case other
      when Point, Array
        Segment.new(start_point - other, end_point - other)
      else
        raise ArgumentError, "Invalid argument class, must be Point"
      end
    end

    # Compares this segment to the other, returning true if the end points match.
    def ==(other)
      return false unless other.kind_of?(Segment)
      start_point == other.start_point && end_point == other.end_point
    end

    def inspect # :nodoc:
      "Segment[#{start_point}-#{end_point}]"
    end
    alias to_s inspect

  end

end
