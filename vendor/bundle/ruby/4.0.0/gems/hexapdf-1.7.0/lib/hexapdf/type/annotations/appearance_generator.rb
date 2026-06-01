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

require 'hexapdf/error'

module HexaPDF
  module Type
    module Annotations

      # The AppearanceGenerator class provides methods for generating the appearance streams of
      # annotations except those for widgets (see HexaPDF::Type::AcroForm::AppearanceGenerator for
      # those).
      #
      # There is one private create_TYPE_appearance method for each annotation type. This allows
      # subclassing the appearance generator and adjusting the appearances to one's needs.
      #
      # By default, an existing appearance is overwritten and the +:print+ flag is set as well as
      # the +:hidden+ flag unset on the annotation so that the appearance will appear on print-outs.
      #
      # Also note that the annotation's /Rect entry is modified so that it contains the whole
      # generated appearance.
      #
      # The visual appearances are chosen to be similar to those used by Adobe Acrobat and others.
      # By subclassing and overriding the necessary methods it is possible to define custom
      # appearances.
      #
      # The default annotation appearance generator for a document can be changed using the
      # 'annotation.appearance_generator' configuration option.
      #
      # See: PDF2.0 s12.5
      class AppearanceGenerator

        # Creates a new instance for the given +annotation+.
        def initialize(annotation)
          @annot = annotation
          @document = annotation.document
        end

        # Creates the appropriate appearance for the annotation provided on initialization.
        def create_appearance
          case @annot[:Subtype]
          when :Line then create_line_appearance
          when :Square then create_square_circle_appearance(:square)
          when :Circle then create_square_circle_appearance(:circle)
          when :Polygon then create_polygon_polyline_appearance(:polygon)
          when :PolyLine then create_polygon_polyline_appearance(:polyline)
          else
            raise HexaPDF::Error, "Appearance regeneration for #{@annot[:Subtype]} not yet supported"
          end
        end

        private

        # Creates the appropriate appearance for a line annotation.
        #
        # Nearly all the needed information can be taken from the annotation object itself. However,
        # the PDF specification doesn't specify where to take the font related information (font,
        # size, alignment...) from. Therefore this is currently hard-coded as left-aligned Helvetica
        # in size 9.
        #
        # There are also some other decisions that are left to the implementation, like padding
        # around the annotation or the size of the line ending shapes. Those are implemented to be
        # similar to how viewers create the appearance.
        #
        # See: HexaPDF::Type::Annotations::Line
        def create_line_appearance
          # Prepare the annotation
          form = (@annot[:AP] ||= {})[:N] ||=
            @document.add({Type: :XObject, Subtype: :Form, BBox: [0, 0, 0, 0]})
          form.contents = ""
          @annot.flag(:print)
          @annot.unflag(:hidden)

          # Get or calculate all needed values from the annotation
          x0, y0, x1, y1 = @annot.line
          style = @annot.border_style
          line_ending_style = @annot.line_ending_style
          opacity = @annot.opacity
          ll = @annot.leader_line_length
          lle = @annot.leader_line_extension_length
          llo = @annot.leader_line_offset

          angle = Math.atan2(y1 - y0, x1 - x0)
          cos_angle = Math.cos(angle)
          sin_angle = Math.sin(angle)
          line_length = Math.sqrt((y1 - y0) ** 2 + (x1 - x0) ** 2)
          ll_sign = (ll > 0 ? 1 : -1)
          ll_y = ll_sign * (ll.abs + lle + llo)
          line_y = (ll != 0 ? ll_sign * (llo + ll.abs) : 0)

          captioned = @annot.captioned
          contents = @annot.contents.to_s
          if captioned && !contents.empty?
            cap_position = @annot.caption_position
            cap_style = HexaPDF::Layout::Style.new(font: 'Helvetica', font_size: 9,
                                                   fill_color: style.color || 'black',
                                                   line_spacing: 1.25)
            cap_items = @document.layout.text_fragments(contents, style: cap_style)
            layouter = Layout::TextLayouter.new(cap_style)
            cap_result = layouter.fit(cap_items, 2**20, 2**20)
            cap_width = cap_result.lines.max_by(&:width).width + 2 # for padding left/right
            cap_offset = @annot.caption_offset

            cap_x = (line_length - cap_width) / 2.0 + cap_offset[0]
            # Note that the '+ 2' is just so that there is a small gap to the line
            cap_y = line_y + cap_offset[1] +
                    (cap_position == :inline ? cap_result.height / 2.0 : cap_result.height + 2)
          end

          # Calculate annotation rectangle and form bounding box. This considers the line's start
          # and end points as well as the end points of the leader lines, the line ending style and
          # the caption when calculating the bounding box.
          #
          # The result could still be improved by tailoring to the specific line ending style.
          dstart = calculate_line_ending_padding(line_ending_style.start_style, style.width)
          dend = calculate_line_ending_padding(line_ending_style.end_style, style.width)
          if captioned
            cap_ulx = x0 + cos_angle * cap_x - sin_angle * cap_y
            cap_uly = y0 + sin_angle * cap_x + cos_angle * cap_y
          end
          min_x, max_x = [x0, x0 - sin_angle * ll_y, x0 - sin_angle * line_y - cos_angle * dstart,
                          x1, x1 - sin_angle * ll_y, x1 - sin_angle * line_y + cos_angle * dend,
                          *([cap_ulx,
                             cap_ulx + cos_angle * cap_width,
                             cap_ulx - sin_angle * cap_result.height,
                             cap_ulx + cos_angle * cap_width - sin_angle * cap_result.height
                            ] if captioned)
                         ].minmax
          min_y, max_y = [y0, y0 + cos_angle * ll_y,
                          y0 + cos_angle * line_y - ([cos_angle, sin_angle].max) * dstart,
                          y1, y1 + cos_angle * ll_y,
                          y1 + cos_angle * line_y + ([cos_angle, sin_angle].max) * dend,
                          *([cap_uly,
                             cap_uly + sin_angle * cap_width,
                             cap_uly - cos_angle * cap_result.height,
                             cap_uly + sin_angle * cap_width - cos_angle * cap_result.height
                            ] if captioned)
                         ].minmax

          padding = 4 * style.width
          rect = [min_x - padding, min_y - padding, max_x + padding, max_y + padding]
          @annot[:Rect] = rect
          form[:BBox] = rect.dup

          # Set the appropriate graphics state and transform the canvas so that the line is
          # unrotated and its start point at the origin.
          canvas = form.canvas(translate: false)
          canvas.opacity(**opacity.to_h)
          canvas.stroke_color(style.color) if style.color
          canvas.fill_color(@annot.interior_color) if @annot.interior_color
          canvas.line_width(style.width)
          canvas.line_dash_pattern(style.style) if style.style.kind_of?(Array)
          canvas.transform(cos_angle, sin_angle, -sin_angle, cos_angle, x0, y0)

          stroke_op = (style.color ? :stroke : :end_path)
          fill_op = (style.color && @annot.interior_color ? :fill_stroke :
                       (style.color ? :stroke : :fill))

          # Draw leader lines and line
          if ll != 0
            canvas.line(0, ll_sign * llo, 0, ll_y)
            canvas.line(line_length, ll_sign * llo, line_length, ll_y)
          end
          if captioned && cap_position == :inline
            canvas.line(0, line_y, [[0, cap_x].max, line_length].min, line_y)
            canvas.line([[cap_x + cap_width, 0].max, line_length].min, line_y, line_length, line_y)
          else
            canvas.line(0, line_y, line_length, line_y)
          end
          canvas.send(stroke_op)

          # Draw line endings
          if line_ending_style.start_style != :none
            do_fill = draw_line_ending(canvas, line_ending_style.start_style, 0, line_y,
                                       style.width, 0)
            canvas.send(do_fill ? fill_op : stroke_op)
          end
          if line_ending_style.end_style != :none
            do_fill = draw_line_ending(canvas, line_ending_style.end_style, line_length, line_y,
                                       style.width, Math::PI)
            canvas.send(do_fill ? fill_op : stroke_op)
          end

          # Draw caption, adding half of the padding added to cap_width
          cap_result.draw(canvas, cap_x + 1, cap_y) if captioned
        end

        # Creates the appropriate appearance for a square or circle annotation depending on the
        # given +type+ (which can either be +:square+ or +:circle+).
        #
        # The cloudy border effect is not supported.
        #
        # See: HexaPDF::Type::Annotations::Square, HexaPDF::Type::Annotations::Circle
        def create_square_circle_appearance(type)
          # Prepare the annotation
          form = (@annot[:AP] ||= {})[:N] ||=
            @document.add({Type: :XObject, Subtype: :Form, BBox: [0, 0, 0, 0]})
          form.contents = ""
          @annot.flag(:print)
          @annot.unflag(:hidden)

          rect = @annot[:Rect]
          x, y, w, h = rect.left, rect.bottom, rect.width, rect.height
          border_style = @annot.border_style
          interior_color = @annot.interior_color
          opacity = @annot.opacity

          # Take the differences array into account. If it exists, the boundary of the actual
          # rectangle is the one with the differences applied to /Rect.
          #
          # If the differences array doesn't exist, we assume that the /Rect is the rectangle we
          # want to draw, with the line width split on both side (like with Canvas#rectangle). In
          # this case we need to update /Rect accordingly so that the line width on the outside is
          # correctly shown.
          line_width_adjustment = border_style.width / 2.0
          if (rd = @annot[:RD])
            x += rd[0]
            y += rd[3]
            w -= rd[0] + rd[2]
            h -= rd[1] + rd[3]
          else
            @annot[:RD] = [0, 0, 0, 0]
            x = rect.left -= line_width_adjustment
            y = rect.bottom -= line_width_adjustment
            w = rect.width += line_width_adjustment
            h = rect.height += line_width_adjustment
          end
          x += line_width_adjustment
          y += line_width_adjustment
          w -= 2 * line_width_adjustment
          h -= 2 * line_width_adjustment

          x -= rect.left
          y -= rect.bottom
          form[:BBox] = [0, 0, rect.width, rect.height]

          if border_style.color || interior_color
            canvas = form.canvas
            canvas.opacity(**opacity.to_h)
            canvas.stroke_color(border_style.color) if border_style.color
            canvas.fill_color(interior_color) if interior_color
            canvas.line_width(border_style.width)
            canvas.line_dash_pattern(border_style.style) if border_style.style.kind_of?(Array)

            if type == :square
              canvas.rectangle(x, y, w, h)
            else
              canvas.ellipse(x + w / 2.0, y + h / 2.0, a: w / 2.0, b: h / 2.0)
            end

            if border_style.color && interior_color
              canvas.fill_stroke
            elsif border_style.color
              canvas.stroke
            else
              canvas.fill
            end
          end
        end

        # Creates the appropriate appearance for a polygon or polyline annotation depending on the
        # given +type+ (which can either be +:polygon+ or +:polyline+).
        #
        # The cloudy border effect is not supported.
        #
        # See: HexaPDF::Type::Annotations::Polygon, HexaPDF::Type::Annotations::Polyline
        def create_polygon_polyline_appearance(type)
          # Prepare the annotation
          form = (@annot[:AP] ||= {})[:N] ||=
            @document.add({Type: :XObject, Subtype: :Form, BBox: [0, 0, 0, 0]})
          form.contents = ""
          @annot.flag(:print)
          @annot.unflag(:hidden)

          # Get all needed values from the annotation
          vertices = @annot.vertices
          border_style = @annot.border_style
          line_ending_style = @annot.line_ending_style
          opacity = @annot.opacity
          interior_color = @annot.interior_color

          # Calculate the annotation's rectangle as well as the form bounding box
          padding_start = calculate_line_ending_padding(line_ending_style.start_style, border_style.width)
          padding_end = calculate_line_ending_padding(line_ending_style.end_style, border_style.width)
          x_coords, y_coords = vertices.partition.with_index {|_, index| index.even? }
          min_x, max_x = (x_coords + [x_coords[0] + padding_start, x_coords[0] - padding_start,
                                      x_coords[-1] + padding_end, x_coords[-1] - padding_end]).minmax
          min_y, max_y = (y_coords + [y_coords[0] + padding_start, y_coords[0] - padding_start,
                                      y_coords[-1] + padding_end, y_coords[-1] - padding_end]).minmax

          padding = 4 * border_style.width
          rect = [min_x - padding, min_y - padding, max_x + padding, max_y + padding]
          @annot[:Rect] = rect
          form[:BBox] = rect.dup

          return if vertices.length < 4

          # Set the appropriate graphics state
          canvas = form.canvas(translate: false)
          canvas.opacity(**opacity.to_h)
          canvas.stroke_color(border_style.color) if border_style.color
          canvas.fill_color(interior_color) if interior_color
          canvas.line_width(border_style.width)
          canvas.line_dash_pattern(border_style.style) if border_style.style.kind_of?(Array)

          stroke_op = (border_style.color ? :stroke : :end_path)
          fill_op = (border_style.color && interior_color ? :fill_stroke :
                       (border_style.color ? :stroke : (interior_color ? :fill : :end_path)))

          # Draw the polygon/polyline
          canvas.send(type, *vertices)
          canvas.send(type == :polygon ? fill_op : stroke_op)

          return unless type == :polyline

          # Draw line endings
          angle_start = Math.atan2(y_coords[1] - y_coords[0], x_coords[1] - x_coords[0])
          angle_end = Math.atan2(y_coords[-2] - y_coords[-1], x_coords[-2] - x_coords[-1])
          if line_ending_style.start_style != :none
            do_fill = draw_line_ending(canvas, line_ending_style.start_style,
                                       x_coords[0], y_coords[0], border_style.width, angle_start)
            canvas.send(do_fill ? fill_op : stroke_op)
          end
          if line_ending_style.end_style != :none
            do_fill = draw_line_ending(canvas, line_ending_style.end_style,
                                       x_coords[-1], y_coords[-1], border_style.width, angle_end)
            canvas.send(do_fill ? fill_op : stroke_op)
          end

        end

        # Calculates the padding needed around the line endings based on the line ending +style+ and
        # the +border_width+.
        def calculate_line_ending_padding(style, border_width)
          case style
          when :square, :circle, :diamond, :slash, :open_arrow, :closed_arrow
            3 * border_width
          when :ropen_arrow, :rclosed_arrow
            10 * border_width
          else
            0
          end
        end

        # Draws the line ending style +type+ at the position (+x+, +y+) and returns +true+ if the
        # shape needs to be filled.
        #
        # The argument +angle+ specifies the angle at which the line ending style should be drawn.
        #
        # The +line_width+ is needed because the size of the line ending depends on it.
        def draw_line_ending(canvas, type, x, y, line_width, angle)
          lw3 = 3 * line_width

          case type
          when :square
            canvas.rectangle(x - lw3, y - lw3, 2 * lw3, 2 * lw3)
            true
          when :circle
            canvas.circle(x, y, lw3)
            true
          when :diamond
            canvas.polygon(x + lw3, y, x, y + lw3, x - lw3, y, x, y - lw3)
            true
          when :open_arrow, :closed_arrow, :ropen_arrow, :rclosed_arrow
            arrow_cos_up = Math.cos(angle + Math::PI / 6)
            arrow_sin_up = Math.sin(angle + Math::PI / 6)
            arrow_cos_down = Math.cos(angle - Math::PI / 6)
            arrow_sin_down = Math.sin(angle - Math::PI / 6)
            dir = (type == :ropen_arrow || type == :rclosed_arrow ? -1 : 1)
            canvas.polyline(x + dir * arrow_cos_up * 3 * lw3, y + arrow_sin_up * 3 * lw3, x, y,
                            x + dir * arrow_cos_down * 3 * lw3, y + arrow_sin_down * 3 * lw3)
            if type == :closed_arrow || type == :rclosed_arrow
              canvas.close_subpath
              true
            else
              false
            end
          when :butt
            canvas.line(x, y + lw3, x, y - lw3)
            false
          when :slash
            sin_60 = Math.sin(Math::PI / 3)
            cos_60 = Math.cos(Math::PI / 3)
            canvas.line(x + cos_60 * lw3, y + sin_60 * lw3, x - cos_60 * lw3, y - sin_60 * lw3)
            false
          end
        end

      end

    end
  end
end
