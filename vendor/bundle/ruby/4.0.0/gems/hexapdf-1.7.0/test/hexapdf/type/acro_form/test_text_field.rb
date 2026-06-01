# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/document'
require 'hexapdf/type/acro_form/text_field'

describe HexaPDF::Type::AcroForm::TextField do
  before do
    @doc = HexaPDF::Document.new
    @field = @doc.add({FT: :Tx}, type: :XXAcroFormField, subtype: :Tx)
  end

  it "identifies as an :XXAcroFormField type" do
    assert_equal(:XXAcroFormField, @field.type)
  end

  it "resolves /MaxLen as inheritable field" do
    assert_nil(@field[:MaxLen])

    @field[:Parent] = {MaxLen: 5}
    assert_equal(5, @field[:MaxLen])

    @field[:MaxLen] = 6
    assert_equal(6, @field[:MaxLen])
  end

  it "can be initialized as a multiline text field" do
    @field.flag(:comb)
    @field.initialize_as_multiline_text_field
    assert(@field.multiline_text_field?)
  end

  it "can be initialized as comb text field" do
    @field.flag(:multiline)
    @field.initialize_as_comb_text_field
    assert(@field.comb_text_field?)
  end

  it "can be initialized as password field" do
    @field.flag(:multiline)
    @field[:V] = 'test'
    @field.initialize_as_password_field
    assert_nil(@field[:V])
    assert(@field.password_field?)
  end

  it "can be initialized as a file select field" do
    @field.flag(:multiline)
    @field.initialize_as_file_select_field
    assert(@field.file_select_field?)
  end

  it "can check whether the field is a multiline text field" do
    refute(@field.multiline_text_field?)
    @field.flag(:multiline)
    assert(@field.multiline_text_field?)
  end

  it "can check whether the field is a comb text field" do
    refute(@field.comb_text_field?)
    @field.flag(:comb)
    assert(@field.comb_text_field?)
  end

  it "can check whether the field is a password field" do
    refute(@field.password_field?)
    @field.flag(:password)
    assert(@field.password_field?)
  end

  it "can check whether the field is a file select field" do
    refute(@field.file_select_field?)
    @field.flag(:file_select)
    assert(@field.file_select_field?)
  end

  describe "field_value" do
    it "handles unset values" do
      assert_nil(@field.field_value)
    end

    it "handles string values" do
      @field[:V] = "str"
      assert_equal("str", @field.field_value)
    end

    it "handles stream values" do
      @field[:V] = @doc.wrap({}, stream: "str")
      assert_equal("str", @field.field_value)
    end
  end

  describe "field_value=" do
    it "sets the field to the given value" do
      @field.field_value = 'str'
      assert_equal('str', @field.field_value)
    end

    it "converts whitespace characters to simple spaces for single line text fields" do
      @field.field_value = "str\ning"
      assert_equal('str ing', @field.field_value)
    end

    it "allows unsetting the value using +nil+" do
      @field[:V] = "test"
      @field.field_value = nil
      assert_nil(@field.field_value)
    end

    it "updates the widgets to reflect the changed value" do
      widget = @field.create_widget(@doc.pages.add, Rect: [0, 0, 0, 0])
      @field.set_default_appearance_string
      @field.field_value = 'str'
      assert(widget[:AP][:N])
    end

    it "calls acro_form.on_invalid_value if the provided value is not a string" do
      @doc.config['acro_form.on_invalid_value'] = proc {|_field, value| value.to_s }
      @field.field_value = 10
      assert_equal("10", @field.field_value)
    end

    it "fails if the :password flag is set" do
      @field.flag(:password)
      assert_raises(HexaPDF::Error) { @field.field_value = 'test' }
    end

    it "fails if it is a comb text field without a /MaxLen entry" do
      @field.initialize_as_comb_text_field
      assert_raises(HexaPDF::Error) { @field.field_value = 'test' }
    end

    it "calls acro_form.text_field.on_max_len_exceeded  if the value exceeds the length set by /MaxLen" do
      @field[:MaxLen] = 5
      assert_raises(HexaPDF::Error) { @field.field_value = 'testdf' }
      @doc.config['acro_form.text_field.on_max_len_exceeded'] = proc {|f, v| v }
      @field.field_value = 'testdf'
      assert_equal('testdf', @field[:V])
    end
  end

  it "sets and returns the default field value" do
    @field.default_field_value = 'hallo'
    assert_equal('hallo', @field.default_field_value)
  end

  it "returns the correct concrete field type" do
    assert_equal(:single_line_text_field, @field.concrete_field_type)
    @field.flag(:multiline, clear_existing: true)
    assert_equal(:multiline_text_field, @field.concrete_field_type)
    @field.flag(:password, clear_existing: true)
    assert_equal(:password_field, @field.concrete_field_type)
    @field.flag(:file_select, clear_existing: true)
    assert_equal(:file_select_field, @field.concrete_field_type)
    @field.flag(:comb, clear_existing: true)
    assert_equal(:comb_text_field, @field.concrete_field_type)
    @field.flag(:rich_text, clear_existing: true)
    assert_equal(:rich_text_field, @field.concrete_field_type)
  end

  describe "create_appearances" do
    before do
      @doc.acro_form(create: true)
      @field.create_widget(@doc.pages.add, Rect: [0, 0, 0, 0])
      @field.set_default_appearance_string
    end

    it "creates the needed streams" do
      @field.create_appearances
      assert(@field[:AP][:N])
    end

    it "doesn't create a new appearance stream if the field value hasn't changed, checked per widget" do
      @field.create_appearances
      stream = @field[:AP][:N].raw_stream
      @field.create_appearances
      assert_same(stream, @field[:AP][:N].raw_stream)
      @field.field_value = 'test'
      refute_same(stream, @field[:AP][:N].raw_stream)
      stream = @field[:AP][:N].raw_stream

      widget = @field.create_widget(@doc.pages.add, Rect: [0, 0, 0, 0])
      assert_nil(widget[:AP])
      @field.create_appearances
      refute_nil(widget[:AP][:N])

      @doc.clear_cache
      @field.create_appearances
      assert_same(stream, @field[:Kids][0][:AP][:N].raw_stream)

      @doc.clear_cache
      @field.field_value = 'other'
      refute_same(stream, @field[:Kids][0][:AP][:N].raw_stream)
    end

    it "always creates a new appearance stream if force is true" do
      @field.create_appearances
      stream = @field[:AP][:N].raw_stream
      @field.create_appearances(force: true)
      refute_same(stream, @field[:AP][:N].raw_stream)
    end

    it "uses the configuration option acro_form.appearance_generator" do
      @doc.config['acro_form.appearance_generator'] = 'NonExistent'
      assert_raises(Exception) { @field.create_appearances }
    end
  end

  describe "set_format_action" do
    it "applies the number format" do
      @doc.acro_form(create: true)
      @field.set_format_action(:number, decimals: 0)
      assert(@field.key?(:AA))
      assert(@field[:AA].key?(:F))
      assert_equal('AFNumber_Format(0, 0, 0, 0, "", true);', @field[:AA][:F][:JS])
    end

    it "applies the percent format" do
      @doc.acro_form(create: true)
      @field.set_format_action(:percent, decimals: 0)
      assert(@field.key?(:AA))
      assert(@field[:AA].key?(:F))
      assert_equal('AFPercent_Format(0, 0);', @field[:AA][:F][:JS])
    end

    it "applies the time format" do
      @doc.acro_form(create: true)
      @field.set_format_action(:time, format: :hh_mm_ss)
      assert(@field.key?(:AA))
      assert(@field[:AA].key?(:F))
      assert_equal('AFTime_Format(2);', @field[:AA][:F][:JS])
    end

    it "fails if an unknown format action is specified" do
      assert_raises(ArgumentError) { @field.set_format_action(:unknown) }
    end
  end

  describe "set_calculate_action" do
    before do
      @form = @doc.acro_form(create: true)
      @form.create_text_field('text1')
      @form.create_text_field('text2')
    end

    it "sets the calculate action using AFSimple_Calculate" do
      @field.set_calculate_action(:sum, fields: ['text1', @form.field_by_name('text2')])
      assert(@field.key?(:AA))
      assert(@field[:AA].key?(:C))
      assert_equal('AFSimple_Calculate("SUM", ["text1","text2"]);', @field[:AA][:C][:JS])
      assert_equal([@field], @form[:CO].value)
    end

    it "sets the simplified field notation calculate action" do
      @field.set_calculate_action(:sfn, fields: "text1")
      assert_equal('/** BVCALC text1 EVCALC **/ event.value = AFMakeNumber(getField("text1").value)',
                   @field[:AA][:C][:JS])
    end

    it "fails if an unknown calculate action is specified" do
      assert_raises(ArgumentError) { @field.set_calculate_action(:unknown) }
    end
  end

  describe "validation" do
    it "checks the value of the /FT field" do
      @field.delete(:FT)
      refute(@field.validate(auto_correct: false))
      assert(@field.validate)
      assert_equal(:Tx, @field.field_type)
    end

    it "checks that the field value has a valid type" do
      assert(@field.validate) # no field value
      @field[:V] = [5]
      refute(@field.validate)
    end

    it "converts an invalid Symbol value to string" do
      @field[:V] = :sym
      assert(@field.validate)
      assert_equal('sym', @field[:V])
    end

    it "checks the field value against /MaxLen" do
      @field[:V] = 'Test'
      assert(@field.validate)
      @field[:MaxLen] = 2
      refute(@field.validate)
      @doc.config['acro_form.text_field.on_max_len_exceeded'] = proc {|field, str| "Hello" }
      assert(@field.validate)
      assert_equal('Hello', @field[:V])
      @field[:V] = nil
      assert(@field.validate)
    end

    it "checks that /MaxLen is set for comb text fields" do
      @field.initialize_as_comb_text_field
      refute(@field.validate)
      @field[:MaxLen] = 2
      assert(@field.validate)
    end
  end
end
