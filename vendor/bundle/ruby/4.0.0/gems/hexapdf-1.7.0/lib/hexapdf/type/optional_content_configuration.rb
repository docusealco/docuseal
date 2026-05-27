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

    # Represents an optional content configuration dictionary.
    #
    # This dictionary is used for the /D and /Configs entries in the optional content properties
    # dictionary. It configures the states of the OCGs as well as defines how those states may be
    # changed by a PDF processor.
    #
    # See: PDF2.0 s8.11.4.3
    class OptionalContentConfiguration < Dictionary

      # Represents an optional content usage application dictionary.
      #
      # This dictionary is used for the elements in the /AS array of an optional content
      # configuration dictionary. It specifies how a PDF processor should use the usage entries of
      # OCGs to automatically change their state based on external factors (like magnifacation
      # factor or language).
      #
      # See: PDF2.0 s8.11.4.4
      class UsageApplication < Dictionary

        define_type :XXOCUsageApplication
        define_field :Event, type: Symbol, required: true, allowed_values: [:View, :Print, :Export]
        define_field :OCGs, type: PDFArray, default: []
        define_field :Category, type: PDFArray, required: true

      end

      define_type :XXOCConfiguration

      define_field :Name,      type: String
      define_field :Creator,   type: String
      define_field :BaseState, type: Symbol, default: :ON, allowed_values: [:ON, :OFF, :Unchanged]
      define_field :ON,        type: PDFArray
      define_field :OFF,       type: PDFArray
      define_field :Intent,    type: [Symbol, PDFArray], default: :View
      define_field :AS,        type: PDFArray
      define_field :Order,     type: PDFArray
      define_field :ListMode,  type: Symbol, default: :AllPages,
                   allowed_values: [:AllPages, :VisiblePages]
      define_field :RBGroups,  type: PDFArray
      define_field :Locked,    type: PDFArray, default: []

      # :call-seq:
      #   configuration.ocg_state(ocg)          -> state
      #   configuration.ocg_state(ocg, state)   -> state
      #
      # Returns the state (+:on+, +:off+ or +nil+) of the optional content group if the +state+
      # argument is not given. Otherwise sets the state of the OCG to the given state value
      # (+:on+/+:ON+ or +:off+/+:OFF+).
      #
      # The value +nil+ is only returned if the state is not defined by the configuration dictionary
      # (which may only be the case if the configuration dictionary is not the default configuration
      # dictionary).
      def ocg_state(ocg, state = nil)
        if state.nil?
          case self[:BaseState]
          when :ON then self[:OFF]&.include?(ocg) ? :off : :on
          when :OFF then self[:ON]&.include?(ocg) ? :on : :off
          else self[:OFF]&.include?(ocg) ? :off : (self[:ON]&.include?(ocg) ? :on : nil)
          end
        elsif state&.downcase == :on
          (self[:ON] ||= []) << ocg unless self[:ON]&.include?(ocg)
          self[:OFF].delete(ocg) if key?(:OFF)
        elsif state&.downcase == :off
          (self[:OFF] ||= []) << ocg unless self[:OFF]&.include?(ocg)
          self[:ON].delete(ocg) if key?(:ON)
        else
          raise ArgumentError, "Invalid value #{state.inspect} for state argument"
        end
      end

      # Returns +true+ if the given optional content group is on.
      def ocg_on?(ocg)
        ocg_state(ocg) == :on
      end

      # Makes the given optional content group visible in an interactive PDF processor's user
      # interface.
      #
      # The OCG is always added to the end of the specified +path+ or, if +path+ is not specified,
      # the top level.
      #
      # The optional argument +path+ specifies the strings or OCGs under which the given OCG should
      # hierarchically be nested. A string is used as a non-selectable label, an OCG reflects an
      # actual nesting of the involved OCGs.
      #
      # Examples:
      #
      #  configuration.add_ocg_to_ui(ocg)                   # Add the OCG as top-level item
      #  configuration.add_ocg_to_ui(ocg, path: 'Debug')    # Add the OCG under the label 'Debug'
      #  # Add the OCG under the label 'Page1' which is under the label 'Debug'
      #  configuration.add_ocg_to_ui(ocg, path: ['Debug', 'Page1'])
      #  configuration.add_ocg_to_ui(ocg, path: other_ocg)  # Add the OCG under the other OCG
      def add_ocg_to_ui(ocg, path: nil)
        array = self[:Order] ||= []
        path = Array(path)
        until path.empty?
          item = path.shift
          index = array.index do |entry|
            if (entry.kind_of?(Array) || entry.kind_of?(PDFArray)) && item.kind_of?(String)
              entry.first == item
            else
              entry == item
            end
          end

          if item.kind_of?(String)
            unless index
              array << [item]
              index = -1
            end
            array = array[index]
          else
            unless index
              array << item << []
              index = -2
            end
            unless array[index + 1].kind_of?(Array) || array[index + 1].kind_of?(PDFArray)
              array.insert(index + 1, [])
            end
            array = array[index + 1]
          end
        end
        array << ocg
      end

    end

  end
end
