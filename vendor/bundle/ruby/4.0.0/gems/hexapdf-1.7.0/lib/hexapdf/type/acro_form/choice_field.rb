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

require 'hexapdf/type/acro_form/variable_text_field'
require 'hexapdf/type/acro_form/appearance_generator'

module HexaPDF
  module Type
    module AcroForm

      # AcroForm choice fields contain multiple text items of which one (or, if so flagged, more)
      # may be selected.
      #
      # They are divided into scrollable list boxes and combo boxes. To create a list or combo box,
      # use the appropriate convenience methods on the main Form instance
      # (HexaPDF::Document#acro_form). By using those methods, everything needed is automatically
      # set up.
      #
      # == Type Specific Field Flags
      #
      # See the class description for Field for the general field flags.
      #
      # :combo:: If set, the field represents a combo box.
      #
      # :edit:: If set, the combo box includes an editable text box for entering arbitrary values.
      #         Therefore the 'combo' flag also needs to be set.
      #
      # :sort:: The option items have to be sorted alphabetically. This flag is intended for PDF
      #         writers, not readers which should display the items in the order they appear.
      #
      # :multi_select:: If set, more than one item may be selected.
      #
      # :do_not_spell_check:: The text should not be spell-checked.
      #
      # :commit_on_sel_change:: If set, a new value should be commited as soon as a selection is
      #                         made.
      #
      # See: PDF2.0 s12.7.5.4
      class ChoiceField < VariableTextField

        define_type :XXAcroFormField

        define_field :Opt, type: PDFArray
        define_field :TI, type: Integer, default: 0
        define_field :I, type: PDFArray, version: '1.4'

        # Updated list of field flags.
        FLAGS_BIT_MAPPING = superclass::FLAGS_BIT_MAPPING.merge(
          {
            combo: 17,
            edit: 18,
            sort: 19,
            multi_select: 21,
            do_not_spell_check: 22,
            commit_on_sel_change: 26,
          }
        ).freeze

        # Initializes the choice field to be a list box.
        #
        # This method should only be called directly after creating a new choice field because it
        # doesn't completely reset the object.
        def initialize_as_list_box
          self[:V] = nil
          unflag(:combo)
        end

        # Initializes the button field to be a combo box.
        #
        # This method should only be called directly after creating a new choice field because it
        # doesn't completely reset the object.
        def initialize_as_combo_box
          self[:V] = nil
          flag(:combo)
        end

        # Returns +true+ if this choice field represents a list box.
        def list_box?
          !combo_box?
        end

        # Returns +true+ if this choice field represents a combo box.
        def combo_box?
          flagged?(:combo)
        end

        # Returns the field value which represents the currently selected item(s).
        #
        # If no item is selected, +nil+ is returned. If multiple values are selected, the return
        # value is an array of strings, otherwise it is just a string.
        def field_value
          process_value(self[:V])
        end

        # Sets the field value to the given string or array of strings.
        #
        # The dictionary field /I is also modified to correctly represent the selected item(s).
        def field_value=(value)
          items = option_items
          array_value = [value].flatten
          all_included = array_value.all? {|v| items.include?(v) }
          self[:V] = if combo_box? && value.kind_of?(String) &&
                         (flagged?(:edit) || all_included)
                       delete(:I)
                       value
                     elsif list_box? && all_included &&
                         (value.kind_of?(String) || flagged?(:multi_select))
                       self[:I] = array_value.map {|val| items.index(val) }.sort!
                       array_value.length == 1 ? value : array_value
                     else
                       @document.config['acro_form.on_invalid_value'].call(self, value)
                     end
          update_widgets
        end

        # Returns the default field value.
        #
        # See: #field_value
        def default_field_value
          process_value(self[:DV])
        end

        # Sets the default field value.
        #
        # See: #field_value=
        def default_field_value=(value)
          items = option_items
          self[:DV] = if [value].flatten.all? {|v| items.include?(v) }
                        value
                      else
                        @document.config['acro_form.on_invalid_value'].call(self, value)
                      end
        end

        # Returns the array with the available option items.
        #
        # Note that this *only* returns the option items themselves! For getting the export values,
        # the #export_values method has to be used.
        def option_items
          prepare_option_items
          key?(:Opt) ? process_value(self[:Opt].map {|i| i.kind_of?(Array) ? i[1] : i }) : []
        end

        # Returns the export values of the option items.
        #
        # If you need the display strings (as in most cases), use the #option_items method.
        def export_values
          prepare_option_items
          key?(:Opt) ? process_value(self[:Opt].map {|i| i.kind_of?(Array) ? i[0] : i }) : []
        end

        # Sets the array with the available option items to the given value.
        #
        # Each entry in the array may either be a string representing the text to be displayed. Or
        # an array of two strings where the first describes the export value (to be used when
        # exporting form field data from the document) and the second is the display value.
        #
        # See: #option_items, #export_values
        def option_items=(value)
          self[:Opt] = if flagged?(:sort)
                         value.sort_by {|i| process_value(i.kind_of?(Array) ? i[1] : i) }
                       else
                         value
                       end
        end

        # Returns the index of the first visible option item of a list box.
        def list_box_top_index
          self[:TI]
        end

        # Makes the option item referred to via the given +index+ the first visible option item of a
        # list box.
        def list_box_top_index=(index)
          if index < 0 || !key?(:Opt) || index >= self[:Opt].length
            raise ArgumentError, "Index out of range for the set option items"
          end
          self[:TI] = index
        end

        # Returns the concrete choice field type, either :list_box, :combo_box or
        # :editable_combo_box.
        def concrete_field_type
          if combo_box?
            flagged?(:edit) ? :editable_combo_box : :combo_box
          else
            :list_box
          end
        end

        # Creates appropriate appearances for all widgets if they don't already exist.
        #
        # For information on how this is done see AppearanceGenerator.
        #
        # Note that no new appearances are created if the dictionary fields involved in the creation
        # of the appearance stream have not been changed between invocations.
        #
        # By setting +force+ to +true+ the creation of the appearances can be forced.
        def create_appearances(force: false)
          current_appearance_state = [self[:V], self[:I], self[:Opt], self[:TI]]

          appearance_generator_class = document.config.constantize('acro_form.appearance_generator')
          each_widget do |widget|
            next if !force && widget.cached?(:appearance_state) &&
              widget.cache(:appearance_state) == current_appearance_state

            widget.cache(:appearance_state, current_appearance_state, update: true)
            if combo_box?
              appearance_generator_class.new(widget).create_combo_box_appearances
            else
              appearance_generator_class.new(widget).create_list_box_appearances
            end
          end
        end

        # Updates the widgets so that they reflect the current field value.
        def update_widgets
          create_appearances
        end

        private

        # Makes sure that the /Opt key is set on the field and not on the individual widgets.
        def prepare_option_items
          return if key?(:Opt) || !terminal_field?
          opt = nil
          self[:Kids]&.each {|widget| opt ||= widget.delete(:Opt) }
          self[:Opt] = opt
        end

        # Uses the HexaPDF::DictionaryFields::StringConverter to process the value (a string or an
        # array of strings) so that it contains only normalized strings.
        def process_value(value)
          value = value.value if value.kind_of?(PDFArray)
          if value.kind_of?(Array)
            value.map! {|item| DictionaryFields::StringConverter.convert(item, nil, nil) || item }
          else
            DictionaryFields::StringConverter.convert(value, nil, nil) || value
          end
        end

        def perform_validation #:nodoc:
          if field_type != :Ch
            yield("Field /FT of AcroForm choie field has to be :Ch", true)
            self[:FT] = :Ch
          end

          super
        end

      end

    end
  end
end
