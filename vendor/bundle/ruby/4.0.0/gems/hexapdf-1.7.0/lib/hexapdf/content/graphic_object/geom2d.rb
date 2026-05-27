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

require 'geom2d'
require 'hexapdf/error'

module HexaPDF
  module Content
    module GraphicObject

      # This class provides support for drawing Geom2D objects like line segments and polygons.
      #
      # By default, the paths for the objects are not only added to the canvas but are also stroked
      # or filled (depending on the specific Geom2D object).
      #
      # Supported Geom2D objects are:
      #
      # * Geom2D::Point
      # * Geom2D::Segment
      # * Geom2D::Polygon
      # * Geom2D::PolygonSet
      #
      # Examples:
      #
      #   #>pdf-center
      #   canvas.draw(:geom2d, object: ::Geom2D::Point(-10, 10))
      #   canvas.draw(:geom2d, object: ::Geom2D::Polygon([10, 10], [30, 20], [0, 50]))
      #
      # See: Geom2D - https://github.com/gettalong/geom2d
      class Geom2D

        # Creates and configures a new Geom2D drawing support object.
        #
        # See #configure for the allowed keyword arguments.
        def self.configure(**kwargs)
          new.configure(**kwargs)
        end

        # The Geom2D object that should be drawn.
        #
        # This attribute *must* be set before drawing.
        attr_accessor :object

        # The radius to use when drawing Geom2D::Point objects, defaults to 1.
        #
        # Examples:
        #
        #   #>pdf-center
        #   canvas.draw(:geom2d, object: ::Geom2D::Point(0, 0))
        #   canvas.draw(:geom2d, object: ::Geom2D::Point(50, 0), point_radius: 5)
        attr_accessor :point_radius

        # Specifies whether only paths should be drawn or if they should be stroked/filled too
        # (the default).
        #
        # Examples:
        #
        #   #>pdf-center
        #   canvas.draw(:geom2d, object: ::Geom2D::Segment([0, 0], [0, 50]))
        #   canvas.draw(:geom2d, object: ::Geom2D::Segment([0, 0], [50, 0]), path_only: true)
        attr_accessor :path_only

        # Creates a Geom2D drawing support object.
        #
        # A call to #configure is mandatory afterwards to set the #object to be drawn.
        def initialize
          @object = nil
          @point_radius = 1
          @path_only = false
        end

        # Configures the Geom2D drawing support object. The following arguments are allowed:
        #
        # :object:: The object that should be drawn. If this argument has not been set before and is
        #           also not given, an error will be raised when calling #draw.
        # :point_radius:: The radius of the points when drawing points.
        # :path_only:: Whether only the path should be drawn.
        #
        # Any arguments not specified are not modified and retain their old value, see the getter
        # methods for the inital values.
        #
        # Returns self.
        #
        # Examples:
        #
        #   #>pdf-center
        #   obj = canvas.graphic_object(:geom2d, object: ::Geom2D::Point(0, 0))
        #   canvas.draw(obj)
        #   canvas.opacity(fill_alpha: 0.5).fill_color("hp-blue").
        #     draw(obj, point_radius: 10)
        def configure(object: nil, point_radius: nil, path_only: nil)
          @object = object if object
          @point_radius = point_radius if point_radius
          @path_only = path_only if path_only
          self
        end

        # Draws the Geom2D object onto the given Canvas.
        #
        # Examples:
        #
        #   #>pdf-center
        #   obj = canvas.graphic_object(:geom2d, object: ::Geom2D::Point(0, 0))
        #   obj.draw(canvas)
        def draw(canvas)
          case @object
          when ::Geom2D::Point then draw_point(canvas)
          when ::Geom2D::Segment then draw_segment(canvas)
          when ::Geom2D::Rectangle then draw_rectangle(canvas)
          when ::Geom2D::Polygon then draw_polygon(canvas)
          when ::Geom2D::PolygonSet then draw_polygon_set(canvas)
          else
            raise HexaPDF::Error, "Object of type #{@object.class} unusable"
          end
        end

        private

        def draw_point(canvas)
          canvas.circle(@object.x, @object.y, @point_radius)
          canvas.fill unless @path_only
        end

        def draw_segment(canvas)
          canvas.line(@object.start_point.x, @object.start_point.y,
                      @object.end_point.x, @object.end_point.y)
          canvas.stroke unless @path_only
        end

        def draw_rectangle(canvas)
          canvas.rectangle(@object.x, @object.y, @object.width, @object.height)
          canvas.stroke unless @path_only
        end

        def draw_polygon(canvas)
          return unless @object.nr_of_vertices > 1
          canvas.move_to(@object[0].x, @object[0].y)
          1.upto(@object.nr_of_vertices - 1) {|i| canvas.line_to(@object[i].x, @object[i].y) }
          canvas.close_subpath
          canvas.stroke unless @path_only
        end

        def draw_polygon_set(canvas)
          return if @object.nr_of_contours == 0
          @object.polygons.each do |poly|
            canvas.move_to(poly[0].x, poly[0].y)
            1.upto(poly.nr_of_vertices - 1) {|i| canvas.line_to(poly[i].x, poly[i].y) }
            canvas.close_subpath
          end
          canvas.stroke unless @path_only
        end

      end

    end
  end
end
