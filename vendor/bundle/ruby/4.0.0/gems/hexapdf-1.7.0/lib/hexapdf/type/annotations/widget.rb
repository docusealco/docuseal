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
require 'hexapdf/content'
require 'hexapdf/serializer'

module HexaPDF
  module Type
    module Annotations

      # Widget annotations are used by interactive forms to represent the appearance of fields and
      # to manage user interactions.
      #
      # See: PDF2.0 s12.5.6.19, HexaPDF::Type::Annotation
      class Widget < Annotation

        include BorderStyling

        # The dictionary used by the /MK key of the widget annotation.
        class AppearanceCharacteristics < Dictionary

          define_type :XXAppearanceCharacteristics

          define_field :R,  type: Integer, default: 0
          define_field :BC, type: PDFArray
          define_field :BG, type: PDFArray
          define_field :CA, type: String
          define_field :RC, type: String
          define_field :AC, type: String
          define_field :I,  type: Stream
          define_field :RI, type: Stream
          define_field :IX, type: Stream
          define_field :IF, type: :XXIconFit
          define_field :TP, type: Integer, default: 0, allowed_values: [0, 1, 2, 3, 4, 5, 6]

          private

          def perform_validation #:nodoc:
            super

            if key?(:R) && self[:R] % 90 != 0
              yield("Value of field R needs to be a multiple of 90")
            end
          end

        end

        define_field :Subtype, type: Symbol, required: true, default: :Widget
        define_field :H,       type: Symbol, allowed_values: [:N, :I, :O, :P, :T]
        define_field :MK,      type: :XXAppearanceCharacteristics
        define_field :A,       type: Dictionary, version: '1.1'
        define_field :AA,      type: Dictionary, version: '1.2'
        define_field :BS,      type: :Border, version: '1.2'
        define_field :Parent,  type: Dictionary

        # Returns the AcroForm field object to which this widget annotation belongs.
        #
        # Since a widget and a field can share the same dictionary object, the returned object is
        # often just the widget re-wrapped in the correct field class.
        def form_field
          field = if key?(:Parent) &&
                      (tmp = document.wrap(self[:Parent], type: :XXAcroFormField)).terminal_field?
                    tmp
                  else
                    document.wrap(self, type: :XXAcroFormField)
                  end
          document.wrap(field, type: :XXAcroFormField, subtype: field[:FT])
        end

        # :call-seq:
        #   widget.background_color                => background_color or nil
        #   widget.background_color(*color)        => widget
        #
        # Returns the current background color as device color object, or +nil+ if no background
        # color is set, when no argument is given. Otherwise sets the background color using the
        # +color+ argument and returns self.
        #
        # See HexaPDF::Content::ColorSpace.device_color_from_specification for information on the
        # allowed arguments.
        def background_color(*color)
          if color.empty?
            components = self[:MK]&.[](:BG)
            if components && !components.empty?
              Content::ColorSpace.prenormalized_device_color(components)
            end
          else
            color = Content::ColorSpace.device_color_from_specification(color)
            (self[:MK] ||= {})[:BG] = color.components
            self
          end
        end

        # Describes the marker style of a check box, radio button or push button widget.
        class MarkerStyle

          # The kind of marker that is shown inside the widget.
          #
          # Radion buttons and check boxes::
          #     Can either be one of the symbols +:check+, +:circle+, +:cross+, +:diamond+,
          #     +:square+ or +:star+, or a one character string. The latter is interpreted using the
          #     ZapfDingbats font.
          #
          #     If an empty string is set, it is treated as if +nil+ was set, i.e. it shows the
          #     default marker for the field type.
          #
          # Push buttons:
          #     The caption string.
          attr_reader :style

          # The size of the marker in PDF points that is shown inside the widget. The special value
          # 0 means that the marker should be auto-sized based on the widget's rectangle.
          attr_reader :size

          # A device color object representing the color of the marker - see
          # HexaPDF::Content::ColorSpace.
          attr_reader :color

          # The resource name of the font that should be used for the caption.
          #
          # This is only used for push button widgets.
          attr_reader :font_name

          # Creates a new instance with the given values.
          def initialize(style, size, color, font_name)
            @style = style
            @size = size
            @color = color
            @font_name = font_name
          end

        end

        # :call-seq:
        #   widget.marker_style                                                      => marker_style
        #   widget.marker_style(style: nil, size: nil, color: nil, font_name: nil)   => widget
        #
        # Returns a MarkerStyle instance representing the marker style of the widget when no
        # argument is given. Otherwise sets the button marker style of the widget and returns self.
        #
        # This method returns valid information only for check boxes, radio buttons and push buttons!
        #
        # When setting a marker style, arguments that are not provided will use the default:
        #
        # * For check boxes a black auto-sized checkmark (i.e. :check)
        # * For radio buttons a black auto-sized circle (i.e. :circle)
        # * For push buttons a black 9pt empty text using Helvetica
        #
        # This also means that multiple invocations will reset *all* prior values.
        #
        # Note that the +font_name+ argument must be a valid HexaPDF font name (this is in contrast
        # to MarkerStyle#font_name which returns the resource name of the font).
        #
        # Note: The marker is called "normal caption" in the PDF 2.0 spec and the /CA entry of the
        # associated appearance characteristics dictionary. The marker size and color are set using
        # the /DA key on the widget (although /DA is not defined for widget, this is how Acrobat
        # does it).
        #
        # See: PDF2.0 s12.5.6.19 and s12.7.4.3
        def marker_style(style: nil, size: nil, color: nil, font_name: nil)
          field = form_field
          if style || size || color || font_name
            style ||= case field.concrete_field_type
                      when :check_box then :check
                      when :radio_button then :circle
                      when :push_button then ''
                      end
            size ||= (field.push_button? ? 9 : 0)
            color = Content::ColorSpace.device_color_from_specification(color || 0)
            serialized_color = Content::ColorSpace.serialize_device_color(color)
            font_name ||= 'Helvetica'

            self[:MK] ||= {}
            self[:MK][:CA] = case style
                             when :check   then '4'
                             when :circle  then 'l'
                             when :cross   then '8'
                             when :diamond then 'u'
                             when :square  then 'n'
                             when :star    then 'H'
                             when String   then style
                             else
                               raise ArgumentError, "Unknown value #{style} for argument 'style'"
                             end
            self[:DA] = if field.push_button?
                          name = document.acro_form(create: true).default_resources.
                            add_font(document.fonts.add(font_name).pdf_object)
                          "/#{name} #{size} Tf #{serialized_color}".strip
                        else
                          "/ZaDb #{size} Tf #{serialized_color}".strip
                        end
          else
            style = case self[:MK]&.[](:CA)
                    when '4' then :check
                    when 'l' then :circle
                    when '8' then :cross
                    when 'u' then :diamond
                    when 'n' then :square
                    when 'H' then :star
                    when String then self[:MK][:CA]
                    else
                      if field.check_box?
                        :check
                      else
                        :circle
                      end
                    end
            size = 0
            color = HexaPDF::Content::ColorSpace.prenormalized_device_color([0])
            if (da = self[:DA] || field[:DA])
              font_name, da_size, da_color = AcroForm::VariableTextField.parse_appearance_string(da)
              size = da_size || size
              color = da_color || color
            end

            MarkerStyle.new(style, size, color, font_name)
          end
        end

        private

        def perform_validation(&block) #:nodoc:
          super
          if !key?(:Parent) && (field = form_field) == self
            field.validate(&block)
          end
        end

      end

    end
  end
end
