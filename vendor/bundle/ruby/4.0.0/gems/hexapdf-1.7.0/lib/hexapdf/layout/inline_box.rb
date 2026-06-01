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

require 'hexapdf/layout/box'
require 'hexapdf/layout/frame'

module HexaPDF
  module Layout

    # An InlineBox wraps a regular Box so that it can be used as an item for a Line. This enables
    # inline graphics.
    #
    # When an inline box gets placed on a line, the method #fit_wrapped_box is called to fit the
    # wrapped box. This allows the wrapped box to correctly set its width and height which are
    # needed by the TextLayouter algorithm.
    #
    # Note: It is *mandatory* that the wrapped box sets its width and height without relying on the
    # dimensions of the frame's current region.
    class InlineBox

      # Creates an InlineBox that wraps a basic Box. All arguments (except +valign+) and the block
      # are passed to Box::create.
      #
      # See ::new for the +valign+ argument.
      def self.create(valign: :baseline, **args, &block)
        new(Box.create(**args, &block), valign: valign)
      end

      # The vertical alignment of the box.
      #
      # Can be any supported value except :text - see Line for all possible values.
      attr_reader :valign

      # The wrapped Box object.
      attr_reader :box

      # Creates a new InlineBox object wrapping +box+.
      #
      # The +valign+ argument can be used to specify the vertical alignment of the box relative to
      # other items in the Line.
      def initialize(box, valign: :baseline)
        @box = box
        @valign = valign
      end

      # Returns the style of the wrapped box.
      def style
        box.style
      end

      # Returns +true+ if this inline box is just a placeholder without drawing operations.
      def empty?
        box.empty?
      end

      # Returns the width of the wrapped box plus its left and right margins.
      def width
        box.width + box.style.margin.left + box.style.margin.right
      end

      # Returns the height of the wrapped box plus its top and bottom margins.
      def height
        box.height + box.style.margin.top + box.style.margin.bottom
      end

      # Draws the wrapped box. If the box has margins specified, the x and y offsets are correctly
      # adjusted.
      def draw(canvas, x, y)
        @fit_result.draw(canvas, dx: x, dy: y)
      end

      # The minimum x-coordinate which is always 0.
      def x_min
        0
      end

      # The maximum x-coordinate which is equivalent to the width of the inline box.
      def x_max
        width
      end

      # The minimum y-coordinate which is always 0.
      def y_min
        0
      end

      # The maximum y-coordinate which is equivalent to the height of the inline box.
      def y_max
        height
      end

      # Fits the wrapped box.
      #
      # If the +frame+ argument is +nil+, a custom frame is created. Otherwise the given +frame+ is
      # used for creating an appropriate child frame for the fitting operation.
      #
      # After this operation the caller is responsible for checking the actual width and height of
      # the inline box and whether it really fits.
      def fit_wrapped_box(frame = nil)
        @fit_result = box.fit(100_000, 100_000, frame || Frame.new(0, 0, 100_000, 100_000))
        margin = box.style.margin if box.style.margin?
        @fit_result.x = margin&.left.to_i
        @fit_result.y = margin&.bottom.to_i
        @fit_result.mask = Geom2D::Rectangle(0, 0, @fit_result.x + box.width + margin&.right.to_i,
                                             @fit_result.y + box.height + margin&.top.to_i)
      end

    end

  end
end
