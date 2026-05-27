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
require 'hexapdf/content/graphics_state'

module HexaPDF
  module Layout

    # A Style is a container for properties that describe the appearance of text or graphics.
    #
    # Each property except #font has a default value, so only the desired properties need to be
    # changed.
    #
    # Each property has three associated methods:
    #
    # property_name:: Getter method.
    # property_name(*args) and property_name=:: Setter method.
    # property_name?:: Tester method to see if a value has been set or if the default value has
    #                  already been used.
    class Style

      # Defines how the distance between the baselines of two adjacent text lines is determined:
      #
      # :single::
      #     :proportional with value 1.
      #
      # :double::
      #     :proportional with value 2.
      #
      # :proportional::
      #     The y_min of the first line and the y_max of the second line are multiplied with the
      #     specified value, and the sum is used as baseline distance.
      #
      # :fixed::
      #     The distance between the baselines is set to the specified value.
      #
      # :leading::
      #     The distance between the baselines is set to the sum of the y_min of the first line, the
      #     y_max of the second line and the specified value.
      class LineSpacing

        # The type of line spacing - see LineSpacing
        attr_reader :type

        # The value (needed for some types) - see LineSpacing
        attr_reader :value

        # Creates a new LineSpacing object for the given type which can be any valid line spacing
        # type or a LineSpacing object.
        def initialize(type:, value: 1)
          case type
          when :single
            @type = :proportional
            @value = 1
          when :double
            @type = :proportional
            @value = 2
          when :fixed, :proportional, :leading
            unless value.kind_of?(Numeric)
              raise ArgumentError, "Need a valid number for #{type} line spacing"
            end
            @type = type
            @value = value
          when LineSpacing
            @type = type.type
            @value = type.value
          when Integer, Float
            @type = :proportional
            @value = type
          else
            raise ArgumentError, "Invalid type #{type} for line spacing"
          end
        end

        # Returns the distance between the baselines of the two given Line objects.
        def baseline_distance(line1, line2)
          case type
          when :proportional then (line1.y_min.abs + line2.y_max) * value
          when :fixed then value
          when :leading then line1.y_min.abs + line2.y_max + value
          end
        end

        # Returns the gap between the two given Line objects, i.e. the distance between the y_min of
        # the first line and the y_max of the second line.
        def gap(line1, line2)
          case type
          when :proportional then (line1.y_min.abs + line2.y_max) * (value - 1)
          when :fixed then value - line1.y_min.abs - line2.y_max
          when :leading then value
          end
        end

      end

      # A Quad holds four values and allows them to be accessed by the names top, right, bottom and
      # left. Quads are normally used for holding values pertaining to boxes, like margins, paddings
      # or borders.
      class Quad

        # The value for top.
        attr_accessor :top

        # The value for bottom.
        attr_accessor :bottom

        # The value for left.
        attr_accessor :left

        # The value for right.
        attr_accessor :right

        # Creates a new Quad object. See #set for more information.
        def initialize(obj)
          set(obj)
        end

        # :call-seq:
        #   quad.set(value)     -> quad
        #   quad.set(array)     -> quad
        #   quad.set(hash)      -> quad
        #   quad.set(quad)      -> quad
        #
        # Sets all values of the quad and returns it.
        #
        # * If a single value is provided that is neither a Quad nor an array nor a hash, it is
        #   handled as if an array with one value was given.
        #
        # * If a Quad is provided, its values are used.
        #
        # * If an array is provided, it depends on the number of elemens in it:
        #
        #   * One value: All attributes are set to the same value.
        #   * Two values: Top and bottom are set to the first value, left and right to the second
        #     value.
        #   * Three values: Top is set to the first, left and right to the second, and bottom to the
        #     third value.
        #   * Four or more values: Top is set to the first, right to the second, bottom to the third
        #     and left to the fourth value.
        #
        # * If a hash is provided, the keys +:top+, +:bottom+, +:left+ and +:right+ are used to set
        #   the respective value. All unspecified keys that have not been set before are set to 0.
        def set(obj)
          case obj
          when Quad
            @top = obj.top
            @bottom = obj.bottom
            @left = obj.left
            @right = obj.right
          when Array
            @top = obj[0]
            @bottom = obj[2] || obj[0]
            @left = obj[3] || obj[1] || obj[0]
            @right = obj[1] || obj[0]
          when Hash
            @top = obj[:top] || @top || 0
            @bottom = obj[:bottom] || @bottom || 0
            @left = obj[:left] || @left || 0
            @right = obj[:right] || @right || 0
          else
            @top = @bottom = @left = @right = obj
          end
          self
        end

        # Returns +true+ if the quad effectively contains only one value.
        def simple?
          @top == @bottom && @top == @left && @top == @right
        end

      end

      # Represents the border of a rectangular area.
      class Border

        # The widths of each edge. See Quad.
        attr_reader :width

        # The colors of each edge. See Quad.
        #
        # See: HexaPDF::Content::ColorSpace.device_color_from_specification
        attr_reader :color

        # The styles of each edge. See Quad.
        attr_reader :style

        # Specifies whether the border should be drawn inside the provided rectangle (+false+,
        # default) or on it (+true+).
        attr_accessor :draw_on_bounds

        # Creates a new border style. All arguments can be set to any value that a Quad can process.
        def initialize(width: 0, color: 0, style: :solid, draw_on_bounds: false)
          @width = Quad.new(width)
          @color = Quad.new(color)
          @style = Quad.new(style)
          @draw_on_bounds = draw_on_bounds
        end

        # Duplicates a Border object's properties.
        def initialize_copy(other)
          super
          @width = @width.dup
          @color = @color.dup
          @style = @style.dup
        end

        # Returns +true+ if there is no border.
        def none?
          width.simple? && width.top == 0
        end

        # Draws the border onto the canvas.
        #
        # Depending on #draw_on_bounds the border is drawn inside the rectangle (x, y, w, h) or on
        # it.
        def draw(canvas, x, y, w, h)
          return if none?

          if draw_on_bounds
            x -= width.left / 2.0
            y -= width.bottom / 2.0
            w += (width.left + width.right) / 2.0
            h += (width.top + width.bottom) / 2.0
          end

          canvas.save_graphics_state do
            if width.simple? && color.simple? && style.simple?
              draw_simple_border(canvas, x, y, w, h)
            else
              draw_complex_border(canvas, x, y, w, h)
            end
          end
        end

        private

        # Draws the border assuming that only one width, style and color are used.
        def draw_simple_border(canvas, x, y, w, h)
          offset = width.top / 2.0
          canvas.stroke_color(color.top).
            line_width(width.top).
            line_join_style(:miter).
            miter_limit(10).
            line_cap_style(line_cap_style(:top))

          if width.top > w || width.top > h
            canvas.rectangle(x, y, w, h).clip_path.end_path
          end
          if style.top == :solid
            canvas.line_dash_pattern(0).
              rectangle(x + offset, y + offset, w - 2 * offset, h - 2 * offset).stroke
          else
            canvas.line_dash_pattern(line_dash_pattern(:top, w)).
              line(x, y + h - offset, x + w, y + h - offset).
              line(x + w, y + offset, x, y + offset).stroke
            canvas.line_dash_pattern(line_dash_pattern(:right, h)).
              line(x + w - offset, y + h, x + w - offset, y).
              line(x + offset, y, x + offset, y + h).stroke
          end
        end

        # Draws a complex border, i.e. one where every edge is potentially differently styled.
        def draw_complex_border(canvas, x, y, w, h)
          left = x
          bottom = y
          right = left + w
          top = bottom + h
          inner_left = left + width.left
          inner_bottom = bottom + width.bottom
          inner_right = right - width.right
          inner_top = top - width.top

          if width.top > 0
            canvas.save_graphics_state do
              canvas.polyline(left, top, right, top, inner_right, inner_top,
                              inner_left, inner_top).
                clip_path.end_path
              canvas.stroke_color(color.top).
                line_width(width.top).
                line_cap_style(line_cap_style(:top)).
                line_dash_pattern(line_dash_pattern(:top, w)).
                line(left, top - width.top / 2.0, right, top - width.top / 2.0).stroke
            end
          end

          if width.right > 0
            canvas.save_graphics_state do
              canvas.polyline(right, top, right, bottom, inner_right, inner_bottom,
                              inner_right, inner_top).
                clip_path.end_path
              canvas.stroke_color(color.right).
                line_width(width.right).
                line_cap_style(line_cap_style(:right)).
                line_dash_pattern(line_dash_pattern(:right, h)).
                line(right - width.right / 2.0, top, right - width.right / 2.0, bottom).stroke
            end
          end

          if width.bottom > 0
            canvas.save_graphics_state do
              canvas.polyline(right, bottom, left, bottom, inner_left, inner_bottom,
                              inner_right, inner_bottom).
                clip_path.end_path
              canvas.stroke_color(color.bottom).
                line_width(width.bottom).
                line_cap_style(line_cap_style(:bottom)).
                line_dash_pattern(line_dash_pattern(:bottom, w)).
                line(right, bottom + width.bottom / 2.0, left, bottom + width.bottom / 2.0).stroke
            end
          end

          if width.left > 0
            canvas.save_graphics_state do
              canvas.polyline(left, bottom, left, top, inner_left, inner_top,
                              inner_left, inner_bottom).
                clip_path.end_path
              canvas.stroke_color(color.left).
                line_width(width.left).
                line_cap_style(line_cap_style(:left)).
                line_dash_pattern(line_dash_pattern(:left, h)).
                line(left + width.left / 2.0, bottom, left + width.left / 2.0, top).stroke
            end
          end
        end

        # Returns the line cap style for the given edge name.
        def line_cap_style(edge)
          case style.send(edge)
          when :solid then :butt
          when :dashed then :projecting_square
          when :dashed_round, :dotted then :round
          else
            raise ArgumentError, "Invalid border style specified: #{style.send(edge)}"
          end
        end

        # Returns the line dash pattern for the given edge name. The argument +length+ needs to
        # contain the length of the edge.
        def line_dash_pattern(edge, length)
          case style.send(edge)
          when :solid
            0
          when :dashed, :dashed_round
            # Due to the used line cap styles, a dash of length w appears with a length of 2w. The
            # gap between dashes is nominally 3w but adjusted so that full dashes start and end in
            # the corners.
            w = width.send(edge)
            count = [(length.to_f / (w * 3)).floor, 1].max
            gap = [(length - w * (count + 2)).to_f, 0].max / count
            HexaPDF::Content::LineDashPattern.new([w, gap], w * 0.5 + gap)
          when :dotted
            # Adjust the gap so that full dots appear in the corners.
            w = width.send(edge)
            gap = [(length - w).to_f / (length.to_f / (w * 2)).ceil, 1].max
            HexaPDF::Content::LineDashPattern.new([0, gap], [gap - w * 0.5, 0].max)
          end
        end

      end

      # Represents layers that can be drawn under or over a box.
      #
      # There are two ways to specify layers via #add:
      #
      # * Directly by providing a callable object.
      #
      # * By reference to a callable object or class in the 'style.layers_map' configuration option.
      #   The reference name is looked up in the configuration option using
      #   HexaPDF::Configuration#constantize. If the resulting object is a callable object, it is
      #   used; otherwise it is assumed that it is a class and an object is instantiated, passing in
      #   any options given on #add.
      #
      # The object resolved in this way needs to respond to #call(canvas, box) where +canvas+ is the
      # HexaPDF::Content::Canvas object on which it should be drawn and +box+ is a box-like object
      # (e.g. Box or TextFragment). The coordinate system is translated so that the origin is at the
      # bottom-left corner of the box during the drawing operations.
      class Layers

        # The array holding all raw layer definitions.
        attr_reader :layers

        # Creates a new Layers object popuplated with the given +layers+.
        def initialize(layers = nil)
          @layers = []
          layers&.each {|name, options| add(name, **(options || {})) }
        end

        # Duplicates the array holding the layers.
        def initialize_copy(other)
          super
          @layers = @layers.dup
        end

        # :call-seq:
        #   layers.add {|canvas, box| block}
        #   layers.add(name, **options)
        #
        # Adds a new layer object.
        #
        # The layer object can either be specified as a block or by reference to a configured layer
        # object in 'style.layers_map'. In this case +name+ is used as the reference and the options
        # are passed to layer object if it needs initialization.
        def add(name = nil, **options, &block)
          if block_given? || name.kind_of?(Proc)
            @layers << (block || name)
          elsif name
            @layers << [name, options]
          else
            raise ArgumentError, "Layer object name or block missing"
          end
        end

        # Draws all layer objects onto the canvas at the position [x, y] for the given box.
        def draw(canvas, x, y, box)
          return if none?

          canvas.translate(x, y) do
            each(canvas.context.document.config) do |layer|
              canvas.save_graphics_state { layer.call(canvas, box) }
            end
          end
        end

        # Yields all layer objects. Objects that have been specified via a reference are first
        # resolved using the provided configuration object.
        def each(config) #:yield: layer
          @layers.each do |obj, options|
            obj = config.constantize('style.layers_map', obj) unless obj.respond_to?(:call)
            obj = obj.new(**options) unless obj.respond_to?(:call)
            yield(obj)
          end
        end

        # Returns +true+ if there are no layers defined.
        def none?
          @layers.empty?
        end

      end

      # The LinkLayer class provides support for linking to in-document or remote destinations for
      # Style objects using link annotations. Typical use cases would be linking to a (named)
      # destination on a different page or executing a URI action.
      #
      # See: PDF2.0 s12.5.6.5, Layers, HexaPDF::Type::Annotations::Link
      class LinkLayer

        # Creates a new LinkLayer object.
        #
        # The following arguments are allowed (note that only *one* of +dest+, +uri+, +file+ or
        # +action+ may be specified):
        #
        # +dest+::
        #   The destination array or a name of a named destination for in-document links. If neither
        #   +dest+, +uri+, +file+ nor +action+ is specified, it is assumed that the box has a custom
        #   property named 'link' which is used for the destination.
        #
        # +uri+::
        #   The URI to link to.
        #
        # +file+::
        #   The file that should be opened or, if it refers to an application, the application that
        #   should be launched. Can either be a string or a Filespec object. Also see:
        #   HexaPDF::Type::FileSpecification.
        #
        # +action+::
        #   The PDF action that should be executed.
        #
        # +border+::
        #   If set to +true+, a standard border is used. Also accepts an array that adheres to the
        #   rules for annotation borders.
        #
        # +border_color+::
        #   Defines the border color. Can be an array with 0 (transparent), 1 (grayscale), 3 (RGB)
        #   or 4 (CMYK) values.
        #
        # Examples:
        #   LinkLayer.new(dest: [page, :XYZ, nil, nil, nil], border: true)
        #   LinkLayer.new(uri: "https://my.example.com/path", border: [5 5 2])
        #   LinkLayer.new     # use 'link' custom box property for dest
        def initialize(dest: nil, uri: nil, file: nil, action: nil, border: false, border_color: nil)
          if dest && (uri || file || action) || uri && (file || action) || file && action
            raise ArgumentError, "Only one of dest, uri, file or action is allowed"
          end
          @dest = dest
          @action = if uri
                      {S: :URI, URI: uri}
                    elsif file
                      {S: :Launch, F: file, NewWindow: true}
                    elsif action
                      action
                    end
          @border = case border
                    when false then [0, 0, 0]
                    when true then nil
                    when Array then border
                    else raise ArgumentError, "Invalid value for border: #{border}"
                    end
          @border_color = border_color
        end

        # Creates the needed link annotation if possible, i.e. if the context of the canvas is a
        # page.
        def call(canvas, box)
          return unless canvas.context.type == :Page
          @dest = box.properties['link'] unless @dest || @action

          page = canvas.context
          matrix = canvas.graphics_state.ctm
          quad_points = [*matrix.evaluate(0, 0), *matrix.evaluate(box.width, 0),
                         *matrix.evaluate(box.width, box.height), *matrix.evaluate(0, box.height)]
          x_minmax = quad_points.values_at(0, 2, 4, 6).minmax
          y_minmax = quad_points.values_at(1, 3, 5, 7).minmax
          border_color = case @border_color
                         when [], nil
                           @border_color
                         else
                           canvas.color_from_specification(@border_color).components
                         end
          annot = {
            Subtype: :Link,
            Rect: [x_minmax[0], y_minmax[0], x_minmax[1], y_minmax[1]],
            QuadPoints: quad_points,
            Dest: @dest,
            A: @action,
            Border: @border,
            C: border_color,
          }
          (page[:Annots] ||= []) << page.document.add(annot)
        end

      end

      UNSET = ::Object.new # :nodoc:

      # :call-seq:
      #   Style.create(style)     -> style
      #   Style.create(properties_hash)   -> style
      #
      # Creates a Style object based on the +style+ argument and returns it:
      #
      # * If +style+ is already a Style object, it is just returned.
      #
      # * If +style+ is a hash, a new Style object with the style properties specified by the hash
      # * is created.
      #
      # * If +style+ is +nil+, a new Style object with only default values is created.
      def self.create(style)
        case style
        when self then style
        when Hash then new(**style)
        when nil then new
        else raise ArgumentError, "Invalid argument class #{style.class}"
        end
      end

      # Creates a new Style object.
      #
      # The +properties+ hash may be used to set the initial values of properties by using keys
      # equivalent to the property names.
      #
      # Example:
      #   Style.new(font_size: 15, text_align: :center, text_valign: center)
      def initialize(**properties)
        update(**properties)
        @scaled_item_widths = {}.compare_by_identity
      end

      # Duplicates the complex properties that can be modified, as well as the cache.
      def initialize_copy(other)
        super
        @scaled_item_widths = {}.compare_by_identity
        clear_cache

        @font_features = @font_features.dup if defined?(@font_features)
        @padding = @padding.dup if defined?(@padding)
        @margin = @margin.dup if defined?(@margin)
        @border = @border.dup if defined?(@border)
        @overlays = @overlays.dup if defined?(@overlays)
        @underlays = @underlays.dup if defined?(@underlays)
      end

      # :call-seq:
      #   style.update(**properties)    -> style
      #
      # Updates the style's properties using the key-value pairs specified by the +properties+ hash.
      #
      # Also see: #merge
      def update(**properties)
        properties.each {|key, value| send(key, value) }
        self
      end

      # Yields all set properties.
      def each_property # :yield: property, value
        return to_enum(__method__) unless block_given?
        instance_variables.each do |iv|
          (val = PROPERTIES[iv]) && yield(val, instance_variable_get(iv))
        end
      end

      # :call-seq:
      #   style.merge(other_style)   -> style
      #
      # Merges the set properties of the +other_style+ object into this one.
      #
      # Note that merging is done on a per-property basis. So if a complex property is set on
      # +other_style+ and also on +self+, the +other_style+ value completely overwrites the one from
      # +self+.
      #
      # Also see: #update
      def merge(other)
        other.each_property {|property, value| send(property, value) }
        self
      end

      ##
      # :method: font
      # :call-seq:
      #   font(name = nil)
      #
      # The font to be used, must be set to a valid font wrapper object before it can be used.
      #
      # HexaPDF::Document::Layout handles this property - together with #font_bold and #font_italic
      # - specially in that it resolves a set string or array to a font wrapper object before doing
      # anything else with the style object.
      #
      # This is the only style property without a default value!
      #
      # See: HexaPDF::Content::Canvas#font
      #
      # Examples:
      #
      #   #>pdf-composer100
      #   composer.text("Helvetica", font: composer.document.fonts.add("Helvetica"))
      #   composer.text("Courier", font: "Courier")
      #
      #   helvetica_bold = composer.document.fonts.add("Helvetica", variant: :bold)
      #   composer.text("Helvetica Bold", font: helvetica_bold)
      #   composer.text("Courier Bold", font: "Courier bold")
      #   composer.text("Courier Bold also", font: ["Courier", variant: :bold])

      ##
      # :method: font_bold
      # :call-seq:
      #   font_bold(bold = false)
      #
      # Specifies whether the bold variant of the font is used.
      #
      # Note that this property only has affect if #font is not already set to a font wrapper
      # object and if it is set explicitly (i.e. #font_bold? returns +true+).
      #
      # See #font, #font_italic
      #
      # Examples:
      #
      #   #>pdf-composer100
      #   composer.text("Helvetica bold", font: "Helvetica", font_bold: true)
      #
      #   helvetica_bold = composer.document.fonts.add("Helvetica", variant: :bold)
      #   composer.text("Helvetica bold", font: helvetica_bold, font_bold: false)
      #   composer.text("Helvetica", font: ["Helvetica", {variant: :bold}], font_bold: false)

      ##
      # :method: font_italic
      # :call-seq:
      #   font_italic(bold = false)
      #
      # Specifies whether the italic variant of the font is used.
      #
      # Note that this property only has affect if #font is not already set to a font wrapper
      # object and if it is set explicitly (i.e. #font_italic? returns +true+).
      #
      # See #font, #font_bold.
      #
      # Examples:
      #
      #   #>pdf-composer100
      #   composer.text("Helvetica italic", font: "Helvetica", font_italic: true)
      #
      #   helvetica_bold = composer.document.fonts.add("Helvetica", variant: :italic)
      #   composer.text("Helvetica italic", font: helvetica_bold, font_italic: false)
      #   composer.text("Helvetica", font: ["Helvetica", {variant: :italic}], font_italic: false)

      ##
      # :method: font_size
      # :call-seq:
      #   font_size(size = nil)
      #
      # The font size, defaults to 10.
      #
      # See: HexaPDF::Content::Canvas#font_size
      #
      # Examples:
      #
      #   #>pdf-composer100
      #   composer.text("Default size")
      #   composer.text("Larger size", font_size: 20)

      ##
      # :method: line_height
      # :call-seq:
      #   line_height(size = nil)
      #
      # The font size used for line height calculations, default is +nil+ meaing it defaults to
      # #font_size.
      #
      # This value should never be smaller than the font size since this would lead to overlapping
      # text.
      #
      # Examples:
      #
      #   #>pdf-composer100
      #   composer.text("Line 1")
      #   composer.text("Larger line height", line_height: 30)
      #   composer.text("Line 3")

      ##
      # :method: character_spacing
      # :call-seq:
      #   character_spacing(amount = nil)
      #
      # The character spacing, defaults to 0 (i.e. no additional character spacing).
      #
      # See: HexaPDF::Content::Canvas#character_spacing
      #
      # Examples:
      #
      #   #>pdf-composer100
      #   composer.text("More spacing between characters", character_spacing: 1)

      ##
      # :method: word_spacing
      # :call-seq:
      #   word_spacing(amount = nil)
      #
      # The word spacing, defaults to 0 (i.e. no additional word spacing).
      #
      # See: HexaPDF::Content::Canvas#word_spacing
      #
      # Examples:
      #
      #   #>pdf-composer100
      #   composer.text("More word spacing", word_spacing: 20)

      ##
      # :method: horizontal_scaling
      # :call-seq:
      #   horizontal_scaling(percent = nil)
      #
      # The horizontal scaling, defaults to 100 (in percent, i.e. normal scaling).
      #
      # See: HexaPDF::Content::Canvas#horizontal_scaling
      #
      # Examples:
      #
      #   #>pdf-composer100
      #   composer.text("Horizontal scaling", horizontal_scaling: 150)

      ##
      # :method: text_rise
      # :call-seq:
      #   text_rise(amount = nil)
      #
      # The text rise, i.e. the vertical offset from the baseline, defaults to 0.
      #
      # See: HexaPDF::Content::Canvas#text_rise
      #
      # Examples:
      #
      #   #>pdf-composer100
      #   composer.formatted_text(["Normal", {text: "Up in the air", text_rise: 5}])

      ##
      # :method: font_features
      # :call-seq:
      #   font_features(features = nil)
      #
      # The font features (e.g. kerning, ligatures, ...) that should be applied by the shaping
      # engine, defaults to {} (i.e. no font features are applied).
      #
      # Each feature to be applied is indicated by a key with a truthy value.
      #
      # See: HexaPDF::Layout::TextShaper#shape_text for available features.
      #
      # Examples:
      #
      #   #>pdf-composer100
      #   composer.style(:base, font: ["Times", custom_encoding: true], font_size: 30)
      #   composer.text("Test flight")
      #   composer.text("Test flight", font_features: {kern: true, liga: true})

      ##
      # :method: text_rendering_mode
      # :call-seq:
      #   text_rendering_mode(mode = nil)
      #
      # The text rendering mode, i.e. whether text should be filled, stroked, clipped, invisible or
      # a combination thereof, defaults to :fill. The returned value is always a normalized text
      # rendering mode value.
      #
      # See: HexaPDF::Content::Canvas#text_rendering_mode
      #
      # Examples:
      #
      #   #>pdf-composer100
      #   composer.text("Test flight", font_size: 40, text_rendering_mode: :stroke)

      ##
      # :method: subscript
      # :call-seq:
      #   subscript(enable = false)
      #
      # Render the text as subscript, i.e. lower and in a smaller font size; defaults to false.
      #
      # If superscript is set, it will be deactivated.
      #
      # Examples:
      #
      #   #>pdf-composer100
      #   composer.formatted_text(["Some ", {text: "subscript text", subscript: true}])

      ##
      # :method: superscript
      # :call-seq:
      #   superscript(enable = false)
      #
      # Render the text as superscript, i.e. higher and in a smaller font size; defaults to false.
      #
      # If subscript is set, it will be deactivated.
      #
      # Examples:
      #
      #   #>pdf-composer100
      #   composer.formatted_text(["Some ", {text: "superscript text", superscript: true}])

      ##
      # :method: underline
      # :call-seq:
      #   underline(enable = false)
      #
      # Renders a line underneath the text; defaults to false.
      #
      # Examples:
      #
      #   #>pdf-composer100
      #   composer.text("Underlined text", underline: true)

      ##
      # :method: strikeout
      # :call-seq:
      #   strikeout(enable = false)
      #
      # Renders a line through the text; defaults to false.
      #
      # Examples:
      #
      #   #>pdf-composer100
      #   composer.text("Strikeout text", strikeout: true)

      ##
      # :method: fill_color
      # :call-seq:
      #   fill_color(color = nil)
      #
      # The color used for filling (e.g. text), defaults to black.
      #
      # See: HexaPDF::Content::ColorSpace.device_color_from_specification
      #
      # Examples:
      #
      #   #>pdf-composer100
      #   composer.text("This is some red text", fill_color: "red")

      ##
      # :method: fill_alpha
      # :call-seq:
      #   fill_alpha(alpha = nil)
      #
      # The alpha value applied to filling operations (e.g. text), defaults to 1 (i.e. 100%
      # opaque).
      #
      # See: HexaPDF::Content::Canvas#opacity
      #
      # Examples:
      #
      #   #>pdf-composer100
      #   composer.text("This is some semi-transparent text", fill_alpha: 0.5)

      ##
      # :method: stroke_color
      # :call-seq:
      #   stroke_color(color = nil)
      #
      # The color used for stroking (e.g. text outlines), defaults to black.
      #
      # See: HexaPDF::Content::ColorSpace.device_color_from_specification
      #
      # Examples:
      #
      #   #>pdf-composer100
      #   composer.text("Stroked text", font_size: 40, stroke_color: "red",
      #                 text_rendering_mode: :stroke)

      ##
      # :method: stroke_alpha
      # :call-seq:
      #   stroke_alpha(alpha = nil)
      #
      # The alpha value applied to stroking operations (e.g. text outlines), defaults to 1 (i.e.
      # 100% opaque).
      #
      # See: HexaPDF::Content::Canvas#opacity
      #
      # Examples:
      #
      #   #>pdf-composer100
      #   composer.text("Stroked text", font_size: 40, stroke_alpha: 0.5,
      #                 text_rendering_mode: :stroke)

      ##
      # :method: stroke_width
      # :call-seq:
      #   stroke_width(width = nil)
      #
      # The line width used for stroking operations (e.g. text outlines), defaults to 1.
      #
      # See: HexaPDF::Content::Canvas#line_width
      #
      # Examples:
      #
      #   #>pdf-composer100
      #   composer.text("Stroked text", font_size: 40, stroke_width: 2,
      #                 text_rendering_mode: :stroke)

      ##
      # :method: stroke_cap_style
      # :call-seq:
      #   stroke_cap_style(style = nil)
      #
      # The line cap style used for stroking operations (e.g. text outlines), defaults to :butt. The
      # returned values is always a normalized line cap style value.
      #
      # See: HexaPDF::Content::Canvas#line_cap_style
      #
      # Examples:
      #
      #   #>pdf-composer100
      #   composer.text("Stroked text", font_size: 40, stroke_cap_style: :round,
      #                 text_rendering_mode: :stroke)

      ##
      # :method: stroke_join_style
      # :call-seq:
      #   stroke_join_style(style = nil)
      #
      # The line join style used for stroking operations (e.g. text outlines), defaults to :miter.
      # The returned values is always a normalized line joine style value.
      #
      # See: HexaPDF::Content::Canvas#line_join_style
      #
      # Examples:
      #
      #   #>pdf-composer100
      #   composer.text("Stroked text", font_size: 40, stroke_join_style: :bevel,
      #                 text_rendering_mode: :stroke)

      ##
      # :method: stroke_miter_limit
      # :call-seq:
      #   stroke_miter_limit(limit = nil)
      #
      # The miter limit used for stroking operations (e.g. text outlines) when #stroke_join_style is
      # :miter, defaults to 10.0.
      #
      # See: HexaPDF::Content::Canvas#miter_limit
      #
      # Examples:
      #
      #   #>pdf-composer100
      #   composer.text("Stroked text", font_size: 40, stroke_join_style: :bevel,
      #                 stroke_miter_limit: 1, text_rendering_mode: :stroke)

      ##
      # :method: stroke_dash_pattern
      # :call-seq:
      #   stroke_dash_pattern(pattern = nil)
      #
      # The line dash pattern used for stroking operations (e.g. text outlines), defaults to a solid
      # line.
      #
      # See: HexaPDF::Content::Canvas#line_dash_pattern
      #
      # Examples:
      #
      #   #>pdf-composer100
      #   composer.text("Stroked text", font_size: 40, stroke_dash_pattern: [4, 2],
      #                 text_rendering_mode: :stroke)

      ##
      # :method: text_align
      # :call-seq:
      #   text_align(direction = nil)
      #
      # The horizontal alignment of text, defaults to :left.
      #
      # Possible values:
      #
      # :left::    Left-align the text, i.e. the right side is rugged.
      # :center::  Center the text horizontally.
      # :right::   Right-align the text, i.e. the left side is rugged.
      # :justify:: Justify the text, except for those lines that end in a hard line break.
      #
      # Examples:
      #
      #   #>pdf-composer100
      #   text = "Lorem ipsum dolor sit amet. " * 2
      #   composer.style(:base, border: {width: 1})
      #   composer.text(text, text_align: :left)
      #   composer.text(text, text_align: :center)
      #   composer.text(text, text_align: :right)
      #   composer.text(text, text_align: :justify)

      ##
      # :method: text_valign
      # :call-seq:
      #   text_valign(direction = nil)
      #
      # The vertical alignment of items (normally text) inside a text box, defaults to :top.
      #
      # For :center and :bottom alignment the box will fill the whole available height. If this is
      # not wanted, an explicit height will need to be set for the box.
      #
      # This property is ignored when using position :flow for a text box.
      #
      # Possible values:
      #
      # :top::    Vertically align the items to the top of the box.
      # :center:: Vertically align the items in the center of the box.
      # :bottom:: Vertically align the items to the bottom of the box.
      #
      # Examples:
      #
      #   #>pdf-composer100
      #   composer.style(:base, border: {width: 1})
      #   composer.text("Top aligned", height: 20, text_valign: :top)
      #   composer.text("Center aligned", height: 20, text_valign: :center)
      #   composer.text("Bottom aligned", text_valign: :bottom)

      ##
      # :method: text_indent
      # :call-seq:
      #   text_indent(amount = nil)
      #
      # The indentation to be used for the first line of a sequence of text lines, defaults to 0.
      #
      # Examples:
      #
      #   #>pdf-composer100
      #   composer.text("This is some longer text that wraps around in two lines.",
      #                 text_indent: 10)

      ##
      # :method: line_spacing
      # :call-seq:
      #   line_spacing(type = nil, value = nil)
      #   line_spacing(type:, value: 1)
      #
      # The type of line spacing to be used for text lines, defaults to type :single.
      #
      # This method can set the line spacing in two ways:
      #
      # * Using the positional, mandatory argument +type+ and the optional +value+.
      # * Or a hash with the keys +type+ and +value+.
      #
      # Note that the last line has no additional spacing after it by default. Set #last_line_gap
      # for adding such a spacing.
      #
      # See LineSpacing for supported types of line spacing.
      #
      # Examples:
      #
      #   #>pdf-composer100
      #   composer.text("This is some longer text that wraps around in two lines.",
      #                 line_spacing: 1.5)
      #   composer.text("This is some longer text that wraps around in two lines.",
      #                 line_spacing: :double)
      #   composer.text("This is some longer text that wraps around in two lines.",
      #                 line_spacing: {type: :proportional, value: 1.2})

      ##
      # :method: last_line_gap
      # :call-seq:
      #   last_line_gap(enable = false)
      #
      # Add an appropriately sized gap after the last line of text if enabled, defaults to false.
      #
      # Examples:
      #
      #   #>pdf-composer100
      #   composer.text("This is some longer text that wraps around in two lines.",
      #                 line_spacing: 1.5, last_line_gap: true)
      #   composer.text("There is spacing above this line due to last_line_gap.")

      ##
      # :method: fill_horizontal
      # :call-seq:
      #   fill_horizontal(factor = nil)
      #
      # If set to a positive number, it specifies that the content of the text item should be
      # repeated and appropriate spacing applied so that the remaining space of the line is
      # completely filled.
      #
      # If there are multiple text items with this property set for a single line, the remaining
      # space is split between those items using the set +factors+. For example, if item A has a
      # factor of 1 and item B a factor of 2, the remaining space will be split so that item
      # B will receive twice the space of A.
      #
      # Notes:
      #
      # * This property _must not_ be applied to inline boxes, it only works for text items.
      # * If the filling should be done with spaces, the non-breaking space character \u{00a0} has
      #   to be used.
      #
      # Examples:
      #
      #   #>pdf-composer100
      #   composer.formatted_text(["Left", {text: "\u{00a0}", fill_horizontal: 1},
      #                            "Right"])
      #   composer.formatted_text(["Typical table of contents entry",
      #                            {text: ".", fill_horizontal: 1}, "34"])
      #   composer.formatted_text(["Factor 1", {text: "\u{00a0}", fill_horizontal: 1},
      #                            "Factor 3", {text: "\u{00a0}", fill_horizontal: 3}, "End"])
      #   overlays = [proc {|c, b| c.line(0, b.height / 2.0, b.width, b.height / 2.0).stroke}]
      #   composer.formatted_text([{text: "\u{00a0}", fill_horizontal: 1, overlays: overlays},
      #                            'Centered',
      #                            {text: "\u{00a0}", fill_horizontal: 1, overlays: overlays}])

      ##
      # :method: background_color
      # :call-seq:
      #   background_color(color = nil)
      #
      # The color used for backgrounds, defaults to +nil+ (i.e. no background).
      #
      # See: HexaPDF::Content::ColorSpace.device_color_from_specification
      #
      # Examples:
      #
      #   #>pdf-composer100
      #   composer.text("Some text here", background_color: "lightgrey")

      ##
      # :method: background_alpha
      # :call-seq:
      #   background_alpha(alpha = nil)
      #
      # The alpha value applied to the background when it is colored, defaults to 1 (i.e. 100%
      # opaque).
      #
      # See: HexaPDF::Content::Canvas#opacity
      #
      # Examples:
      #
      #   #>pdf-composer100
      #   composer.text("Some text here", background_color: "red", background_alpha: 0.5)

      ##
      # :method: padding
      # :call-seq:
      #   padding(value = nil)
      #
      # The padding between the border and the contents, defaults to 0 for all four sides.
      #
      # See Style::Quad#set for information on how to set the values.
      #
      # Examples:
      #
      #   #>pdf-composer100
      #   composer.text("Some text here", padding: 10, border: {width: 1})

      ##
      # :method: margin
      # :call-seq:
      #   margin(value = nil)
      #
      # The margin around a box, defaults to 0 for all four sides.
      #
      # See Style::Quad#set for information on how to set the values.
      #
      # Examples:
      #
      #   #>pdf-composer100
      #   composer.text("Some text here", margin: [5, 10], position: :float,
      #                 border: {width: 1})
      #   composer.text("Text starts after floating box and continues below it, " \
      #                 "respecting the margin.", position: :flow)

      ##
      # :method: border
      # :call-seq:
      #   border(value = nil)
      #
      # The border around the contents, defaults to no border for all four sides.
      #
      # The value has to be a hash containing any of the keys :width, :color and :style. The width,
      # color and style of the border can be set independently for each side (see Style::Quad#set).
      #
      # See Border for more details.
      #
      # Examples:
      #
      #   #>pdf-composer100
      #   composer.text("Some text here", border: {
      #                    width: [6, 3],
      #                    color: ["green", "blue", "orange"],
      #                    style: [:solid, :dashed]
      #                 })

      ##
      # :method: overlays
      # :call-seq:
      #   overlays(layers = nil)
      #
      # A Style::Layers object containing all the layers that should be drawn over the box; defaults
      # to no layers being drawn.
      #
      # The +layers+ argument needs to be an array of layer objects. To define a layer either use a
      # callable object taking the canvas and the box as arguments; or use a pre-defined layer using
      # an array of the form [:layer_name, **options]. See Style::Layers for details.
      #
      # Examples:
      #
      #   #>pdf-composer100
      #   composer.text("Some text here", overlays: [
      #     lambda do |canvas, box|
      #       canvas.stroke_color("red").opacity(stroke_alpha: 0.5).
      #         line_width(5).line(0, 0, box.width, box.height).stroke
      #     end,
      #     [:link, uri: "https://hexapdf.gettalong.org"]
      #   ])

      ##
      # :method: underlays
      # :call-seq:
      #   underlays(layers = nil)
      #
      # A Style::Layers object containing all the layers that should be drawn under the box;
      # defaults to no layers being drawn.
      #
      # The +layers+ argument needs to be an array of layer objects. To define a layer either use a
      # callable object taking the canvas and the box as arguments; or use a pre-defined layer using
      # an array of the form [:layer_name, **options]. See Style::Layers for details.
      #
      # Examples:
      #
      #   #>pdf-composer100
      #   composer.text("Some text here", underlays: [
      #     lambda do |canvas, box|
      #       canvas.stroke_color("red").opacity(stroke_alpha: 0.5).
      #         line_width(5).line(0, 0, box.width, box.height).stroke
      #     end,
      #     [:link, uri: "https://hexapdf.gettalong.org"]
      #   ])

      ##
      # :method: position
      # :call-seq:
      #   position(value = nil)
      #
      # Specifies how a box should be positioned in a frame. Defaults to :default.
      #
      # The properties #align and #valign provide alignment information while #mask_mode defines how
      # the to-be-removed region should be constructed.
      #
      # Possible values:
      #
      # :default::
      #     Position the box at the current position. The exact horizontal and vertical position
      #     inside the current region is given via the #align and #valign style properties.
      #
      #     Examples:
      #
      #       #>pdf-composer100
      #       composer.box(:base, width: 40, height: 20,
      #                    style: {align: :right, border: {width: 1}})
      #       composer.box(:base, width: 40, height: 20,
      #                    style: {align: :center, valign: :center, border: {width: 1}})
      #
      # :float::
      #     This is the same as :default except that the used value for #mask_mode when it is set to
      #     :default is :box instead of :fill_frame_horizontal.
      #
      #     Examples:
      #
      #       #>pdf-composer100
      #       composer.box(:base, width: 40, height: 20,
      #                    style: {position: :float, border: {width: 1}})
      #       composer.box(:base, width: 40, height: 20,
      #                    style: {position: :float, border: {color: "hp-blue", width: 1}})
      #
      # :flow::
      #     Flows the content of the box inside the frame around objects.
      #
      #     A box needs to indicate whether it supports this value by implementing the
      #     #supports_position_flow? method and returning +true+ if it does or +false+ if it
      #     doesn't. If a box doesn't support this value, it is positioned as if the value :default
      #     was set.
      #
      #     Notes:
      #
      #     * The properties #align and #valign are not used with this value.
      #     * The rectangular area of the box is the rectangle containing all the flowed content.
      #       That rectangle is used for drawing the border, background and so on.
      #
      #     Examples:
      #
      #       #>pdf-composer100
      #       composer.box(:base, width: 40, height: 20,
      #                    style: {position: :float, border: {width: 1}})
      #       composer.lorem_ipsum(position: :flow)
      #
      # [x, y]::
      #     Position the box with the bottom-left corner at the given absolute position relative to
      #     the bottom-left corner of the frame.
      #
      #     Examples:
      #
      #       #>pdf-composer100
      #       composer.text('Absolute', position: [50, 50], border: {width: 1})
      #       draw_current_frame_shape("red")

      ##
      # :method: align
      # :call-seq:
      #   align(value = nil)
      #
      # Specifies the horizontal alignment of a box inside the current region. Defaults to :left.
      #
      # Possible values:
      #
      # :left:: Align the box to the left side of the current region.
      # :center:: Horizontally center the box in the current region.
      # :right:: Align the box to the right side of the current region.
      #
      # Examples:
      #
      #   #>pdf-composer100
      #   composer.text("Left", border: {width: 1})
      #   draw_current_frame_shape("hp-blue")
      #   composer.text("Center", align: :center, border: {width: 1})
      #   draw_current_frame_shape("hp-orange")
      #   composer.text("Right", align: :right, border: {width: 1})
      #   draw_current_frame_shape("hp-teal")

      ##
      # :method: valign
      # :call-seq:
      #   valign(value = nil)
      #
      # Specifies the vertical alignment of a box inside the current region. Defaults to :top.
      #
      # Possible values:
      #
      # :top:: Align the box to the top side of the current region.
      # :center:: Vertically center the box in the current region.
      # :bottom:: Align the box to the bottom side of the current region.
      #
      # Examples:
      #
      #   #>pdf-composer100
      #   composer.text("Top", mask_mode: :fill_vertical, border: {width: 1})
      #   composer.text("Center", valign: :center, mask_mode: :fill_vertical, border: {width: 1})
      #   composer.text("Bottom", valign: :bottom, border: {width: 1})

      ##
      # :method: mask_mode
      # :call-seq:
      #   mask_mode(value = nil)
      #
      # Specifies how the mask defining the to-be-removed region should be constructed. Defaults to
      # :default.
      #
      # Possible values:
      #
      # :default::
      #     The actually used value depends on the value of #position:
      #
      #     * For :default the used value is :fill_frame_horizontal.
      #     * For :float the used value is :box.
      #     * For :flow the used value is :fill_frame_horizontal.
      #     * For :absolute the used value is :box.
      #
      # :none::
      #     The mask covers nothing (useful for layering boxes over each other).
      #
      #     Examples:
      #
      #       #>pdf-composer100
      #       composer.text('Text on bottom', mask_mode: :none)
      #       composer.text('Text on top', fill_color: 'hp-blue')
      #
      # :box::
      #     The mask covers the box including the margin around the box.
      #
      #     Examples:
      #
      #       #>pdf-composer100
      #       composer.text('Box only mask', mask_mode: :box)
      #       draw_current_frame_shape('hp-blue')
      #       composer.text('Text to the right')
      #
      # :fill_horizontal::
      #     The mask covers the box including the margin around the box and the space to the left
      #     and right in the current region.
      #
      #     Examples:
      #
      #       #>pdf-composer100
      #       composer.text('Standard, whole horizontal space')
      #       draw_current_frame_shape('hp-blue')
      #       composer.text('Text underneath')
      #
      # :fill_frame_horizontal::
      #     The mask covers the box including the margin around the box, the space to the left and
      #     right in the frame and the space to the top of the current region.
      #
      #     Examples:
      #
      #       #>pdf-composer100
      #       composer.frame.remove_area(Geom2D::Rectangle(100, 50, 10, 50))
      #       composer.text('Mask covers frame horizontally', mask_mode: :fill_frame_horizontal)
      #       draw_current_frame_shape('hp-blue')
      #       composer.text('Text underneath')
      #
      # :fill_vertical::
      #     The mask covers the box including the margin around the box and the space to the top
      #     and bottom in the current region.
      #
      #     Examples:
      #
      #       #>pdf-composer100
      #       composer.text('Mask covers vertical space', mask_mode: :fill_vertical)
      #       draw_current_frame_shape('hp-blue')
      #       composer.text('Text to the right')
      #
      # :fill::
      #     The mask covers the current region completely.
      #
      #     Examples:
      #
      #       #>pdf-composer100
      #       composer.text('Mask covers everything', mask_mode: :fill)
      #       composer.text('On the next page')

      ##
      # :method: overflow
      # :call-seq:
      #   overflow(mode = nil)
      #
      # Specifies how overflowing boxes (e.g. the text of a box or the children of a container) with
      # a given initial height should be handled:
      #
      # Possible values:
      #
      # :error::    An error is raised (default).
      # :truncate:: Truncates the overflowing parts.
      #
      # Examples:
      #
      #   #>pdf-composer100
      #   composer.text("This is some longer text that does appear in two lines.")
      #   composer.text("This is some longer text that does not appear in two lines.",
      #                 height: 15, overflow: :truncate)

      ##
      # :method: box_options
      # :call-seq:
      #   box_options(**options)
      #
      # Contains initialization arguments for the box instance that is created with this
      # style. Together with the other style properties this allows the complete specification of a
      # box instance just via a Style instance.
      #
      # Note that this property is only used by the HexaPDF::Document::Layout methods when a box
      # instance is created. If a box instance is created directly, this property has no effect.
      #
      # Examples:
      #
      #   #>pdf-composer100
      #   composer.style(:my_list, box_options: {marker_type: :decimal, item_spacing: 15})
      #   composer.list(style: :my_list) do |list|
      #     list.text("This is some text.")
      #     list.text("This is some other text.")
      #   end


      # :nodoc:
      PROPERTIES = [
        [:font, "raise HexaPDF::Error, 'No font set'"],
        [:font_bold, false],
        [:font_italic, false],
        [:font_size, 10],
        [:line_height, nil],
        [:character_spacing, 0],
        [:word_spacing, 0],
        [:horizontal_scaling, 100],
        [:text_rise, 0],
        [:font_features, {}],
        [:text_rendering_mode, "Content::TextRenderingMode::FILL",
         {setter: "Content::TextRenderingMode.normalize(value)"}],
        [:subscript, false,
         {setter: "value; superscript(false) if value && superscript? && superscript",
          valid_values: [true, false]}],
        [:superscript, false,
         {setter: "value; subscript(false) if value && subscript? && subscript",
          valid_values: [true, false]}],
        [:underline, false, {valid_values: [true, false]}],
        [:strikeout, false, {valid_values: [true, false]}],
        [:fill_color, "default_color"],
        [:fill_alpha, 1],
        [:stroke_color, "default_color"],
        [:stroke_alpha, 1],
        [:stroke_width, 1],
        [:stroke_cap_style, "Content::LineCapStyle::BUTT_CAP",
         {setter: "Content::LineCapStyle.normalize(value)"}],
        [:stroke_join_style, "Content::LineJoinStyle::MITER_JOIN",
         {setter: "Content::LineJoinStyle.normalize(value)"}],
        [:stroke_miter_limit, 10.0],
        [:stroke_dash_pattern, "Content::LineDashPattern.new",
         {setter: "Content::LineDashPattern.normalize(value, phase)", extra_args: ", phase = 0"}],
        [:text_align, :left, {valid_values: [:left, :center, :right, :justify]}],
        [:text_valign, :top, {valid_values: [:top, :center, :bottom]}],
        [:text_indent, 0],
        [:line_spacing, "LineSpacing.new(type: :single)",
         {setter: "LineSpacing.new(**(value.kind_of?(Symbol) || value.kind_of?(Numeric) || " \
           "value.kind_of?(LineSpacing) ? {type: value, value: extra_arg} : value))",
          extra_args: ", extra_arg = nil"}],
        [:last_line_gap, false, {valid_values: [true, false]}],
        [:fill_horizontal, nil],
        [:background_color, nil],
        [:background_alpha, 1],
        [:padding, "Quad.new(0)",
         {setter: "value.kind_of?(Hash) && @name ? @name.set(value) : Quad.new(value)"}],
        [:margin, "Quad.new(0)",
         {setter: "value.kind_of?(Hash) && @name ? @name.set(value) : Quad.new(value)"}],
        [:border, "Border.new", {setter: "Border.new(**value)"}],
        [:overlays, "Layers.new", {setter: "Layers.new(value)"}],
        [:underlays, "Layers.new", {setter: "Layers.new(value)"}],
        [:position, :default],
        [:align, :left, {valid_values: [:left, :center, :right]}],
        [:valign, :top, {valid_values: [:top, :center, :bottom]}],
        [:mask_mode, :default, {valid_values: [:default, :none, :box, :fill_horizontal,
                                               :fill_frame_horizontal, :fill_vertical, :fill]}],
        [:overflow, :error],
        [:box_options, {}],
      ].each do |name, default, options = {}|
        default = default.inspect unless default.kind_of?(String)
        setter = options.delete(:setter) || "value"
        extra_args = options.delete(:extra_args) || ""
        valid_values = options.delete(:valid_values)
        raise ArgumentError, "Invalid keywords: #{options.keys.join(', ')}" unless options.empty?
        valid_values_const = "#{name}_valid_values".upcase
        const_set(valid_values_const, valid_values)
        module_eval(<<-EOF, __FILE__, __LINE__ + 1)
          def #{name}(value = UNSET#{extra_args})
            if value == UNSET
              @#{name} ||= #{default}
            elsif #{valid_values_const} && !#{valid_values_const}.include?(value)
              raise ArgumentError, "\#{value.inspect} is not a valid #{name} value " \\
                "(\#{#{valid_values_const}.map(&:inspect).join(', ')})"
            else
              @#{name} = #{setter}
              self
            end
          end
          def #{name}?
            defined?(@#{name})
          end
        EOF
        alias_method("#{name}=", name)
      end.each_with_object({}) {|arr, hash| hash[:"@#{arr.first}"] = arr.first }

      ##
      # :method: text_segmentation_algorithm
      # :call-seq:
      #   text_segmentation_algorithm(algorithm = nil) {|items| block }
      #
      # The algorithm to use for text segmentation purposes, defaults to
      # TextLayouter::SimpleTextSegmentation.
      #
      # When setting the algorithm, either an object that responds to #call(items) or a block can be
      # used.

      ##
      # :method: text_line_wrapping_algorithm
      # :call-seq:
      #   text_line_wrapping_algorithm(algorithm = nil) {|items, width_block| block }
      #
      # The line wrapping algorithm that should be used, defaults to
      # TextLayouter::SimpleLineWrapping.
      #
      # When setting the algorithm, either an object that responds to #call or a block can be used.
      # See TextLayouter::SimpleLineWrapping#call for the needed method signature.

      [
        [:text_segmentation_algorithm, 'TextLayouter::SimpleTextSegmentation'],
        [:text_line_wrapping_algorithm, 'TextLayouter::SimpleLineWrapping'],
      ].each do |name, default|
        default = default.inspect unless default.kind_of?(String)
        module_eval(<<-EOF, __FILE__, __LINE__ + 1)
          def #{name}(value = UNSET, &block)
            if value == UNSET && !block
              @#{name} ||= #{default}
            else
              @#{name} = (value != UNSET ? value : block)
              self
            end
          end
          def #{name}?
            defined?(@#{name})
          end
        EOF
        alias_method("#{name}=", name)
      end

      # The calculated text rise, taking superscript and subscript into account.
      def calculated_text_rise
        if superscript? && superscript
          text_rise + font_size * 0.33
        elsif subscript? && subscript
          text_rise - font_size * 0.20
        else
          text_rise
        end
      end

      # The calculated font size, taking superscript and subscript into account.
      def calculated_font_size
        ((superscript? && superscript) || (subscript? && subscript) ? 0.583 : 1) * font_size
      end

      # Returns the correct offset from the baseline for the underline.
      def calculated_underline_position
        calculated_text_rise +
          font.wrapped_font.underline_position * font.scaling_factor *
          font.pdf_object.glyph_scaling_factor * calculated_font_size -
          calculated_underline_thickness / 2.0
      end

      # Returns the correct thickness for the underline.
      def calculated_underline_thickness
        font.wrapped_font.underline_thickness * font.scaling_factor *
          font.pdf_object.glyph_scaling_factor * calculated_font_size
      end

      # Returns the correct offset from the baseline for the strikeout line.
      def calculated_strikeout_position
        calculated_text_rise +
          font.wrapped_font.strikeout_position * font.scaling_factor *
          font.pdf_object.glyph_scaling_factor * calculated_font_size -
          calculated_strikeout_thickness / 2.0
      end

      # Returns the correct thickness for the strikeout line.
      def calculated_strikeout_thickness
        font.wrapped_font.strikeout_thickness * font.scaling_factor *
          font.pdf_object.glyph_scaling_factor * calculated_font_size
      end

      # The font size scaled appropriately.
      def scaled_font_size
        @scaled_font_size ||= calculated_font_size * font.pdf_object.glyph_scaling_factor *
          scaled_horizontal_scaling
      end

      # The character spacing scaled appropriately.
      def scaled_character_spacing
        @scaled_character_spacing ||= character_spacing * scaled_horizontal_scaling
      end

      # The word spacing scaled appropriately.
      def scaled_word_spacing
        @scaled_word_spacing ||= word_spacing * scaled_horizontal_scaling
      end

      # The horizontal scaling scaled appropriately.
      def scaled_horizontal_scaling
        @scaled_horizontal_scaling ||= horizontal_scaling / 100.0
      end

      # The ascender of the font scaled appropriately.
      def scaled_font_ascender
        @scaled_font_ascender ||= font.wrapped_font.ascender * font.scaling_factor *
          font.pdf_object.glyph_scaling_factor * font_size
      end

      # The descender of the font scaled appropriately.
      def scaled_font_descender
        @scaled_font_descender ||= font.wrapped_font.descender * font.scaling_factor *
          font.pdf_object.glyph_scaling_factor * font_size
      end

      # The minimum y-coordinate, calculated using the scaled descender of the font and the line
      # height or font size.
      def scaled_y_min
        @scaled_y_min ||= scaled_font_descender * (line_height || font_size) / font_size.to_f +
          calculated_text_rise
      end

      # The maximum y-coordinate, calculated using the scaled ascender of the font and the line
      # height or font size.
      def scaled_y_max
        @scaled_y_max ||= scaled_font_ascender * (line_height || font_size) / font_size.to_f +
          calculated_text_rise
      end

      # Returns the width of the item scaled appropriately (by taking font size, characters spacing,
      # word spacing and horizontal scaling into account).
      #
      # The item may be a (singleton) glyph object or an integer/float, i.e. items that can appear
      # inside a TextFragment.
      def scaled_item_width(item)
        @scaled_item_widths[item] ||=
          if item.kind_of?(Numeric)
            -item * scaled_font_size
          else
            item.width * scaled_font_size + scaled_character_spacing +
              (item.apply_word_spacing? ? scaled_word_spacing : 0)
          end
      end

      # Clears all cached values.
      #
      # This method needs to be called if the following style properties are changed and values were
      # already cached: font, font_size, character_spacing, word_spacing, horizontal_scaling,
      # ascender, descender.
      def clear_cache
        @scaled_font_size = @scaled_character_spacing = @scaled_word_spacing = nil
        @scaled_horizontal_scaling = @scaled_font_ascender = @scaled_font_descender = nil
        @scaled_y_min = @scaled_y_max = nil
        @scaled_item_widths.clear
      end

      private

      # Returns the default color for an empty PDF page, i.e. black.
      def default_color
        GlobalConfiguration.constantize('color_space.map', :DeviceGray).new.default_color
      end

    end

  end
end
