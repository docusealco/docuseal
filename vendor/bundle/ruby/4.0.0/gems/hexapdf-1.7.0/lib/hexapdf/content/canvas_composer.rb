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

require 'hexapdf/layout'

module HexaPDF
  module Content

    # The CanvasComposer class allows using the document layout functionality for a single canvas.
    # It works in a similar manner as the HexaPDF::Composer class.
    #
    # See: HexaPDF::Composer, HexaPDF::Document::Layout
    class CanvasComposer

      # The associated canvas.
      attr_reader :canvas

      # The associated HexaPDF::Document instance.
      attr_reader :document

      # The HexaPDF::Layout::Frame instance into which the boxes are laid out.
      attr_reader :frame

      # Creates a new CanvasComposer instance for the given +canvas+.
      #
      # The +margin+ can be any value allowed by HexaPDF::Layout::Style::Quad#set and defines the
      # margin that should not be used during composition. For the remaining area of the canvas a
      # frame object will be created.
      def initialize(canvas, margin: 0)
        @canvas = canvas
        @document = @canvas.context.document

        box = @canvas.context.box
        margin = Layout::Style::Quad.new(margin)
        @frame = Layout::Frame.new(box.left + margin.left,
                                   box.bottom + margin.bottom,
                                   box.width - margin.left - margin.right,
                                   box.height - margin.bottom - margin.top,
                                   context: @canvas.context)
      end

      # Invokes HexaPDF::Document::Layout#style with the given arguments to create/update and return
      # a style object.
      def style(name, base: :base, **properties)
        @document.layout.style(name, base: base, **properties)
      end

      # Draws the given HexaPDF::Layout::Box and returns the last drawn box.
      #
      # The box is drawn into the frame. If it doesn't fit, the box is split. If it still doesn't
      # fit, a new region of the frame is determined and then the process starts again.
      #
      # If none or only some parts of the box fit into the frame, an exception is thrown.
      def draw_box(box)
        while true
          result = @frame.fit(box)
          if result.success?
            @frame.draw(@canvas, result)
            break
          elsif @frame.full?
            raise HexaPDF::Error, "Frame for canvas composer is full and box doesn't fit anymore"
          else
            draw_box, box = @frame.split(result)
            if draw_box
              @frame.draw(@canvas, result)
              (box = draw_box; break) unless box
            elsif !@frame.find_next_region
              raise HexaPDF::Error, "Frame for canvas composer is full and box doesn't fit anymore"
            end
          end
        end
        box
      end

      # Draws any box that can be created using HexaPDF::Document::Layout.
      #
      # This includes all named boxes defined in the 'layout.boxes.map' configuration option.
      #
      # Examples:
      #
      #   #>pdf
      #   canvas.composer(margin: 10) do |composer|
      #     composer.text("Some text", position: :float)
      #     composer.image(machu_picchu, height: 30, align: :right)
      #     composer.lorem_ipsum(sentences: 1, margin: [0, 0, 5])
      #     composer.list(item_spacing: 2) do |list|
      #       composer.document.config['layout.boxes.map'].each do |name, klass|
      #         list.formatted_text([{text: name.to_s, fill_color: "hp-blue-dark"},
      #                              {text: "\n#{klass}"}], font_size: 6)
      #       end
      #     end
      #   end
      #
      # See: HexaPDF::Document::Layout#box
      def method_missing(name, *args, **kwargs, &block)
        if @document.layout.box_creation_method?(name)
          draw_box(@document.layout.send(name, *args, **kwargs, &block))
        else
          super
        end
      end

      def respond_to_missing?(name, _private) # :nodoc:
        @document.layout.box_creation_method?(name) || super
      end

    end

  end
end
