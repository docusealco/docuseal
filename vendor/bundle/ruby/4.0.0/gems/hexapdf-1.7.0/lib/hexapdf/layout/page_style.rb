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
require 'hexapdf/layout/style'
require 'hexapdf/layout/frame'

module HexaPDF
  module Layout

    # A PageStyle defines the dimensions of a page, its initial look, the Frame for object placement
    # and which page style should be used next.
    #
    # This class is used by HexaPDF::Composer to style the individual pages.
    class PageStyle

      # The page size.
      #
      # Can be any valid predefined page size (see HexaPDF::Type::Page::PAPER_SIZE) or an array
      # [llx, lly, urx, ury] specifying a custom page size.
      #
      # Example:
      #
      #   style.page_size = :A4
      #   style.page_size = [0, 0, 200, 200]
      attr_accessor :page_size

      # The page orientation, either +:portrait+ or +:landscape+.
      #
      # Only used if #page_size is one of the predefined page sizes and not an array.
      attr_accessor :orientation

      # A callable object that defines the initial content of a page created with #create_page.
      #
      # The callable object is given a canvas and the page style as arguments. It needs to draw the
      # initial content of the page. Note that the graphics state of the canvas is *not* saved
      # before executing the template code and restored afterwards. If this is needed, the object
      # needs to do it itself. The #next_style attribute can optionally be set.
      #
      # Furthermore, the callable object should set the #frame that defines the area on the page
      # where content should be placed. The #create_frame method can be used for easily creating a
      # rectangular frame.
      #
      # Example:
      #
      #   page_style.template = lambda do |canvas, style|
      #     box = canvas.context.box
      #     canvas.fill_color("fd0") do
      #       canvas.rectangle(0, 0, box.width, box.height).fill
      #     end
      #     style.frame = style.create_frame(canvas.context, 72)
      #   end
      attr_accessor :template

      # The Frame object that defines the area for the last page created with #create_page where
      # content should be placed.
      #
      # This value is usually updated during execution of the #template. If the value is not
      # updated, a frame covering the page except for a default margin on all sides is set during
      # #create_page.
      attr_accessor :frame

      # Defines the name of the page style that should be used for the next page.
      #
      # Note that this value can be different each time a new page is created via #create_page.
      #
      # If this attribute is +nil+ (the default), it means that this style should be used again.
      attr_accessor :next_style

      # Creates a new page style instance for the given page size, orientation and next style
      # values. If a block is given, it is used as #template for defining the initial content of a
      # page.
      #
      # Example:
      #
      #   PageStyle.new(page_size: :Letter) do |canvas, style|
      #     style.frame = style.create_frame(canvas.context, 72)
      #     style.next_style = :other
      #     canvas.fill_color("fd0") { canvas.circle(100, 100, 50).fill }
      #   end
      def initialize(page_size: :A4, orientation: :portrait, next_style: nil, &block)
        @page_size = page_size
        @orientation = orientation
        @template = block
        @frame = nil
        @next_style = next_style
      end

      # Creates a new page in the given document using this page style and returns it.
      #
      # If the #frame has not changed during execution of the #template, a default frame covering
      # the whole page except a margin of 36 is assigned.
      def create_page(document)
        frame_before = @frame
        page = document.pages.create(media_box: page_size, orientation: orientation)
        template&.call(page.canvas, self)
        self.frame = create_frame(page, 36) if @frame.equal?(frame_before)
        page
      end

      # Creates a frame based on the given page's box and margin.
      #
      # The +margin+ can be any value allowed by HexaPDF::Layout::Style::Quad#set.
      #
      # *Note*: This is a helper method for use inside the #template callable.
      def create_frame(page, margin = 36)
        box = page.box
        margin = Layout::Style::Quad.new(margin)
        Layout::Frame.new(box.left + margin.left,
                          box.bottom + margin.bottom,
                          box.width - margin.left - margin.right,
                          box.height - margin.bottom - margin.top,
                          context: page)
      end

    end

  end
end
