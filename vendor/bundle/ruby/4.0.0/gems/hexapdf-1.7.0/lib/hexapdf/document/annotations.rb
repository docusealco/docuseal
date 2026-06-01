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

require 'hexapdf/dictionary'
require 'hexapdf/error'

module HexaPDF
  class Document

    # This class provides methods for creating and managing the annotations of a PDF file.
    #
    # An annotation is an object that can be added to a certain location on a page, provides a
    # visual appearance and allows for interaction with the user via keyboard and mouse.
    #
    # == Usage
    #
    # To create an annotation either call the general #create method or a specific creation method
    # for an annotation type. After the annotation has been created customize it using the
    # convenience methods on the annotation object. The last step should be the call to
    # +regenerate_appearance+ so that the appearance is generated.
    #
    # See: PDF2.0 s12.5
    class Annotations

      include Enumerable

      # Creates a new Annotations object for the given PDF document.
      def initialize(document)
        @document = document
      end

      # :call-seq:
      #   annotations.create(type, page, **options)      -> annotation
      #
      # Creates a new annotation object with the given +type+ and +page+ by calling the respective
      # +create_type+ method.
      #
      # The +options+ are passed on the specific annotation creation method.
      def create(type, page, *args, **options)
        method_name = "create_#{type}"
        unless respond_to?(method_name)
          raise ArgumentError, "Invalid type specified"
        end
        send("create_#{type}", page, *args, **options)
      end

      # :call-seq:
      #   annotations.create_line(page, start_point:, end_point:)  -> annotation
      #
      # Creates a line annotation from +start_point+ to +end_point+ on the given page and returns
      # it.
      #
      # The line uses a black color and a width of 1pt. It can be further styled using the
      # convenience methods on the returned annotation object.
      #
      # Example:
      #
      #   doc.annotations.create_line(doc.pages[0], start_point: [100, 100], end_point: [130, 180]).
      #     border_style(color: "blue", width: 2).
      #     leader_line_length(10).
      #     regenerate_appearance
      #
      # See: Type::Annotations::Line
      def create_line(page, start_point:, end_point:)
        create_and_add_to_page(:Line, page).
          line(*start_point, *end_point).
          border_style(color: 0, width: 1)
      end

      # :call-seq:
      #   annotations.create_rectangle(page, x, y, width, height)  -> annotation
      #
      # Creates a rectangle (called "square" in the PDF specification) annotation with the
      # lower-left corner at (+x+, +y+) and the given +width+ and +height+.
      #
      # The rectangle uses a black stroke color, no interior color and a line width of 1pt by
      # default. It can be further styled using the convenience methods on the returned annotation
      # object.
      #
      # Example:
      #
      #   #>pdf-small
      #   doc.annotations.create_rectangle(doc.pages[0], 20, 20, 20, 60).
      #     regenerate_appearance
      #
      #   doc.annotations.create_rectangle(doc.pages[0], 60, 20, 20, 60).
      #     border_style(color: "hp-blue", width: 2).
      #     interior_color("hp-orange").
      #     regenerate_appearance
      #
      # See: Type::Annotations::Square
      def create_rectangle(page, x, y, w, h)
        annot = create_and_add_to_page(:Square, page)
        annot[:Rect] = [x, y, x + w, y + h]
        annot.border_style(color: 0, width: 1)
        annot
      end

      # :call-seq:
      #   annotations.create_ellipse(page, cx, cy, a:, b:)  -> annotation
      #
      # Creates an ellipse (called "circle" in the PDF specification) annotation with the center
      # point at (+cx+, +cy+), the semi-major axis +a+ and the semi-minor axis +b+.
      #
      # The ellipse uses a black stroke color, no interior color and a line width of 1pt by
      # default. It can be further styled using the convenience methods on the returned annotation
      # object.
      #
      # Example:
      #
      #   #>pdf-small
      #   doc.annotations.create_ellipse(doc.pages[0], 30, 50, a: 15, b: 20).
      #     regenerate_appearance
      #
      #   doc.annotations.create_ellipse(doc.pages[0], 70, 50, a: 15, b: 20).
      #     border_style(color: "hp-blue", width: 2).
      #     interior_color("hp-orange").
      #     regenerate_appearance
      #
      # See: Type::Annotations::Circle
      def create_ellipse(page, x, y, a:, b:)
        annot = create_and_add_to_page(:Circle, page)
        annot[:Rect] = [x - a, y - b, x + a, y + b]
        annot.border_style(color: 0, width: 1)
        annot
      end

      # :call-seq:
      #   annotations.create_polyline(page, *points)  -> annotation
      #
      # Creates a polyline annotation for the given +points+ (alternating horizontal and vertical
      # coordinates) on the given page and returns it.
      #
      # The polyline uses a black color and a width of 1pt. It can be further styled using the
      # convenience methods on the returned annotation object.
      #
      # Example:
      #
      #   #>pdf-small
      #   doc.annotations.create_polyline(doc.pages[0], 20, 20, 30, 70, 80, 60, 40, 30).
      #     border_style(color: "hp-blue", width: 2, style: [3, 1]).
      #     regenerate_appearance
      #
      # See: Type::Annotations::Polyline
      def create_polyline(page, *points)
        create_and_add_to_page(:PolyLine, page).
          vertices(*points).
          border_style(color: 0, width: 1)
      end

      # :call-seq:
      #   annotations.create_polygon(page, *points)  -> annotation
      #
      # Creates a polygon annotation for the given +points+ (alternating horizontal and vertical
      # coordinates) on the given page and returns it.
      #
      # The polygon uses a black color and a width of 1pt for the border and no interior color. It
      # can be further styled using the convenience methods on the returned annotation object.
      #
      # Example:
      #
      #   #>pdf-small
      #   doc.annotations.create_polygon(doc.pages[0], 20, 20, 30, 70, 80, 60, 40, 30).
      #     border_style(color: "hp-blue", width: 2, style: [3, 1]).
      #     interior_color("hp-orange").
      #     regenerate_appearance
      #
      # See: Type::Annotations::Polygon
      def create_polygon(page, *points)
        create_and_add_to_page(:Polygon, page).
          vertices(*points).
          border_style(color: 0, width: 1)
      end

      private

      # Returns the root of the destinations name tree.
      def create_and_add_to_page(subtype, page)
        annot = @document.add({Type: :Annot, Subtype: subtype})
        (page[:Annots] ||= []) << annot
        annot
      end

    end

  end
end
