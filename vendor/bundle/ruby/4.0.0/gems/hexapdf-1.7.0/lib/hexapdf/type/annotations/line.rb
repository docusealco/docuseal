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

module HexaPDF
  module Type
    module Annotations

      # A line annotation is a markup annotation that displays a single straight line.
      #
      # The style of the line annotation, like adding leader lines, changing the colors and so on,
      # can be customized using the provided convenience methods and those from the included
      # modules.
      #
      # Note that while BorderStyling#border_style allows special styling of the line (like
      # :beveled), only a simple line dash pattern is supported by the line annotation.
      #
      # Example:
      #
      #   #>pdf-small
      #   doc.annotations.create_line(doc.pages[0], start_point: [30, 20], end_point: [90, 60]).
      #     border_style(color: "hp-blue", width: 2, style: [3, 1]).
      #     leader_line_length(15).
      #     leader_line_extension_length(10).
      #     leader_line_offset(5).
      #     interior_color("hp-orange").
      #     line_ending_style(start_style: :circle, end_style: :open_arrow).
      #     captioned(true).
      #     contents("Caption").
      #     caption_position(:top).
      #     caption_offset(0, 5).
      #     regenerate_appearance
      #   canvas.line(30, 20, 90, 60).stroke
      #
      # See: PDF2.0 s12.5.6.7, HexaPDF::Type::MarkupAnnotation
      class Line < MarkupAnnotation

        include BorderStyling
        include InteriorColor
        include LineEndingStyling

        define_field :Subtype, type: Symbol, required: true, default: :Line
        define_field :L,       type: PDFArray, required: true
        define_field :BS,      type: :Border
        define_field :LE,      type: PDFArray, default: [:None, :None], version: '1.4'
        define_field :IC,      type: PDFArray, version: '1.4'
        define_field :LL,      type: Numeric, default: 0, version: '1.6'
        define_field :LLE,     type: Numeric, default: 0, version: '1.6'
        define_field :Cap,     type: Boolean, default: false, version: '1.6'
        define_field :IT,      type: Symbol, version: '1.6',
          allowed_values: [:LineArrow, :LineDimension]
        define_field :LLO,     type: Numeric, version: '1.7'
        define_field :CP,      type: Symbol, default: :Inline, version: '1.7',
          allowed_values: [:Inline, :Top]
        define_field :Measure, type: Dictionary, version: '1.7'
        define_field :CO,      type: PDFArray, default: [0, 0], version: '1.7'

        # :call-seq:
        #   line.line                   => [x0, y0, x1, y1]
        #   line.line(x0, y0, x1, y1)   => line
        #
        # Returns the start point and end point of the line as an array of four numbers [x0, y0, x1,
        # y1] when no argument is given. Otherwise sets the start and end point of the line and
        # returns self.
        #
        # This is the only required setting for a line annotation. Note, however, that without
        # setting an appropriate color through #border_style the line will be transparent.
        #
        # Example:
        #
        #   #>pdf-small
        #   doc.annotations.
        #     create_line(doc.pages[0], start_point: [20, 20], end_point: [80, 60]).
        #     regenerate_appearance
        def line(x0 = nil, y0 = nil, x1 = nil, y1 = nil)
          if x0.nil? && y0.nil? && x1.nil? && y1.nil?
            self[:L].to_ary
          elsif !x0 || !y0 || !x1 || !y1
            raise ArgumentError, "All four arguments x0, y0, x1, y1 must be provided"
          else
            self[:L] = [x0, y0, x1, y1]
            self
          end
        end

        # :call-seq:
        #   line.leader_line_length          => leader_line_length
        #   line.leader_line_length(length)  => line
        #
        # Returns the leader line length when no argument is given. Otherwise sets the leader line
        # length and returns self.
        #
        # Leader lines extend from the line's end points perpendicular to the line. If the length
        # value is positive, the leader lines appear in the clockwise direction, otherwise in the
        # opposite direction.
        #
        # Note: The "line's end points" mean the actually drawn line and not the one specified with
        # #line as those two are different when leader lines are involved.
        #
        # A value of zero means that no leader lines are used.
        #
        # Example:
        #
        #   #>pdf-small
        #   doc.annotations.
        #     create_line(doc.pages[0], start_point: [20, 20], end_point: [80, 60]).
        #     leader_line_length(15).
        #     regenerate_appearance
        #   canvas.stroke_color("hp-orange").line(20, 20, 80, 60).stroke
        #
        # Also see: #leader_line_extension_length, #leader_line_offset
        def leader_line_length(length = nil)
          length ? (self[:LL] = length; self) : self[:LL]
        end

        # :call-seq:
        #   line.leader_line_extension_length          => leader_line_extension_length
        #   line.leader_line_extension_length(length)  => line
        #
        # Returns the leader line extension length when no argument is given. Otherwise sets the
        # leader line extension length and returns self.
        #
        # Leader line extensions extend from the line into the opposite direction of the leader
        # lines.
        #
        # The argument +length+ must be non-negative.
        #
        # If the leader line extension length is set to a positive value, the leader line length
        # also needs to be specified.
        #
        # Example:
        #
        #   #>pdf-small
        #   doc.annotations.
        #     create_line(doc.pages[0], start_point: [20, 20], end_point: [80, 60]).
        #     leader_line_length(15).
        #     leader_line_extension_length(5).
        #     regenerate_appearance
        #   canvas.stroke_color("hp-orange").line(20, 20, 80, 60).stroke
        #
        # Also see: #leader_line_length, #leader_line_offset
        def leader_line_extension_length(length = nil)
          if length
            raise ArgumentError, "length must be non-negative" if length < 0
            self[:LLE] = length
            self
          else
            self[:LLE]
          end
        end

        # :call-seq:
        #   line.leader_line_offset          => leader_line_offset
        #   line.leader_line_offset(number)  => line
        #
        # Returns the leader line offset when no argument is given. Otherwise sets the leader line
        # offset and returns self.
        #
        # The leader line offset is a non-negative number that describes the offset of the leader
        # lines from the endpoints of the line.
        #
        # Example:
        #
        #   #>pdf-small
        #   doc.annotations.
        #     create_line(doc.pages[0], start_point: [20, 20], end_point: [80, 60]).
        #     leader_line_length(15).
        #     leader_line_offset(5).
        #     regenerate_appearance
        #   canvas.stroke_color("hp-orange").line(20, 20, 80, 60).stroke
        #
        # Also see: #leader_line_length, #leader_line_extension_length
        def leader_line_offset(offset = nil)
          offset ? (self[:LLO] = offset; self) : self[:LLO] || 0
        end

        # :call-seq:
        #   line.captioned          => true or false
        #   line.captioned(value)   => line
        #
        # Returns +true+ (if the line has a visible caption) or +false+ (no visible caption) when no
        # argument is given. Otherwise sets whether a caption should be visible and returns self.
        #
        # If a caption should be shown, the text specified by the /Contents or /RC entries is shown
        # in the appearance of the line.
        #
        # Example:
        #
        #   #>pdf-small-hide
        #   doc.annotations.
        #     create_line(doc.pages[0], start_point: [20, 20], end_point: [80, 60]).
        #     contents("Inline text").
        #     captioned(true).
        #     regenerate_appearance
        # Also see: #caption_position, #caption_offset
        def captioned(value = nil)
          value ? (self[:Cap] = value; self) : self[:Cap]
        end

        # Maps HexaPDF names to PDF names.
        CAPTION_POSITION_MAP = { # :nodoc:
          Inline: :Inline, inline: :Inline,
          Top: :Top, top: :Top,
        }.freeze
        CAPTION_POSITION_REVERSE_MAP = CAPTION_POSITION_MAP.invert # :nodoc:

        # :call-seq:
        #   line.caption_position          => caption_position
        #   line.caption_position(value)   => line
        #
        # Returns the caption position when no argument is given. Otherwise sets the caption
        # position and returns self.
        #
        # Possible caption positions are (the first one is the HexaPDF name, the second the PDF
        # name):
        #
        # :inline or :Inline::
        #     The caption is centered inside the line (default).
        #
        #       #>pdf-small-hide
        #       doc.annotations.
        #         create_line(doc.pages[0], start_point: [20, 20], end_point: [80, 60]).
        #         contents("Inline text").
        #         captioned(true).
        #         caption_position(:inline).
        #         regenerate_appearance
        #
        # :top or :Top::
        #     The caption is on the top of the line.
        #
        #       #>pdf-small-hide
        #       doc.annotations.
        #         create_line(doc.pages[0], start_point: [20, 20], end_point: [80, 60]).
        #         contents("Top text").
        #         captioned(true).
        #         caption_position(:top).
        #         regenerate_appearance
        #
        # Also see: #captioned, #caption_offset
        def caption_position(value = nil)
          if value
            value = CAPTION_POSITION_MAP.fetch(value) do
              raise ArgumentError, "Invalid caption position: #{value.inspect}"
            end
            self[:CP] = value
            self
          else
            CAPTION_POSITION_REVERSE_MAP[self[:CP]]
          end
        end

        # :call-seq:
        #   line.caption_offset        => caption_offset
        #   line.caption_offset(x, y)  => line
        #
        # Returns the caption offset when no argument is given. Otherwise sets the caption offset
        # and returns self.
        #
        # The caption offset is an array of two numbers that specify the horizontal and vertical
        # offsets of the caption from its normal position. A positive horizontal offset means moving
        # the caption to the right. A positive vertical offset means shifting the caption up.
        #
        # Example:
        #
        #   #>pdf-small-hide
        #   doc.annotations.
        #     create_line(doc.pages[0], start_point: [20, 20], end_point: [80, 60]).
        #     contents("Top text").
        #     captioned(true).
        #     caption_position(:top).
        #     caption_offset(20, 10).
        #     regenerate_appearance
        #
        # Also see: #captioned, #caption_position
        def caption_offset(x = nil, y = nil)
          x || y ? (self[:CO] = [x || 0, y || 0]; self) : self[:CO].to_ary
        end

        private

        def perform_validation #:nodoc:
          super
          if self[:LLE] < 0
            yield('/LLE must be a non-negative number', true)
            self[:LLE] = -self[:LLE]
          end
          if key?(:LLO) && self[:LLO] < 0
            yield('/LLO must be a non-negative number', true)
            self[:LLO] = -self[:LLO]
          end
          if self[:LLE] > 0 && self[:LL] == 0
            yield("/LL required to be non-zero if /LLE is set")
          end
        end

      end

    end
  end
end
