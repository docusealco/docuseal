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

require 'hexapdf/type/annotation'
require 'hexapdf/content'
require 'hexapdf/serializer'

module HexaPDF
  module Type
    module Annotations

      # This module provides a convenience method for getting and setting the border style and is
      # included in the annotations that need it.
      #
      # See: PDF2.0 s12.5.4
      module BorderStyling

        # Describes the border of an annotation.
        #
        # The +color+ property is either +nil+ if the border is transparent or else a device color
        # object - see HexaPDF::Content::ColorSpace.
        #
        # The +style+ property can be one of the following:
        #
        # :solid::      Solid line.
        # :beveled::    Embossed rectangle seemingly raised above the surface of the page.
        # :inset::      Engraved rectangle receeding into the page.
        # :underlined:: Underlined, i.e. only the bottom border is draw.
        # Array:        Dash array describing how to dash the line.
        BorderStyle = Struct.new(:width, :color, :style, :horizontal_corner_radius,
                                 :vertical_corner_radius)

        # :call-seq:
        #   annot.border_style                                      => border_style
        #   annot.border_style(color: 0, width: 1, style: :solid)   => annot
        #
        # Returns a BorderStyle instance representing the border style of the annotation when no
        # argument is given. Otherwise sets the border style of the annotation and returns self.
        #
        # When setting a border style, arguments that are not provided will use the default: a
        # border with a solid, black, 1pt wide line. This also means that multiple invocations will
        # reset *all* prior values.
        #
        # +color+:: The color of the border. See
        #           HexaPDF::Content::ColorSpace.device_color_from_specification for information on
        #           the allowed arguments.
        #
        #           If the special value +:transparent+ is used when setting the color, a
        #           transparent is used. A transparent border will return a +nil+ value when getting
        #           the border color.
        #
        # +width+:: The width of the border. If set to 0, no border is shown.
        #
        # +style+:: Defines how the border is drawn. can be one of the following:
        #
        #           +:solid+::      Draws a solid border.
        #           +:beveled+::    Draws a beveled border.
        #           +:inset+::      Draws an inset border.
        #           +:underlined+:: Draws only the bottom border.
        #           Array::         An array specifying a line dash pattern (see
        #                           HexaPDF::Content::LineDashPattern)
        def border_style(color: nil, width: nil, style: nil)
          if color || width || style
            color = if color == :transparent
                      []
                    else
                      Content::ColorSpace.device_color_from_specification(color || 0).components
                    end
            width ||= 1
            style ||= :solid

            if self[:Subtype] == :Widget
              (self[:MK] ||= {})[:BC] = color
            else
              self[:C] = color
            end
            bs = self[:BS] = {W: width}
            case style
            when :solid then bs[:S] = :S
            when :beveled then bs[:S] = :B
            when :inset then bs[:S] = :I
            when :underlined then bs[:S] = :U
            when Array
              bs[:S] = :D
              bs[:D] = style
            else
              raise ArgumentError, "Unknown value #{style} for style argument"
            end
            self
          else
            result = BorderStyle.new(1, nil, :solid, 0, 0)
            bc = if self[:Subtype] == :Widget
                   (ac = self[:MK]) && (bc = ac[:BC])
                 else
                   self[:C]
                 end
            if bc && !bc.empty?
              result.color = Content::ColorSpace.prenormalized_device_color(bc.value)
            end

            if (bs = self[:BS])
              result.width = bs[:W] if bs.key?(:W)
              result.style = case bs[:S]
                             when :S then :solid
                             when :B then :beveled
                             when :I then :inset
                             when :U then :underlined
                             when :D then bs[:D].value
                             else :solid
                             end
            elsif key?(:Border)
              border = self[:Border]
              result.horizontal_corner_radius = border[0]
              result.vertical_corner_radius = border[1]
              result.width = border[2]
              result.style = border[3] if border[3]
            end

            result
          end
        end

      end

    end
  end
end
