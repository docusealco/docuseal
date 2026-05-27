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
require 'time'
require 'hexapdf/error'
require 'hexapdf/layout/style'
require 'hexapdf/layout/text_fragment'
require 'hexapdf/layout/text_layouter'

module HexaPDF
  module Type
    module AcroForm

      # The JavaScriptActions module implements JavaScript actions that can be specified for form
      # fields, such as formatting or calculating a field's value.
      #
      # These JavaScript functions are not specified in the PDF specification but can be found in
      # other reference materials (e.g. from Adobe).
      #
      # Formatting a field's value::
      #
      #   The main entry point is #apply_format which applies the format to a value. Supported
      #   JavaScript actions are:
      #
      #   * +AFNumber_Format+: See #af_number_format_action and #apply_af_number_format
      #   * +AFPercent_Format+: See #af_percent_format_action and #apply_af_percent_format
      #
      # Calculating a field's value::
      #
      #   The main entry point is #calculate which calculates a field's value. Supported JavaScript
      #   actions are:
      #
      #   * +AFSimple_Calculate+: See #af_simple_calculate_action and #run_af_simple_calculate
      #   * Simplified Field Notation expressions: See #simplified_field_notation_action and
      #     #run_simplified_field_notation
      #
      # See: PDF2.0 s12.6.4.17
      #
      # See:
      # - https://experienceleague.adobe.com/docs/experience-manager-learn/assets/FormsAPIReference.pdf
      # - https://opensource.adobe.com/dc-acrobat-sdk-docs/library/jsapiref/JS_API_AcroJS.html#printf
      module JavaScriptActions

        # Implements a parser for the simplified field notation used for calculating field values.
        #
        # This notation is used if the predefined functions are too simple but the calculation can
        # still be done by simple arithmetic.
        class SimplifiedFieldNotationParser

          # Raised if there was an error during parsing.
          class ParseError < StandardError; end

          # Creates a new instance for the given AcroForm +form+ instance and simplified field
          # notation string +sfn_string+.
          def initialize(form, sfn_string)
            @form = form
            @tokens = sfn_string.scan(/\p{Alpha}[^()*\/+-]*|\d+(?:[.,]\d*)?|[()*\/+-]/)
          end

          # Parses the string holding the simplified field notation.
          #
          # If +operations+ is :calculate, the calculation is performed and the result returned. If
          # +operations+ is :generate, a JavaScript representation is generated and returned.
          #
          #  +nil+ is returned regardless of the +operations+ value if there was any problem.
          def parse(operations = :calculate)
            operations = (operations == :calculate ? CALCULATE_OPERATIONS : JS_GENERATE_OPERATIONS)
            result = expression(operations)
            @tokens.empty? ? result : nil
          rescue ParseError
            nil
          end

          private

          # Implementation of the operations for calculating the result.
          CALCULATE_OPERATIONS = {
            '+' => lambda {|l, r| l + r },
            '-' => lambda {|l, r| l - r },
            '*' => lambda {|l, r| l * r },
            '/' => lambda {|l, r| l / r },
            field: lambda {|field| JavaScriptActions.af_make_number(field.field_value) },
            number: lambda {|token| JavaScriptActions.af_make_number(token) },
            parens: lambda {|expr| expr },
          }

          # Implementation of the operations for generating the equivalent JavaScript code.
          JS_GENERATE_OPERATIONS = {
            '+' => lambda {|l, r| "#{l} + #{r}" },
            '-' => lambda {|l, r| "#{l} - #{r}" },
            '*' => lambda {|l, r| "#{l} * #{r}" },
            '/' => lambda {|l, r| "#{l} / #{r}" },
            field: lambda {|field| "AFMakeNumber(getField(#{field.full_field_name.to_json}).value)" },
            number: lambda {|token| JavaScriptActions.af_make_number(token).to_s },
            parens: lambda {|expr| "(#{expr})" },
          }

          # Parses the expression at the current position.
          #
          # expression = term [('+'|'-') term]*
          def expression(operations)
            result = term(operations)
            while @tokens.first == '+' || @tokens.first == '-'
              result = operations[@tokens.shift].call(result, term(operations))
            end
            result
          end

          # Parses the term at the current position.
          #
          # term = factor [('*'|'/') factor]*
          def term(operations)
            result = factor(operations)
            while @tokens.first == '*' || @tokens.first == '/'
              result = operations[@tokens.shift].call(result, factor(operations))
            end
            result
          end

          # Parses the factor at the current position.
          #
          # factor = '(' expr ')' | field_name | number
          def factor(operations)
            token = @tokens.shift
            if token == '('
              value = expression(operations)
              raise ParseError, "Unmatched parentheses" unless @tokens.shift == ')'
              operations[:parens].call(value)
            elsif (field = @form.field_by_name(token.strip.gsub('\\', ''))) && field.terminal_field?
              operations[:field].call(field)
            elsif token.match?(/\A\d+(?:[.,]\d*)?\z/)
              operations[:number].call(token)
            else
              raise ParseError, "Invalid token encountered: #{token}"
            end
          end

        end

        module_function

        # Handles JavaScript field format actions for single-line text fields.
        #
        # The argument +value+ is the value that should be formatted and +format_action+ is the PDF
        # format action object that should be applied. The latter may be +nil+ if no associated
        # format action is available.
        #
        # Returns [value, nil_or_text_color] where value is the new, potentially changed field value
        # and the second argument is either +nil+ (no change in color) or the color that should be
        # used for the text value.
        def apply_format(value, format_action)
          return [value, nil] unless (action_string = action_string(format_action))
          if action_string.start_with?('AFNumber_Format(')
            apply_af_number_format(value, action_string)
          elsif action_string.start_with?('AFPercent_Format(')
            apply_af_percent_format(value, action_string)
          elsif action_string.start_with?('AFTime_Format(')
            apply_af_time_format(value, action_string)
          else
            [value, nil]
          end
        end

        AF_NUMBER_FORMAT_MAPPINGS = { #:nodoc:
          separator: {
            point: 0,
            point_no_thousands: 1,
            comma: 2,
            comma_no_thousands: 3,
          },
          negative: {
            minus_black: 0,
            red: 1,
            parens_black: 2,
            parens_red: 3,
          },
        }

        # Returns the appropriate JavaScript action string for the AFNumber_Format function.
        #
        # +decimals+::
        #     The number of decimal digits to use. Default 2.
        #
        # +separator_style+::
        #     Specifies the character for the decimal and thousands separator, one of:
        #
        #     :point:: (Default) Use point as decimal separator and comma as thousands separator.
        #     :point_no_thousands:: Use point as decimal separator and no thousands separator.
        #     :comma:: Use comma as decimal separator and point as thousands separator.
        #     :comma_no_thousands:: Use comma as decimal separator and no thousands separator.
        #
        # +negative_style+::
        #     Specifies how negative numbers should be formatted, one of:
        #
        #     :minus_black:: (Default) Use minus before the number and black as color.
        #     :red:: Just use red as color.
        #     :parens_black:: Use parentheses around the number and black as color.
        #     :parens_red:: Use parentheses around the number and red as color.
        #
        # +currency_string+::
        #      Specifies the currency string that should be used. Default is the empty string.
        #
        # +prepend_currency+::
        #      Specifies whether the currency string should be prepended (+true+, default) or
        #      appended (+false).
        #
        # See: #apply_af_number_format
        def af_number_format_action(decimals: 2, separator_style: :point, negative_style: :minus_black,
                                    currency_string: "", prepend_currency: true)
          separator_style = AF_NUMBER_FORMAT_MAPPINGS[:separator].fetch(separator_style) do
            raise ArgumentError, "Unsupported value for separator_style argument: #{separator_style}"
          end
          negative_style = AF_NUMBER_FORMAT_MAPPINGS[:negative].fetch(negative_style) do
            raise ArgumentError, "Unsupported value for negative_style argument: #{negative_style}"
          end

          "AFNumber_Format(#{decimals}, #{separator_style}, " \
            "#{negative_style}, 0, \"#{currency_string}\", " \
            "#{prepend_currency});"
        end

        # Regular expression for matching the AFNumber_Format method.
        #
        # See: #apply_af_number_format
        AF_NUMBER_FORMAT_RE = /
          \AAFNumber_Format\(
            \s*(?<ndec>\d+)\s*,
            \s*(?<sep_style>[0-3])\s*,
            \s*(?<neg_style>[0-3])\s*,
            \s*0\s*,
            \s*(?<currency_string>".*?")\s*,
            \s*(?<prepend>false|true)\s*
          \);?\z
        /x

        # Implements the JavaScript AFNumber_Format function and returns the formatted field value.
        #
        # The argument +value+ has to be the field's value (a String) and +action_string+ has to be
        # the JavaScript action string.
        #
        # The AFNumber_Format function assumes that the text field's value contains a number (as a
        # string) and formats it according to the instructions.
        #
        # It has the form <tt>AFNumber_Format(no_of_decimals, separator_style, negative_style,
        # currency_style, currency_string, prepend_currency)</tt> where the arguments have the
        # following meaning:
        #
        # +no_of_decimals+::
        #   The number of decimal places after the decimal point, e.g. for 3 it would result in
        #   123.456.
        #
        # +separator_style+::
        #   Defines which decimal separator and whether a thousands separator should be used.
        #
        #   Possible values are:
        #
        #   +0+:: Comma for thousands separator, point for decimal separator: 12,345.67
        #   +1+:: No thousands separator, point for decimal separator: 12345.67
        #   +2+:: Point for thousands separator, comma for decimal separator: 12.345,67
        #   +3+:: No thousands separator, comma for decimal separator: 12345,67
        #
        # +negative_style+::
        #   Defines how negative numbers should be formatted.
        #
        #   Possible values are:
        #
        #   +0+:: With minus and in color black: -12,345.67
        #   +1+:: Just in color red: 12,345.67
        #   +2+:: With parentheses and in color black: (12,345.67)
        #   +3+:: With parentheses and in color red: (12,345.67)
        #
        # +currency_style+::
        #   This argument is not used, should be 0.
        #
        # +currency_string+::
        #   A string with the currency symbol, e.g. € or $.
        #
        # +prepend_currency+::
        #   A boolean defining whether the currency string should be prepended (+true+) or appended
        #   (+false+).
        def apply_af_number_format(value, action_string)
          return [value, nil] unless (match = AF_NUMBER_FORMAT_RE.match(action_string))
          value = af_make_number(value)
          format = "%.#{match[:ndec]}f"
          text_color = 'black'

          currency_string = JSON.parse(match[:currency_string])
          format = (match[:prepend] == 'true' ? currency_string + format : format + currency_string)

          if value < 0
            value = value.abs
            case match[:neg_style]
            when '0' # MinusBlack
              format = "-#{format}"
            when '1' # Red
              text_color = 'red'
            when '2' # ParensBlack
              format = "(#{format})"
            when '3' # ParensRed
              format = "(#{format})"
              text_color = 'red'
            end
          end

          [af_format_number(value, format, match[:sep_style]), text_color]
        end

        # Returns the appropriate JavaScript action string for the AFPercent_Format function.
        #
        # +decimals+::
        #     The number of decimal digits to use. Default 2.
        #
        # +separator_style+::
        #     Specifies the character for the decimal and thousands separator, one of:
        #
        #     :point:: (Default) Use point as decimal separator and comma as thousands separator.
        #     :point_no_thousands:: Use point as decimal separator and no thousands separator.
        #     :comma:: Use comma as decimal separator and point as thousands separator.
        #     :comma_no_thousands:: Use comma as decimal separator and no thousands separator.
        #
        # See: #apply_af_percent_format
        def af_percent_format_action(decimals: 2, separator_style: :point)
          separator_style = AF_NUMBER_FORMAT_MAPPINGS[:separator].fetch(separator_style) do
            raise ArgumentError, "Unsupported value for separator_style argument: #{separator_style}"
          end
          "AFPercent_Format(#{decimals}, #{separator_style});"
        end

        # Regular expression for matching the AFPercent_Format method.
        #
        # See: #apply_af_percent_format
        AF_PERCENT_FORMAT_RE = /
          \AAFPercent_Format\(
            \s*(?<ndec>\d+)\s*,
            \s*(?<sep_style>[0-3])\s*
          \);?\z
        /x

        # Implements the JavaScript AFPercent_Format function and returns the formatted field value.
        #
        # The argument +value+ has to be the field's value (a String) and +action_string+ has to be
        # the JavaScript action string.
        #
        # The AFPercent_Format function assumes that the text field's value contains a number (as a
        # string) and formats it according to the instructions.
        #
        # It has the form <tt>AFPercent_Format(no_of_decimals, separator_style)</tt> where the
        # arguments have the following meaning:
        #
        # +no_of_decimals+::
        #   The number of decimal places after the decimal point, e.g. for 3 it would result in
        #   123.456.
        #
        # +separator_style+::
        #   Defines which decimal separator and whether a thousands separator should be used.
        #
        #   Possible values are:
        #
        #   +0+:: Comma for thousands separator, point for decimal separator: 12,345.67
        #   +1+:: No thousands separator, point for decimal separator: 12345.67
        #   +2+:: Point for thousands separator, comma for decimal separator: 12.345,67
        #   +3+:: No thousands separator, comma for decimal separator: 12345,67
        def apply_af_percent_format(value, action_string)
          return value unless (match = AF_PERCENT_FORMAT_RE.match(action_string))
          af_format_number(af_make_number(value) * 100, "%.#{match[:ndec]}f%%", match[:sep_style])
        end

        AF_TIME_FORMAT_MAPPINGS = { #:nodoc:
          format_integers: {
            hh_mm: 0,
            0 => 0,
            hh12_mm: 1,
            1 => 1,
            hh_mm_ss: 2,
            2 => 2,
            hh12_mm_ss: 3,
            3 => 3,
          },
          strftime_format: {
            '0' => '%H:%M',
            '1' => '%l:%M %p',
            '2' => '%H:%M:%S',
            '3' => '%l:%M:%S %p',
          },
        }

        # Returns the appropriate JavaScript action string for the AFTime_Format function.
        #
        # +format+::
        #     Specifies the time format, one of:
        #
        #     :hh_mm:: (Default) Use 24h time format %H:%M (e.g. 15:25)
        #     :hh12_mm:: (Default) Use 12h time format %l:%M %p (e.g. 3:25 PM)
        #     :hh_mm_ss:: Use 24h time format with seconds %H:%M:%S (e.g. 15:25:37)
        #     :hh12_mm_ss:: Use 24h time format with seconds %l:%M:%S %p (e.g. 3:25:37 PM)
        #
        # See: #apply_af_time_format
        def af_time_format_action(format: :hh_mm)
          format = AF_TIME_FORMAT_MAPPINGS[:format_integers].fetch(format) do
            raise ArgumentError, "Unsupported value for time_format argument: #{format}"
          end
          "AFTime_Format(#{format});"
        end

        # Regular expression for matching the AFTime_Format method.
        #
        # See: #apply_af_time_format
        AF_TIME_FORMAT_RE = /
          \AAFTime_Format\(
            \s*(?<time_format>[0-3])\s*
          \);?\z
        /x

        # Implements the JavaScript AFTime_Format function and returns the formatted field value.
        #
        # The argument +value+ has to be the field's value (a String) and +action_string+ has to be
        # the JavaScript action string.
        #
        # The AFTime_Format function assumes that the text field's value contains a valid time
        # string (for HexaPDF that is anything Time.parse can work with) and formats it according to
        # the instructions.
        #
        # It has the form <tt>AFTime_Format(time_format)</tt> where the argument has the following
        # meaning:
        #
        # +time_format+::
        #   Defines the time format which should be applied.
        #
        #   Possible values are:
        #
        #   +0+:: Use 24h time format, e.g. 15:25
        #   +1+:: Use 12h time format, e.g. 3:25 PM
        #   +2+:: Use 24h time format with seconds, e.g. 15:25:37
        #   +3+:: Use 12h time format with seconds, e.g. 3:25:37 PM
        def apply_af_time_format(value, action_string)
          return value unless (match = AF_TIME_FORMAT_RE.match(action_string))
          value = Time.parse(value) rescue nil
          return "" unless value
          value.strftime(AF_TIME_FORMAT_MAPPINGS[:strftime_format][match[:time_format]]).strip
        end

        # Handles JavaScript calculate actions for single-line text fields.
        #
        # The argument +form+ is the main Form instance of the document (needed for accessing the
        # fields for the calculation) and +calculation_action+ is the PDF calculate action object
        # that should be applied.
        #
        # Returns the calculated value as string if the calculation was succcessful or +nil+
        # otherwise.
        #
        # A calculation may not be successful if
        #
        # * HexaPDF doesn't support the specific calculate action (e.g. because it contains general
        #   JavaScript instructions), or if
        # * there was an error during the calculation (e.g. because a field could not be resolved).
        def calculate(form, calculate_action)
          return nil unless (action_string = action_string(calculate_action))
          result = if action_string.start_with?('AFSimple_Calculate(')
                     run_af_simple_calculate(form, action_string)
                   elsif action_string.match?(/\/\*\*\s*BVCALC/)
                     run_simplified_field_notation(form, action_string)
                   else
                     nil
                   end
          result && (result.finite? && result == result.truncate ? result.to_i.to_s : result.to_s)
        end

        AF_SIMPLE_CALCULATE_MAPPING = { #:nodoc:
          sum: 'SUM',
          average: 'AVG',
          product: 'PRD',
          min: 'MIN',
          max: 'MAX',
        }

        # Returns the appropriate JavaScript action string for the AFSimple_Calculate function.
        #
        # +type+::
        #     The type of operation that should be used, one of:
        #
        #     :sum:: Sums the values of the given +fields+.
        #     :average:: Calculates the average value of the given +fields+.
        #     :product:: Multiplies the values of the given +fields+.
        #     :min:: Uses the minimum value of the given +fields+.
        #     :max:: Uses the maximum value of the given +fields+.
        #
        # +fields+::
        #     An array of form field objects and/or full field names.
        #
        # See: #run_af_simple_calculate
        def af_simple_calculate_action(type, fields)
          fields = fields.map {|field| field.kind_of?(String) ? field : field.full_field_name }
          "AFSimple_Calculate(\"#{AF_SIMPLE_CALCULATE_MAPPING[type]}\", #{fields.to_json});"
        end

        # Regular expression for matching the AFSimple_Calculate function.
        #
        # See: #run_af_simple_calculate
        AF_SIMPLE_CALCULATE_RE = /
          \AAFSimple_Calculate\(
            \s*"(?<function>AVG|SUM|PRD|MIN|MAX)"\s*,
            \s*(?<fields>.*)\s*
          \);?\z
        /x

        # Mapping of AFSimple_Calculate function names to implementations.
        #
        # See: #run_af_simple_calculate
        AF_SIMPLE_CALCULATE = {
          'AVG' => lambda {|values| values.sum / values.length },
          'SUM' => lambda {|values| values.sum },
          'PRD' => lambda {|values| values.inject {|product, val| product * val } },
          'MIN' => lambda {|values| values.min },
          'MAX' => lambda {|values| values.max },
        }

        # Implements the JavaScript AFSimple_Calculate function and returns the calculated value.
        #
        # The argument +form+ has to be the document's main AcroForm object and +action_string+ has
        # to be the JavaScript action string.
        #
        # The AFSimple_Calculate function applies one of several predefined functions to the values
        # of the given fields. The values of those fields need to be strings representing numbers.
        #
        # It has the form <tt>AFSimple_Calculate(function, fields))</tt> where the arguments have
        # the following meaning:
        #
        # +function+::
        #   The name of the calculation function that should be applied to the values.
        #
        #   Possible values are:
        #
        #   +SUM+:: Calculate the sum of the given field values.
        #   +AVG+:: Calculate the average of the given field values.
        #   +PRD+:: Calculate the product of the given field values.
        #   +MIN+:: Calculate the minimum of the given field values.
        #   +MAX+:: Calculate the maximum of the given field values.
        #
        # +fields+::
        #   An array of AcroForm field names the values of which should be used.
        def run_af_simple_calculate(form, action_string)
          return nil unless (match = AF_SIMPLE_CALCULATE_RE.match(action_string))
          function = match[:function]
          values = match[:fields].scan(/".*?"/).map do |name|
            return nil unless (field = form.field_by_name(name[1..-2]))
            af_make_number(field.field_value)
          end
          AF_SIMPLE_CALCULATE.fetch(function)&.call(values)
        end

        # Returns the appropriate JavaScript action string for a calculate action that uses
        # Simplified Field Notation.
        #
        # The argument +form+ has to be the document's main AcroForm object and +sfn_string+ the
        # string containing the simplified field notation.
        #
        # See: #run_simplified_field_notation
        def simplified_field_notation_action(form, sfn_string)
          js_part = SimplifiedFieldNotationParser.new(form, sfn_string).parse(:generate)
          raise ArgumentError, "Invalid simplified field notation rule" unless js_part
          "/** BVCALC #{sfn_string} EVCALC **/ event.value = #{js_part}"
        end

        # Implements parsing of the simplified field notation (SFN).
        #
        # The argument +form+ has to be the document's main AcroForm object and +action_string+ has
        # to be the JavaScript action string.
        #
        # This notation is more powerful than AFSimple_Calculate as it allows arbitrary expressions
        # consisting of additions, substractions, multiplications and divisions, possibly grouped
        # using parentheses, and field names (which stand in for their value) as well as numbers.
        #
        # Note: The implementation has been created by looking at sample documents using SFN. As
        # such this may not work for all documents that use SFN.
        def run_simplified_field_notation(form, action_string)
          return nil unless (match = /BVCALC(.*?)EVCALC/m.match(action_string))
          SimplifiedFieldNotationParser.new(form, match[1]).parse
        end

        # Returns the numeric value of the string, interpreting comma as point.
        def af_make_number(value)
          value = value.to_s
          if value.match?(/(?:[+-])?Inf(?:inity)?/i)
            value.start_with?('-') ? -Float::INFINITY : Float::INFINITY
          elsif value.match?(/NaN/i)
            Float::NAN
          else
            value.tr(',', '.').to_f
          end
        end

        # Formats the numeric value according to the format string and separator style.
        def af_format_number(value, format, sep_style)
          result = sprintf(format, value)

          before_decimal_point, after_decimal_point = result.split('.')
          if sep_style == '0' || sep_style == '2'
            separator = (sep_style == '0' ? ',' : '.')
            before_decimal_point.gsub!(/\B(?=(\d\d\d)+(?:[^\d]|\z))/, separator)
          end

          if after_decimal_point
            decimal_point = (sep_style <= "1" ? '.' : ',')
            "#{before_decimal_point}#{decimal_point}#{after_decimal_point}"
          else
            before_decimal_point
          end
        end

        # Returns the JavaScript action string for the given action.
        def action_string(action)
          return nil unless action && action[:S] == :JavaScript
          result = action[:JS]
          result.kind_of?(HexaPDF::Stream) ? result.stream : result
        end
        private :action_string

      end

    end
  end
end
