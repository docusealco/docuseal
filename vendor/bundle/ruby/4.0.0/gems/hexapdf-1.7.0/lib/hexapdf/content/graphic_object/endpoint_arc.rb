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

require 'hexapdf/utils/math_helpers'

module HexaPDF
  module Content
    module GraphicObject

      # This class describes an elliptical arc in endpoint parameterization. It allows one to
      # generate an arc from the current point to a given point, similar to Canvas#line_to. Behind
      # the scenes the endpoint parameterization is turned into a center parameterization and drawn
      # with Arc.
      #
      # Note that only the path of the arc itself is added to the canvas. So depending on the
      # use-case the path itself still has to be, for example, stroked.
      #
      # This graphic object is registered under the :endpoint_arc key for use with the
      # HexaPDF::Content::Canvas class.
      #
      # Examples:
      #
      #   #>pdf-center
      #   arc = canvas.graphic_object(:endpoint_arc, x: 50, y: 20, a: 30, b: 10)
      #   canvas.move_to(0, 0).draw(arc).stroke
      #
      # See: Arc, ARC - https://www.w3.org/TR/SVG/implnote.html#ArcImplementationNotes (in the
      # version of about 2016, see
      # https://web.archive.org/web/20160310153722/https://www.w3.org/TR/SVG/implnote.html).
      class EndpointArc

        include Utils
        include Utils::MathHelpers

        # Creates and configures a new endpoint arc object.
        #
        # See #configure for the allowed keyword arguments.
        def self.configure(**kwargs)
          new.configure(**kwargs)
        end

        # x-coordinate of endpoint, defaults to 0.
        #
        # Examples:
        #
        #   #>pdf-center
        #   arc = canvas.graphic_object(:endpoint_arc, x: 50, y: 20, a: 30, b: 20)
        #   canvas.move_to(0, 0).draw(arc).stroke
        #   canvas.stroke_color("hp-blue").move_to(0, 0).draw(arc, x: -50).stroke
        attr_reader :x

        # y-coordinate of endpoint, defaults to 0.
        #
        # Examples:
        #
        #   #>pdf-center
        #   arc = canvas.graphic_object(:endpoint_arc, x: 50, y: 20, a: 30, b: 20)
        #   canvas.move_to(0, 0).draw(arc).stroke
        #   canvas.stroke_color("hp-blue").move_to(0, 0).draw(arc, y: -20).stroke
        attr_reader :y

        # Length of semi-major axis, defaults to 0.
        #
        # Examples:
        #
        #   #>pdf-center
        #   arc = canvas.graphic_object(:endpoint_arc, x: 50, y: 20, a: 30, b: 20)
        #   canvas.move_to(0, 0).draw(arc).stroke
        #   canvas.stroke_color("hp-blue").move_to(0, 0).draw(arc, a: 40).stroke
        attr_reader :a

        # Length of semi-minor axis, defaults to 0.
        #
        # Examples:
        #
        #   #>pdf-center
        #   arc = canvas.graphic_object(:endpoint_arc, x: 50, y: 20, a: 30, b: 20)
        #   canvas.move_to(0, 0).draw(arc).stroke
        #   canvas.stroke_color("hp-blue").move_to(0, 0).draw(arc, b: 50).stroke
        attr_reader :b

        # Inclination in degrees of semi-major axis in respect to x-axis, defaults to 0.
        #
        # Examples:
        #
        #   #>pdf-center
        #   arc = canvas.graphic_object(:endpoint_arc, x: 50, y: 20, a: 30, b: 20)
        #   canvas.move_to(0, 0).draw(arc).stroke
        #   canvas.stroke_color("hp-blue").move_to(0, 0).draw(arc, inclination: 45).stroke
        attr_reader :inclination

        # Large arc choice - if +true+ (the default) use the large arc (i.e. the one spanning more
        # than 180 degrees), else the small arc
        #
        # Examples:
        #
        #   #>pdf-center
        #   arc = canvas.graphic_object(:endpoint_arc, x: 50, y: 20, a: 30, b: 20)
        #   canvas.move_to(0, 0).draw(arc).stroke
        #   canvas.stroke_color("hp-blue").
        #     move_to(0, 0).draw(arc, large_arc: false, clockwise: true).stroke
        attr_reader :large_arc

        # Direction of arc - if +true+ in clockwise direction, else in counterclockwise direction
        # (the default).
        #
        # This is needed, for example, when filling paths using the nonzero winding number rule to
        # achieve different effects.
        #
        # Examples:
        #
        #   #>pdf-center
        #   arc = canvas.graphic_object(:endpoint_arc, x: 50, y: 20, a: 30, b: 20)
        #   canvas.move_to(0, 0).draw(arc).stroke
        #   canvas.stroke_color("hp-blue").move_to(0, 0).draw(arc, clockwise: true).stroke
        attr_reader :clockwise

        # The maximal number of curves used for approximating a complete ellipse.
        #
        # See Arc#max_curves for details.
        #
        # Examples:
        #
        #   #>pdf-center
        #   arc = canvas.graphic_object(:endpoint_arc, x: 50, y: 20, a: 30, b: 20)
        #   canvas.move_to(0, 0).draw(arc, max_curves: 1).stroke
        #   canvas.stroke_color("hp-blue").
        #     move_to(0, 0).draw(arc, max_curves: 2).stroke
        attr_accessor :max_curves

        # Creates an endpoint arc with default values x=0, y=0, a=0, b=0, inclination=0,
        # large_arc=true, clockwise=false (a line to the origin).
        #
        # Examples:
        #
        #   #>pdf-center
        #   canvas.move_to(30, 30).draw(:endpoint_arc).stroke
        def initialize
          @x = @y = 0
          @a = @b = 0
          @inclination = 0
          @large_arc = true
          @clockwise = false
          @max_curves = nil
        end

        # Configures the endpoint arc with
        #
        # * endpoint (+x+, +y+),
        # * semi-major axis +a+,
        # * semi-minor axis +b+,
        # * an inclination in respect to the x-axis of +inclination+ degrees,
        # * the given large_arc flag,
        # * the given clockwise flag and.
        # * the given maximum number of approximation curves.
        #
        # The +large_arc+ option determines whether the large arc, i.e. the one spanning more than
        # 180 degrees, is used (+true+) or the small arc (+false+).
        #
        # The +clockwise+ option determines if the arc is drawn in the counterclockwise direction
        # (+false+) or in the clockwise direction (+true+).
        #
        # Any arguments not specified are not modified and retain their old value, see #initialize
        # for the inital values.
        #
        # Returns self.
        #
        # Examples:
        #
        #   #>pdf-center
        #   arc = canvas.graphic_object(:endpoint_arc)
        #   arc.configure(x: 50, y: 20, a: 30, b: 10)
        #   canvas.move_to(0, 0).draw(arc).stroke
        def configure(x: nil, y: nil, a: nil, b: nil, inclination: nil, large_arc: nil,
                      clockwise: nil, max_curves: nil)
          @x = x if x
          @y = y if y
          @a = a.abs if a
          @b = b.abs if b
          @inclination = inclination % 360 if inclination
          @large_arc = large_arc unless large_arc.nil?
          @clockwise = clockwise unless clockwise.nil?
          @max_curves = max_curves if max_curves

          self
        end

        # Draws the arc on the given Canvas.
        #
        # Since this method doesn't have any other arguments than +canvas+, it is usually better and
        # easier to use Canvas#draw.
        #
        # Examples:
        #
        #   #>pdf-center
        #   arc = canvas.graphic_object(:endpoint_arc, x: 50, y: 20, a: 30, b: 10)
        #   canvas.move_to(-20, -20)
        #   arc.draw(canvas)
        #   canvas.stroke
        def draw(canvas)
          x1, y1 = *canvas.current_point

          # ARC F.6.2 - nothing to do if endpoint is equal to current point
          return if float_equal(x1, @x) && float_equal(y1, @y)

          if @a == 0 || @b == 0
            # ARC F.6.2, F.6.6 - just use a line if it is not really an arc
            canvas.line_to(@x, @y)
          else
            values = compute_arc_values(x1, y1)
            arc = canvas.graphic_object(:arc, **values)
            arc.draw(canvas, move_to_start: false)
          end
        end

        private

        # Compute the center parameterization from the endpoint parameterization.
        #
        # The argument (x1, y1) is the starting point.
        #
        # See: ARC F.6.5, F.6.6
        def compute_arc_values(x1, y1)
          x2 = @x
          y2 = @y
          rx = @a
          ry = @b
          theta = deg_to_rad(@inclination)
          cos_theta = Math.cos(theta)
          sin_theta = Math.sin(theta)

          # F.6.5.1
          x1p = (x1 - x2) / 2.0 * cos_theta + (y1 - y2) / 2.0 * sin_theta
          y1p = (x1 - x2) / 2.0 * -sin_theta + (y1 - y2) / 2.0 * cos_theta

          x1ps = x1p**2
          y1ps = y1p**2
          rxs = rx**2
          rys = ry**2

          # F.6.6.2
          l = x1ps / rxs + y1ps / rys
          if l > 1
            rx *= Math.sqrt(l)
            ry *= Math.sqrt(l)
            rxs = rx**2
            rys = ry**2
          end

          # F.6.5.2
          sqrt = (rxs * rys - rxs * y1ps - rys * x1ps) / (rxs * y1ps + rys * x1ps)
          sqrt = 0 if sqrt.abs < Utils::EPSILON
          sqrt = Math.sqrt(sqrt)
          sqrt *= -1 unless @large_arc == @clockwise
          cxp = sqrt * rx * y1p / ry
          cyp = - sqrt * ry * x1p / rx

          # F.6.5.3
          cx = cos_theta * cxp - sin_theta * cyp + (x1 + x2) / 2.0
          cy = sin_theta * cxp + cos_theta * cyp + (y1 + y2) / 2.0

          # F.6.5.5
          start_angle = compute_angle_to_x_axis((x1p - cxp), (y1p - cyp)) % 360

          # F.6.5.6 (modified bc we just need the end angle)
          end_angle = compute_angle_to_x_axis((-x1p - cxp), (-y1p - cyp)) % 360

          {cx: cx, cy: cy, a: rx, b: ry, start_angle: start_angle, end_angle: end_angle,
           inclination: @inclination, clockwise: @clockwise, max_curves: @max_curves}
        end

        # Computes the angle in degrees between the x-axis and the vector.
        def compute_angle_to_x_axis(vx, vy)
          (vy < 0 ? -1 : 1) * rad_to_deg(Math.acos(vx / Math.sqrt(vx**2 + vy**2)))
        end

      end

    end
  end
end
