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
require 'hexapdf/layout/text_fragment'
require 'hexapdf/layout/inline_box'
require 'hexapdf/layout/line'
require 'hexapdf/layout/numeric_refinements'

module HexaPDF
  module Layout

    # Arranges text and inline objects into lines according to a specified width and height as well
    # as other options.
    #
    # == Features
    #
    # * Existing line breaking characters inside of TextFragment objects are respected when fitting
    #   text. If this is not wanted, they have to be removed beforehand.
    #
    # * The first line of each paragraph may be indented by setting Style#text_indent which may also
    #   be negative.
    #
    # * Text can be fitted into arbitrarily shaped areas, even containing holes.
    #
    # == Layouting Algorithm
    #
    # Laying out text consists of three phases:
    #
    # 1. The items are broken into pieces which are wrapped into Box, Glue or Penalty objects.
    #    Additional Penalty objects marking line breaking opportunities are inserted where needed.
    #    This step is done by the SimpleTextSegmentation module.
    #
    # 2. The pieces are arranged into lines using a very simple algorithm that just puts the maximum
    #    number of consecutive pieces into each line. This step is done by the SimpleLineWrapping
    #    module.
    #
    # 3. The lines of step two may actually not be whole lines but line fragments if the area has
    #    holes or other discontinuities. The #fit method deals with those so that the line wrapping
    #    algorithm can be separate.
    class TextLayouter

      using NumericRefinements

      # Used for layouting. Describes an item with a fixed width, like an InlineBox or TextFragment.
      class Box

        # The wrapped item.
        attr_reader :item

        # Creates a new Box for the item.
        def initialize(item)
          @item = item
        end

        # The width of the item.
        def width
          @item.width
        end

        # The height of the item.
        def height
          @item.height
        end

        # Returns :box.
        def type
          :box
        end

        def inspect #:nodoc:
          "Box[#{@item.inspect}]"
        end

      end

      # Used for layouting. Describes a glue item, i.e. an item describing white space that could
      # potentially be shrunk or stretched.
      class Glue

        # The wrapped item.
        attr_reader :item

        # The amount by which the glue could be stretched.
        attr_reader :stretchability

        # The amount by which the glue could be shrunk.
        attr_reader :shrinkability

        # Creates a new Glue for the item.
        def initialize(item, stretchability = item.width / 2, shrinkability = item.width / 3)
          @item = item
          @stretchability = stretchability
          @shrinkability = shrinkability
        end

        # The width of the item.
        def width
          @item.width
        end

        # Returns :glue.
        def type
          :glue
        end

        def inspect #:nodoc:
          "Glue[#{@item.inspect}]"
        end

      end

      # Used for layouting. Describes a penalty item, i.e. a point where a break is allowed.
      #
      # If the penalty is greater than or equal to INFINITY, a break is forbidden. If it is smaller
      # than or equal to -INFINITY, a break is mandatory.
      #
      # If a penalty contains an item and a break occurs at the penalty (taking the width of the
      # penalty/item into account), then the penality item must be the last item of the line.
      class Penalty

        # All numbers greater than this one are deemed infinite.
        INFINITY = 1000

        # The penalty value for a mandatory paragraph break.
        PARAGRAPH_BREAK = -INFINITY - 1_000_000

        # The penalty value for a mandatory line break.
        LINE_BREAK = -INFINITY - 1_000_001

        # The penalty for breaking at this point.
        attr_reader :penalty

        # The width assigned to this item.
        attr_reader :width

        # The wrapped item.
        attr_reader :item

        # Creates a new Penalty with the given penality.
        def initialize(penalty, width = 0, item: nil)
          @penalty = penalty
          @width = width
          @item = item
        end

        # Returns :penalty.
        def type
          :penalty
        end

        def inspect #:nodoc:
          "Penalty[#{penalty} #{width} #{@item.inspect}]"
        end

        # Singleton object describing a Penalty for a prohibited break.
        ProhibitedBreak = new(Penalty::INFINITY)

        # Singleton object describing a standard Penalty, e.g. for hyphens.
        Standard = new(50)

      end

      # Implementation of a simple text segmentation algorithm.
      #
      # The algorithm breaks TextFragment objects into objects wrapped by Box, Glue or Penalty
      # items, and inserts additional Penalty items when needed:
      #
      # * Any valid Unicode newline separator inserts a Penalty object describing a mandatory break.
      #
      #   See http://www.unicode.org/reports/tr18/#Line_Boundaries
      #
      # * Spaces and tabulators are wrapped by Glue objects, allowing breaks.
      #
      # * Non-breaking spaces are wrapped into Penalty objects that prohibit line breaking.
      #
      # * Hyphens are attached to the preceeding text fragment (or are a standalone text fragment)
      #   and followed by a Penalty object to allow a break.
      #
      # * If a soft-hyphens is encountered, a hyphen wrapped by a Penalty object is inserted to
      #   allow a break.
      #
      # * If a zero-width-space is encountered, a Penalty object is inserted to allow a break.
      module SimpleTextSegmentation

        # Breaks are detected at: space, tab, zero-width-space, non-breaking space, hyphen,
        # soft-hypen and any valid Unicode newline separator
        BREAK_CHARS = {}
        " \u{A}\u{B}\u{C}\u{D}\u{85}\u{2028}\u{2029}\t\u{200B}\u{00AD}\u{00A0}-".each_char do |c|
          BREAK_CHARS[c] = true
        end

        # Breaks the items (an array of InlineBox and TextFragment objects) into atomic pieces
        # wrapped by Box, Glue or Penalty items, and returns those as an array.
        def self.call(items)
          result = []
          glues = {}
          penalties = {}
          items.each do |item|
            if item.kind_of?(InlineBox)
              result << Box.new(item)
            else
              i = 0
              while i < item.items.size
                # Collect characters and kerning values until break character is encountered
                box_items = []
                while (glyph = item.items[i]) &&
                    (glyph.kind_of?(Numeric) || !BREAK_CHARS.key?(glyph.str))
                  box_items << glyph
                  i += 1
                end

                # A hyphen belongs to the text fragment
                box_items << glyph if glyph && !glyph.kind_of?(Numeric) && glyph.str == '-'

                unless box_items.empty?
                  result << Box.new(item.dup_attributes(box_items.freeze))
                end

                if glyph
                  case glyph.str
                  when ' '
                    result << (glues[item.attributes_hash] ||=
                               Glue.new(item.dup_attributes([glyph].freeze)))
                  when "\n", "\v", "\f", "\u{85}", "\u{2029}"
                    result << (penalties[item.attributes_hash] ||=
                               Penalty.new(Penalty::PARAGRAPH_BREAK, 0))
                  when "\u{2028}"
                    result << Penalty.new(Penalty::LINE_BREAK, 0)
                  when "\r"
                    if !item.items[i + 1] || item.items[i + 1].kind_of?(Numeric) ||
                        item.items[i + 1].str != "\n"
                      result << (penalties[item.attributes_hash] ||=
                                 Penalty.new(Penalty::PARAGRAPH_BREAK, 0))
                    end
                  when '-'
                    result << Penalty::Standard
                  when "\t"
                    spaces = [item.style.font.decode_utf8(" ").first] * 8
                    result << Glue.new(item.dup_attributes(spaces.freeze))
                  when "\u{00AD}"
                    frag = item.dup_attributes([item.style.font.decode_utf8("-").first].freeze)
                    result << Penalty.new(Penalty::Standard.penalty, frag.width, item: frag)
                  when "\u{00A0}"
                    frag = item.dup_attributes([item.style.font.decode_utf8(" ").first].freeze)
                    result << Penalty.new(Penalty::ProhibitedBreak.penalty, frag.width, item: frag)
                  when "\u{200B}"
                    result << Penalty.new(0)
                  end
                end
                i += 1
              end
            end
          end
          result
        end
      end

      # A dummy line class for use with variable width wrapping, and Style#line_spacing methods in
      # case a line actually consists of multiple line fragments.
      DummyLine = Struct.new(:y_min, :y_max) do
        def update(y_min, y_max)
          self.y_min = y_min
          self.y_max = y_max
        end

        def height
          y_max - y_min
        end
      end

      # Implementation of a simple line wrapping algorithm.
      #
      # The algorithm arranges the given items so that the maximum number is put onto each line,
      # taking the differences of Box, Glue and Penalty items into account. It is not as advanced as
      # say Knuth's line wrapping algorithm in that it doesn't optimize paragraphs.
      class SimpleLineWrapping

        # :call-seq:
        #   SimpleLineWrapping.call(items, width_block, frame = nil) {|line, item| block }   -> rest
        #
        # Arranges the items into lines.
        #
        # The optional +frame+ argument needs to be a Frame object that is used when fitting inline
        # boxes. If not provided, a custom Frame object is used. However, if the items contain
        # inline boxes that need to access a frame's context object, it is mandatory to provide an
        # appropriate Frame object.
        #
        # The +width_block+ argument has to be a callable object that returns the width of the line:
        #
        # * If the line width doesn't depend on the height or the vertical position of the line
        #   (i.e. fixed line width), the +width_block+ should have an arity of zero. However, this
        #   doesn't mean that the block is called only once; it is actually called before each new
        #   line (e.g. for varying line widths that don't depend on the line height; one common case
        #   is the indentation of the first line). This is the general case.
        #
        # * However, if lines should have varying widths (e.g. for flowing text around shapes), the
        #   +width_block+ argument should be an object responding to #call(line_like) where
        #   +line_like+ is a Line-like object responding to #y_min, #y_max and #height holding the
        #   values for the currently layed out line. The caller is responsible for tracking the
        #   height of the already layed out lines. This method involves more work and is therefore
        #   slower.
        #
        # Regardless of whether varying line widths are used or not, each time a line is finished,
        # it is yielded to the caller. The second argument +item+ is the item that caused the line
        # break (e.g. a Box, Glue or Penalty). The return value should be truthy if line wrapping
        # should continue, or falsy if it should stop. If the yielded line is empty and the yielded
        # item is a box item, this single item didn't fit into the available width; the caller has
        # to handle this situation, e.g. by stopping.
        #
        # In case of varying widths, the +width_block+ may also return +nil+ in which case the
        # algorithm should revert back to a stored item index and then start as if beginning a new
        # line. Which index to use is told the algorithm through the special return value
        # +:store_start_of_line+ of the yielded-to block. When this return value is used, the
        # current start of the line index should be stored for later use.
        #
        # After the algorithm is finished, it returns the unused items.
        def self.call(items, width_block, frame = nil, &block)
          obj = new(items, width_block, frame)
          if width_block.arity == 1
            obj.variable_width_wrapping(&block)
          else
            obj.fixed_width_wrapping(&block)
          end
        end

        private_class_method :new

        # Creates a new line wrapping object that arranges the +items+ on lines with the given
        # width.
        def initialize(items, width_block, frame)
          @items = items
          @width_block = width_block
          @frame = frame
          @line_items = []
          @width = 0
          @glue_items = []
          @beginning_of_line_index = 0
          @last_breakpoint_index = 0
          @last_breakpoint_line_items_index = 0
          @break_prohibited_state = false
          @fill_horizontal = false

          @height_calc = Line::HeightCalculator.new
          @line = DummyLine.new(0, 0)

          @available_width = @width_block.call(@line)
        end

        # Peforms line wrapping with a fixed width per line, with line height playing no role.
        def fixed_width_wrapping
          index = 0

          while (item = @items[index])
            case item.type
            when :box
              unless add_box_item(item.item)
                if @break_prohibited_state
                  index = reset_line_to_last_breakpoint_state
                  item = @items[index]
                end
                break unless yield(create_line, item)
                reset_after_line_break(index)
                redo
              end
            when :glue
              unless add_glue_item(item.item, index)
                break unless yield(create_line, item)
                reset_after_line_break(index + 1)
              end
            when :penalty
              if item.penalty <= -Penalty::INFINITY
                add_box_item(item.item) if item.width > 0
                break unless yield(create_unjustified_line, item)
                reset_after_line_break(index + 1)
              elsif item.penalty >= Penalty::INFINITY
                @break_prohibited_state = true
                add_box_item(item.item) if item.width > 0
              elsif item.width > 0
                if item_fits_on_line?(item)
                  next_index = index + 1
                  next_item = @items[next_index]
                  next_item = @items[next_index += 1] while next_item&.type == :penalty
                  if next_item && !item_fits_on_line?(next_item)
                    @line_items.concat(@glue_items).push(item.item)
                    @width += item.width
                  end
                  update_last_breakpoint(index)
                else
                  @break_prohibited_state = true
                end
              else
                update_last_breakpoint(index)
              end
            end

            index += 1
          end

          line = create_unjustified_line
          last_line_used = (item.nil? && !line.items.empty? ? yield(line, nil) : true)
          item.nil? && last_line_used ? [] : @items[@beginning_of_line_index..-1]
        end

        # Performs the line wrapping with variable widths.
        def variable_width_wrapping
          index = @stored_index = 0

          while (item = @items[index])
            case item.type
            when :box
              y_min, y_max, new_height = @height_calc.simulate_height(item.item)
              if new_height > @line.height
                @line.update(y_min, y_max)
                @available_width = @width_block.call(@line)
                if !@available_width || @width > @available_width
                  index = (@available_width ? @beginning_of_line_index : @stored_index)
                  item = @items[index]
                  reset_after_line_break_variable_width(index)
                  redo
                end
              end
              if add_box_item(item.item)
                @height_calc << item.item
              else
                if @break_prohibited_state
                  index = reset_line_to_last_breakpoint_state
                  item = @items[index]
                end
                break unless (action = yield(create_line, item))
                reset_after_line_break_variable_width(index, true, action)
                redo
              end
            when :glue
              unless add_glue_item(item.item, index)
                break unless (action = yield(create_line, item))
                reset_after_line_break_variable_width(index + 1, true, action)
              end
            when :penalty
              if item.penalty <= -Penalty::INFINITY
                add_box_item(item.item) if item.width > 0
                break unless (action = yield(create_unjustified_line, item))
                reset_after_line_break_variable_width(index + 1, true, action)
              elsif item.penalty >= Penalty::INFINITY
                @break_prohibited_state = true
                add_box_item(item.item) if item.width > 0
              elsif item.width > 0
                if item_fits_on_line?(item)
                  next_index = index + 1
                  next_item = @items[next_index]
                  next_item = @items[next_index += 1] while next_item&.type == :penalty
                  y_min, y_max, new_height = @height_calc.simulate_height(next_item.item)
                  if next_item && @width + next_item.width > @width_block.call(DummyLine.new(y_min, y_max))
                    @line_items.concat(@glue_items).push(item.item)
                    @width += item.width
                    # No need to clean up, since in the next iteration a line break occurs
                  end
                  update_last_breakpoint(index)
                else
                  @break_prohibited_state = true
                end
              else
                update_last_breakpoint(index)
              end
            end

            index += 1
          end

          line = create_unjustified_line
          last_line_used = (item.nil? && !line.items.empty? ? yield(line, nil) : true)
          item.nil? && last_line_used ? [] : @items[@beginning_of_line_index..-1]
        end

        private

        # Adds the box item to the line items if it fits on the line.
        #
        # Returns +true+ if the item could be added and +false+ otherwise.
        def add_box_item(item)
          item.fit_wrapped_box(@frame) if item.kind_of?(InlineBox)
          return false unless @width + item.width <= @available_width
          @line_items.concat(@glue_items).push(item)
          @width += item.width
          @fill_horizontal ||= item.style.fill_horizontal
          @glue_items.clear
          true
        end

        # Adds the glue item to the line items if it fits on the line.
        #
        # Returns +true+ if the item could be added and +false+ otherwise.
        def add_glue_item(item, index)
          return false unless @width + item.width <= @available_width
          unless @line_items.empty? # ignore glue at beginning of line
            @glue_items << item
            @width += item.width
            update_last_breakpoint(index)
          end
          true
        end

        # Updates the information on the last possible breakpoint of the current line.
        def update_last_breakpoint(index)
          @break_prohibited_state = false
          @last_breakpoint_index = index
          @last_breakpoint_line_items_index = @line_items.size
        end

        # Resets the line items array to contain only those items that were in it when the last
        # breakpoint was encountered and returns the items' index of the last breakpoint.
        def reset_line_to_last_breakpoint_state
          @line_items.slice!(@last_breakpoint_line_items_index..-1)
          @break_prohibited_state = false
          @last_breakpoint_index
        end

        # Returns +true+ if the item fits on the line.
        def item_fits_on_line?(item)
          @width + item.width <= @available_width
        end

        # Creates a Line object from the current line items.
        def create_line
          if @fill_horizontal
            rest_width = @available_width - @width
            indices = []
            @line_items.each_with_index do |item, index|
              next unless item.style.fill_horizontal
              indices << [index, item.style.fill_horizontal]
              rest_width += item.width
            end
            unit_width = rest_width / indices.sum(&:last)
            indices.each {|i, count| @line_items[i] = @line_items[i].fill_horizontal!(unit_width * count) }
          end
          Line.new(@line_items)
        end

        # Creates a Line object from the current line items that ignores line justification.
        def create_unjustified_line
          create_line.tap(&:ignore_justification!)
        end

        # Resets the line state variables to their initial values. The +index+ specifies the items
        # index of the first item on the new line. The +line_height+ specifies the line height to
        # use for getting the available width.
        def reset_after_line_break(index)
          @beginning_of_line_index = index
          @line_items.clear
          @width = 0
          @glue_items.clear
          @last_breakpoint_index = index
          @last_breakpoint_line_items_index = 0
          @break_prohibited_state = false
          @fill_horizontal = false
          @available_width = @width_block.call(@line)
        end

        # Specialized reset method for variable width wrapping.
        #
        # * The arguments +index+ and +line_height+ are also passed to #reset_after_line_break.
        #
        # * If the +action+ argument is +:store_start_of_line+, the stored item index is reset to
        #   the index of the first item of the line.
        def reset_after_line_break_variable_width(index, reset_line = false, action = :none)
          @stored_index = @beginning_of_line_index if action == :store_start_of_line
          @line.update(0, 0) if reset_line
          @height_calc.reset
          reset_after_line_break(index)
        end

      end

      # Encapsulates the result of layouting items using a TextLayouter and provides a method for
      # drawing the result (i.e. the layed out lines) on a canvas.
      class Result

        # The status after layouting the items:
        #
        # +:success+:: There are no remaining items.
        # +:box_too_wide+:: A single text or inline box was too wide to fit alone on a line.
        # +:height+:: There was not enough height for all items to layout.
        #
        # Even if the result is not +:success+, the layouting may still be successful depending on
        # the usage. For example, if we expect that there may be too many items to fit, +:height+ is
        # still a success.
        attr_reader :status

        # Array of layed out lines.
        attr_reader :lines

        # The actual height of all layed out lines (this includes a possible offset for the first
        # line).
        attr_reader :height

        # The remaining items that couldn't be layed out.
        attr_reader :remaining_items

        # Creates a new Result structure.
        def initialize(status, lines, remaining_items)
          @status = status
          @lines = lines
          @height = @lines.sum(&:y_offset) - (@lines.last&.y_min || 0)
          @remaining_items = remaining_items
        end

        # Draws the layed out lines onto the canvas with the top-left corner being at [x, y].
        def draw(canvas, x, y)
          last_text_fragment = nil
          canvas.save_graphics_state do
            # Best effort for leading in case we have an evenly spaced paragraph
            canvas.leading(@lines[1].y_offset) if @lines.size > 1
            @lines.each do |line|
              y -= line.y_offset
              line_x = x + line.x_offset
              line.each do |item, item_x, item_y|
                if item.kind_of?(TextFragment)
                  item.draw(canvas, line_x + item_x, y + item_y,
                            ignore_text_properties: last_text_fragment&.style == item.style)
                  last_text_fragment = item
                elsif !item.empty?
                  canvas.restore_graphics_state
                  item.draw(canvas, line_x + item_x, y + item_y)
                  canvas.save_graphics_state
                  last_text_fragment = nil
                end
              end
            end
          end
        end

      end

      # The style to be applied.
      #
      # Only the following properties are used: Style#text_indent, Style#text_align,
      # Style#text_valign, Style#line_spacing, Style#fill_horizontal,
      # Style#text_segmentation_algorithm, Style#text_line_wrapping_algorithm
      attr_reader :style

      # Creates a new TextLayouter object with the given style.
      #
      # The +style+ argument can either be a Style object or a hash of style options. See #style for
      # the properties that are used by the layouter.
      def initialize(style = Style.new)
        @style = (style.kind_of?(Style) ? style : Style.new(**style))
      end

      # :call-seq:
      #   text_layouter.fit(items, width, height, apply_first_text_indent: true) -> result
      #
      # Fits the items into the given area and returns a Result object with all the information.
      #
      # The +height+ argument is just a number specifying the maximum height that can be used.
      #
      # The +width+ argument can be one of the following:
      #
      # **a number**::
      #     In this case the layed out lines have this number as maximum width. This is the standard
      #     case and means that the area in which the text is layed out is a rectangle.
      #
      # **an array with an even number of numbers**::
      #     The array has to be of the form [offset, width, offset, width, ...], so the even indices
      #     specify offsets (relative to the current position, not absolute offsets from the left),
      #     the odd indices widths. This allows laying out lines containing holes in them.
      #
      #     A simple example: [15, 100, 30, 40]. This means that a space of 15 on the left is never
      #     used, then comes text with a maximum width of 100, starting at the absolute offset 15,
      #     followed by a hole with a width of 30 and then text again with a width of 40, starting
      #     at the absolute offset 145 (=15 + 100 + 30).
      #
      # **an object responding to #call(height, line_height)**::
      #
      #     The provided argument +height+ is the bottom of last line (or 0 in case of the first
      #     line) and +line_height+ is the height of the line to be layed out. The return value has
      #     to be of one of the forms above (i.e. a single number or an array of numbers) and should
      #     describe the area given these height restrictions.
      #
      #     This allows laying out text inside complex, arbitrarily formed shapes and can be used,
      #     for example, for flowing text around objects.
      #
      # The text segmentation algorithm specified via #style is applied to the items in case they
      # are not already in segmented form. This also means that Result#remaining_items always
      # contains segmented items.
      #
      # Optional arguments:
      #
      # +apply_first_text_indent+::
      #     Specifies whether style.text_indent should be applied to the first line. This should be
      #     set to +false+ if the items start with a continuation of a paragraph instead of starting
      #     a new paragraph (e.g. after a page break).
      #
      # +frame+::
      #     If used with the document layout functionality, this should be the frame into which the
      #     text is laid out.
      def fit(items, width, height, apply_first_text_indent: true, frame: nil)
        unless items.empty? || items[0].respond_to?(:type)
          items = style.text_segmentation_algorithm.call(items)
        end

        # result variables
        lines = []
        actual_height = 0
        rest = items

        # processing state variables
        indent = apply_first_text_indent ? style.text_indent : 0
        line_fragments = []
        line_height = 0
        previous_line = nil
        y_offset = 0
        width_spec = nil
        width_spec_index = 0
        width_block =
          if width.respond_to?(:call)
            last_actual_height = nil
            previous_line_height = nil
            proc do |cur_line|
              line_height = [line_height, cur_line.height || 0].max
              if last_actual_height != actual_height || previous_line_height != line_height
                gap = if previous_line
                        style.line_spacing.gap(previous_line, cur_line)
                      else
                        0
                      end
                spec = width.call(actual_height + gap, cur_line.height)
                spec = [0, spec] unless spec.kind_of?(Array)
                last_actual_height = actual_height
                previous_line_height = line_height
              else
                spec = width_spec
              end
              if spec == width_spec
                # no changes, just need to return the width of the current part
                width_spec[width_spec_index * 2 + 1] - (width_spec_index == 0 ? indent : 0)
              elsif line_fragments.each_with_index.all? {|l, i| l.width <= spec[i * 2 + 1] }
                # width_spec changed, parts can only get smaller but processed parts still fit
                width_spec = spec
                width_spec[width_spec_index * 2 + 1] - (width_spec_index == 0 ? indent : 0)
              else
                # width_spec changed and some processed part doesn't fit anymore, retry from start
                line_fragments.clear
                width_spec = spec
                width_spec_index = 0
                nil
              end
            end
          elsif width.kind_of?(Array)
            width_spec = width
            proc { width_spec[width_spec_index * 2 + 1] - (width_spec_index == 0 ? indent : 0) }
          else
            width_spec = [0, width]
            proc { width - indent }
          end

        while true
          too_wide_box = nil
          line_height = 0

          rest = style.text_line_wrapping_algorithm.call(rest, width_block, frame) do |line, item|
            # make sure empty lines broken by mandatory paragraph breaks are not empty
            line << TextFragment.new([], style) if item&.type != :box && line.items.empty?

            # item didn't fit into first part, find next available part
            if line.items.empty? && line_fragments.empty?
              # item didn't fit because no more height is available
              next nil if actual_height + item.height > height
              # item fits but is followed by penalty item that didn't fit
              if item.width < width_block.call(item.item)
                too_wide_box = item
                next nil
              end

              old_height = actual_height
              while item.width > width_block.call(item.item) && actual_height <= height
                width_spec_index += 1
                if width_spec_index >= width_spec.size / 2
                  actual_height += item.height / 3
                  width_spec_index = 0
                end
              end
              if actual_height + item.height <= height
                width_spec_index.times { line_fragments << Line.new }
                y_offset = actual_height - old_height
                next true
              else
                actual_height = old_height
                too_wide_box = item
                next nil
              end
            end

            # continue with line fragments of current line if there are still parts and items
            # available; also handles the case if at least the first fragment is not empty and a
            # single item didn't fit into at least one of the other parts
            line_fragments << line
            unless line_fragments.size == width_spec.size / 2 || !item || item.type == :penalty
              width_spec_index += 1
              next (width_spec_index == 1 ? :store_start_of_line : true)
            end

            combined_line = create_combined_line(line_fragments)
            new_height = actual_height + combined_line.height +
              (previous_line ? style.line_spacing.gap(previous_line, combined_line) : 0)

            if new_height <= height
              # valid line found, use it
              apply_offsets(line_fragments, width_spec, indent, previous_line, combined_line, y_offset)
              lines.concat(line_fragments)
              line_fragments.clear
              width_spec_index = 0
              indent = if item&.type == :penalty && item.penalty == Penalty::PARAGRAPH_BREAK
                         style.text_indent
                       else
                         0
                       end
              previous_line = combined_line
              actual_height = new_height
              line_height = 0
              y_offset = nil
              true
            else
              nil
            end
          end

          if too_wide_box && (too_wide_box.item.kind_of?(TextFragment) &&
                              too_wide_box.item.items.size > 1)
            rest[0..rest.index(too_wide_box)] = too_wide_box.item.items.map do |item|
              Box.new(too_wide_box.item.dup_attributes([item].freeze))
            end
            too_wide_box = nil
          else
            status = (too_wide_box ? :box_too_wide : (rest.empty? ? :success : :height))
            break
          end
        end

        unless lines.empty?
          # Apply baseline offset only for non-variable width text
          lines.first.y_offset += if width_block.arity == 1
                                    lines.first.y_max
                                  else
                                    initial_baseline_offset(lines, height, actual_height)
                                  end
        end

        Result.new(status, lines, rest)
      end

      private

      # Creates a line combining all items from the given line fragments for height calculations.
      def create_combined_line(line_frags)
        if line_frags.size == 1
          line_frags[0]
        else
          calc = Line::HeightCalculator.new
          line_frags.each {|l| l.items.each {|i| calc << i } }
          y_min, y_max, = calc.result
          DummyLine.new(y_min, y_max)
        end
      end

      # Applies the necessary x- and y-offsets to the line fragments.
      #
      # Note that the offset for the first fragment of the first line is the top of the line since
      # the #initial_baseline_offset method applies the correct offset to it once layouting is
      # completely done.
      def apply_offsets(line_frags, width_spec, indent, previous_line, combined_line, y_offset)
        cumulated_width = 0
        line_frags.each_with_index do |line, index|
          line.x_offset = cumulated_width + indent
          line.x_offset += width_spec[index * 2]
          line.x_offset += horizontal_alignment_offset(line, width_spec[index * 2 + 1] - indent)
          cumulated_width += width_spec[index * 2] + width_spec[index * 2 + 1]
          if index == 0
            line.y_offset = if y_offset
                              y_offset + combined_line.y_max -
                                (previous_line ? previous_line.y_min : line.y_max)
                            else
                              style.line_spacing.baseline_distance(previous_line, combined_line)
                            end
            indent = 0
          end
        end
      end

      # Returns the initial baseline offset from the top, based on the text_valign style property.
      def initial_baseline_offset(lines, height, actual_height)
        case style.text_valign
        when :top
          lines.first.y_max
        when :center
          (height - actual_height) / 2.0 + lines.first.y_max
        when :bottom
          (height - actual_height) + lines.first.y_max
        end
      end

      # Returns the horizontal offset from the left side, based on the text_align style property.
      def horizontal_alignment_offset(line, available_width)
        case style.text_align
        when :left then 0
        when :center then (available_width - line.width) / 2
        when :right then available_width - line.width
        when :justify then (justify_line(line, available_width); 0)
        end
      end

      # Justifies the given line.
      def justify_line(line, width)
        return if line.ignore_justification? || (width - line.width).abs < 0.001

        indexes = []
        sum = 0.0
        line.items.each_with_index do |item, item_index|
          next if item.kind_of?(InlineBox)
          item.items.each_with_index do |glyph, glyph_index|
            if !glyph.kind_of?(Numeric) && glyph.str == ' '
              sum += glyph.width * item.style.scaled_font_size
              indexes << item_index << glyph_index
            end
          end
        end

        if sum > 0
          adjustment = (width - line.width) / sum
          i = indexes.length - 2
          while i >= 0
            frag = line.items[indexes[i]]
            value = -frag.items[indexes[i + 1]].width * adjustment
            if frag.items.frozen?
              line.items.insert(indexes[i], frag.dup_attributes([value]))
            else
              frag.items.insert(indexes[i + 1], value)
              frag.clear_cache
            end
            i -= 2
          end
          line.clear_cache
        end
      end

    end

  end
end
