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

module HexaPDF
  module Type

    # Represents an optional content group (OCG).
    #
    # An optional content group represents graphics that can be made visible or invisible
    # dynamically by the PDF processor. These graphics may reside in any content stream and don't
    # need to be consecutive with respect to the drawing order.
    #
    # Most PDF viewers call this feature "layers" since it is often used to show/hide parts of
    # drawings or maps.
    #
    # == Intent and Usage
    #
    # An OCG may be assigned an intent (defaults to :View) and usage information. This allows one to
    # specify in more detail how an OCG may be used (e.g. to only show the content when a certain
    # zoom level is active).
    #
    # See: PDF2.0 s8.11.2
    class OptionalContentGroup < Dictionary

      # Represents an optional content group's usage dictionary which describes how the content
      # controlled by the group should be used.
      #
      # See: PDF2.0 s8.11.4.4
      class OptionalContentUsage < Dictionary

        # The dictionary used as value for the /CreatorInfo key.
        #
        # See: PDF2.0 s8.11.4.4
        class CreatorInfo < Dictionary

          define_type :XXOCUsageCreatorInfo
          define_field :Creator, type: String, required: true
          define_field :Subtype, type: Symbol, required: true

        end

        # The dictionary used as value for the /Language key.
        #
        # See: PDF2.0 s8.11.4.4
        class Language < Dictionary

          define_type :XXOCUsageLanguage
          define_field :Lang, type: String, required: true
          define_field :Preferred, type: Symbol, default: :OFF, allowed_values: [:ON, :OFF]

        end

        # The dictionary used as value for the /Export key.
        #
        # See: PDF2.0 s8.11.4.4
        class Export < Dictionary

          define_type :XXOCUsageExport
          define_field :ExportState, type: Symbol, required: true, allowed_values: [:ON, :OFF]

        end

        # The dictionary used as value for the /Zoom key.
        #
        # See: PDF2.0 s8.11.4.4
        class Zoom < Dictionary

          define_type :XXOCUsageZoom
          define_field :min, type: Numeric, default: 0
          define_field :max, type: Numeric

        end

        # The dictionary used as value for the /Print key.
        #
        # See: PDF2.0 s8.11.4.4
        class Print < Dictionary

          define_type :XXOCUsagePrint
          define_field :Subtype, type: Symbol
          define_field :PrintState, type: Symbol, allowed_values: [:ON, :OFF]

        end

        # The dictionary used as value for the /View key.
        #
        # See: PDF2.0 s8.11.4.4
        class View < Dictionary

          define_type :XXOCUsageView
          define_field :ViewState, type: Symbol, required: true, allowed_values: [:ON, :OFF]

        end

        # The dictionary used as value for the /User key.
        #
        # See: PDF2.0 s8.11.4.4
        class User < Dictionary

          define_type :XXOCUsageUser
          define_field :Type, type: Symbol, required: true, allowed_values: [:Ind, :Ttl, :Org]
          define_field :Name, type: [String, PDFArray], required: true

        end

        # The dictionary used as value for the /PageElement key.
        #
        # See: PDF2.0 s8.11.4.4
        class PageElement < Dictionary

          define_type :XXOCUsagePageElement
          define_field :Subtype, type: Symbol, required: true, allowed_values: [:HF, :FG, :BG, :L]

        end

        define_type :XXOCUsage

        define_field :CreatorInfo, type: :XXOCUsageCreatorInfo
        define_field :Language,    type: :XXOCUsageLanguage
        define_field :Export,      type: :XXOCUsageExport
        define_field :Zoom,        type: :XXOCUsageZoom
        define_field :Print,       type: :XXOCUsagePrint
        define_field :View,        type: :XXOCUsageView
        define_field :User,        type: :XXOCUsageUser
        define_field :PageElement, type: :XXOCUsagePageElement

      end

      define_type :OCG

      define_field :Type,   type: Symbol, required: true, default: type
      define_field :Name,   type: String, required: true
      define_field :Intent, type: [Symbol, PDFArray], default: :View
      define_field :Usage,  type: :XXOCUsage

      # Returns +true+ since optional content group dictionaries objects must always be indirect.
      def must_be_indirect?
        true
      end

      # :call-seq:
      #   ocg.name          -> name
      #   ocg.name(value)   -> value
      #
      # Returns the name of the OCG if no argument is given. Otherwise sets the name to the given
      # value.
      def name(value = nil)
        if value
          self[:Name] = value
        else
          self[:Name]
        end
      end

      # Applies the given intent (:View, :Design or a custom intent) to the OCG.
      def apply_intent(intent)
        self[:Intent] = key?(:Intent) ? Array(self[:Intent]) : []
        self[:Intent] << intent
      end

      # Returns +true+ if this OCG has an intent of :View.
      def intent_view?
        Array(self[:Intent]).include?(:View)
      end

      # Returns +true+ if this OCG has an intent of :Design.
      def intent_design?
        Array(self[:Intent]).include?(:Design)
      end

      # Returns +true+ if the OCG is set to on in the default configuration (see
      # OptionalContentProperties#default_configuration).
      def on?
        document.optional_content.default_configuration.ocg_on?(self)
      end

      # Sets the state of the OCG to on in the default configuration (see
      # OptionalContentProperties#default_configuration).
      def on!
        document.optional_content.default_configuration.ocg_state(self, :on)
      end

      # Sets the state of the OCG to off in the default configuration (see
      # OptionalContentProperties#default_configuration).
      def off!
        document.optional_content.default_configuration.ocg_state(self, :off)
      end

      # Adds the OCG to the PDF processor's user interface in the default configuration (see
      # OptionalContentProperties#default_configuration), either at the top-level or under the given
      # hierarchical +path+ but always as the last item.
      def add_to_ui(path: nil)
        document.optional_content.default_configuration.add_ocg_to_ui(self, path: path)
      end

      # :call-seq:
      #   ocg.creator_info                     -> creator_info or nil
      #   ocg.creator_info(creator, subtype)   -> creator_info
      #
      # Returns the creator info dictionary (see OptionalContentUsage::CreatorInfo) or +nil+ if no
      # argument is given. Otherwise sets the creator info using the given values.
      #
      # The creator info dictionary is used to store application-specific data. The string +creator+
      # specifies the application that created the group and the symbol +subtype+ defines the type
      # of content controlled by the OCG (for example :Artwork for graphic design applications or
      # :Technical for technical designs such as plans).
      def creator_info(creator = nil, subtype = nil)
        if creator && subtype
          self[:Usage] ||= {}
          self[:Usage][:CreatorInfo] = {Creator: creator, Subtype: subtype}
        elsif creator || subtype
          raise ArgumentError, "Missing argument, both creator and subtype are needed"
        end
        self[:Usage]&.[](:CreatorInfo)
      end

      # :call-seq:
      #   ocg.language                          -> language_info or nil
      #   ocg.language(lang, preferred: false)  -> language_info
      #
      # Returns the language dictionary (see OptionalContentUsage::Language) or +nil+ if no argument
      # is given. Otherwise sets the langauge using the given values.
      #
      # The language dictionary describes the language of the content controlled by the OCG. The
      # string +lang+ needs to be a language tag as defined in BCP 47 (e.g. 'en' or 'de-AT'). If
      # +preferred+ is +true+, this dictionary is preferred if there is only a partial match
      def language(lang = nil, preferred: false)
        if lang
          self[:Usage] ||= {}
          self[:Usage][:Language] = {Lang: lang, Preferred: (preferred ? :ON : :OFF)}
        end
        self[:Usage]&.[](:Language)
      end

      # :call-seq:
      #   ocg.export_state         -> true or false
      #   ocg.export_state(state)  -> state
      #
      # Returns the export state if no argument is given. Otherwise sets the export state using the
      # given value.
      #
      # The export state indicates the recommended state of the content when the PDF document is
      # saved to a format that does not support optional content (e.g. a raster image format). If
      # +state+ is +true+, the content controlled by the OCG will be visible.
      def export_state(state = nil)
        if state
          self[:Usage] ||= {}
          self[:Usage][:Export] = {ExportState: (state ? :ON : :OFF)}
        end
        self[:Usage]&.[](:Export)&.[](:ExportState) == :ON
      end

      # :call-seq:
      #   ocg.view_state         -> true or false
      #   ocg.view_state(state)  -> state
      #
      # Returns the view state if no argument is given. Otherwise sets the view state using the
      # given value.
      #
      # The view state indicates the state of the content when the PDF document is first opened. If
      # +state+ is +true+, the content controlled by the OCG will be visible.
      def view_state(state = nil)
        if state
          self[:Usage] ||= {}
          self[:Usage][:View] = {ViewState: (state ? :ON : :OFF)}
        end
        self[:Usage]&.[](:View)&.[](:ViewState) == :ON
      end

      # :call-seq:
      #   ocg.print_state                       -> print_state or nil
      #   ocg.print_state(state, subtype: nil)  -> print_state
      #
      # Returns the print state (see OptionalContentUsage::Print) or +nil+ if no argument is given.
      # Otherwise sets the print state using the given values.
      #
      # The print state indicates the state of the content when the PDF document is printed. If
      # +state+ is +true+, the content controlled by the OCG will be printed. The symbol +subtype+
      # may optionally specify the kind of content controlled by the OCG (e.g. :Trapping or
      # :Watermark).
      def print_state(state = nil, subtype: nil)
        if state
          self[:Usage] ||= {}
          self[:Usage][:Print] = {PrintState: (state ? :ON : :OFF), Subtype: subtype}
        end
        self[:Usage]&.[](:Print)
      end

      # :call-seq:
      #   ocg.zoom                      -> zoom_dict or nil
      #   ocg.zoom(min: nil, max: nil)  -> zoom_dict
      #
      # Returns the zoom dictionary (see OptionalContentUsage::Zoom) or +nil+ if no argument is
      # given. Otherwise sets the zoom range using the given values.
      #
      # The zoom range specifies the magnifications at which the content in the OCG is visible.
      # Either +min+ or +max+ or both can be specified as magnification factors (i.e. 1.0 means
      # viewing at 100%):
      #
      # * If +min+ is specified but +max+ isn't, the maximum possible magnification factor of the
      #   PDF processor is used for +max+.
      #
      # * If +max+ is specified but +min+ isn't, the default value of 0 for +min+ is used.
      def zoom(min: nil, max: nil)
        if min || max
          self[:Usage] ||= {}
          self[:Usage][:Zoom] = {min: min, max: max}
        end
        self[:Usage]&.[](:Zoom)
      end

      # :call-seq:
      #   ocg.intended_user              -> user_dict or nil
      #   ocg.intended_user(type, name)  -> user_dict
      #
      # Returns the user dictionary (see OptionalContentUsage::User) or +nil+ if no argument is
      # given. Otherwise sets the user information using the given values.
      #
      # The information specifies one or more users for whom this OCG is primarily intended. The
      # symbol +type+ can either be :Ind (individual), :Ttl (title or position) or :Org
      # (organisation). The argument +name+ can either be a single name or an array of names.
      def intended_user(type = nil, name = nil)
        if type && name
          self[:Usage] ||= {}
          self[:Usage][:User] = {Type: type, Name: name}
        end
        self[:Usage]&.[](:User)
      end

      # :call-seq:
      #   ocg.page_element           -> element_type or nil
      #   ocg.page_element(subtype)  -> element_type
      #
      # Returns the page element type if no argument is given. Otherwise sets the page element type
      # using the given value.
      #
      # When set, the page element declares that the OCG contains a pagination artificat. The symbol
      # argument +subtype+ can either be :HF (header/footer), :FG (foreground image or graphics),
      # :BG (background image or graphics), or :L (logo).
      def page_element(subtype = nil)
        if subtype
          self[:Usage] ||= {}
          self[:Usage][:PageElement] = {Subtype: subtype}
        end
        self[:Usage]&.[](:PageElement)&.[](:Subtype)
      end

    end

  end
end
