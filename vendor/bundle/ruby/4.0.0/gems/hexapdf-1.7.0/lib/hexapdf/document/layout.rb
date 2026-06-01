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
  class Document

    # This class provides methods for working with classes in the HexaPDF::Layout module.
    #
    # Often times the layout related classes are used through HexaPDF::Composer which makes it easy
    # to create documents. However, sometimes one wants to have a bit more control or do something
    # special and use the HexaPDF::Layout classes directly. This is possible but it is better to use
    # those classes through an instance of this class because it makes it more convenient and ties
    # everything together. Incidentally, HexaPDF::Composer relies on this class for a good part of
    # its work.
    #
    #
    # == Boxes
    #
    # The main focus of the class is on providing convenience methods for creating box objects. The
    # most often used box classes like HexaPDF::Layout::TextBox or HexaPDF::Layout::ImageBox can be
    # created through dedicated methods:
    #
    # * #text_box
    # * #formatted_text_box
    # * #image_box
    # * #lorem_ipsum_box
    #
    # Other, more general boxes don't have their own method but can be created through the general
    # #box method. This method uses the 'layout.boxes.map' configuration option.
    #
    # Additionally, the +_box+ suffix can be omitted, so calling #text, #formatted_text and #image
    # also works. Furthermore, all box names defined in the 'layout.boxes.map' configuration option
    # can be used as method names (with or without a +_box+ suffix) and will invoke #box, i.e.
    # #column and #column_box will also work.
    #
    #
    # == Box Styles
    #
    # All box creation methods accept Layout::Style objects or names for style objects (defined via
    # #style). This allows one to predefine certain styles (like first level heading, second level
    # heading, paragraph, ...) and consistently use them throughout the document creation process.
    #
    # One style property, Layout::Style#font, is handled specially:
    #
    # * If no font is set on a style, the default font specified via the configuration option
    #   'font.default' is automatically set because otherwise there would be problems with text
    #   drawing operations (font is the only style property that has no valid default value).
    #
    # * Standard style objects only allow font wrapper objects to be set via the Layout::Style#font
    #   method. This class makes usage easier by allowing strings or an array [name, options_hash]
    #   to be used, like with e.g Content::Canvas#font. So to use Helvetica as font, one could just
    #   do:
    #
    #     style.font = 'Helvetica'
    #
    #   And if Helvetica in its bold variant should be used it would be:
    #
    #     style.font = ['Helvetica', variant: :bold]
    #
    #   Helvetica in bold could also be set in the following ways:
    #
    #     style.font = 'Helvetica bold'
    #     # or
    #     style.font_bold = true
    #     style.font = 'Helvetica'
    #
    #   The font_bold and font_italic style properties are always taken into account. For example,
    #   if the font is set to 'Helvetica italic' and font_bold to +true+, the actual font would be
    #   the bold _and_ italic Helvetica font.
    #
    #   However, using an array it is also possible to specify other options when setting a font,
    #   like the :subset option.
    #
    # * It is possible to resolve the font of a style object manually by using the #resolve_font
    #   method.
    #
    class Layout

      # This class is used when a box can contain child boxes and the creation of such boxes should
      # be seemlessly doable when creating the parent node. It is yieled, for example, by Layout#box
      # to collect the children for the created box.
      #
      # A box can be added to the list of collected children in the following ways:
      #
      # #<<:: This appends the given box to the list.
      #
      # text_box, formatted_text_box, image_box, ...:: Any method accepted by the Layout class.
      #
      # text, formatted_text, image, ...:: Any method accepted by the Layout class without the _box
      #                                    suffix.
      #
      # list, column, ...:: Any name registered with the configuration option +layout.boxes.map+.
      #
      # The special method #multiple allows adding multiple boxes as a single array to the collected
      # children.
      #
      # Example:
      #
      #   document.layout.box(:list) do |list|  # list is a ChildrenCollector
      #     list.text_box("Some text here")     # layout method
      #     list.image(image_path)              # layout method without _box suffix
      #     list.column(columns: 3) do |column| # registered box name
      #       column.text("Text in column")
      #       column << document.layout.lorem_ipsum_box   # adding a Box instance
      #     end
      #   end
      class ChildrenCollector

        # Creates a children collector, yields it and then returns the collected children.
        def self.collect(layout)
          collector = new(layout)
          yield(collector)
          collector.children
        end

        # The collected children
        attr_reader :children

        # Create a new ChildrenCollector for the given +layout+ (a HexaPDF::Document::Layout)
        # instance.
        def initialize(layout)
          @layout = layout
          @children = []
        end

        # :nodoc:
        def method_missing(name, *args, **kwargs, &block)
          if @layout.box_creation_method?(name)
            box = @layout.send(name, *args, **kwargs, &block)
            @children << box
            box
          else
            super
          end
        end

        # :nodoc:
        def respond_to_missing?(name, _private)
          @layout.box_creation_method?(name) || super
        end

        # Appends the given box to the list of collected children.
        def <<(box)
          @children << box
        end

        # Yields a ChildrenCollector instance and adds the collected children as a single array to
        # the list of collected children.
        def multiple(&block)
          @children << self.class.collect(@layout, &block)
        end

      end

      # Creates a new Layout object for the given PDF document.
      def initialize(document)
        @document = document
        @styles = {base: HexaPDF::Layout::Style.new}
      end

      # :call-seq:
      #    layout.style(name)                              -> style
      #    layout.style(name, base: :base, **properties)   -> style
      #
      # Creates or updates the Layout::Style object called +name+ with the given property values and
      # returns it.
      #
      # If neither +base+ nor any style properties are specified, the style +name+ is just returned.
      #
      # This method allows convenient access to the stored styles and to update them. Such styles
      # can then be used by name in the various box creation methods, e.g. #text_box or #image_box.
      #
      # If the style +name+ does not exist yet and the argument +base+ specifies the name of another
      # style, that style is duplicated and used as basis for the style. This also means that the
      # referenced +base+ style needs be defined first!
      #
      # The special name :base should be used for setting the base style which is used for the
      # +base+ argument when no specific style is specified.
      #
      # Note that the style property 'font' is handled specially, see the class documentation for
      # details.
      #
      # Example:
      #
      #   layout.style(:base, font_size: 12, leading: 1.2)
      #   layout.style(:header, font: 'Helvetica', fill_color: "008")
      #   layout.style(:header1, base: :header, font_size: 30)
      #
      # See: HexaPDF::Layout::Style
      def style(name, base: :base, **properties)
        style = @styles[name] ||= (@styles.key?(base) ? @styles[base].dup : HexaPDF::Layout::Style.new)
        style.update(**properties) unless properties.empty?
        style
      end

      # Returns +true+ if a style with the given +name+ exists, else +false+.
      #
      # Example:
      #
      #   layout.style(:header, font: 'Helvetica')
      #   layout.style?(:header)     # => true
      #   layout.style?(:paragraph)  # => false
      #
      # See: #style
      def style?(name)
        @styles.key?(name)
      end

      FONT_BOLD_VARIANT_MAPPER = { #:nodoc:
        nil => {true => :bold, false: :none},
        none: {true => :bold, false: :none},
        bold: {true => :bold, false: :none},
        italic: {true => :bold_italic, false: :italic},
        bold_italic: {true => :bold_italic, false: :italic},
      }

      FONT_ITALIC_VARIANT_MAPPER = { #:nodoc:
        nil => {true => :italic, false: :none},
        none: {true => :italic, false: :none},
        italic: {true => :italic, false: :none},
        bold: {true => :bold_italic, false: :bold},
        bold_italic: {true => :bold_italic, false: :bold},
      }

      # Resolves the font object for the given +style+ and applies the result to it.
      #
      # The Layout::Style#font property is the only one without a default value but is needed for
      # many operations. This method ensures that the +style+ has a valid font object for the font
      # property by resolving the font name.
      #
      # The font object is resolved in the following way:
      #
      # * If the font property is not set, the font value of the :base style is used and if that is
      #   also not set, the 'font.default' configuration value is used.
      #
      # * Afterwards, if the font property is a valid font object, nothing needs to be done.
      #
      # * Otherwise, if the font property is a single font name or a [font name, options hash]
      #   array, it is resolved to a font object, also taking the font_bold and font_italic style
      #   properties into account.
      #
      # Example:
      #
      #   style = layout.style(:header, font: 'Helvetica')
      #   style.font                   # => 'Helvetica'
      #   layout.resolve_font(style)
      #   style.font                   # => #<HexaPDF::Font::Type1Wrapper>
      #
      # See: The "Box Styles" section in Layout for more details.
      def resolve_font(style)
        unless style.font?
          style.font(@styles[:base].font? && @styles[:base].font || @document.config['font.default'])
        end
        unless style.font.respond_to?(:pdf_object)
          name, options = *style.font
          options ||= {}
          if style.font_bold?
            options[:variant] = FONT_BOLD_VARIANT_MAPPER.dig(options[:variant], style.font_bold)
          end
          if style.font_italic?
            options[:variant] = FONT_ITALIC_VARIANT_MAPPER.dig(options[:variant], style.font_italic)
          end
          style.font(@document.fonts.add(name, **options))
        end
      end

      # :call-seq:
      #    layout.styles            -> styles
      #    layout.styles(**mapping)   -> styles
      #
      # Returns the mapping of style names to Layout::Style instances. If +mapping+ is provided,
      # also defines the given styles using #style.
      #
      # The argument +mapping+ needs to be a hash mapping a style name (a Symbol) to style
      # properties. The special key +:base+ can be used to define the base style. For details see
      # #style.
      def styles(**mapping)
        mapping.each {|name, properties| style(name, **properties) } unless mapping.empty?
        @styles
      end

      # Creates an inline box for use together with text fragments.
      #
      # The +valign+ argument ist used to specify the vertical alignment of the box within the text
      # line. See HexaPDF::Layout::Line for details.
      #
      # If a box instance is provided as first argument, it is used. Otherwise the first argument
      # has to be the name of a box creation method and +args+, +kwargs+ and +block+ are passed to
      # it.
      #
      # Example:
      #
      #   layout.inline_box(:text, "Hallo")
      #   layout.inline_box(:list) {|list| list.text("Hallo") }
      def inline_box(box_or_name, *args, valign: :baseline, **kwargs, &block)
        box = if box_or_name.kind_of?(HexaPDF::Layout::Box)
                box_or_name
              else
                send(box_or_name, *args, **kwargs, &block)
              end
        HexaPDF::Layout::InlineBox.new(box, valign: valign)
      end

      # Creates the named box and returns it.
      #
      # The +name+ argument refers to the registered name of the box class that is looked up in the
      # 'layout.boxes.map' configuration option. The +box_options+ are passed as-is to the
      # initialization method of that box class.
      #
      # If a block is provided, a ChildrenCollector is yielded and the collected children are passed
      # to the box initialization method via the :children keyword argument. There is one exception
      # to this rule in case +name+ is +base+: The provided block is passed to the initialization
      # method of the base box class to function as drawing method.
      #
      # See #text_box for details on +width+, +height+ and +style+ (note that there is no
      # +style_properties+ argument).
      #
      # Example:
      #
      #   layout.box(:column, columns: 2, gap: 15)   # => column_box_instance
      #   layout.box(:column) do |column|            # column box with one child
      #     column.lorem_ipsum
      #   end
      #   layout.box(width: 100) do |canvas, box|
      #     canvas.line(0, 0, box.content_width, box.content_height).stroke
      #   end
      def box(name = :base, width: 0, height: 0, style: nil, **box_options, &block)
        if block_given?
          if name == :base
            box_block = block
          elsif !box_options.key?(:children)
            box_options[:children] = ChildrenCollector.collect(self, &block)
          end
        end
        style = retrieve_style(style)
        box_class_for_name(name).new(width: width, height: height,
                                     style: style, **style.box_options, **box_options, &box_block)
      end

      # Creates an array of HexaPDF::Layout::TextFragment objects for the given +text+.
      #
      # This method uses the configuration option 'font.on_invalid_glyph' to map Unicode characters
      # without a valid glyph in the given font to zero, one or more glyphs in a fallback font.
      #
      # +style+, +style_properties+::
      #     The text is styled using the given +style+. This can either be a style name set via
      #     #style or anything Layout::Style::create accepts. If any additional +style_properties+
      #     are specified, the style is duplicated and the additional styles are applied.
      #
      # +properties+::
      #     This can be used to set custom properties on the created text fragments. See
      #     Layout::Box#properties for details and usage.
      def text_fragments(text, style: nil, properties: nil, **style_properties)
        style = retrieve_style(style, style_properties)
        fragments = HexaPDF::Layout::TextFragment.create_with_fallback_glyphs(
          text, style, &@document.config['font.on_invalid_glyph']
        )
        fragments.each {|f| f.properties.update(properties) } if properties
        fragments
      end

      # Creates a HexaPDF::Layout::TextBox for the given text.
      #
      # This method is of the two main methods for creating text boxes, the other being
      # #formatted_text_box.
      #
      # +width+, +height+::
      #     The arguments +width+ and +height+ are used as constraints and are respected when
      #     fitting the box. The default value of 0 means that no constraints are set.
      #
      # +style+, +style_properties+::
      #     The box and the text are styled using the given +style+. This can either be a style name
      #     set via #style or anything Layout::Style::create accepts. If any additional
      #     +style_properties+ are specified, the style is duplicated and the additional styles are
      #     applied.
      #
      # +properties+::
      #     This can be used to set custom properties on the created text box. See
      #     Layout::Box#properties for details and usage.
      #
      # +box_style+::
      #     Sometimes it is necessary for the box to have a different style than the text, e.g. when
      #     using overlays. In such a case use +box_style+ for specifiying the style of the box (a
      #     style name set via #style or anything Layout::Style::create accepts).
      #
      #     The +style+ together with the +style_properties+ will be used for the text style.
      #
      # Examples:
      #
      #   layout.text_box("Test is on " * 15)
      #   layout.text_box("Now " * 7, width: 100)
      #   layout.text_box("Another test", font_size: 15, fill_color: "hp-blue")
      #   layout.text_box("Different box style", fill_color: 'white', box_style: {
      #     underlays: [->(c, b) { c.rectangle(0, 0, b.content_width, b.content_height).fill }]
      #   })
      #
      # See: #formatted_text_box, HexaPDF::Layout::TextBox, HexaPDF::Layout::TextFragment
      def text_box(text, width: 0, height: 0, style: nil, properties: nil, box_style: nil,
                   **style_properties)
        style = retrieve_style(style, style_properties)
        box_style = (box_style ? retrieve_style(box_style) : style)
        box_class_for_name(:text).new(items: text_fragments(text, style: style),
                                      width: width, height: height, properties: properties,
                                      style: box_style, **box_style.box_options)
      end
      alias text text_box

      # Creates a HexaPDF::Layout::TextBox like #text_box but allows parts of the text to be
      # formatted differently.
      #
      # The argument +data+ needs to be an array of String, HexaPDF::Layout::InlineBox and/or Hash
      # objects and is transformed so that it is suitable as argument for the text box
      # initialization method.
      #
      # * A String object is treated like {text: data}.
      #
      # * A HexaPDF::Layout::InlineBox is used without modification.
      #
      # * Hashes can contain any style properties and the following special keys:
      #
      #   text:: The text to be formatted. If this is set and :box is not, the hash will be
      #          transformed into text fragments.
      #
      #   link:: A URL that should be linked to. If no text is provided but a link, the link is used
      #          for the text. If this is set and :box is not, the hash will be transformed into
      #          text fragments with an appropriate link overlay.
      #
      #   style:: The style to use as base style instead of the style created from the +style+ and
      #           +style_properties+ arguments. This can either be a style name set via #style or
      #           anything HexaPDF::Layout::Style::create allows.
      #
      #           If any style properties are set, the used style is duplicated and the additional
      #           properties applied.
      #
      #           The final style is used for a created text fragment.
      #
      #   properties:: The custom properties that should be set on the created text fragments.
      #
      #   box:: An inline box to be used. If this is set, the hash will be transformed into an
      #         inline box.
      #
      #         The value must be one or more (as an array) positional arguments to be used with the
      #         #inline_box method. The rest of the hash keys are passed as keyword arguments to
      #         #inline_box except for :block which would be passed as the block.
      #
      # See #text_box for details on +width+, +height+, +style+, +style_properties+, +properties+
      # and +box_style+.
      #
      # Examples:
      #
      #   # Text without special styling
      #   layout.formatted_text_box(["Some string"])
      #
      #   # A predefined inline box
      #   ibox = layout.inline_box(:text, 'Hello')
      #   layout.formatted_text_box([ibox])
      #
      #   # Text with styling properties
      #   layout.formatted_text_box([{text: "string", fill_color: 128}])
      #
      #   # Text referencing a base style
      #   layout.formatted_text_box([{text: "string", style: :bold}])
      #
      #   # Text with a link
      #   layout.formatted_text_box([{link: "https://example.com",
      #                               fill_color: 'blue', text: "Example"}])
      #
      #   # Inline boxes created from the given data
      #   layout.formatted_text_box([{box: [:text, "string"], valign: :top}])
      #   block = lambda {|list| list.text("First item"); list.text("Second item") }
      #   layout.formatted_text_box(["Some ", {box: :list, item_spacing: 10, block: block}])
      #
      #   # Combining the above variants
      #   layout.formatted_text_box(["Hello", {box: [:text, 'World!']}, "Here comes a ",
      #                             {link: 'https://example.com', text: 'link'}, '!',
      #                             {text: 'And more!', style: :bold, font_size: 20}])
      #
      # See: #text_box, #inline_box, HexaPDF::Layout::TextBox, HexaPDF::Layout::TextFragment,
      # HexaPDF::Layout::InlineBox
      def formatted_text_box(data, width: 0, height: 0, style: nil, properties: nil, box_style: nil,
                             **style_properties)
        style = retrieve_style(style, style_properties)
        box_style = (box_style ? retrieve_style(box_style) : style)
        data = data.inject([]) do |result, item|
          case item
          when String
            result.concat(text_fragments(item, style: style))
          when Hash
            if (args = item.delete(:box))
              block = item.delete(:block)
              result << inline_box(*args, **item, &block)
            else
              link = item.delete(:link)
              (item[:overlays] ||= []) << [:link, {uri: link}] if link
              text = item.delete(:text) || link || ""
              item_properties = item.delete(:properties)
              frag_style = retrieve_style(item.delete(:style) || style, item)
              result.concat(text_fragments(text, style: frag_style, properties: item_properties))
            end
          when HexaPDF::Layout::InlineBox
            result << item
          else
            raise ArgumentError, "Invalid item of class #{item.class} in data array"
          end
        end
        box_class_for_name(:text).new(items: data, width: width, height: height,
                                      properties: properties, style: box_style,
                                      **box_style.box_options)
      end
      alias formatted_text formatted_text_box

      # Creates a HexaPDF::Layout::ImageBox for the given image.
      #
      # The +file+ argument can be anything that is accepted by HexaPDF::Document::Images#add or a
      # HexaPDF::Type::Form object.
      #
      # See #text_box for details on +width+, +height+, +style+, +style_properties+ and
      # +properties+.
      #
      # Examples:
      #
      #   layout.image_box(machu_picchu, border: {width: 3})
      #   layout.image_box(machu_picchu, height: 30)
      #
      # See: HexaPDF::Layout::ImageBox
      def image_box(file, width: 0, height: 0, properties: nil, style: nil, **style_properties)
        style = retrieve_style(style, style_properties)
        image = file.kind_of?(HexaPDF::Stream) ? file : @document.images.add(file)
        box_class_for_name(:image).new(image: image, width: width, height: height,
                                       properties: properties, style: style, **style.box_options)
      end
      alias image image_box

      # This helper class is used by Layout#table_box to allow specifying the keyword arguments used
      # when converting cell data to box instances.
      class CellArgumentCollector

        # Stores a single keyword argument definition for a number of rows/columns.
        ArgumentInfo = Struct.new(:rows, :cols, :args)

        # Returns all stored ArgumentInfo instances.
        attr_reader :argument_infos

        # Creates a new instance, providing the number of rows and columns of the table.
        def initialize(number_of_rows, number_of_columns)
          @argument_infos = []
          @number_of_rows = number_of_rows
          @number_of_columns = number_of_columns
        end

        # Stores the hash +args+ containing styling properties for the cells specified via the given
        # 0-based rows and columns.
        #
        # Rows and columns can either be single numbers, ranges of numbers or stepped ranges (i.e.
        # Enumerator::ArithmeticSequence instances).
        #
        # Examples:
        #
        #   # Gray background for all cells
        #   args[] = {cell: {background_color: "gray"}}
        #
        #   # Cell at (2, 3) gets a bigger font size
        #   args[2, 3] = {font_size: 50}
        #
        #   # First column of every row has bold font
        #   args[0..-1, 0] = {font: 'Helvetica bold'}
        #
        #   # Every second row has a blue background
        #   args[(0..-1).step(2)] = {cell: {background_color: "blue"}}
        def []=(rows = 0..-1, cols = 0..-1, args)
          rows = adjust_range(rows.kind_of?(Integer) ? rows..rows : rows, @number_of_rows)
          cols = adjust_range(cols.kind_of?(Integer) ? cols..cols : cols, @number_of_columns)
          @argument_infos << ArgumentInfo.new(rows, cols, args)
        end

        # Retrieves the merged keyword arguments for the cell in +row+ and +col+.
        #
        # Earlier defined arguments are overridden by later ones, except for the +:cell+ key which
        # is merged.
        def retrieve_arguments_for(row, col)
          @argument_infos.each_with_object({}) do |arg_info, result|
            next unless arg_info.rows.include?(row) && arg_info.cols.include?(col)
            if arg_info.args[:cell]
              result.update(arg_info.args, cell: (result[:cell] || {}).merge(arg_info.args[:cell]))
            else
              result.update(arg_info.args)
            end
          end
        end

        private

        # Adjusts the +range+ so that both the begin and the end of the range are zero or positive
        # integers smaller than +max+.
        def adjust_range(range, max)
          r = (range.begin % max)..(range.end % max)
          range.kind_of?(Range) ? r : r.step(range.step)
        end

      end

      # Creates a HexaPDF::Layout::TableBox for the given table data.
      #
      # This method is a small wrapper around the actual class and mainly facilitates transforming
      # the contents of the +data+ into the box instances needed by the table box implementation.
      #
      # In addition to everything the table box implementation allows for +data+, it is also
      # possible to specify strings as cell contents. Those strings will be converted to text boxes
      # by using the #text_box method. *Note* that this functionality is *not* available for the
      # header and footer!
      #
      # Additional arguments for the #text_box invocations can be specified using the optional block
      # that yields a CellArgumentCollector instance. This allows customization of the text boxes.
      # By specifying the special key +:cell+ it is also possible to assign style properties to the
      # cells themselves, irrespective of the type of content of the cells. See
      # CellArgumentCollector#[]= for details.
      #
      # See HexaPDF::Layout::TableBox::new for details on +column_widths+, +header+, +footer+, and
      # +cell_style+.
      #
      # See #text_box for details on +width+, +height+, +style+, +style_properties+ and
      # +properties+.
      #
      # Examples:
      #
      #   layout.table_box([[layout.text('A'), layout.text('B')],
      #                     [layout.image(image_path), layout.text('D')]]
      #   layout.table_box([['A', 'B'], [layout.image(image_path), 'D]])     # same as above
      #
      #   layout.table_box([['A', 'B'], ['C', 'D]]) do |args|
      #     # assign the predefined style :cell_text to all texts
      #     args[] = {style: :cell_text}
      #     # row 0 has a grey background and bold text
      #     args[0] = {font: 'Helvetica bold', cell: {background_color: 'eee'}}
      #     # text in last column is right aligned
      #     args[0..-1, -1] = {text_align: :right}
      #   end
      #
      # See: HexaPDF::Layout::TableBox
      def table_box(data, column_widths: nil, header: nil, footer: nil, cell_style: nil,
                    width: 0, height: 0, style: nil, properties: nil, **style_properties)
        style = retrieve_style(style, style_properties)
        cells = HexaPDF::Layout::TableBox::Cells.new(data, cell_style: cell_style)
        collector = CellArgumentCollector.new(cells.number_of_rows, cells.number_of_columns)
        yield(collector) if block_given?
        cells.style do |cell|
          args = collector.retrieve_arguments_for(cell.row, cell.column)
          cstyle = args.delete(:cell)
          result = case cell.children
                   when Array, HexaPDF::Layout::Box
                     cell.children
                   else
                     text_box(cell.children.to_s, **args)
                   end
          cell.children = result
          cell.style.update(**cstyle) if cstyle
        end
        box_class_for_name(:table).new(cells: cells, column_widths: column_widths, header: header,
                                       footer: footer, cell_style: cell_style, width: width,
                                       height: height, properties: properties, style: style,
                                       **style.box_options)
      end
      alias table table_box

      LOREM_IPSUM = [ # :nodoc:
        "Lorem ipsum dolor sit amet, con\u{00AD}sectetur adipis\u{00AD}cing elit, sed " \
          "do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
        "Ut enim ad minim veniam, quis nostrud exer\u{00AD}citation ullamco laboris nisi ut " \
          "aliquip ex ea commodo consequat.",
        "Duis aute irure dolor in reprehen\u{00AD}derit in voluptate velit esse cillum dolore " \
          "eu fugiat nulla pariatur.",
        "Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt " \
          "mollit anim id est laborum.",
      ]

      # Uses #text_box to create +count+ paragraphs with +sentences+ number of sentences (1 to 4) of
      # lorem ipsum text.
      #
      # The +text_box_properties+ arguments are passed as is to #text_box.
      def lorem_ipsum_box(sentences: 4, count: 1, **text_box_properties)
        text_box(([LOREM_IPSUM[0, sentences].join(" ")] * count).join("\n\n"), **text_box_properties)
      end
      alias lorem_ipsum lorem_ipsum_box

      # Allows creating boxes using more convenient method names: The name of a pre-defined box
      # class like #column will invoke #box appropriately. Same if used with a '_box' suffix.
      def method_missing(name, *args, **kwargs, &block)
        name_without_box = name.to_s.sub(/_box$/, '').intern
        if @document.config['layout.boxes.map'].key?(name_without_box)
          box(name_without_box, *args, **kwargs, &block)
        else
          super
        end
      end

      # :nodoc:
      def respond_to_missing?(name, _private)
        box_creation_method?(name) || super
      end

      BOX_METHOD_NAMES = [:text, :formatted_text, :image, :table, :lorem_ipsum] #:nodoc:

      # :nodoc:
      def box_creation_method?(name)
        name = name.to_s.sub(/_box$/, '').intern
        BOX_METHOD_NAMES.include?(name) || @document.config['layout.boxes.map'].key?(name) ||
          name == :box
      end

      private

      # Returns the configured box class for the given +name+.
      def box_class_for_name(name)
        @document.config.constantize('layout.boxes.map', name) do
          raise HexaPDF::Error, "Couldn't retrieve box class #{name} from configuration"
        end
      end

      # Retrieves the appropriate HexaPDF::Layout::Style object based on the +style+ and
      # +properties+ arguments.
      #
      # The +style+ argument specifies the style to retrieve. It can either be a registered style
      # name (see #style), a hash with style properties or +nil+. In the latter case the registered
      # style :base is used
      #
      # If the +properties+ hash is not empty, the retrieved style is duplicated and the properties
      # hash is applied to it.
      #
      # Finally, a default font (the one from the :base style or otherwise the one set using the
      # configuration option 'font.default') is set if necessary to ensure that the style object
      # works in all cases.
      def retrieve_style(style, properties = nil)
        if style.kind_of?(Symbol) && !@styles.key?(style)
          raise HexaPDF::Error, "Style #{style} not defined"
        end
        style = HexaPDF::Layout::Style.create(@styles[style] || style || @styles[:base])
        style = style.dup.update(**properties) unless properties.nil? || properties.empty?
        resolve_font(style)
        style
      end

    end

  end
end
