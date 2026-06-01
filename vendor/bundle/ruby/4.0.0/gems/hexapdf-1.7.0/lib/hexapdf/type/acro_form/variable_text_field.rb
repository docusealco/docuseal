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

require 'hexapdf/dictionary'
require 'hexapdf/stream'
require 'hexapdf/error'
require 'hexapdf/content'

module HexaPDF
  module Type
    module AcroForm

      # An AcroForm variable text field defines how text that it is not known at generation time
      # should be rendered. For example, AcroForm text fields (normally) don't have an initial
      # value; the value is entered by the user and needs to be rendered correctly by the PDF
      # reader.
      #
      # See: PDF2.0 s12.7.4.3
      class VariableTextField < Field

        define_field :DA, type: PDFByteString
        define_field :Q, type: Integer, default: 0, allowed_values: [0, 1, 2]
        define_field :DS, type: String, version: '1.5'
        define_field :RV, type: [String, Stream], version: '1.5'

        # All inheritable dictionary fields for text fields.
        INHERITABLE_FIELDS = (superclass::INHERITABLE_FIELDS + [:DA, :Q]).freeze

        UNSET_ARG = ::Object.new # :nodoc:

        # Creates an AcroForm appearance string for the HexaPDF +document+ from the given arguments
        # and returns it.
        #
        # +font+::
        #     The name of the font.
        #
        # +font_options+::
        #     Additional font options like :variant used when loading the font. See
        #     HexaPDF::Document::Fonts#add
        #
        # +font_size+::
        #     The font size. If this is set to 0, the font size is calculated using the height/width
        #     of the field.
        #
        # +font_color+::
        #     The font color. See HexaPDF::Content::ColorSpace.device_color_from_specification for
        #     allowed values.
        def self.create_appearance_string(document, font: 'Helvetica', font_options: {},
                                          font_size: 0, font_color: 0)
          name = document.acro_form(create: true).default_resources.
            add_font(document.fonts.add(font, **font_options).pdf_object)
          font_color = HexaPDF::Content::ColorSpace.device_color_from_specification(font_color)
          color_string = HexaPDF::Content::ColorSpace.serialize_device_color(font_color)
          "#{color_string.chomp} /#{name} #{font_size} Tf"
        end

        # :call-seq:
        #   VariableTextField.parse_appearance_string(string)  -> [font_name, font_size, font_color]
        #   VariableTextField.parse_appearance_string(string) {|obj, params| block }   -> nil
        #
        # Parses the given appearance string.
        #
        # If no block is given, the appearance string is searched for font name, font size and font
        # color all of which are returned. Otherwise the block is called with each found content
        # stream operator and has to handle them itself.
        def self.parse_appearance_string(appearance_string, &block) # :yield: obj, params
          font_params = [nil, nil, nil]
          block ||= lambda do |obj, params|
            case obj
            when :Tf
              font_params[0, 2] = params
            when :rg, :g, :k
              font_params[2] = HexaPDF::Content::ColorSpace.prenormalized_device_color(params)
            end
          end
          HexaPDF::Content::Parser.parse(appearance_string.to_s.sub(/\/\//, '/'), &block)
          block_given? ? nil : font_params
        end

        # :call-seq:
        #   field.text_alignment                -> alignment
        #   field.text_alignment(alignment)     -> field
        #
        # Sets or returns the text alignment that should be used when displaying text.
        #
        # With no argument, the current text alignment is returned. When a value is provided, the
        # text alignment is set accordingly.
        #
        # The alignment value is one of :left, :center or :right.
        def text_alignment(alignment = UNSET_ARG)
          if alignment == UNSET_ARG
            case self[:Q]
            when 0 then :left
            when 1 then :center
            when 2 then :right
            end
          else
            self[:Q] = case alignment
                       when :left then 0
                       when :center then 1
                       when :right then 2
                       else
                         raise ArgumentError, "Invalid variable text field alignment #{alignment}"
                       end
          end
        end

        # Sets the default appearance string using the provided values or the default values which
        # provide a sane default.
        #
        # See ::create_appearance_string for information on the arguments.
        def set_default_appearance_string(font: 'Helvetica', font_options: {}, font_size: 0,
                                          font_color: 0)
          self[:DA] = self.class.create_appearance_string(document, font: font,
                                                          font_options: font_options,
                                                          font_size: font_size,
                                                          font_color: font_color)
        end

        # Parses the default appearance string and returns an array containing [font_name,
        # font_size, font_color].
        #
        # The default appearance string is taken from the given +widget+ of the field, falls back to
        # the field itself and then the default appearance string of the form. If it still not
        # available, a standard default appearance string is set (see
        # #set_default_appearance_string) and used.
        #
        # The reason why a specific widget of the field can be specified is because the widgets of a
        # field might differ in their visual representation.
        def parse_default_appearance_string(widget = self)
          da = widget[:DA] || self[:DA] || (document.acro_form && document.acro_form[:DA])
          unless da
            if (args = document.config['acro_form.fallback_default_appearance'])
              da = set_default_appearance_string(**args)
            else
              raise HexaPDF::Error, "No default appearance string set"
            end
          end
          self.class.parse_appearance_string(da)
        end

      end

    end
  end
end
