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

require 'hexapdf/type/acro_form/field'
require 'hexapdf/type/acro_form/appearance_generator'

module HexaPDF
  module Type
    module AcroForm

      # AcroForm button fields represent interactive controls to be used with the mouse.
      #
      # They are divided into push buttons (things to click on), check boxes and radio buttons. All
      # of these are represented with this class.
      #
      # To create a push button, check box or radio button field, use the appropriate convenience
      # methods on the main Form instance (HexaPDF::Document#acro_form). By using those methods,
      # everything needed is automatically set up.
      #
      # Radio buttons are widgets of a single radio button field. This is also called a radio button
      # group. Of the radio button group only one radio button (= widget of the radio button field)
      # may be selected at all times. Each widget must have a different value to be distinguishable;
      # otherwise the widgets with the same value represent the same thing. Although there is the
      # +no_toggle_to_off+ field flag, no PDF viewer implements that; one needs to use check boxes
      # for this feature.
      #
      # Check boxes can be toggled on and off. One check box field may have multiple widgets. If
      # those widgets have the same value, they will all be toggled on or off simultaneously.
      # Otherwise only one of those widgets will be toggled on while the others are off. In such a
      # case the check box fields acts like a radio button group, with the additional feature that
      # no check box may be selected.
      #
      # == Type Specific Field Flags
      #
      # See the class description for Field for the general field flags.
      #
      # :no_toggle_to_off:: Only used with radio buttons fields. If this flag is set, one button
      #                     needs to be selected at all times. Otherwise, clicking on the selected
      #                     button deselects it.
      #
      #                     Note: This deselectiong is not implemented in *any* tested PDF viewer. A
      #                     work-around is to use multiple check box widgets with different on
      #                     names.
      #
      # :radio:: If this flag is set, the field is a set of radio buttons. Otherwise it is a check
      #          box. Additionally, the :pushbutton flag needs to be clear.
      #
      # :push_button:: The field represents a pushbutton without a permanent value.
      #
      # :radios_in_unison:: A group of radio buttons with the same value for the on state will turn
      #                     on or off in unison.
      #
      # See: PDF2.0 s12.7.4.2
      class ButtonField < Field

        define_type :XXAcroFormField

        define_field :Opt, type: PDFArray, version: '1.4'

        # All inheritable dictionary fields for button fields.
        INHERITABLE_FIELDS = (superclass::INHERITABLE_FIELDS + [:Opt]).freeze

        # Updated list of field flags.
        FLAGS_BIT_MAPPING = superclass::FLAGS_BIT_MAPPING.merge(
          {
            no_toggle_to_off: 14,
            radio: 15,
            push_button: 16,
            radios_in_unison: 25,
          }
        ).freeze

        # Initializes the button field to be a push button.
        #
        # This method should only be called directly after creating a new button field because it
        # doesn't completely reset the object.
        def initialize_as_push_button
          self[:V] = nil
          flag(:push_button)
          unflag(:radio)
        end

        # Initializes the button field to be a check box.
        #
        # This method should only be called directly after creating a new button field because it
        # doesn't completely reset the object.
        def initialize_as_check_box
          self[:V] = :Off
          unflag(:push_button)
          unflag(:radio)
        end

        # Initializes the button field to be a radio button.
        #
        # This method should only be called directly after creating a new button field because it
        # doesn't completely reset the object.
        def initialize_as_radio_button
          self[:V] = :Off
          unflag(:push_button)
          flag(:radio)
        end

        # Returns +true+ if this button field represents a push button.
        def push_button?
          flagged?(:push_button)
        end

        # Returns +true+ if this button field represents a check box.
        def check_box?
          !push_button? && !flagged?(:radio)
        end

        # Returns +true+ if this button field represents a radio button set.
        def radio_button?
          !push_button? && flagged?(:radio)
        end

        # Returns the field value which depends on the concrete type.
        #
        # Push buttons:: They don't have a value, so +nil+ is always returned.
        #
        # Check boxes:: For check boxes that are checked the value of the specific check box that is
        #               checked is returned. Otherwise +nil+ is returned.
        #
        # Radio buttons:: If no radio button is selected, +nil+ is returned. Otherwise the value (a
        #                 Symbol) of the specific radio button that is selected is returned.
        def field_value
          normalized_field_value(:V)
        end

        # Sets the field value which depends on the concrete type.
        #
        # Push buttons:: Since push buttons don't store any value, the given value is ignored and
        #                nothing is stored for them (e.g a no-op).
        #
        # Check boxes:: Provide +nil+ or +false+ as value to toggle all check box widgets off. If
        #               +true+ is provided, all check box widgets with the same name as the first
        #               one are toggled on. Otherwise provide the value (a Symbol or an object
        #               responding to +#to_sym+) of the check box widget that should be toggled on.
        #
        # Radio buttons:: To turn all radio buttons off, provide +nil+ as value. Otherwise provide
        #                 the value (a Symbol or an object responding to +#to_sym+) of a radio
        #                 button that should be turned on.
        #
        # Note that in most cases the field needs to already have widgets because the value is
        # checked against the possibly allowed values which depend on the existing widgets.
        def field_value=(value)
          normalized_field_value_set(:V, value)
        end

        # Returns the default field value.
        #
        # See: #field_value
        def default_field_value
          normalized_field_value(:DV)
        end

        # Sets the default field value.
        #
        # See: #field_value=
        def default_field_value=(value)
          normalized_field_value_set(:DV, value)
        end

        # Returns the concrete button field type, either :push_button, :check_box or :radio_button.
        def concrete_field_type
          if push_button?
            :push_button
          elsif radio_button?
            :radio_button
          else
            :check_box
          end
        end

        # Returns the array of Symbol values (minus the /Off value) that can be used for the field
        # value for check boxes or radio buttons.
        #
        # Note that this will only return useful values if there is at least one correctly set-up
        # widget.
        def allowed_values
          (each_widget.with_object([]) do |widget, result|
             keys = widget.appearance_dict&.normal_appearance&.value&.keys
             result.concat(keys) if keys
           end - [:Off]).uniq
        end

        # Creates a widget for the button field.
        #
        # If +defaults+ is +true+, then default values will be set on the widget so that it uses a
        # default appearance.
        #
        # If the widget is created for a radio button field, the +value+ argument needs to set to
        # the value (a Symbol or an object responding to +#to_sym+) this widget represents. It can
        # be used with #field_value= to set this specific widget of the radio button set to on.
        #
        # The +value+ is optional for check box fields; if not specified, the default of :Yes will
        # be used.
        #
        # See: Field#create_widget, AppearanceGenerator button field methods
        def create_widget(page, defaults: true, value: nil, **values)
          super(page, allow_embedded: !radio_button?, **values).tap do |widget|
            value = :Yes if check_box? && value.nil?
            if radio_button? || check_box?
              unless value.respond_to?(:to_sym)
                raise ArgumentError, "Argument 'value' has to be provided for radio buttons " \
                  "and needs to respond to #to_sym"
              end
              widget[:AP] = {N: {value.to_sym => nil, Off: nil}}
            end
            next unless defaults
            widget.border_style(color: 0, width: 1, style: (push_button? ? :beveled : :solid))
            widget.background_color(push_button? ? 0.5 : 255)
            widget.marker_style(style: check_box? ? :check : :circle) unless push_button?
          end
        end

        # Creates appropriate appearances for all widgets if they don't already exist.
        #
        # The created appearance streams depend on the actual type of the button field. See
        # AppearanceGenerator for the details.
        #
        # By setting +force+ to +true+ the creation of the appearances can be forced.
        def create_appearances(force: false)
          appearance_generator_class = document.config.constantize('acro_form.appearance_generator')
          each_widget do |widget|
            normal_appearance = widget.appearance_dict&.normal_appearance
            next if !force && normal_appearance &&
              ((!push_button? && normal_appearance.value.length == 2 &&
                normal_appearance.each.all? {|_, v| v.kind_of?(HexaPDF::Stream) }) ||
               (push_button? && normal_appearance.kind_of?(HexaPDF::Stream)))
            if check_box?
              appearance_generator_class.new(widget).create_check_box_appearances
            elsif radio_button?
              appearance_generator_class.new(widget).create_radio_button_appearances
            else
              appearance_generator_class.new(widget).create_push_button_appearances
            end
          end
        end

        # Updates the widgets so that they reflect the current field value.
        def update_widgets
          return if push_button?
          create_appearances
          value = self[:V]
          each_widget do |widget|
            widget[:AS] = (widget.appearance_dict&.normal_appearance&.key?(value) ? value : :Off)
          end
        end

        private

        # Returns the normalized field value for the given key which can be :V or :DV.
        #
        # See #field_value for details.
        def normalized_field_value(key)
          if push_button?
            nil
          else
            self[key] == :Off ? nil : self[key]
          end
        end

        # Sets the key, either :V or :DV, to the value. The given normalized value is first
        # transformed into the expected value depending on the specific field type.
        #
        # See #field_value= for details.
        def normalized_field_value_set(key, value)
          return if push_button?
          av = allowed_values
          self[key] = if value.nil? || value == :Off
                        :Off
                      elsif check_box?
                        if value == false
                          :Off
                        elsif value == true && av.size >= 1
                          av[0]
                        elsif av.include?(value.to_sym)
                          value.to_sym
                        else
                          @document.config['acro_form.on_invalid_value'].call(self, value)
                        end
                      elsif av.include?(value.to_sym)
                        value.to_sym
                      else
                        @document.config['acro_form.on_invalid_value'].call(self, value)
                      end
          update_widgets
        end

        def perform_validation #:nodoc:
          if field_type != :Btn
            yield("Field /FT of AcroForm button field has to be :Btn", true)
            self[:FT] = :Btn
          end

          super

          unless key?(:V)
            yield("Button field has no value set, defaulting to :Off", true)
            self[:V] = :Off
          end
        end

      end

    end
  end
end
