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

require 'geom2d/utils'

module HexaPDF
  module Layout

    # Utility class for generating width specifications for TextLayouter#fit from polygons.
    class WidthFromPolygon

      include HexaPDF::Utils

      # Creates a new object for the given polygon (or polygon set) and immediately prepares it so
      # that #call can be used.
      #
      # The offset argument specifies the vertical offset from the top at which calculations
      # should start.
      def initialize(polygon, offset = 0)
        @polygon = polygon
        prepare(offset)
      end

      # Returns the width specification for the given values with respect to the wrapped polygon.
      def call(height, line_height)
        width(@max_y - height - line_height, @max_y - height)
      end

      private

      # Calculates the width specification for the area between the horizontal lines at y1 < y2.
      #
      # The following algorithm is used: Given y1 < y2 as the horizontal lines between which text
      # should be layed out, and a polygon set p that is not self-intersecting but may have
      # arbitrarily nested holes:
      #
      # * Get all segments of the polygon set in sequence, removing the horizontal segments in the
      #   process (done in #prepare).
      #
      # * Make sure that the first segment represents a left-most outside-inside transition,
      #   rotate array of segments (separate for each polygon) if necessary. (done in #prepare)
      #
      # * For the segments of each polygon do separately:
      #
      #   * Ignore all segments except those with min_y < y2 and max_y > y1.
      #
      #   * Determine the min_x and max_x of the segment within y1 <= y2.
      #
      #   * If the segment crosses both, y1 and y2, store min_x/max_x and this segment is
      #     finished. Otherwise traverse the segments in-order to find the next crossing, updating
      #     min_x/max_x in the process. If it crosses the other line, the result is the same as if
      #     a single segment had crossed both lines. Otherwise the result depends on whether the
      #     segment sequence represents an outside-inside transition (it is ignored) or
      #     inside-outside transition (store two pairs min_x/min_x and max_x/max_x).
      #
      # * Order stored x-values.
      #
      # * For each pair [a_min, a_max], [b_min, b_max]
      #   - if inside (index is even): calculate width = b_min - a_max
      #   - if outside: calculate offset = b_max - a_min
      #
      # * Prepend a0_max for first offset and remove all offset-width pairs where width is zero.
      def width(y1, y2)
        result = []

        @polygon_segments.each do |segments|
          temp_result = []
          status = if float_compare(segments.first[0].start_point.y, y2) >= 0 ||
                       float_compare(segments.first[0].start_point.y, y1) <= 0
                     :outside
                   else
                     :inside
                   end

          segments.each do |_segment, miny, maxy, minyx, maxyx, vertical, slope, intercept|
            next unless float_compare(miny, y2) < 0 && float_compare(maxy, y1) > 0

            if vertical
              min_x = max_x = minyx
            else
              min_x = (miny <= y1 ? (y1 - intercept) / slope : (miny <= y2 ? minyx : maxyx))
              max_x = (maxy >= y2 ? (y2 - intercept) / slope : (miny >= y1 ? minyx : maxyx))
              min_x, max_x = max_x, min_x if min_x > max_x
            end

            if float_compare(miny, y1) <= 0 && float_compare(maxy, y2) >= 0 # segment crosses both lines
              temp_result << [min_x, max_x, :crossed_both]
            elsif float_compare(miny, y1) <= 0 # segment crosses bottom line
              if status == :outside
                temp_result << [min_x, max_x, :crossed_bottom]
                status = :inside
              elsif temp_result.last
                temp_result.last[0] = min_x if temp_result.last[0] > min_x
                temp_result.last[1] = max_x if temp_result.last[1] < max_x
                temp_result.last[2] = :crossed_both if temp_result.last[2] == :crossed_top
                temp_result.last[2] = :crossed_bottom if temp_result.last[2] == :crossed_none
                status = :outside
              else
                temp_result << [min_x, max_x, :crossed_bottom]
                status = :outside
              end
            elsif float_compare(maxy, y2) >= 0 # segment crosses top line
              if status == :outside
                temp_result << [min_x, max_x, :crossed_top]
                status = :inside
              elsif temp_result.last
                temp_result.last[0] = min_x if temp_result.last[0] > min_x
                temp_result.last[1] = max_x if temp_result.last[1] < max_x
                temp_result.last[2] = :crossed_both if temp_result.last[2] == :crossed_bottom
                temp_result.last[2] = :crossed_top if temp_result.last[2] == :crossed_none
                status = :outside
              else
                temp_result << [min_x, max_x, :crossed_top]
                status = :outside
              end
            elsif status == :inside && temp_result.last # segment crosses no line
              temp_result.last[0] = min_x if temp_result.last[0] > min_x
              temp_result.last[1] = max_x if temp_result.last[1] < max_x
            else # first segment completely inside
              temp_result << [min_x, max_x, :crossed_none]
            end
          end

          if temp_result.empty? # Ignore degenerate results
            next
          elsif temp_result.size == 1
            # either polygon completely inside or just the top/bottom part, handle the same
            temp_result[0][2] = :crossed_top
          elsif temp_result[0][2] != :crossed_both && temp_result[-1][2] != :crossed_both
            # Handle case where first and last segments only crosses one line
            temp_result[0][0] = temp_result[-1][0] if temp_result[0][0] > temp_result[-1][0]
            temp_result[0][1] = temp_result[-1][1] if temp_result[0][1] < temp_result[-1][1]
            temp_result[0][2] = :crossed_both if temp_result[0][2] != temp_result[-1][2]
            temp_result.pop
          end

          result.concat(temp_result)
        end

        temp_result = result
        outside = true
        temp_result.sort!.map! do |min, max, stat|
          if stat == :crossed_both
            outside = !outside
            [min, max]
          elsif outside
            []
          else
            [min, min, max, max]
          end
        end.flatten!
        temp_result.unshift(0, 0)

        i = 0
        result = []
        while i < temp_result.size - 2
          if i % 4 == 2 # inside the polygon, i.e. width (min2 - max1)
            if (width = temp_result[i + 2] - temp_result[i + 1]) > 0
              result << width
            else
              result.pop # remove last offset and don't add width
            end
          else # outside the polygon, i.e. offset (max2 - min1)
            result << temp_result[i + 3] - temp_result[i + 0]
          end
          i += 2
        end
        result.empty? ? [0, 0] : result
      end

      # Prepare the segments and other data for later use.
      def prepare(offset)
        @max_y = @polygon.bbox.max_y - offset
        @polygon_segments = if @polygon.respond_to?(:polygons)
                              @polygon.polygons.map {|polygon| process_polygon(polygon) }
                            else
                              [process_polygon(@polygon)]
                            end
      end

      # Processes the given polygon segment by segment and returns an array with the following
      # processing information for each segment of the polygon:
      #
      # * the segment itself
      # * minimum y-value
      # * maximum y-value
      # * x-value corresponding to the minimum y-value
      # * x-value corresponding to the maximum y-value
      # * whether the segment is vertical
      # * for non-vertical segments: slope and y-intercept of the segment
      #
      # Additionally, the returned array is rotated sothat the data for the segment with the
      # minimum x-value is the first item (without changing the order).
      def process_polygon(polygon)
        rotate_nr = 0
        min_x = Float::INFINITY
        segments = polygon.each_segment.reject(&:horizontal?)
        segments.map!.with_index do |segment, index|
          (rotate_nr = index; min_x = segment.min.x) if segment.min.x < min_x
          data = [segment]
          if segment.start_point.y < segment.end_point.y
            data.push(segment.start_point.y, segment.end_point.y,
                      segment.start_point.x, segment.end_point.x)
          else
            data.push(segment.end_point.y, segment.start_point.y,
                      segment.end_point.x, segment.start_point.x)
          end
          data.push(segment.vertical?)
          unless segment.vertical?
            data.push(segment.slope)
            data.push((segment.start_point.y - segment.slope * segment.start_point.x).to_f)
          end
          data
        end
        segments.rotate!(rotate_nr)
      end

    end

  end
end
