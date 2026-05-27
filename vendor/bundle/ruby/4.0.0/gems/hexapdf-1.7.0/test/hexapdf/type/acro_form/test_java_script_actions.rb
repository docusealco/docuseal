# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/document'
require 'hexapdf/type/acro_form/java_script_actions'

describe HexaPDF::Type::AcroForm::JavaScriptActions do
  before do
    @klass = HexaPDF::Type::AcroForm::JavaScriptActions
    @action = {S: :JavaScript}
  end

  describe "format" do
    it "returns the original value if the format action can't be processed" do
      @action[:JS] = 'Unknown();'
      @klass.apply_format("10", @action)
    end

    describe "AFNumber_Format" do
      before do
        @value = '1234567.898765'
        @action[:JS] = ''
      end

      it "returns a correct JavaScript string" do
        assert_equal('AFNumber_Format(2, 0, 0, 0, "", true);',
                     @klass.af_number_format_action)
        assert_equal('AFNumber_Format(1, 1, 1, 0, "E", false);',
                     @klass.af_number_format_action(decimals: 1, separator_style: :point_no_thousands,
                                                    negative_style: :red, currency_string: "E",
                                                    prepend_currency: false))
      end

      it "raise an error for invalid arguments" do
        assert_raises(ArgumentError) { @klass.af_number_format_action(separator_style: :unknown) }
        assert_raises(ArgumentError) { @klass.af_number_format_action(negative_style: :unknown) }
      end

      def assert_format(arg_string, result_value, result_color)
        @action[:JS] = "AFNumber_Format(#{arg_string});"
        value, text_color = @klass.apply_format(@value, @action)
        assert_equal(result_value, value)
        result_color ? assert_equal(result_color, text_color) : assert_nil(text_color)
      end

      it "works with both commas and points as decimal separator" do
        @value = '1234567.898'
        assert_format('2, 2, 0, 0, "", false', "1.234.567,90", "black")
        @value = '1234567,898'
        assert_format('2, 2, 0, 0, "", false', "1.234.567,90", "black")
        @value = '123,4567,898'
        assert_format('2, 2, 0, 0, "", false', "123,46", "black")
      end

      it "respects the set number of decimals" do
        assert_format('0, 2, 0, 0, "E", false', "1.234.568E", "black")
        assert_format('2, 2, 0, 0, "E", false', "1.234.567,90E", "black")
      end

      it "respects the digit separator style" do
        ["1,234,567.90", "1234567.90", "1.234.567,90", "1234567,90"].each_with_index do |result, style|
          assert_format("2, #{style}, 0, 0, \"\", false", result, "black")
        end
      end

      it "respects the negative value styling" do
        @value = '-1234567.898'
        [["-E1234567,90", "black"], ["E1234567,90", "red"], ["(E1234567,90)", "black"],
         ["(E1234567,90)", "red"]].each_with_index do |result, style|
          assert_format("2, 3, #{style}, 0, \"E\", true", result[0], result[1])
        end
      end

      it "respects the specified currency string and position" do
        assert_format('2, 3, 0, 0, " E", false', "1234567,90 E", "black")
        assert_format('2, 3, 0, 0, "E ", true', "E 1234567,90", "black")
      end

      it "allows omitting the trailing semicolon" do
        @action[:JS] = "AFNumber_Format(2,2,0,0,\"\",false )"
        value, = @klass.apply_format('1234.567', @action)
        assert_equal('1.234,57', value)
      end

      it "works with the special Infinity and NaN values" do
        @value = 'Infinity'
        assert_format('2, 2, 0, 0, "", false', "Inf", "black")
        @value = '-Infinity'
        assert_format('2, 2, 0, 0, "", false', "-Inf", "black")
        @value = 'Nan'
        assert_format('2, 2, 0, 0, "", false', "NaN", "black")
      end

      it "works if the value is nil" do
        @value = nil
        assert_format('2, 2, 0, 0, "", false', "0,00", "black")
      end

      it "does nothing to the value if the JavaScript method could not be determined " do
        assert_format('2, 3, 0, 0, " E", false, a', "1234567.898765", nil)
      end
    end

    describe "AFPercent_Format" do
      before do
        @value = '123.456789'
        @action[:JS] = ''
      end

      it "returns a correct JavaScript string" do
        assert_equal('AFPercent_Format(2, 0);',
                     @klass.af_percent_format_action)
        assert_equal('AFPercent_Format(1, 1);',
                     @klass.af_percent_format_action(decimals: 1, separator_style: :point_no_thousands))
      end

      it "raise an error for invalid arguments" do
        assert_raises(ArgumentError) { @klass.af_percent_format_action(separator_style: :unknown) }
      end

      def assert_format(arg_string, result_value)
        @action[:JS] = "AFPercent_Format(#{arg_string});"
        value, text_color = @klass.apply_format(@value, @action)
        assert_equal(result_value, value)
        assert_nil(text_color)
      end

      it "works with both commas and points as decimal separator" do
        @value = '123.456789'
        assert_format('2, 2', "12.345,68%")
        @value = '123,456789'
        assert_format('2, 2', "12.345,68%")
        @value = '123,4567,89'
        assert_format('2, 2', "12.345,67%")
      end

      it "respects the set number of decimals" do
        assert_format('0, 2', "12.346%")
        assert_format('2, 2', "12.345,68%")
      end

      it "respects the digit separator style" do
        ["12,345.68%", "12345.68%", "12.345,68%", "12345,68%"].each_with_index do |result, style|
          assert_format("2, #{style}", result)
        end
      end

      it "allows omitting the trailing semicolon" do
        @action[:JS] = "AFPercent_Format(2,2 )"
        value, = @klass.apply_format('1.234', @action)
        assert_equal('123,40%', value)
      end

      it "does nothing to the value if the JavaScript method could not be determined " do
        assert_format('2, "df"', "123.456789")
      end
    end

    describe "AFTime_Format" do
      before do
        @value = '15:25:37'
        @action[:JS] = ''
      end

      it "returns a correct JavaScript string" do
        assert_equal('AFTime_Format(0);',
                     @klass.af_time_format_action)
        assert_equal('AFTime_Format(1);',
                     @klass.af_time_format_action(format: :hh12_mm))
      end

      it "raise an error for invalid arguments" do
        assert_raises(ArgumentError) { @klass.af_time_format_action(format: :unknown) }
      end

      def assert_format(arg_string, result_value)
        @action[:JS] = "AFTime_Format(#{arg_string});"
        value, text_color = @klass.apply_format(@value, @action)
        assert_equal(result_value, value)
        assert_nil(text_color)
      end

      it "respects the time format" do
        ["15:25", "3:25 PM", "15:25:37", "3:25:37 PM"].each_with_index do |result, style|
          assert_format(style, result)
        end
      end

      it "allows omitting the trailing semicolon" do
        @action[:JS] = "AFTime_Format(2 )"
        value, = @klass.apply_format('15:34', @action)
        assert_equal('15:34:00', value)
      end

      it "does nothing to the value if the JavaScript method could not be determined " do
        assert_format('1, "df"', "15:25:37")
      end
    end
  end

  describe "calculate" do
    before do
      @doc = HexaPDF::Document.new
      @form = @doc.acro_form(create: true)
      @form.create_text_field('text')
      @field1 = @form.create_text_field('text.1')
      @field1.field_value = "10"
      @field2 = @form.create_text_field('text.2')
      @field2.field_value = "20"
      @field3 = @form.create_text_field('text.3')
      @field3.field_value = "30"
    end

    it "returns nil if the calculate action is not a JavaScript action" do
      @action[:S] = :GoTo
      assert_nil(@klass.calculate(@form, @action))
    end

    it "returns nil if the calculate action contains unknown JavaScript" do
      @action[:JS] = 'Unknown();'
      assert_nil(@klass.calculate(@form, @action))
    end

    describe "predefined calculations" do
      it "returns a correct JavaScript string" do
        assert_equal('AFSimple_Calculate("SUM", ["text.1","text.2"]);',
                     @klass.af_simple_calculate_action(:sum, ['text.1', @field2]))
      end

      def assert_calculation(function, fields, value)
        fields = fields.map {|field| "\"#{field.full_field_name}\"" }.join(", ")
        @action[:JS] = "AFSimple_Calculate(\"#{function}\", new Array(#{fields}));"
        assert_equal(value, @klass.calculate(@form, @action))
      end

      it "can sum fields" do
        assert_calculation('SUM', [@field1, @field2, @field3], "60")
      end

      it "can average fields" do
        assert_calculation('AVG', [@field1, @field2, @field3], "20")
      end

      it "can multiply fields" do
        assert_calculation('PRD', [@field1, @field2, @field3], "6000")
      end

      it "can find the minimum field value" do
        assert_calculation('MIN', [@field1, @field2, @field3], "10")
      end

      it "can find the maximum field value" do
        assert_calculation('MAX', [@field1, @field2, @field3], "30")
      end

      it "works with floats" do
        @field1.field_value = "10,54"
        assert_calculation('SUM', [@field1, @field2], "30.54")
      end

      it "works with the special values Infinity and NaN" do
        @field1.field_value = "Infinity"
        assert_calculation('SUM', [@field1, @field2], "Infinity")
        @field1.field_value = "NaN"
        assert_calculation('SUM', [@field1, @field2], "NaN")
      end

      it "returns nil if a field cannot be resolved" do
        @action[:JS] = 'AFSimple_Calculate("SUM", ["unknown"]);'
        assert_nil(@klass.calculate(@form, @action))
      end

      it "allows omitting the trailing semicolon" do
        @action[:JS] = 'AFSimple_Calculate("SUM", ["text.1"] )'
        assert_equal("10", @klass.calculate(@form, @action))
      end
    end

    describe "simplified field notation calculations" do
      it "returns a correct JavaScript string" do
        sfn = '(text.1 + text.2) * text.3 - text.1 / text.1 + 0 + 5.43 + 7,24'
        assert_equal("/** BVCALC #{sfn} EVCALC **/ " \
                     'event.value = (AFMakeNumber(getField("text.1").value) + ' \
                     'AFMakeNumber(getField("text.2").value)) * ' \
                     'AFMakeNumber(getField("text.3").value) - ' \
                     'AFMakeNumber(getField("text.1").value) / ' \
                     'AFMakeNumber(getField("text.1").value) ' \
                     '+ 0.0 + 5.43 + 7.24',
                     @klass.simplified_field_notation_action(@form, sfn))
      end

      it "fails if the SFN string is invalid when generating a JavaScript action string" do
        assert_raises(ArgumentError) { @klass.simplified_field_notation_action(@form, '(test') }
      end

      def assert_calculation(sfn, value)
        @action[:JS] = "/** BVCALC #{sfn} EVCALC **/"
        result = @klass.calculate(@form, @action)
        value ? assert_equal(value, result) : assert_nil(result)
      end

      it "works for additions" do
        assert_calculation('text.1 + text.2 + text.1', "40")
      end

      it "works for substraction" do
        assert_calculation('text.2-text\.1', "10")
      end

      it "works for multiplication" do
        assert_calculation('text.2\* text\.1 * text\.3', "6000")
      end

      it "works for division" do
        assert_calculation('text.2 /text\.1', "2")
      end

      it "works with parentheses" do
        assert_calculation('(text.2 + (text.1*text.3))', "320")
      end

      it "works with numbers" do
        assert_calculation('text.1 + 10.54 - 1,54 + 3', "22")
      end

      it "works in a more complex case" do
        assert_calculation('(text.1 + text.2)/(text.3) * text.1', "10")
      end

      it "works with floats" do
        @field1.field_value = "10,54"
        assert_calculation('text.1 + text.2', "30.54")
      end

      it "fails if a referenced field is not a terminal field" do
        assert_calculation('text + text.2', nil)
      end

      it "fails if a referenced field does not exist" do
        assert_calculation('unknown + text.2', nil)
      end

      it "fails if parentheses don't match" do
        assert_calculation('(text.1 + text.2', nil)
      end
    end
  end
end
