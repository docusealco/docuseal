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

module HexaPDF
  module Content
    module GraphicObject

      # This graphic object represents a solid elliptical arc, i.e. an arc that has an inner and
      # an outer set of a/b values.
      #
      # Note that only the path itself is added to the canvas. So depending on the use-case the path
      # itself still has to be, for example, stroked.
      #
      # This graphic object is registered under the :solid_arc key for use with the
      # HexaPDF::Content::Canvas class.
      #
      # It can be used to create
      #
      # * an (*elliptical*) *disk* (when the inner a/b are zero and the difference between start and
      #   end angles is greater than or equal to 360),
      #
      #     #>pdf-center
      #     canvas.fill_color("hp-blue").
      #       draw(:solid_arc, outer_a: 80, outer_b: 50).
      #       fill_stroke
      #
      # * an (*elliptical*) *sector* (when the inner a/b are zero and the difference between start
      #   and end angles is less than 360),
      #
      #     #>pdf-center
      #     canvas.fill_color("hp-blue").
      #       draw(:solid_arc, outer_a: 80, outer_b: 50, start_angle: 20, end_angle: 230).
      #       fill_stroke
      #
      # * an (*elliptical*) *annulus* (when the inner a/b are nonzero and the difference between
      #   start and end angles is greater than or equal to 360),
      #
      #     #>pdf-center
      #     canvas.fill_color("hp-blue").
      #       draw(:solid_arc, outer_a: 80, outer_b: 50, inner_a: 70, inner_b: 30).
      #       fill_stroke
      #
      # * and an (*elliptical*) *annular sector* (when the inner a/b are nonzero and the difference
      #   between start and end angles is less than 360)
      #
      #     #>pdf-center
      #     canvas.fill_color("hp-blue").
      #       draw(:solid_arc, outer_a: 80, outer_b: 50, inner_a: 70, inner_b: 30,
      #            start_angle: 20, end_angle: 230).
      #       fill_stroke
      #
      # See: Arc
      class SolidArc

        # Creates and configures a new solid arc object.
        #
        # See #configure for the allowed keyword arguments.
        def self.configure(**kwargs)
          new.configure(**kwargs)
        end

        # x-coordinate of center point, defaults to 0.
        #
        # Examples:
        #
        #   #>pdf-center
        #   solid_arc = canvas.graphic_object(:solid_arc, outer_a: 30, outer_b: 20,
        #                                     inner_a: 20, inner_b: 10)
        #   canvas.draw(solid_arc).stroke
        #   canvas.stroke_color("hp-blue").draw(solid_arc, cx: 50).stroke
        attr_reader :cx

        # y-coordinate of center point, defaults to 0.
        #
        # Examples:
        #
        #   #>pdf-center
        #   solid_arc = canvas.graphic_object(:solid_arc, outer_a: 30, outer_b: 20,
        #                                     inner_a: 20, inner_b: 10)
        #   canvas.draw(solid_arc).stroke
        #   canvas.stroke_color("hp-blue").draw(solid_arc, cy: 50).stroke
        attr_reader :cy

        # Length of inner semi-major axis which (without altering the #inclination) is parallel to
        # the x-axis, defaults to 0.
        #
        # Examples:
        #
        #   #>pdf-center
        #   solid_arc = canvas.graphic_object(:solid_arc, cx: -50, outer_a: 30, outer_b: 20,
        #                                     inner_a: 20, inner_b: 10)
        #   canvas.draw(solid_arc).stroke
        #   canvas.stroke_color("hp-blue").draw(solid_arc, cx: 50, inner_a: 5).stroke
        attr_reader :inner_a

        # Length of inner semi-minor axis which (without altering the #inclination) is parallel to
        # the y-axis, defaults to 0.
        #
        # Examples:
        #
        #   #>pdf-center
        #   solid_arc = canvas.graphic_object(:solid_arc, cx: -50, outer_a: 30, outer_b: 20,
        #                                     inner_a: 20, inner_b: 10)
        #   canvas.draw(solid_arc).stroke
        #   canvas.stroke_color("hp-blue").draw(solid_arc, cx: 50, inner_b: 20).stroke
        attr_reader :inner_b

        # Length of outer semi-major axis which (without altering the #inclination) is parallel to
        # the x-axis, defaults to 1.
        #
        # Examples:
        #
        #   #>pdf-center
        #   solid_arc = canvas.graphic_object(:solid_arc, cx: -50, outer_a: 30, outer_b: 20,
        #                                     inner_a: 20, inner_b: 10)
        #   canvas.draw(solid_arc).stroke
        #   canvas.stroke_color("hp-blue").draw(solid_arc, cx: 50, outer_a: 45).stroke
        attr_reader :outer_a

        # Length of outer semi-minor axis which (without altering the #inclination) is parallel to the
        # y-axis, defaults to 1.
        #
        # Examples:
        #
        #   #>pdf-center
        #   solid_arc = canvas.graphic_object(:solid_arc, cx: -50, outer_a: 30, outer_b: 20,
        #                                     inner_a: 20, inner_b: 10)
        #   canvas.draw(solid_arc).stroke
        #   canvas.stroke_color("hp-blue").draw(solid_arc, cx: 50, outer_b: 40).stroke
        attr_reader :outer_b

        # Start angle of the solid arc in degrees, defaults to 0.
        #
        # Examples:
        #
        #   #>pdf-center
        #   solid_arc = canvas.graphic_object(:solid_arc, cx: -50, outer_a: 30, outer_b: 20,
        #                                     inner_a: 20, inner_b: 10)
        #   canvas.draw(solid_arc).stroke
        #   canvas.stroke_color("hp-blue").draw(solid_arc, cx: 50, start_angle: 60).stroke
        attr_reader :start_angle

        # End angle  of the solid arc in degrees, defaults to 0.
        #
        # Examples:
        #
        #   #>pdf-center
        #   solid_arc = canvas.graphic_object(:solid_arc, cx: -50, outer_a: 30, outer_b: 20,
        #                                     inner_a: 20, inner_b: 10)
        #   canvas.draw(solid_arc).stroke
        #   canvas.stroke_color("hp-blue").draw(solid_arc, cx: 50, end_angle: 120).stroke
        attr_reader :end_angle

        # Inclination in degrees of semi-major axis in respect to x-axis, defaults to 0.
        #
        # Examples:
        #
        #   #>pdf-center
        #   solid_arc = canvas.graphic_object(:solid_arc, cx: -50, outer_a: 30, outer_b: 20,
        #                                     inner_a: 20, inner_b: 10)
        #   canvas.draw(solid_arc).stroke
        #   canvas.stroke_color("hp-blue").draw(solid_arc, cx: 50, inclination: 40).stroke
        attr_reader :inclination

        # Creates a solid arc with default values (a unit disk at the origin).
        #
        # Examples:
        #
        #   #>pdf-center
        #   canvas.draw(:solid_arc).stroke
        def initialize
          @cx = @cy = 0
          @inner_a = @inner_b = 0
          @outer_a = @outer_b = 1
          @start_angle = 0
          @end_angle = 0
          @inclination = 0
        end

        # Configures the solid arc with
        #
        # * center point (+cx+, +cy+),
        # * inner semi-major axis +inner_a+,
        # * inner semi-minor axis +inner_b+,
        # * outer semi-major axis +outer_a+,
        # * outer semi-minor axis +outer_b+,
        # * start angle of +start_angle+ degrees,
        # * end angle of +end_angle+ degrees and
        # * an inclination in respect to the x-axis of +inclination+ degrees.
        #
        # Any arguments not specified are not modified and retain their old value, see #initialize
        # for the inital values.
        #
        # Returns self.
        #
        # Examples:
        #
        #   #>pdf-center
        #   solid_arc = canvas.graphic_object(:solid_arc)
        #   solid_arc.configure(outer_a: 30, outer_b: 20, inner_a: 20, inner_b: 10)
        #   canvas.draw(solid_arc).stroke
        def configure(cx: nil, cy: nil, inner_a: nil, inner_b: nil, outer_a: nil, outer_b: nil,
                      start_angle: nil, end_angle: nil, inclination: nil)
          @cx = cx if cx
          @cy = cy if cy
          @inner_a = inner_a.abs if inner_a
          @inner_b = inner_b.abs if inner_b
          @outer_a = outer_a.abs if outer_a
          @outer_b = outer_b.abs if outer_b
          @start_angle = start_angle % 360 if start_angle
          @end_angle = end_angle % 360 if end_angle
          @inclination = inclination if inclination

          self
        end

        # Draws the solid arc on the given Canvas.
        #
        # Examples:
        #
        #   #>pdf-center
        #   solid_arc = canvas.graphic_object(:solid_arc, outer_a: 30, outer_b: 20,
        #                                     inner_a: 20, inner_b: 10)
        #   solid_arc.draw(canvas)
        #   canvas.stroke
        def draw(canvas)
          angle_difference = (@end_angle - @start_angle).abs
          if @inner_a == 0 && @inner_b == 0
            arc = canvas.graphic_object(:arc, cx: @cx, cy: @cy, a: @outer_a, b: @outer_b,
                                        start_angle: @start_angle, end_angle: @end_angle,
                                        inclination: @inclination, clockwise: false)
            if angle_difference == 0
              arc.draw(canvas)
            else
              canvas.move_to(@cx, @cy)
              canvas.line_to(*arc.start_point)
              arc.draw(canvas, move_to_start: false)
            end
          else
            inner = canvas.graphic_object(:arc, cx: @cx, cy: @cy, a: @inner_a, b: @inner_b,
                                          start_angle: @end_angle, end_angle: @start_angle,
                                          inclination: @inclination, clockwise: true)
            outer = canvas.graphic_object(:arc, cx: @cx, cy: @cy, a: @outer_a, b: @outer_b,
                                          start_angle: @start_angle, end_angle: @end_angle,
                                          inclination: @inclination, clockwise: false)
            outer.draw(canvas)
            if angle_difference == 0
              canvas.close_subpath
              inner.draw(canvas)
            else
              canvas.line_to(*inner.start_point)
              inner.draw(canvas, move_to_start: false)
            end
          end
          canvas.close_subpath
        end

      end

    end
  end
end
