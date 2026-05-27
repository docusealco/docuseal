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
require 'hexapdf/type/acro_form/field'
require 'hexapdf/utils/bit_field'

module HexaPDF
  module Type
    module AcroForm

      # Represents the PDF's interactive form dictionary. It is linked from the catalog dictionary
      # via the /AcroForm entry.
      #
      # == Overview
      #
      # An interactive form consists of fields which can be structured hierarchically and shown on
      # pages by using Annotations::Widget annotations. This means one field can have zero, one or
      # more visual representations on one or more pages. The fields at the bottom of the hierarchy
      # which have no parent are called "root fields" and are stored in /Fields.
      #
      # Each field in a form has a certain type which determines how it should be displayed and what
      # a user can do with it. The most common type is "text field" which allows the user to enter
      # one or more lines of text. There are also check boxes, radio buttons, list boxes and combo
      # boxes.
      #
      # == Visual Appearance
      #
      # The visual appearance of a field is normally provided by the application creating the PDF.
      # This is done by generating the so called appearances for all widgets of a field. However, it
      # is also possible to instruct the PDF reader application to generate the appearances on the
      # fly using the /NeedAppearances key, see #need_appearances!.
      #
      # HexaPDF uses the configuration option +acro_form.create_appearance_streams+ to determine
      # whether appearances should automatically be generated.
      #
      # See: PDF2.0 s12.7.3, Field, HexaPDF::Type::Annotations::Widget
      class Form < Dictionary

        extend Utils::BitField

        define_type :XXAcroForm

        define_field :Fields,          type: PDFArray, required: true, default: [], version: '1.2'
        define_field :NeedAppearances, type: Boolean, default: false
        define_field :SigFlags,        type: Integer, version: '1.3'
        define_field :CO,              type: PDFArray, version: '1.3'
        define_field :DR,              type: :XXResources
        define_field :DA,              type: String
        define_field :Q,               type: Integer
        define_field :XFA,             type: [Stream, PDFArray], version: '1.5'

        bit_field(:signature_flags, {signatures_exist: 0, append_only: 1},
                  lister: "signature_flags", getter: "signature_flag?", setter: "signature_flag",
                  unsetter: "signature_unflag", value_getter: "self[:SigFlags]",
                  value_setter: "self[:SigFlags]")

        # Returns the PDFArray containing the root fields.
        def root_fields
          self[:Fields] ||= document.wrap([])
        end

        # Returns an array with all root fields that were found in the PDF document.
        def find_root_fields
          result = []
          document.pages.each do |page|
            page.each_annotation do |annot|
              if !annot.key?(:Parent) && annot.key?(:FT)
                result << Field.wrap(document, annot)
              elsif annot.key?(:Parent)
                field = annot[:Parent]
                field = field[:Parent] while field[:Parent]
                result << Field.wrap(document, field)
              end
            end
          end
          result
        end

        # Finds all root fields and sets /Fields appropriately.
        #
        # See: #find_root_fields
        def find_root_fields!
          self[:Fields] = find_root_fields
        end

        # :call-seq:
        #   acroform.each_field(terminal_only: true) {|field| block}    -> acroform
        #   acroform.each_field(terminal_only: true)                    -> Enumerator
        #
        # Yields all terminal fields or all fields, depending on the +terminal_only+ argument.
        def each_field(terminal_only: true)
          return to_enum(__method__, terminal_only: terminal_only) unless block_given?

          process_field_array = lambda do |array|
            array.each_with_index do |field, index|
              next if field.nil?
              unless field.respond_to?(:type) && field.type == :XXAcroFormField
                array[index] = field = Field.wrap(document, field)
              end
              if field.terminal_field?
                yield(field)
              else
                yield(field) unless terminal_only
                process_field_array.call(field[:Kids])
              end
            end
          end

          process_field_array.call(root_fields)
          self
        end

        # Returns the field with the given +name+ or +nil+ if no such field exists.
        def field_by_name(name)
          fields = root_fields
          field = nil

          name.split('.').each do |part|
            field = nil
            fields&.each do |f|
              f = Field.wrap(document, f)
              next unless f[:T] == part
              field = f
              fields = field[:Kids] unless field.terminal_field?
              break
            end
          end

          field
        end

        # Creates an untyped namespace field for creating hierarchies.
        #
        # Example:
        #
        #   form.create_namespace_field('text')
        #   form.create_text_field('text.a1')
        def create_namespace_field(name)
          create_field(name)
        end

        # Creates a new text field with the given name and adds it to the form.
        #
        # The +name+ may contain dots to signify a field hierarchy. If the parent fields don't
        # already exist, they are created as pure namespace fields (see #create_namespace_field). If
        # the +name+ doesn't contain dots, a top-level field is created.
        #
        # The optional keyword arguments allow setting often used properties of the field:
        #
        # +font+::
        #     The font that should be used for the text of the field. If not specified, it
        #     defaults to Helvetica.
        #
        # +font_options+::
        #     A hash with font options like :variant that should be used. If not specified, it
        #     defaults to the empty hash.
        #
        # +font_size+::
        #     The font size that should be used. If not specified, it defaults to 0 (= auto-sizing).
        #
        # +font_color+::
        #     The font color that should be used. If not specified, it defaults to 0 (i.e. black).
        #
        # +align+::
        #     The alignment of the text, either :left, :center or :right.
        def create_text_field(name, font: nil, font_options: nil, font_size: nil, font_color: nil,
                              align: nil)
          create_field(name, :Tx) do |field|
            apply_variable_text_properties(field, font: font, font_options: font_options,
                                           font_size: font_size, font_color: font_color, align: align)
          end
        end

        # Creates a new multiline text field with the given name and adds it to the form.
        #
        # The +name+ may contain dots to signify a field hierarchy. If the parent fields don't
        # already exist, they are created as pure namespace fields (see #create_namespace_field). If
        # the +name+ doesn't contain dots, a top-level field is created.
        #
        # The optional keyword arguments allow setting often used properties of the field, see
        # #create_text_field for details.
        def create_multiline_text_field(name, font: nil, font_options: nil, font_size: nil,
                                        font_color: nil, align: nil)
          create_field(name, :Tx) do |field|
            field.initialize_as_multiline_text_field
            apply_variable_text_properties(field, font: font, font_options: font_options,
                                           font_size: font_size, font_color: font_color, align: align)
          end
        end

        # Creates a new comb text field with the given name and adds it to the form.
        #
        # The +max_chars+ argument defines the maximum number of characters the comb text field can
        # accommodate.
        #
        # The +name+ may contain dots to signify a field hierarchy. If the parent fields don't
        # already exist, they are created as pure namespace fields (see #create_namespace_field). If
        # the +name+ doesn't contain dots, a top-level field is created.
        #
        # The optional keyword arguments allow setting often used properties of the field, see
        # #create_text_field for details.
        def create_comb_text_field(name, max_chars:, font: nil, font_options: nil, font_size: nil,
                                   font_color: nil, align: nil)
          create_field(name, :Tx) do |field|
            field.initialize_as_comb_text_field
            apply_variable_text_properties(field, font: font, font_options: font_options,
                                           font_size: font_size, font_color: font_color, align: align)
            field[:MaxLen] = max_chars
          end
        end

        # Creates a new file select field with the given name and adds it to the form.
        #
        # The +name+ may contain dots to signify a field hierarchy. If the parent fields don't
        # already exist, they are created as pure namespace fields (see #create_namespace_field). If
        # the +name+ doesn't contain dots, a top-level field is created.
        #
        # The optional keyword arguments allow setting often used properties of the field, see
        # #create_text_field for details.
        def create_file_select_field(name, font: nil, font_options: nil, font_size: nil,
                                     font_color: nil, align: nil)
          create_field(name, :Tx) do |field|
            field.initialize_as_file_select_field
            apply_variable_text_properties(field, font: font, font_options: font_options,
                                           font_size: font_size, font_color: font_color, align: align)
          end
        end

        # Creates a new password field with the given name and adds it to the form.
        #
        # The +name+ may contain dots to signify a field hierarchy. If the parent fields don't
        # already exist, they are created as pure namespace fields (see #create_namespace_field). If
        # the +name+ doesn't contain dots, a top-level field is created.
        #
        # The optional keyword arguments allow setting often used properties of the field, see
        # #create_text_field for details.
        def create_password_field(name, font: nil, font_options: nil, font_size: nil,
                                  font_color: nil, align: nil)
          create_field(name, :Tx) do |field|
            field.initialize_as_password_field
            apply_variable_text_properties(field, font: font, font_options: font_options,
                                           font_size: font_size, font_color: font_color, align: align)
          end
        end

        # Creates a new check box with the given name and adds it to the form.
        #
        # The +name+ may contain dots to signify a field hierarchy. If the parent fields don't
        # already exist, they are created as pure namespace fields (see #create_namespace_field). If
        # the +name+ doesn't contain dots, a top-level field is created.
        #
        # Before a field value other than +false+ can be assigned to the check box, a widget needs
        # to be created.
        def create_check_box(name)
          create_field(name, :Btn, &:initialize_as_check_box)
        end

        # Creates a radio button with the given name and adds it to the form.
        #
        # The +name+ may contain dots to signify a field hierarchy. If the parent fields don't
        # already exist, they are created as pure namespace fields (see #create_namespace_field). If
        # the +name+ doesn't contain dots, a top-level field is created.
        #
        # Before a field value other than +nil+ can be assigned to the radio button, at least one
        # widget needs to be created.
        def create_radio_button(name)
          create_field(name, :Btn, &:initialize_as_radio_button)
        end

        # Creates a combo box with the given name and adds it to the form.
        #
        # The +name+ may contain dots to signify a field hierarchy. If the parent fields don't
        # already exist, they are created as pure namespace fields (see #create_namespace_field). If
        # the +name+ doesn't contain dots, a top-level field is created.
        #
        # The optional keyword arguments allow setting often used properties of the field:
        #
        # +option_items+::
        #     Specifies the values of the list box.
        #
        # +editable+::
        #     If set to +true+, the combo box allows entering an arbitrary value in addition to
        #     selecting one of the provided option items.
        #
        # +font+, +font_options+, +font_size+ and +align+::
        #     See #create_text_field
        def create_combo_box(name, option_items: nil, editable: nil, font: nil,
                             font_options: nil, font_size: nil, font_color: nil, align: nil)
          create_field(name, :Ch) do |field|
            field.initialize_as_combo_box
            field.option_items = option_items if option_items
            field.flag(:edit) if editable
            apply_variable_text_properties(field, font: font, font_options: font_options,
                                           font_size: font_size, font_color: font_color, align: align)
          end
        end

        # Creates a list box with the given name and adds it to the form.
        #
        # The +name+ may contain dots to signify a field hierarchy. If the parent fields don't
        # already exist, they are created as pure namespace fields (see #create_namespace_field). If
        # the +name+ doesn't contain dots, a top-level field is created.
        #
        # The optional keyword arguments allow setting often used properties of the field:
        #
        # +option_items+::
        #     Specifies the values of the list box.
        #
        # +multi_select+::
        #     If set to +true+, the list box allows selecting multiple items instead of only one.
        #
        # +font+, +font_options+, +font_size+ and +align+::
        #     See #create_text_field.
        def create_list_box(name, option_items: nil, multi_select: nil, font: nil,
                            font_options: nil, font_size: nil, font_color: nil, align: nil)
          create_field(name, :Ch) do |field|
            field.initialize_as_list_box
            field.option_items = option_items if option_items
            field.flag(:multi_select) if multi_select
            apply_variable_text_properties(field, font: font, font_options: font_options,
                                           font_size: font_size, font_color: font_color, align: align)
          end
        end

        # Creates a signature field with the given name and adds it to the form.
        #
        # The +name+ may contain dots to signify a field hierarchy. If the parent fields don't
        # already exist, they are created as pure namespace fields (see #create_namespace_field). If
        # the +name+ doesn't contain dots, a top-level field is created.
        def create_signature_field(name)
          create_field(name, :Sig)
        end

        # :call-seq:
        #    form.delete_field(name)
        #    form.delete_field(field)
        #
        # Deletes the field specified by the given name or via the given field object.
        #
        # If the field is a signature field, the associated signature dictionary is also deleted.
        def delete_field(name_or_field)
          field = (name_or_field.kind_of?(String) ? field_by_name(name_or_field) : name_or_field)
          document.delete(field[:V]) if field.field_type == :Sig

          to_delete = field.each_widget(direct_only: false).to_a
          document.pages.each do |page|
            next unless page.key?(:Annots)
            page_annots = page[:Annots].to_a - to_delete
            page[:Annots].value.replace(page_annots)
          end

          if field[:Parent]
            field[:Parent][:Kids].delete(field)
          else
            self[:Fields].delete(field)
          end

          to_delete.each {|widget| document.delete(widget) }
          document.delete(field)
        end

        # Fills form fields with the values from the given +data+ hash.
        #
        # The keys of the +data+ hash need to be full field names and the values are the respective
        # values, usually in string form. It is possible to specify only some of the fields of the
        # form.
        #
        # What kind of values are supported for a field depends on the field type:
        #
        # * For fields containing text (single/multiline/comb text fields, file select fields, combo
        #   boxes and list boxes) the value needs to be a string and it is assigned as is.
        #
        # * For check boxes, the values "y"/"yes"/"t"/"true" are handled as assigning +true+ to the
        #   field, the values "n"/"no"/"f"/"false" are handled as assigning +false+ to the field,
        #   and every other string value is assigned as is. See ButtonField#field_value= for
        #   details.
        #
        # * For radio buttons the value needs to be a String or a Symbol representing the name of
        #   the radio button widget to select.
        #
        # * Values for password fields are ignored as they should not be stored in the PDF.
        def fill(data)
          data.each do |field_name, value|
            field = field_by_name(field_name)
            raise HexaPDF::Error, "AcroForm field named '#{field_name}' not found" unless field

            case field.concrete_field_type
            when :single_line_text_field, :multiline_text_field, :comb_text_field, :file_select_field,
                :combo_box, :list_box, :editable_combo_box, :radio_button
              field.field_value = value
            when :check_box
              field.field_value = case value
                                  when /\A(?:y(es)?|t(rue)?)\z/ then true
                                  when /\A(?:n(o)?|f(alse)?)\z/ then false
                                  else value
                                  end
            when :password_field
              # Ignore the value
            else
              raise HexaPDF::Error, "AcroForm field type #{field.concrete_field_type} not yet supported"
            end
          end
        end

        # Returns the dictionary containing the default resources for form field appearance streams.
        def default_resources
          self[:DR] ||= document.wrap({}, type: :XXResources)
        end

        # Sets the global default appearance string using the provided values or the default values
        # which provide a sane default.
        #
        # See VariableTextField::create_appearance_string for information on the arguments.
        def set_default_appearance_string(font: 'Helvetica', font_options: {}, font_size: 0,
                                          font_color: 0)
          self[:DA] = VariableTextField.create_appearance_string(document, font: font,
                                                                 font_options: font_options,
                                                                 font_size: font_size,
                                                                 font_color: font_color)
        end

        # Sets the /NeedAppearances field to +true+.
        #
        # This will make PDF reader applications generate appropriate appearance streams based on
        # the information stored in the fields and associated widgets.
        def need_appearances!
          self[:NeedAppearances] = true
        end

        # Creates the appearances for all widgets of all terminal fields if they don't exist.
        #
        # If +force+ is +true+, new appearances are created even if there are existing ones.
        def create_appearances(force: false)
          each_field do |field|
            field.create_appearances(force: force) if field.respond_to?(:create_appearances)
          end
        end

        # Flattens the whole interactive form or only the given fields, and returns the fields that
        # couldn't be flattened.
        #
        # Flattening means making the appearance streams of the field widgets part of the respective
        # page's content stream and removing the fields themselves.
        #
        # If the whole interactive form is flattened, the form object itself is also removed if all
        # fields were flattened.
        #
        # The +create_appearances+ argument controls whether missing appearances should
        # automatically be created.
        #
        # See: HexaPDF::Type::Page#flatten_annotations
        def flatten(fields: nil, create_appearances: true)
          remove_form = fields.nil?
          fields ||= each_field.to_a
          if create_appearances
            fields.each {|field| field.create_appearances if field.respond_to?(:create_appearances) }
          end

          not_flattened = fields.map {|field| field.each_widget(direct_only: true).to_a }.flatten
          document.pages.each {|page| not_flattened = page.flatten_annotations(not_flattened) }
          not_flattened.map!(&:form_field)
          fields -= not_flattened

          fields.each do |field|
            (field[:Parent]&.[](:Kids) || self[:Fields]).delete(field)
            document.delete(field)
          end

          if remove_form && not_flattened.empty?
            document.catalog.delete(:AcroForm)
            document.delete(self)
          end

          not_flattened
        end

        # Recalculates all form fields that have a calculate action applied (which are all fields
        # listed in the /CO entry).
        #
        # If HexaPDF doesn't support a calculation method or an error occurs during calculation, the
        # field value is not updated.
        #
        # Note that calculations are *not* done automatically when a form field's value changes
        # since it would lead to possibly many calls to this actions. So first fill in all field
        # values and then call this method.
        #
        # See: JavaScriptActions
        def recalculate_fields
          (each_field.to_a & self[:CO].to_a).each do |field|
            field = Field.wrap(document, field)
            next unless field && (calculation_action = field[:AA]&.[](:C))
            result = JavaScriptActions.calculate(self, calculation_action)
            field.field_value = result if result
          end
        end

        private

        # Creates a new field with the full name +name+ and the optional field type +type+.
        def create_field(name, type = nil)
          parent_name, _, name = name.rpartition('.')
          parent_field = parent_name.empty? ? nil : field_by_name(parent_name)
          if !parent_name.empty? && !parent_field
            parent_field = create_namespace_field(parent_name)
          end

          field = if type
                    document.add({FT: type, T: name, Parent: parent_field},
                                 type: :XXAcroFormField, subtype: type)
                  else
                    document.add({T: name, Parent: parent_field}, type: :XXAcroFormField)
                  end
          if parent_field
            (parent_field[:Kids] ||= []) << field
          else
            (self[:Fields] ||= []) << field
          end

          yield(field) if block_given?

          field
        end

        # Applies the given variable field properties to the field.
        def apply_variable_text_properties(field, font: nil, font_options: nil, font_size: nil,
                                           font_color: nil, align: nil)
          field.set_default_appearance_string(font: font || 'Helvetica',
                                              font_options: font_options || {},
                                              font_size: font_size || 0,
                                              font_color: font_color || 0)
          field.text_alignment(align || :left)
        end

        def perform_validation # :nodoc:
          super

          seen = {} # used for combining field

          validate_array = lambda do |parent, container|
            container.map! do |field|
              if !field.kind_of?(HexaPDF::Object) || !field.kind_of?(HexaPDF::Dictionary) || field.null?
                yield("Invalid object in AcroForm field hierarchy", true)
                next nil
              end
              next field unless field.key?(:T) # Skip widgets

              field = Field.wrap(document, field)
              reject = false
              if field[:Parent] != parent
                yield("Parent entry of field (#{field.oid},#{field.gen}) invalid", true)
                if field[:Parent].nil?
                  root_fields << field
                  reject = true
                else
                  field[:Parent] = parent
                end
              end

              # Combine fields with same name
              name = field.full_field_name
              if (other_field = seen[name])
                kids = other_field[:Kids] ||= []
                kids << other_field.send(:extract_widget) if other_field.embedded_widget?
                widgets = field.embedded_widget? ? [field.send(:extract_widget)] : field.each_widget.to_a
                widgets.each do |widget|
                  widget[:Parent] = other_field
                  kids << widget
                end
                document.delete(field)
                reject = true
              elsif !reject
                seen[name] = field
              end

              validate_array.call(field, field[:Kids]) if !field.null? && field.key?(:Kids)
              reject ? nil : field
            end.compact!
          end
          validate_array.call(nil, root_fields)

          if (da = self[:DA])
            unless self[:DR]
              yield("When the field /DA is present, the field /DR must also be present")
              return
            end
            font_name, = VariableTextField.parse_appearance_string(da)
            if font_name && !(self[:DR][:Font] && self[:DR][:Font][font_name])
              yield("The font specified in /DA is not in the /DR resource dictionary")
            end
          end

          create_appearances if document.config['acro_form.create_appearances']
        end

      end

    end
  end
end
