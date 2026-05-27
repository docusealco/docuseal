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

    # Represents a page label dictionary.
    #
    # A page label dictionary contains information about the numbering style, the label prefix and
    # the start number to construct page labels like 'A-1' or 'iii'. What is not stored is the page
    # to which it is applied since that is stored in a number tree referenced through the
    # /PageLabels entry in the document catalog.
    #
    # See HexaPDF::Document::Pages for details on how to create and manage page labels.
    #
    # Examples:
    #
    # * numbering style :decimal, prefix none, start number default value
    #
    #   1, 2, 3, 4, ...
    #
    # * numbering style :lowercase_letters, prefix 'Appendix ', start number 5
    #
    #   Appendix e, Appendix f, Appendix g, ...
    #
    # * numbering style :uppercase_roman, prefix none, start number 10
    #
    #   X, XI, XII, XIII, ...
    #
    # * numbering style :none, prefix 'Page', start number default value
    #
    #   Page, Page, Page, Page, ...
    #
    # * numbering style :none, prefix none, start number default value
    #
    #   "", "", "", ... (i.e. always the empty string)
    #
    # See: PDF2.0 s12.4.2, HexaPDF::Document::Pages, HexaPDF::Type::Catalog
    class PageLabel < Dictionary

      define_type :PageLabel

      define_field :Type, type: Symbol, default: type
      define_field :S,    type: Symbol, allowed_values: [:D, :R, :r, :A, :a]
      define_field :P,    type: String
      define_field :St,   type: Integer, default: 1

      # Constructs the page label for the given index which needs to be relative to the page index
      # of the first page in the associated labelling range.
      #
      # This method is usually not called directly but through HexaPDF::Document::Pages#page_label.
      def construct_label(index)
        label = (prefix || '').dup
        number = start_number + index
        case numbering_style
        when :decimal
          label + number.to_s
        when :uppercase_roman
          label + number_to_roman_numeral(number)
        when :lowercase_roman
          label + number_to_roman_numeral(number, lowercase: true)
        when :uppercase_letters
          label + number_to_letters(number)
        when :lowercase_letters
          label + number_to_letters(number, lowercase: true)
        when :none
          label
        end
      end

      NUMBERING_STYLE_MAPPING = { # :nodoc:
        decimal: :D, D: :D,
        uppercase_roman: :R, R: :R,
        lowercase_roman: :r, r: :r,
        uppercase_letters: :A, A: :A,
        lowercase_letters: :a, a: :a,
        none: nil
      }

      REVERSE_NUMBERING_STYLE_MAPPING = Hash[*NUMBERING_STYLE_MAPPING.flatten.reverse] # :nodoc:

      # :call-seq:
      #   page_label.numbering_style             -> numbering_style
      #   page_label.numbering_style(value)      -> numbering_style
      #
      # Returns the numbering style if no argument is given. Otherwise sets the numbering style to
      # the given value.
      #
      # The following numbering styles are available:
      #
      # :none:: No numbering is done; the label only consists of the prefix.
      # :decimal:: Decimal arabic numerals (1, 2, 3, 4, ...).
      # :uppercase_roman:: Uppercase roman numerals (I, II, III, IV, ...)
      # :lowercase_roman:: Lowercase roman numerals (i, ii, iii, iv, ...)
      # :uppercase_letters:: Uppercase letters (A, B, C, D, ...)
      # :lowercase_letters:: Lowercase letters (a, b, c, d, ...)
      def numbering_style(value = nil)
        if value
          self[:S] = NUMBERING_STYLE_MAPPING.fetch(value) do
            raise ArgumentError, "Invalid numbering style specified: #{value}"
          end
        else
          REVERSE_NUMBERING_STYLE_MAPPING.fetch(self[:S], :none)
        end
      end

      # :call-seq:
      #   page_label.prefix             -> prefix
      #   page_label.prefix(value)      -> prefix
      #
      # Returns the label prefix if no argument is given. Otherwise sets the label prefix to the
      # given string value.
      def prefix(value = nil)
        if value
          self[:P] = value
        else
          self[:P]
        end
      end

      # :call-seq:
      #   page_label.start_number             -> start_number
      #   page_label.start_number(value)      -> start_number
      #
      # Returns the start number if no argument is given. Otherwise sets the start number to the
      # given integer value.
      def start_number(value = nil)
        if value
          if !value.kind_of?(Integer) || value < 1
            raise ArgumentError, "Start number must be an integer greater than or equal to 1"
          end
          self[:St] = value
        else
          self[:St]
        end
      end

      private

      ALPHABET = ('A'..'Z').to_a # :nodoc:

      # Maps the given number to uppercase (or, if +lowercase+ is +true+, lowercase) letters (e.g. 1
      # -> A, 27 -> AA, 28 -> AB, ...).
      def number_to_letters(number, lowercase: false)
        result = "".dup
        while number > 0
          number, rest = (number - 1).divmod(26)
          result.prepend(ALPHABET[rest])
        end
        lowercase ? result.downcase : result
      end

      ROMAN_NUMERAL_MAPPING = { # :nodoc:
        1000 => "M",
        900 => "CM",
        500 => "D",
        400 => "CD",
        100 => "C",
        90 => "XC",
        50 => "L",
        40 => "XL",
        10 => "X",
        9 => "IX",
        5 => "V",
        4 => "IV",
        1 => "I",
      }

      # Maps the given number to an uppercase (or, if +lowercase+ is +true+, lowercase) roman
      # numeral.
      def number_to_roman_numeral(number, lowercase: false)
        result = ROMAN_NUMERAL_MAPPING.inject("".dup) do |memo, (base, roman_numeral)|
          next memo if number < base
          quotient, number = number.divmod(base)
          memo << roman_numeral * quotient
        end
        lowercase ? result.downcase : result
      end

    end

  end
end
