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

require 'json'
require 'hexapdf/error'
require 'hexapdf/layout/style'
require 'hexapdf/layout/text_fragment'
require 'hexapdf/layout/text_layouter'
require 'hexapdf/type/acro_form/java_script_actions'

module HexaPDF
  module Type
    module AcroForm

      # The AppearanceGenerator class provides methods for generating and updating the appearance
      # streams of form fields.
      #
      # The only method needed is #create_appearances since this method determines to what field the
      # widget belongs and therefore which appearance should be generated.
      #
      # The visual appearance of a field is constructed using information from the field itself as
      # well as information from the widget. See the documentation for the individual methods which
      # information is used in which way.
      #
      # By default, any existing appearances are overwritten and the +:print+ flag is set on the
      # widget so that the field appearance will appear on print-outs.
      #
      # The visual appearances are chosen to be similar to those used by Adobe Acrobat and others.
      # By subclassing and overriding the necessary methods it is possible to define custom
      # appearances.
      #
      # See: PDF2.0 s12.5.5, s12.7
      class AppearanceGenerator

        # Creates a new instance for the given +widget+.
        def initialize(widget)
          @widget = widget
          @field = widget.form_field
          @document = widget.document
        end

        # Creates the appropriate appearances for the widget.
        def create_appearances
          case @field.field_type
          when :Btn
            if @field.push_button?
              create_push_button_appearances
            else
              create_check_box_appearances
            end
          when :Tx, :Ch
            create_text_appearances
          else
            raise HexaPDF::Error, "Unsupported field type #{@field.field_type}"
          end
        end

        # Creates the appropriate appearances for check boxes and radio buttons.
        #
        # The unchecked box or unselected radio button is always represented by the appearance with
        # the key /Off. If there is more than one other key besides the /Off key, the first one is
        # used for the appearance of the checked box or selected radio button.
        #
        # For unchecked boxes an empty rectangle is drawn. Similarly, for unselected radio buttons
        # an empty circle (if the marker is :circle) or rectangle is drawn. When checked or
        # selected, a symbol from the ZapfDingbats font is placed inside. How this is exactly done
        # depends on the following values:
        #
        # * The widget's rectangle /Rect must be defined. If the height and/or width of the
        #   rectangle are zero, they are based on the configuration option
        #   +acro_form.default_font_size+ and widget's border width. In such a case the rectangle is
        #   appropriately updated.
        #
        # * The line width, style and color of the cirle/rectangle are taken from the widget's
        #   border style. See HexaPDF::Type::Annotations::Widget#border_style.
        #
        # * The background color is determined by the widget's background color. See
        #   HexaPDF::Type::Annotations::Widget#background_color.
        #
        # * The symbol (marker) as well as its size and color are determined by the marker style of
        #   the widget. See HexaPDF::Type::Annotations::Widget#marker_style for details.
        #
        # Examples:
        #
        #   # check box: default appearance
        #   widget.border_style(color: 0)
        #   widget.background_color(1)
        #   widget.marker_style(style: :check, size: 0, color: 0)
        #
        #   # check box: no visible rectangle, gray background, cross mark when checked
        #   widget.border_style(color: :transparent, width: 2)
        #   widget.background_color(0.7)
        #   widget.marker_style(style: :cross)
        #
        #   # radio button: default appearance
        #   widget.border_style(color: 0)
        #   widget.background_color(1)
        #   widget.marker_style(style: :circle, size: 0, color: 0)
        def create_check_box_appearances
          normal_appearance = @widget.appearance_dict&.normal_appearance
          if !normal_appearance.kind_of?(HexaPDF::Dictionary) || normal_appearance.kind_of?(HexaPDF::Stream)
            (@widget[:AP] ||= {})[:N] = {Off: nil}
            normal_appearance = @widget[:AP][:N]
            normal_appearance[@field.field_value&.to_sym || :Yes] = nil
          end
          on_name = (normal_appearance.value.keys - [:Off]).first
          unless on_name
            on_name = @field.field_value&.to_sym || :Yes
            normal_appearance[on_name] = nil
          end

          @widget[:AS] = (@field[:V] == on_name ? on_name : :Off)
          @widget.flag(:print)
          @widget.unflag(:hidden)

          border_style = @widget.border_style
          marker_style = @widget.marker_style
          circular = @field.radio_button? && marker_style.style == :circle

          default_font_size = @document.config['acro_form.default_font_size']
          rect = @widget[:Rect]
          rect.width = default_font_size + 2 * border_style.width if rect.width == 0
          rect.height = default_font_size + 2 * border_style.width if rect.height == 0

          width, height, matrix = perform_rotation(rect.width, rect.height)

          off_form = @widget.appearance_dict.normal_appearance[:Off] =
            @document.add({Type: :XObject, Subtype: :Form, BBox: [0, 0, width, height],
                           Matrix: matrix})
          apply_background_and_border(border_style, off_form.canvas, circular: circular)

          on_form = @widget.appearance_dict.normal_appearance[on_name] =
            @document.add({Type: :XObject, Subtype: :Form, BBox: [0, 0, width, height],
                           Matrix: matrix})
          canvas = on_form.canvas
          apply_background_and_border(border_style, canvas, circular: circular)
          canvas.save_graphics_state do
            draw_marker(canvas, width, height, border_style.width, marker_style)
          end
        end

        alias create_radio_button_appearances create_check_box_appearances

        # Creates the appropriate appearances for push button fields
        #
        # The following describes how the appearance is built:
        #
        # * The widget's rectangle /Rect must be defined.
        #
        # * If the font size (used for the caption) is zero, a font size of
        #   +acro_form.default_font_size+ is used.
        #
        # * The line width, style and color of the rectangle are taken from the widget's border
        #   style. See HexaPDF::Type::Annotations::Widget#border_style.
        #
        # * The background color is determined by the widget's background color. See
        #   HexaPDF::Type::Annotations::Widget#background_color.
        def create_push_button_appearances
          default_resources = @document.acro_form(create: true).default_resources
          border_style = @widget.border_style
          padding = border_style.width
          marker_style = @widget.marker_style
          font = retrieve_font_information(marker_style.font_name, default_resources)

          @widget[:AS] = :N
          @widget.flag(:print)
          @widget.unflag(:hidden)
          rect = @widget[:Rect]

          width, height, matrix = perform_rotation(rect.width, rect.height)

          form = (@widget[:AP] ||= {})[:N] ||= @document.add({Type: :XObject, Subtype: :Form})
          # Wrap existing object in Form class in case the PDF writer didn't include the /Subtype
          # key or the type of the object is wrong; we can do this since we know this has to be a
          # Form object
          unless form.type == :XObject && form[:Subtype] == :Form
            form = @document.wrap(form, type: :XObject, subtype: :Form)
          end
          form.value.replace({Type: :XObject, Subtype: :Form, BBox: [0, 0, width, height],
                              Matrix: matrix, Resources: HexaPDF::Object.deep_copy(default_resources)})
          form.contents = ''

          canvas = form.canvas
          apply_background_and_border(border_style, canvas)

          style = HexaPDF::Layout::Style.new(font: font, font_size: marker_style.size,
                                             fill_color: marker_style.color)
          if (text = marker_style.style) && text.kind_of?(String)
            items = @document.layout.text_fragments(marker_style.style, style: style)
            layouter = Layout::TextLayouter.new(style)
            layouter.style.text_align(:center).text_valign(:center).line_spacing(:proportional, 1.25)
            result = layouter.fit(items, width - 2 * padding, height - 2 * padding)
            unless result.lines.empty?
              result.draw(canvas, padding, height - padding)
            end
          end
        end

        # Creates the appropriate appearances for text fields, combo box fields and list box fields.
        #
        # The following describes how the appearance is built:
        #
        # * The font, font size and font color are taken from the associated field's default
        #   appearance string. See VariableTextField.
        #
        #   If the font is not usable by HexaPDF (which may be due to a variety of reasons, e.g. no
        #   associated information in the form's default resources), the font specified by the
        #   configuration option +acro_form.fallback_font+ will be used.
        #
        # * The widget's rectangle /Rect must be defined. If the height is zero, it is auto-sized
        #   based on the font size. If additionally the font size is zero, a font size of
        #   +acro_form.default_font_size+ is used. If the width is zero, the
        #   +acro_form.text_field.default_width+ value is used. In such cases the rectangle is
        #   appropriately updated.
        #
        # * The line width, style and color of the rectangle are taken from the widget's border
        #   style. See HexaPDF::Type::Annotations::Widget#border_style.
        #
        # * The background color is determined by the widget's background color. See
        #   HexaPDF::Type::Annotations::Widget#background_color.
        #
        # Note: Rich text fields are currently not supported!
        def create_text_appearances
          default_resources = @document.acro_form.default_resources
          font_name, font_size, font_color = @field.parse_default_appearance_string(@widget)
          font = retrieve_font_information(font_name, default_resources)
          style = HexaPDF::Layout::Style.new(font: font, font_size: font_size, fill_color: font_color)
          border_style = @widget.border_style
          padding = [1, border_style.width].max

          @widget[:AS] = :N
          @widget.flag(:print)
          @widget.unflag(:hidden)
          rect = @widget[:Rect]
          rect.width = @document.config['acro_form.text_field.default_width'] if rect.width == 0
          if rect.height == 0
            style.font_size =
              (font_size == 0 ? @document.config['acro_form.default_font_size'] : font_size)
            rect.height = style.scaled_y_max - style.scaled_y_min + 2 * padding
          end

          width, height, matrix = perform_rotation(rect.width, rect.height)

          form = (@widget[:AP] ||= {})[:N] ||= @document.add({Type: :XObject, Subtype: :Form})
          # Wrap existing object in Form class in case the PDF writer didn't include the /Subtype
          # key or the type of the object is wrong; we can do this since we know this has to be a
          # Form object
          unless form.type == :XObject && form[:Subtype] == :Form
            form = @document.wrap(form, type: :XObject, subtype: :Form)
          end
          form.value.replace({Type: :XObject, Subtype: :Form, BBox: [0, 0, width, height],
                              Matrix: matrix, Resources: HexaPDF::Object.deep_copy(default_resources)})
          form.contents = ''

          canvas = form.canvas
          apply_background_and_border(border_style, canvas)

          canvas.marked_content_sequence(:Tx) do
            if @field.field_value || @field.concrete_field_type == :list_box
              canvas.save_graphics_state do
                canvas.rectangle(padding, padding, width - 2 * padding,
                                 height - 2 * padding).clip_path.end_path
                case @field.concrete_field_type
                when :multiline_text_field
                  draw_multiline_text(canvas, width, height, style, padding)
                when :list_box
                  draw_list_box(canvas, width, height, style, padding)
                else
                  draw_single_line_text(canvas, width, height, style, padding)
                end
              end
            end
          end
        end

        alias create_combo_box_appearances create_text_appearances
        alias create_list_box_appearances create_text_appearances

        private

        # Performs the rotation specified in /R of the appearance characteristics dictionary and
        # returns the correct width, height and Form XObject matrix.
        def perform_rotation(width, height)
          matrix = case (@widget[:MK]&.[](:R) || 0) % 360
                   when 90
                     width, height = height, width
                     [0, 1, -1, 0, 0, 0]
                   when 270
                     width, height = height, width
                     [0, -1, 1, 0, 0, 0]
                   when 180
                     [0, -1, -1, 0, 0, 0]
                   end
          [width, height, matrix]
        end

        # Applies the background and border style of the widget annotation to the appearances.
        #
        # If +circular+ is +true+, then the border is drawn as inscribed circle instead of as
        # rectangle.
        def apply_background_and_border(border_style, canvas, circular: false)
          rect = @widget[:Rect]
          background_color = @widget.background_color

          if (border_style.width > 0 && border_style.color) || background_color
            canvas.save_graphics_state
            if background_color
              canvas.fill_color(background_color)
              if circular
                canvas.circle(rect.width / 2.0, rect.height / 2.0,
                              [rect.width / 2.0, rect.height / 2.0].min)
              else
                canvas.rectangle(0, 0, rect.width, rect.height)
              end
              canvas.fill
            end
            if border_style.color
              offset = [0.5, border_style.width / 2.0].max
              width, height = rect.width - 2 * offset, rect.height - 2 * offset
              canvas.stroke_color(border_style.color).line_width(border_style.width)
              if border_style.style == :underlined # TODO: :beveleded, :inset
                if circular
                  canvas.arc(rect.width / 2.0, rect.height / 2.0,
                             a: [width / 2.0, height / 2.0].min,
                             start_angle: 180, end_angle: 0)
                else
                  canvas.line(offset, offset, offset + width, offset)
                end
              else
                canvas.line_dash_pattern(border_style.style) if border_style.style.kind_of?(Array)
                if circular
                  canvas.circle(rect.width / 2.0, rect.height / 2.0, [width / 2.0, height / 2.0].min)
                else
                  canvas.rectangle(offset, offset, width, height)
                  if @field.concrete_field_type == :comb_text_field
                    cell_width = rect.width.to_f / @field[:MaxLen]
                    1.upto(@field[:MaxLen] - 1) do |i|
                      canvas.line(i * cell_width, border_style.width,
                                  i * cell_width, border_style.width + height)
                    end
                  end
                end
              end
              canvas.stroke
            end
            canvas.restore_graphics_state
          end
        end

        # Draws the marker defined by the marker style inside the widget's rectangle.
        #
        # This method can only used for check boxes and radio buttons!
        def draw_marker(canvas, width, height, border_width, marker_style)
          if @field.radio_button? && marker_style.style == :circle
            # Acrobat handles this specially
            canvas.
              fill_color(marker_style.color).
              circle(width / 2.0, height / 2.0,
                     ([width / 2.0, height / 2.0].min - border_width) / 2).
              fill
          elsif marker_style.style == :cross # Acrobat just places a cross inside
            canvas.
              stroke_color(marker_style.color).
              line(border_width, border_width, width - border_width,
                   height - border_width).
              line(border_width, height - border_width, width - border_width,
                   border_width).
              stroke
          else
            font = @document.fonts.add('ZapfDingbats')
            marker_string = @widget[:MK]&.[](:CA).to_s
            mark = font.decode_utf8(marker_string.empty? ? '4' : marker_string).first
            square_width = [width, height].min - 2 * border_width
            font_size = (marker_style.size == 0 ? square_width : marker_style.size)
            mark_width = mark.width * font.scaling_factor * font_size / 1000.0
            mark_height = (mark.y_max - mark.y_min) * font.scaling_factor * font_size / 1000.0
            x_offset = (width - square_width) / 2.0 + (square_width - mark_width) / 2.0
            y_offset = (height - square_width) / 2.0 + (square_width - mark_height) / 2.0 -
              (mark.y_min * font.scaling_factor * font_size / 1000.0)

            canvas.font(font, size: font_size)
            canvas.fill_color(marker_style.color)
            canvas.move_text_cursor(offset: [x_offset, y_offset]).show_glyphs_only([mark])
          end
        end

        # Draws a single line of text inside the widget's rectangle.
        def draw_single_line_text(canvas, width, height, style, padding)
          value, text_color = JavaScriptActions.apply_format(@field.field_value, @field[:AA]&.[](:F))
          style.fill_color = text_color if text_color
          calculate_and_apply_font_size(value, style, width, height, padding)
          line = HexaPDF::Layout::Line.new(@document.layout.text_fragments(value, style: style))

          if @field.concrete_field_type == :comb_text_field && !value.empty?
            unless @field.key?(:MaxLen)
              raise HexaPDF::Error, "Missing or invalid dictionary field /MaxLen for comb text field"
            end
            unless line.items.size == 1
              raise HexaPDF::Error, "Fallback glyphs are not yet supported with comb text fields"
            end
            fragment = line.items[0]
            new_items = []
            cell_width = width.to_f / @field[:MaxLen]
            scaled_cell_width = cell_width / style.scaled_font_size.to_f
            fragment.items.each_cons(2) do |a, b|
              new_items << a << -(scaled_cell_width - a.width / 2.0 - b.width / 2.0)
            end
            new_items << fragment.items.last
            fragment.items.replace(new_items)
            fragment.clear_cache
            line.clear_cache
            # Adobe always seems to add 1 to the first offset...
            x_offset = 1 + (cell_width - style.scaled_item_width(fragment.items[0])) / 2.0
            x = case @field.text_alignment
                when :left then x_offset
                when :right then x_offset + cell_width * (@field[:MaxLen] - value.length)
                when :center then x_offset + cell_width * ((@field[:MaxLen] - value.length) / 2)
                end
          else
            # Adobe seems to be left/right-aligning based on twice the border width
            x = case @field.text_alignment
                when :left then 2 * padding
                when :right then [width - 2 * padding - line.width, 2 * padding].max
                when :center then [(width - line.width) / 2.0, 2 * padding].max
                end
          end

          # Adobe seems to be vertically centering based on the cap height, if enough space is
          # available
          tmp_cap_height = style.font.wrapped_font.cap_height ||
            style.font.pdf_object.font_descriptor&.[](:CapHeight)
          cap_height = tmp_cap_height * style.font.scaling_factor / 1000.0 *
            style.font_size
          y = padding + (height - 2 * padding - cap_height) / 2.0
          y = padding - style.scaled_font_descender if y < 0
          line.each {|frag, fx, _| frag.draw(canvas, x + fx, y) }
        end

        # Draws multiple lines  of text inside the widget's rectangle.
        def draw_multiline_text(canvas, width, height, style, padding)
          items = @document.layout.text_fragments(@field.field_value, style: style)
          layouter = Layout::TextLayouter.new(style)
          layouter.style.text_align(@field.text_alignment).line_spacing(:proportional, 1.25)

          result = nil
          if style.font_size == 0 # need to auto-size text
            style.font_size = 12 # Adobe seems to use this as starting point
            style.clear_cache
            loop do
              result = layouter.fit(items, width - 4 * padding, height - 4 * padding)
              break if result.status == :success || style.font_size <= 4 # don't make text too small
              style.font_size -= 1
              style.clear_cache
            end
          else
            result = layouter.fit(items, width - 4 * padding, 2**20)
          end

          unless result.lines.empty?
            result.draw(canvas, 2 * padding, height - 2 * padding - result.lines[0].height / 2.0)
          end
        end

        # Draws the visible option items of the list box in the widget's rectangle.
        def draw_list_box(canvas, width, height, style, padding)
          if style.font_size == 0
            style.font_size = 12 # Seems to be Adobe's default
            style.clear_cache
          end

          option_items = @field.option_items
          top_index = @field.list_box_top_index
          items = @document.layout.text_fragments(option_items[top_index..-1].join("\n"), style: style)
          # Should use /I but if it differs from /V, we need to use /V; so just use /V...
          indices = [@field.field_value].flatten.compact.map {|val| option_items.index(val) }

          layouter = Layout::TextLayouter.new(style)
          layouter.style.text_align(@field.text_alignment).line_spacing(:proportional, 1.25)
          result = layouter.fit(items, width - 4 * padding, height)

          unless result.lines.empty?
            top_gap = style.line_spacing.gap(result.lines[0], result.lines[0])
            line_height = style.line_spacing.baseline_distance(result.lines[0], result.lines[0])
            canvas.fill_color(153, 193, 218) # Adobe's color for selection highlighting
            indices.map! {|i| height - padding - (i - top_index + 1) * line_height }.each do |y|
              next if y + line_height > height || y + line_height < padding
              canvas.rectangle(padding, y, width - 2 * padding, line_height)
            end
            canvas.fill if canvas.graphics_object == :path
            result.draw(canvas, 2 * padding, height - padding - top_gap)
          end
        end

        # Returns the font wrapper, font size and font color to be used for variable text fields and
        # push button captions.
        def retrieve_font_information(font_name, resources)
          font_object = resources.font(font_name) rescue nil
          font = font_object&.font_wrapper
          unless font
            fallback_font = @document.config['acro_form.fallback_font']
            fallback_font_name, fallback_font_options = if fallback_font.respond_to?(:call)
                                                          fallback_font.call(@field, font_object)
                                                        else
                                                          fallback_font
                                                        end
            if fallback_font_name
              font = @document.fonts.add(fallback_font_name, **(fallback_font_options || {}))
            else
              raise(HexaPDF::Error, "Font #{font_name} of the AcroForm's default resources not usable")
            end
          end
          font
        end

        # Calculates the font size for single line text fields using auto-sizing, based on the font
        # and font size of the default appearance string, the annotation rectangle's height and
        # width and the given padding. The font size is then applied to the provided style object.
        def calculate_and_apply_font_size(value, style, width, height, padding)
          return if style.font_size != 0

          font = style.font
          unit_font_size = (font.wrapped_font.bounding_box[3] - font.wrapped_font.bounding_box[1]) *
            font.scaling_factor / 1000.0
          # The constant factor was found empirically by checking what Adobe Reader etc. do
          style.font_size = (height - 2 * padding) / unit_font_size * 0.85
          calc_width = @document.layout.text_fragments(value, style: style).sum(&:width)
          style.font_size = [style.font_size, style.font_size * (width - 4 * padding) / calc_width].min
          style.clear_cache
        end

      end

    end
  end
end
