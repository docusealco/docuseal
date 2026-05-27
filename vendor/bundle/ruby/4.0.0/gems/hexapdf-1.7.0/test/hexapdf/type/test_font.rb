# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/document'
require 'hexapdf/type/font'

describe HexaPDF::Type::Font do
  before do
    @doc = HexaPDF::Document.new
    cmap = @doc.add({}, stream: <<-EOF)
      2 beginbfchar
      <20> <0041>
      <22> <0042>
      endbfchar
    EOF
    fd = @doc.add({Type: :FontDescriptor, FontBBox: [0, 1, 2, 3]})
    @font = @doc.add({Type: :Font, BaseFont: :TestFont, FontDescriptor: fd, ToUnicode: cmap})
  end

  it "allows setting and returning a font wrapper object" do
    @font.font_wrapper = :fake_wrapper
    assert_equal(:fake_wrapper, @font.font_wrapper)
  end

  it "must always be an indirect" do
    assert(@font.must_be_indirect?)
  end

  describe "to_utf" do
    it "uses the /ToUnicode CMap if it is available" do
      assert_equal("A", @font.to_utf8(32))
      assert_equal("B", @font.to_utf8(34))
      assert_raises(HexaPDF::Error) { @font.to_utf8(0) }
    end

    it "calls the configured proc if no /ToUnicode CMap is available" do
      @font.delete(:ToUnicode)
      assert_raises(HexaPDF::Error) { @font.to_utf8(32) }
    end
  end

  describe "bounding_box" do
    it "returns the bounding box" do
      assert_equal([0, 1, 2, 3], @font.bounding_box)
    end

    it "returns nil if no bounding box information can be found" do
      @font[:FontDescriptor].delete(:FontBBox)
      assert_nil(@font.bounding_box)
    end
  end

  describe "embedded" do
    it "returns true if the font is embedded" do
      refute(@font.embedded?)
      @font[:FontDescriptor][:FontFile] = 5
      assert(@font.embedded?)
    end
  end

  describe "font_file" do
    it "returns the stream object representing the embedded font file" do
      @font[:FontDescriptor][:FontFile] = 5
      assert_equal(5, @font.font_file)
    end
  end

  it "returns the glyph scaling factor" do
    assert_equal(0.001, @font.glyph_scaling_factor)
  end
end
