# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/font_loader'
require 'hexapdf/document'

describe HexaPDF::FontLoader::FromFile do
  before do
    @doc = HexaPDF::Document.new
    @font_file = File.join(TEST_DATA_DIR, "fonts", "Ubuntu-Title.ttf")
    @klass = HexaPDF::FontLoader::FromFile
  end

  it "loads the specified font file" do
    wrapper = @klass.call(@doc, @font_file)
    assert_equal("Ubuntu-Title", wrapper.wrapped_font.font_name)
  end

  it "loads the specified font object" do
    font = HexaPDF::Font::TrueType::Font.new(File.open(@font_file, 'rb'))
    wrapper = @klass.call(@doc, font)
    assert_equal("Ubuntu-Title", wrapper.wrapped_font.font_name)
    assert_same(font, wrapper.wrapped_font)
  end

  it "passes the subset value to the wrapper" do
    wrapper = @klass.call(@doc, @font_file)
    assert(wrapper.subset?)
    wrapper = @klass.call(@doc, @font_file, subset: false)
    refute(wrapper.subset?)
  end

  it "returns nil if the given name doesn't represent a file" do
    assert_nil(@klass.call(@doc, "Unknown"))
  end
end
