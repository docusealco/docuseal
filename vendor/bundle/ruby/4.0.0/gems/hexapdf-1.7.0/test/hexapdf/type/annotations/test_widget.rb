# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/document'
require 'hexapdf/type/annotations/widget'

describe HexaPDF::Type::Annotations::Widget::AppearanceCharacteristics do
  before do
    @doc = HexaPDF::Document.new
    @annot = @doc.wrap({}, type: :XXAppearanceCharacteristics)
  end

  describe "validation" do
    it "needs /R to be a multiple of 90" do
      assert(@annot.validate)

      @annot[:R] = 45
      refute(@annot.validate)

      @annot[:R] = 90
      assert(@annot.validate)
    end
  end
end

describe HexaPDF::Type::Annotations::Widget do
  before do
    @doc = HexaPDF::Document.new
    @widget = @doc.wrap({Type: :Annot, Subtype: :Widget})
  end

  describe "form_field" do
    it "works for the field and widget being the same object" do
      @widget[:FT] = :Tx
      @widget[:T] = 'field'
      result = @widget.form_field
      assert_kind_of(HexaPDF::Type::AcroForm::TextField, result)
      assert_same(@widget.data, result.data)
    end

    it "works for a field with a parent field and the widget being the same object" do
      @widget[:Parent] = {FT: :Tx, T: 'parent', Kids: [@widget]}
      @widget[:T] = 'field'
      result = @widget.form_field
      assert_kind_of(HexaPDF::Type::AcroForm::TextField, result)
      assert_same(@widget.data, result.data)
    end

    it "works for the widget being in the /Kids array of the field" do
      @widget[:Parent] = {FT: :Tx, T: 'parent', Kids: [@widget]}
      result = @widget.form_field
      assert_kind_of(HexaPDF::Type::AcroForm::TextField, result)
      refute_same(@widget.data, result.data)
    end

    it "works when the type of the field is defined higher up in the field hierarchy" do
      @widget[:Parent] = {T: 'parent', Kids: [@widget]}
      @widget[:Parent][:Parent] = {FT: :Tx, Kids: [@widget[:Parent]]}
      result = @widget.form_field
      assert_kind_of(HexaPDF::Type::AcroForm::TextField, result)
      refute_same(@widget.data, result.data)
    end
  end

  describe "background_color" do
    it "returns the current background color" do
      assert_nil(@widget.background_color)
      @widget[:MK] = {BG: []}
      assert_nil(@widget.background_color)
      @widget[:MK] = {BG: [1]}
      assert_equal([1], @widget.background_color.components)
    end

    it "sets the color and returns self" do
      assert_same(@widget, @widget.background_color(51))
      assert_equal([0.2], @widget.background_color.components)
    end
  end

  describe "marker_style" do
    before do
      @chars = %w[4 l 8 u n H S]
      @values = [:check, :circle, :cross, :diamond, :square, :star, 'S']
      @widget[:Parent] = {FT: :Btn}
    end

    describe "style" do
      it "returns the style" do
        @chars.zip(@values) do |char, result|
          @widget[:MK] = {CA: char}
          assert_equal(result, @widget.marker_style.style)
        end
      end

      it "returns the correct default button style depending on the field" do
        @widget.form_field.initialize_as_check_box
        assert_equal(:check, @widget.marker_style.style)
        @widget.form_field.initialize_as_radio_button
        assert_equal(:circle, @widget.marker_style.style)
      end

      it "sets the button style" do
        @values.zip(@chars) do |argument, char|
          @widget.marker_style(style: argument)
          assert_equal(char, @widget[:MK][:CA])
        end
      end

      it "uses the correct default style" do
        @widget.form_field.initialize_as_check_box
        @widget.marker_style(size: 10)
        assert_equal('4', @widget[:MK][:CA])

        @widget.form_field.initialize_as_radio_button
        @widget.marker_style(size: 10)
        assert_equal('l', @widget[:MK][:CA])

        @widget.form_field.initialize_as_push_button
        @widget.marker_style(size: 10)
        assert_equal('', @widget[:MK][:CA])
      end

      it "fails if an invalid argument is provided" do
        assert_raises(ArgumentError) { @widget.marker_style(style: 5) }
      end
    end

    describe "size" do
      it "returns the size" do
        @widget.form_field[:DA] = "/F 15 Tf"
        assert_equal(15, @widget.marker_style.size)
        @widget[:DA] = "/F 10 Tf"
        assert_equal(10, @widget.marker_style.size)
      end

      it "returns the default size if none is set" do
        assert_equal(0, @widget.marker_style.size)
        @widget.form_field[:DA] = "0.0 g"
        assert_equal(0, @widget.marker_style.size)
      end

      it "sets the given size" do
        @widget.marker_style(size: 10)
        assert_equal('/ZaDb 10 Tf 0.0 g', @widget[:DA])
      end
    end

    describe "color" do
      it "returns the color" do
        @widget.form_field[:DA] = "0 1 0 rg"
        assert_equal([0, 1, 0], @widget.marker_style.color.components)
        @widget[:DA] = "0 0 1 rg"
        assert_equal([0, 0, 1], @widget.marker_style.color.components)
      end

      it "returns the default color if none is set" do
        assert_equal([0], @widget.marker_style.color.components)
        @widget.form_field[:DA] = "/ZaDb 10 Tfg"
        assert_equal([0], @widget.marker_style.color.components)
      end

      it "sets the given color" do
        @widget.marker_style(color: [1.0, 51, 1.0])
        assert_equal([1, 0.2, 1], @widget.marker_style.color.components)
        @widget.marker_style(color: [1.0, 20, 1.0, 1.0])
        assert_equal([1, 0.2, 1, 1], @widget.marker_style.color.components)
      end
    end

    describe "font_name" do
      it "returns the font_name" do
        @widget.form_field[:DA] = "/F1 15 Tf"
        assert_equal(:F1, @widget.marker_style.font_name)
        @widget[:DA] = "/F2 10 Tf"
        assert_equal(:F2, @widget.marker_style.font_name)
      end

      it "returns nil if none is set" do
        assert_nil(@widget.marker_style.font_name)
        @widget.form_field[:DA] = "0.0 g"
        assert_nil(@widget.marker_style.font_name)
      end

      it "sets the given font_name" do
        @widget.form_field.initialize_as_push_button
        @widget.marker_style(font_name: 'Helvetica', size: 10)
        assert_equal('/F1 10 Tf 0.0 g', @widget[:DA])
      end
    end
  end

  describe "perform_validation" do
    it "validates the widget as form field if they are the same" do
      @widget[:Rect] = [0, 0, 0, 0]
      @widget[:FT] = :Tx
      @widget[:T] = 'field'
      @widget[:V] = :Sym
      assert(@widget.validate)
      assert_equal('Sym', @widget[:V]) # this auto-correct is part of TextField
    end
  end
end
