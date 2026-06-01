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
require 'hexapdf/type/acro_form/variable_text_field'
require 'hexapdf/type/acro_form/java_script_actions'

module HexaPDF
  module Type
    module AcroForm

      # AcroForm text fields provide a box or space to fill-in data entered from keyboard. The text
      # may be restricted to a single line or can span multiple lines.
      #
      # A special type of single-line text field is the comb text field. This type of field divides
      # the existing space into /MaxLen equally spaced positions.
      #
      # == Type Specific Field Flags
      #
      # See the class description for Field for the general field flags.
      #
      # :multiline:: If set, the text field may contain multiple lines.
      #
      # :password:: The field is a password field. This changes the behaviour of the PDF reader
      #             application to not echo the input text and to not store it in the PDF file.
      #
      # :file_select:: The text field represents a file selection control where the input text is
      #                the path to a file.
      #
      # :do_not_spell_check:: The text should not be spell-checked.
      #
      # :do_not_scroll:: The text field should not scroll (horizontally for single-line fields and
      #                  vertically for multiline fields) to accomodate more text than fits into the
      #                  annotation rectangle. This means that no more text can be entered once the
      #                  field is full.
      #
      # :comb:: The field is divided into /MaxLen equally spaced positions (so /MaxLen needs to be
      #         set). This is useful, for example, when entering things like social security
      #         numbers which always have the same length.
      #
      # :rich_text:: The field is a rich text field.
      #
      # See: PDF2.0 s12.7.5.3
      class TextField < VariableTextField

        define_type :XXAcroFormField

        define_field :MaxLen, type: Integer

        # All inheritable dictionary fields for text fields.
        INHERITABLE_FIELDS = (superclass::INHERITABLE_FIELDS + [:MaxLen]).freeze

        # Updated list of field flags.
        FLAGS_BIT_MAPPING = superclass::FLAGS_BIT_MAPPING.merge(
          {
            multiline: 12,
            password: 13,
            file_select: 20,
            do_not_spell_check: 22,
            do_not_scroll: 23,
            comb: 24,
            rich_text: 25,
          }
        ).freeze

        # Initializes the text field to be a multiline text field.
        #
        # This method should only be called directly after creating a new text field because it
        # doesn't completely reset the object.
        def initialize_as_multiline_text_field
          flag(:multiline)
          unflag(:file_select, :comb, :password)
        end

        # Initializes the text field to be a comb text field.
        #
        # This method should only be called directly after creating a new text field because it
        # doesn't completely reset the object.
        def initialize_as_comb_text_field
          flag(:comb)
          unflag(:file_select, :multiline, :password)
        end

        # Initializes the text field to be a password field.
        #
        # This method should only be called directly after creating a new text field because it
        # doesn't completely reset the object.
        def initialize_as_password_field
          delete(:V)
          flag(:password)
          unflag(:comb, :multiline, :file_select)
        end

        # Initializes the text field to be a file select field.
        #
        # This method should only be called directly after creating a new text field because it
        # doesn't completely reset the object.
        def initialize_as_file_select_field
          flag(:file_select)
          unflag(:comb, :multiline, :password)
        end

        # Returns +true+ if this field is a multiline text field.
        def multiline_text_field?
          flagged?(:multiline) && !(flagged?(:file_select) || flagged?(:comb) || flagged?(:password))
        end

        # Returns +true+ if this field is a comb text field.
        def comb_text_field?
          flagged?(:comb) && !(flagged?(:file_select) || flagged?(:multiline) || flagged?(:password))
        end

        # Returns +true+ if this field is a password field.
        def password_field?
          flagged?(:password) && !(flagged?(:file_select) || flagged?(:multiline) || flagged?(:comb))
        end

        # Returns +true+ if this field is a file select field.
        def file_select_field?
          flagged?(:file_select) && !(flagged?(:password) || flagged?(:multiline) || flagged?(:comb))
        end

        # Returns the field value, i.e. the text contents of the field, or +nil+ if no value is set.
        #
        # Note that modifying the returned value *might not* modify the text contents in case it is
        # stored as stream! So always use #field_value= to set the field value.
        def field_value
          return unless value[:V]
          self[:V].kind_of?(String) ? self[:V] : self[:V].stream
        end

        # Sets the field value, i.e. the text contents of the field, to the given string.
        #
        # Note that for single line text fields, all whitespace characters are changed to simple
        # spaces.
        def field_value=(str)
          if flagged?(:password)
            raise HexaPDF::Error, "Storing a field value for a password field is not allowed"
          elsif comb_text_field? && !key?(:MaxLen)
            raise HexaPDF::Error, "A comb text field need a valid /MaxLen value"
          elsif str && !str.kind_of?(String)
            str = @document.config['acro_form.on_invalid_value'].call(self, str)
          end
          str = str.gsub(/[[:space:]]/, ' ') if str && concrete_field_type == :single_line_text_field
          if key?(:MaxLen) && str && str.length > self[:MaxLen]
            str = @document.config['acro_form.text_field.on_max_len_exceeded'].call(self, str)
          end
          self[:V] = str
          update_widgets
        end

        # Returns the default field value.
        #
        # See: #field_value
        def default_field_value
          self[:DV].kind_of?(String) ? self[:DV] : self[:DV].stream
        end

        # Sets the default field value.
        #
        # See: #field_value=
        def default_field_value=(str)
          self[:DV] = str
        end

        # Returns the concrete text field type, either :single_line_text_field,
        # :multiline_text_field, :password_field, :file_select_field, :comb_text_field or
        # :rich_text_field.
        def concrete_field_type
          if flagged?(:multiline)
            :multiline_text_field
          elsif flagged?(:password)
            :password_field
          elsif flagged?(:file_select)
            :file_select_field
          elsif flagged?(:comb)
            :comb_text_field
          elsif flagged?(:rich_text)
            :rich_text_field
          else
            :single_line_text_field
          end
        end

        # Creates appropriate appearances for all widgets.
        #
        # For information on how this is done see AppearanceGenerator.
        #
        # Note that no new appearances are created if the field value hasn't changed between
        # invocations.
        #
        # By setting +force+ to +true+ the creation of the appearances can be forced.
        def create_appearances(force: false)
          current_value = field_value
          appearance_generator_class = document.config.constantize('acro_form.appearance_generator')
          each_widget do |widget|
            is_cached = widget.cached?(:last_value)
            unless force
              if is_cached && widget.cache(:last_value) == current_value
                next
              elsif !is_cached && widget.appearance?
                widget.cache(:last_value, current_value, update: true)
                next
              end
            end
            widget.cache(:last_value, current_value, update: true)
            appearance_generator_class.new(widget).create_text_appearances
          end
        end

        # Updates the widgets so that they reflect the current field value.
        def update_widgets
          create_appearances(force: true)
        end

        # Sets the specified JavaScript format action on the field's widgets.
        #
        # This action is executed when the field value needs to be formatted for rendering in the
        # appearance streams of the associated widgets.
        #
        # The argument +type+ can be one of the following:
        #
        # :number::
        #     Assumes that the field value is a number and formats it according to the given
        #     arguments. See JavaScriptActions.af_number_format_action for details on the arguments.
        #
        # :percent::
        #     Assumes that the field value is a number and formats it as percentage (where 1=100%
        #     and 0=0%). See JavaScriptActions.af_percent_format_action for details on the
        #     arguments.
        #
        # :time::
        #     Assumes that the field value is a string with a time value and formats it according to
        #     the given argument. See JavaScriptActions.af_time_format_action for details on the
        #     arguments.
        def set_format_action(type, **arguments)
          action_string = case type
                          when :number then JavaScriptActions.af_number_format_action(**arguments)
                          when :percent then JavaScriptActions.af_percent_format_action(**arguments)
                          when :time then JavaScriptActions.af_time_format_action(**arguments)
                          else
                            raise ArgumentError, "Invalid value for type argument: #{type.inspect}"
                          end
          self[:AA] ||= {}
          self[:AA][:F] = {S: :JavaScript, JS: action_string}
        end

        # Sets the specified JavaScript calculate action on the field.
        #
        # This action is executed by a viewer when any field's value changes so as to recalculate
        # the value of this field. Usually, the field is also flagged as read only to avoid a user
        # changing the value manually.
        #
        # Note that HexaPDF *doesn't* automatically recalculate field values, use
        # Form#recalculate_fields to manually kick off recalculation.
        #
        # The argument +type+ can be one of the following:
        #
        # :sum::
        #     Sums the values of the given +fields+.
        #
        # :average::
        #     Calculates the average value of the given +fields+.
        #
        # :product::
        #     Multiplies the values of the given +fields+.
        #
        # :min::
        #     Uses the minimum value of the given +fields+.
        #
        # :max::
        #     Uses the maximum value of the given +fields+.
        #
        # :sfn::
        #     Uses the Simplified Field Notation for calculating the field's value. This allows for
        #     more complex calculations involving addition, subtraction, multiplication and
        #     division. Field values are specified by using the full field names which should not
        #     contain spaces or punctuation characters except point.
        #
        #     The +fields+ argument needs to contain a string with the SFN calculation rule.
        #
        #     Here are some examples:
        #
        #       field1 + field2 - field3
        #       (field.1 + field.2) * (field.3 - field.4)
        #
        # Note: Setting this action appends the field to the main Form's /CO entry which specifies
        # the calculation order. Rearrange the entries as needed.
        def set_calculate_action(type, fields: nil)
          action_string = case type
                          when :sum, :average, :product, :min, :max
                            JavaScriptActions.af_simple_calculate_action(type, fields)
                          when :sfn
                            JavaScriptActions.simplified_field_notation_action(document.acro_form, fields)
                          else
                            raise ArgumentError, "Invalid value for type argument: #{type.inspect}"
                          end
          self[:AA] ||= {}
          self[:AA][:C] = {S: :JavaScript, JS: action_string}
          (document.acro_form[:CO] ||= []) << self
        end

        private

        def perform_validation #:nodoc:
          if field_type != :Tx
            yield("Field /FT of AcroForm text field has to be :Tx", true)
            self[:FT] = :Tx
          end

          super

          if self[:V] && !(self[:V].kind_of?(String) || self[:V].kind_of?(HexaPDF::Stream))
            correctable = self[:V].kind_of?(Symbol)
            yield("Text field doesn't contain text but an object of type #{self[:V].class}", correctable)
            return unless correctable
            self[:V] = self[:V].to_s
          end
          if (max_len = self[:MaxLen]) && field_value && field_value.length > max_len
            correctable = true
            begin
              str = @document.config['acro_form.text_field.on_max_len_exceeded'].call(self, field_value)
            rescue HexaPDF::Error
              correctable = false
            end
            yield("Text contents of field '#{full_field_name}' is too long", correctable)
            self.field_value = str if correctable
          end
          if comb_text_field? && !max_len
            yield("Comb text field needs a value for /MaxLen")
          end
        end

      end

    end
  end
end
