# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/font_loader'
require 'hexapdf/document'

describe HexaPDF::FontLoader::FromConfiguration do
  before do
    @doc = HexaPDF::Document.new
    font_file = File.join(TEST_DATA_DIR, "fonts", "Ubuntu-Title.ttf")
    @font_obj = HexaPDF::Font::TrueType::Font.new(File.open(font_file, 'rb'))
    @doc.config['font.map'] = {'font' => {none: font_file}, 'font1' => {none: @font_obj}}
    @klass = HexaPDF::FontLoader::FromConfiguration
  end

  it "loads the configured font" do
    wrapper = @klass.call(@doc, "font")
    assert_equal("Ubuntu-Title", wrapper.wrapped_font.font_name)
    wrapper = @klass.call(@doc, "font1")
    assert_equal("Ubuntu-Title", wrapper.wrapped_font.font_name)
    assert_same(@font_obj, wrapper.wrapped_font)
  end

  it "passes the subset value to the wrapper" do
    wrapper = @klass.call(@doc, "font")
    assert(wrapper.subset?)
    wrapper = @klass.call(@doc, "font", subset: false)
    refute(wrapper.subset?)
  end

  it "fails if the provided font is invalid" do
    @doc.config['font.map']['font'][:none] << "unknown"
    assert_raises(HexaPDF::Error) { @klass.call(@doc, "font") }
  end

  it "returns nil for unknown fonts" do
    assert_nil(@klass.call(@doc, "Unknown"))
  end

  it "allows arbitrary keywords arguments" do
    assert_nil(@klass.call(@doc, "Unknown", something: :other))
  end

  it "returns a hash with all configured fonts" do
    assert_equal({'font' => [:none], 'font1' => [:none]}, @klass.available_fonts(@doc))
  end
end
