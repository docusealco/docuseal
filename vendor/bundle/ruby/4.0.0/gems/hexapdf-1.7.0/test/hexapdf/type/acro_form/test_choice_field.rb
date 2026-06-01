# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/document'
require 'hexapdf/type/acro_form/choice_field'

describe HexaPDF::Type::AcroForm::ChoiceField do
  before do
    @doc = HexaPDF::Document.new
    @field = @doc.add({FT: :Ch, T: 'choice'}, type: :XXAcroFormField, subtype: :Ch)
  end

  it "identifies as an :XXAcroFormField type" do
    assert_equal(:XXAcroFormField, @field.type)
  end

  it "can be initialized as list box" do
    @field.initialize_as_list_box
    assert_nil(@field[:V])
    assert(@field.list_box?)
  end

  it "can be initialized as combo box" do
    @field.initialize_as_combo_box
    assert_nil(@field[:V])
    assert(@field.combo_box?)
  end

  describe "field_value" do
    it "returns the correct Unicode string value" do
      @field[:V] = "H\xe4llo".b
      assert_equal("Hällo", @field.field_value)
    end

    it "returns an array of Unicode string values" do
      @field[:V] = ["H\xe4llo".b, "\xFE\xFF".b << "Óthér".encode('UTF-16BE').b]
      assert_equal(["Hällo", "Óthér"], @field.field_value)
    end
  end

  describe "field_value=" do
    before do
      @field.option_items = ["test", "something", "other", "neu"]
    end

    it "updates the widgets to reflect the changed value" do
      @field.initialize_as_combo_box
      widget = @field.create_widget(@doc.pages.add, Rect: [0, 0, 0, 0])
      @field.set_default_appearance_string
      @field.field_value = 'test'
      assert(widget[:AP][:N])
    end

    describe "combo_box" do
      before do
        @field.initialize_as_combo_box
        @field[:I] = 2
      end

      it "can set the value for an uneditable combo box" do
        @field.field_value = 'test'
        assert_equal("test", @field[:V])
        assert_nil(@field[:I])
      end

      it "can set the value for an editable combo box" do
        @field.flag(:edit)
        @field.field_value = 'another'
        assert_equal("another", @field[:V])
        assert_nil(@field[:I])
      end

      it "fails if mulitple values are provided for a combo box" do
        assert_raises(HexaPDF::Error) { @field.field_value = ['a', 'b'] }
      end

      it "fails if an unlisted value is specified for an uneditable combo box" do
        assert_raises(HexaPDF::Error) { @field.field_value = 'a' }
      end
    end

    describe "list_box" do
      before do
        @field.initialize_as_list_box
      end

      it "can set a single value" do
        @field.field_value = 'test'
        assert_equal("test", @field[:V])
      end

      it "can set a multiple values if the list box is a multi-select" do
        @field.flag(:multi_select)
        @field.field_value = ['other', 'test']
        assert_equal(['other', 'test'], @field[:V].value)
        assert_equal([0, 2], @field[:I].value)
      end

      it "can read and set the top index" do
        assert_raises(ArgumentError) { @field.list_box_top_index = 4 }
        @field.delete(:Opt)
        assert_raises(ArgumentError) { @field.list_box_top_index = 0 }
        @field.option_items = [1, 2, 3, 4]
        @field.list_box_top_index = 2
        assert_equal(2, @field.list_box_top_index)
      end

      it "fails if mulitple values are provided but the list box is not a multi-select" do
        assert_raises(HexaPDF::Error) { @field.field_value = ['a', 'b'] }
      end

      it "fails if an unlisted value is specified" do
        assert_raises(HexaPDF::Error) { @field.field_value = 'a' }
      end
    end
  end

  it "sets and returns the default field value" do
    @field.option_items = ["hällo"]
    @field.default_field_value = 'hällo'
    assert_equal('hällo', @field.default_field_value)
    assert_raises(HexaPDF::Error) { @field.default_field_value = 'unknown' }
  end

  describe "option items" do
    before do
      @items = [["a", "Zx"], "\xFE\xFF".b << "Töne".encode('UTF-16BE').b, "H\xe4llo".b]
    end

    it "sets the option items" do
      @field.option_items = @items
      assert_equal(@items, @field[:Opt].value)

      @field.flag(:sort)
      @field.option_items = @items
      assert_equal(@items.values_at(2, 1, 0), @field[:Opt].value)
    end

    it "can retrieve the option items" do
      @field[:Opt] = @items
      assert_equal(["Zx", "Töne", "Hällo"], @field.option_items)
    end

    it "can retrieve the export values" do
      @field[:Opt] = @items
      assert_equal(["a", "Töne", "Hällo"], @field.export_values)
    end

    it "can retrieve the option items/export values if they are set on a widget and not on the field" do
      @field.create_widget(@doc.pages.add, allow_embedded: false, Rect: [0, 0, 0, 0], Opt: @items)
      @field.create_widget(@doc.pages.add, Rect: [0, 0, 0, 0], Opt: ['other'])
      assert_equal(["Zx", "Töne", "Hällo"], @field.option_items)
      assert_equal(["a", "Töne", "Hällo"], @field.export_values)
    end
  end

  it "returns the correct concrete field type" do
    assert_equal(:list_box, @field.concrete_field_type)
    @field.initialize_as_combo_box
    assert_equal(:combo_box, @field.concrete_field_type)
  end

  describe "create_appearances" do
    before do
      @widget = @field.create_widget(@doc.pages.add, Rect: [0, 0, 0, 0])
    end

    it "works for combo box fields" do
      @field.initialize_as_combo_box
      @field.set_default_appearance_string
      @field.create_appearances
      assert(@field[:AP][:N])
    end

    it "works for list box fields" do
      @field.initialize_as_list_box
      @field.set_default_appearance_string
      @field.create_appearances
      assert(@field[:AP][:N])
    end

    it "only creates a new appearance if the involved dictionary values have changed per widget" do
      @field.initialize_as_list_box
      @field.set_default_appearance_string
      @field.create_appearances
      appearance_stream = @field[:AP][:N].raw_stream

      @field.create_appearances
      assert_same(appearance_stream, @field[:AP][:N].raw_stream)

      do_check = lambda do
        @field.create_appearances
        refute_same(appearance_stream, @field[:AP][:N].raw_stream)
        appearance_stream = @field[:AP][:N].raw_stream
      end

      @field.option_items = ['a', 'b', 'c']
      do_check.call

      @field.list_box_top_index = 2
      do_check.call

      @field.field_value = 'b'
      do_check.call

      widget = @field.create_widget(@doc.pages.add, Rect: [0, 0, 0, 0])
      assert_nil(widget[:AP])
      @field.create_appearances
      refute_nil(widget[:AP][:N])
    end

    it "force the creation of appearance streams when force: true" do
      @field.initialize_as_list_box
      @field.set_default_appearance_string
      @field.create_appearances
      appearance_stream = @field[:AP][:N].raw_stream

      @field.create_appearances(force: true)
      refute_same(appearance_stream, @field[:AP][:N].raw_stream)
    end
  end

  describe "validation" do
    it "checks the value of the /FT field" do
      @field.delete(:FT)
      refute(@field.validate(auto_correct: false))
      assert(@field.validate)
      assert_equal(:Ch, @field.field_type)
    end
  end
end
