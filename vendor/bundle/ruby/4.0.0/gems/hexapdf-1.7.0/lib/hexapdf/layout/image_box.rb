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

module HexaPDF
  module Layout

    # An Image box object is used for displaying an image.
    #
    # It can either be used directly or through the HexaPDF::Composer#image method.
    #
    # How an image is displayed inside an image box, depends on whether the +width+ and/or +height+
    # of the box has been set:
    #
    # * If one of them has been set, the other is adjusted to retain the image ratio.
    #
    #     #>pdf-composer100
    #     composer.image(machu_picchu, width: 40)
    #     composer.image(machu_picchu, height: 40)
    #
    # * If both have been set, both are used as is.
    #
    #     #>pdf-composer100
    #     composer.image(machu_picchu, width: 100, height: 30)
    #
    # * If neither has been set, the image is scaled to fit the current region.
    #
    #     #>pdf-composer100
    #     composer.image(machu_picchu)
    #
    # Also see: HexaPDF::Content::Canvas#image
    class ImageBox < Box

      # The image that is shown in the box.
      attr_reader :image

      # Creates a new Image box object for the given +image+ argument which needs to be an image
      # object (e.g. returned by HexaPDF::Document::Images#add).
      def initialize(image:, **kwargs)
        super(**kwargs)
        @image = image
      end

      # Returns +false+ since the image is always drawn if it fits.
      def empty?
        false
      end

      private

      # Fits the image into the current region of the frame, taking the initially set width and
      # height into account (see the class description for details).
      def fit_content(available_width, available_height, _frame)
        image_width = @image.width.to_f
        image_height = @image.height.to_f
        image_ratio = image_width / image_height

        if @initial_width > 0 && @initial_height > 0
          @width = @initial_width
          @height = @initial_height
        elsif @initial_width > 0
          @width = @initial_width
          @height = (@width - reserved_width) / image_ratio + reserved_height
        elsif @initial_height > 0
          @height = @initial_height
          @width = (@height - reserved_height) * image_ratio + reserved_width
        else
          rw = reserved_width
          rh = reserved_height
          ratio = [(available_width - rw) / image_width, (available_height - rh) / image_height].min
          @width = image_width * ratio + rw
          @height = image_height * ratio + rh
        end

        fit_result.success! if float_compare(@width, available_width) <= 0 &&
          float_compare(@height, available_height) <= 0
      end

      # Draws the image onto the canvas at position [x, y].
      def draw_content(canvas, x, y)
        canvas.image(@image, at: [x, y], width: content_width, height: content_height)
      end

    end

  end
end
