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

require 'hexapdf/type/annotations'

module HexaPDF
  module Type
    module Annotations

      # This module provides a convenience method for getting and setting the line ending style for
      # line and polyline annotations.
      #
      # See: PDF2.0 s12.5.6.7
      module LineEndingStyling

        # Maps HexaPDF names to PDF names.
        LINE_ENDING_STYLE_MAP = { # :nodoc:
          Square: :Square, square: :Square,
          Circle: :Circle, circle: :Circle,
          Diamond: :Diamond, diamond: :Diamond,
          OpenArrow: :OpenArrow, open_arrow: :OpenArrow,
          ClosedArrow: :ClosedArrow, closed_arrow: :ClosedArrow,
          None: :None, none: :None,
          Butt: :Butt, butt: :Butt,
          ROpenArrow: :ROpenArrow, ropen_arrow: :ROpenArrow,
          RClosedArrow: :RClosedArrow, rclosed_arrow: :RClosedArrow,
          Slash: :Slash, slash: :Slash,
        }.freeze
        LINE_ENDING_STYLE_REVERSE_MAP = LINE_ENDING_STYLE_MAP.invert # :nodoc:

        # Describes the line ending style, i.e. the +start_style+ and the +end_style+.
        #
        # See LineEndingStyling#line_ending_style for more information.
        LineEndingStyle = Struct.new(:start_style, :end_style)

        # :call-seq:
        #   annot.line_ending_style                                         => style
        #   annot.line_ending_style(start_style: :none, end_style: :none)   => line
        #
        # Returns a LineEndingStyle instance holding the current line ending styles when no argument
        # is given. Otherwise sets the line ending style of the annotation and returns self.
        #
        # When returning the styles, unknown line ending styles are mapped to :none.
        #
        # When setting the line ending style, arguments that are not provided will use the currently
        # defined value or fall back to the default of +:none+.
        #
        # Possible line ending styles (the first one is the HexaPDF name, the second the PDF name):
        #
        # :square or :Square::
        #     A square filled with the annotation's interior colour, if any.
        #
        #       #>pdf-small-hide
        #       doc.annotations.
        #         create_line(doc.pages[0], start_point: [20, 20], end_point: [80, 60]).
        #         interior_color("hp-orange").
        #         line_ending_style(end_style: :square).
        #         regenerate_appearance
        #
        # :circle or :Circle::
        #     A circle filled with the annotation’s interior colour, if any.
        #
        #       #>pdf-small-hide
        #       doc.annotations.
        #         create_line(doc.pages[0], start_point: [20, 20], end_point: [80, 60]).
        #         interior_color("hp-orange").
        #         line_ending_style(end_style: :circle).
        #         regenerate_appearance
        #
        # :diamond or :Diamond::
        #     A diamond shape filled with the annotation’s interior colour, if any.
        #
        #       #>pdf-small-hide
        #       doc.annotations.
        #         create_line(doc.pages[0], start_point: [20, 20], end_point: [80, 60]).
        #         interior_color("hp-orange").
        #         line_ending_style(end_style: :diamond).
        #         regenerate_appearance
        #
        # :open_arrow or :OpenArrow::
        #     Two short lines meeting in an acute angle to form an open arrowhead.
        #
        #       #>pdf-small-hide
        #       doc.annotations.
        #         create_line(doc.pages[0], start_point: [20, 20], end_point: [80, 60]).
        #         interior_color("hp-orange").
        #         line_ending_style(end_style: :open_arrow).
        #         regenerate_appearance
        #
        # :closed_arrow or :ClosedArrow::
        #     Two short lines meeting in an acute angle as in the +:open_arrow+ style and connected
        #     by a third line to form a triangular closed arrowhead filled with the annotation’s
        #     interior colour, if any.
        #
        #       #>pdf-small-hide
        #       doc.annotations.
        #         create_line(doc.pages[0], start_point: [20, 20], end_point: [80, 60]).
        #         interior_color("hp-orange").
        #         line_ending_style(end_style: :closed_arrow).
        #         regenerate_appearance
        #
        # :none or :None::
        #     No line ending.
        #
        #       #>pdf-small-hide
        #       doc.annotations.
        #         create_line(doc.pages[0], start_point: [20, 20], end_point: [80, 60]).
        #         interior_color("hp-orange").
        #         line_ending_style(end_style: :none).
        #         regenerate_appearance
        #
        # :butt or :Butt::
        #     A short line at the endpoint perpendicular to the line itself.
        #
        #       #>pdf-small-hide
        #       doc.annotations.
        #         create_line(doc.pages[0], start_point: [20, 20], end_point: [80, 60]).
        #         interior_color("hp-orange").
        #         line_ending_style(end_style: :butt).
        #         regenerate_appearance
        #
        # :ropen_arrow or :ROpenArrow::
        #     Two short lines in the reverse direction from +:open_arrow+.
        #
        #       #>pdf-small-hide
        #       doc.annotations.
        #         create_line(doc.pages[0], start_point: [20, 20], end_point: [80, 60]).
        #         interior_color("hp-orange").
        #         line_ending_style(end_style: :ropen_arrow).
        #         regenerate_appearance
        #
        # :rclosed_arrow or :RClosedArrow::
        #     A triangular closed arrowhead in the reverse direction from +:closed_arrow+.
        #
        #       #>pdf-small-hide
        #       doc.annotations.
        #         create_line(doc.pages[0], start_point: [20, 20], end_point: [80, 60]).
        #         interior_color("hp-orange").
        #         line_ending_style(end_style: :rclosed_arrow).
        #         regenerate_appearance
        #
        # :slash or :Slash::
        #      A short line at the endpoint approximately 30 degrees clockwise from perpendicular to
        #      the line itself.
        #
        #       #>pdf-small-hide
        #       doc.annotations.
        #         create_line(doc.pages[0], start_point: [20, 20], end_point: [80, 60]).
        #         interior_color("hp-orange").
        #         line_ending_style(end_style: :slash).
        #         regenerate_appearance
        def line_ending_style(start_style: :UNSET, end_style: :UNSET)
          if start_style == :UNSET && end_style == :UNSET
            le = self[:LE]
            LineEndingStyle.new(LINE_ENDING_STYLE_REVERSE_MAP.fetch(le[0], :none),
                                LINE_ENDING_STYLE_REVERSE_MAP.fetch(le[1], :none))
          else
            start_style = self[:LE][0] if start_style == :UNSET
            end_style = self[:LE][1] if end_style == :UNSET
            start_style = LINE_ENDING_STYLE_MAP.fetch(start_style) do
              raise ArgumentError, "Invalid line ending style: #{start_style.inspect}"
            end
            end_style = LINE_ENDING_STYLE_MAP.fetch(end_style) do
              raise ArgumentError, "Invalid line ending style: #{end_style.inspect}"
            end
            self[:LE] = [start_style, end_style]
            self
          end
        end

      end

    end
  end
end
