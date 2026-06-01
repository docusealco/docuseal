# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/document'
require 'hexapdf/type/acro_form/variable_text_field'

describe HexaPDF::Type::AcroForm::VariableTextField do
  before do
    @doc = HexaPDF::Document.new
    @doc.acro_form(create: true).set_default_appearance_string
    @field = @doc.add({}, type: HexaPDF::Type::AcroForm::VariableTextField)
  end

  describe "text_alignment" do
    it "returns the alignment value for displaying text" do
      assert_equal(:left, @field.text_alignment)
      @field[:Q] = 1
      assert_equal(:center, @field.text_alignment)
      @field[:Q] = 2
      assert_equal(:right, @field.text_alignment)
    end

    it "sets the alignment value for displaying text to a given value" do
      @field.text_alignment(:center)
      assert_equal(1, @field[:Q])
      @field.text_alignment(:right)
      assert_equal(2, @field[:Q])
      @field.text_alignment(:left)
      assert_equal(0, @field[:Q])
      assert_raises(ArgumentError) { @field.text_alignment(:unknown) }
    end
  end

  describe "set_default_appearance_string / self.create_appearance_string" do
    it "creates the AcroForm object if it doesn't exist" do
      @doc.catalog.delete(:AcroForm)
      @field.set_default_appearance_string
      assert(@doc.acro_form)
    end

    it "uses sane default values if no arguments are provided" do
      @field.set_default_appearance_string
      assert_equal("0.0 g /F1 0 Tf", @field[:DA])
      font = @doc.acro_form.default_resources.font(:F1)
      assert(font)
      assert_equal(:Helvetica, font[:BaseFont])
    end

    it "allows specifying the font" do
      @field.set_default_appearance_string(font: 'Times')
      assert_equal("0.0 g /F2 0 Tf", @field[:DA])
      assert_equal(:'Times-Roman', @doc.acro_form.default_resources.font(:F2)[:BaseFont])
    end

    it "allows specifying the font options" do
      @field.set_default_appearance_string(font_options: {variant: :italic})
      assert_equal("0.0 g /F2 0 Tf", @field[:DA])
      assert_equal(:'Helvetica-Oblique', @doc.acro_form.default_resources.font(:F2)[:BaseFont])
    end

    it "allows specifying the font size" do
      @field.set_default_appearance_string(font_size: 10)
      assert_equal("0.0 g /F1 10 Tf", @field[:DA])
    end

    it "allows specifying the font color" do
      @field.set_default_appearance_string(font_color: "red")
      assert_equal("1.0 0.0 0.0 rg /F1 0 Tf", @field[:DA])
    end
  end

  describe "parse_default_appearance_string" do
    before do
      @color = HexaPDF::Content::ColorSpace.prenormalized_device_color([1])
    end

    it "parses the default appearance string of the field" do
      @field[:DA] = "1 g //F1 20 Tf 5 w /F2 10 Tf"
      assert_equal([:F2, 10, @color], @field.parse_default_appearance_string)
    end

    it "parses the default appearance string of the given widget" do
      widget = @field.create_widget(@doc.pages.add, allow_embedded: false, Rect: [0, 0, 1, 1],
                                   DA: "/F1 10 Tf 1 g")
      assert_equal([:F1, 10, @color], @field.parse_default_appearance_string(widget))
    end

    it "falls back to the field if the widget has no appearance string set" do
      @field[:DA] = "/F2 5 Tf"
      widget = @field.create_widget(@doc.pages.add, allow_embedded: false, Rect: [0, 0, 1, 1])
      assert_equal([:F2, 5, nil], @field.parse_default_appearance_string(widget))
    end

    it "uses the default appearance string of a parent field" do
      parent = @doc.add({DA: "/F1 15 Tf"}, type: :XXAcroFormField)
      @field[:Parent] = parent
      assert_equal([:F1, 15, nil], @field.parse_default_appearance_string)
    end

    it "uses the global default appearance string" do
      assert_equal([:F1, 0, HexaPDF::Content::ColorSpace.prenormalized_device_color([0])],
                   @field.parse_default_appearance_string)
    end

    it "sets a standard /DA value if no other /DA is found" do
      @doc.acro_form.delete(:DA)
      assert_equal([:F1, 0, HexaPDF::Content::ColorSpace.prenormalized_device_color([0])],
                   @field.parse_default_appearance_string)
    end

    it "converts the /DA to a string in case an invalid PDF uses a Symbol" do
      @field[:DA] = :"1 g /F1 20 Tf"
      assert_equal([:F1, 20, @color], @field.parse_default_appearance_string)
    end

    it "fails if no /DA value is set and no default appearance string should be set" do
      @doc.acro_form.delete(:DA)
      @doc.config['acro_form.fallback_default_appearance'] = nil
      assert_raises(HexaPDF::Error) { @field.parse_default_appearance_string }
    end

  end
end
