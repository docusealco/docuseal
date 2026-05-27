# -*- encoding: utf-8 -*-

require 'test_helper'
require_relative 'common'
require 'hexapdf/font/type1'

describe HexaPDF::Font::Type1::Font do
  before do
    metrics = HexaPDF::Font::Type1::FontMetrics.new
    @font = HexaPDF::Font::Type1::Font.new(metrics)
  end

  describe "::from_afm" do
    it "can load the Font object from an AFM file" do
      font = HexaPDF::Font::Type1::Font.from_afm(File.join(HexaPDF.data_dir, 'afm/Symbol.afm'))
      assert_equal('Symbol', font.family_name)
    end
  end

  describe "encoding" do
    it "uses the StandardEncoding if possible" do
      @font.metrics.encoding_scheme = 'AdobeStandardEncoding'
      assert_equal(HexaPDF::Font::Encoding.for_name(:StandardEncoding), @font.encoding)
    end

    it "handles the special case of the ZapfDingbats font" do
      @font.metrics.font_name = "ZapfDingbats"
      assert_equal(HexaPDF::Font::Encoding.for_name(:ZapfDingbatsEncoding), @font.encoding)
    end

    it "handles the special case of the Symbol font" do
      @font.metrics.font_name = "Symbol"
      assert_equal(HexaPDF::Font::Encoding.for_name(:SymbolEncoding), @font.encoding)
    end

    it "generates an encoding object if necessary" do
      char_metrics = HexaPDF::Font::Type1::CharacterMetrics.new
      char_metrics.code = 5
      char_metrics.name = :A
      @font.metrics.character_metrics[5] = char_metrics.dup
      char_metrics.code = 6
      char_metrics.name = :Z
      @font.metrics.character_metrics[6] = char_metrics.dup

      assert_equal({5 => :A, 6 => :Z}, @font.encoding.code_to_name)
    end
  end

  describe "width" do
    before do
      @char_metrics = HexaPDF::Font::Type1::CharacterMetrics.new
      @char_metrics.width = 100
    end

    it "returns the width for a code point in the built-in encoding" do
      @font.metrics.character_metrics[5] = @char_metrics
      assert_equal(100, @font.width(5))
    end

    it "returns the width for a named glyph" do
      @font.metrics.character_metrics[:A] = @char_metrics
      assert_equal(100, @font.width(:A))
    end
  end

  it "is able to return the ID of the missing glyph" do
    assert_equal(:'.notdef', @font.missing_glyph_id)
  end

  it "returns the features available for a font" do
    assert_equal([:kern, :liga].to_set, FONT_TIMES.features)
    assert(FONT_SYMBOL.features.empty?)
  end

  describe "underline properties" do
    before do
      @font.metrics.underline_position = -100
      @font.metrics.underline_thickness = 50
    end

    it "returns the underline position" do
      assert_equal(-75, @font.underline_position)
    end

    it "returns the underline thickness" do
      assert_equal(50, @font.underline_thickness)
    end
  end

  describe "strikeout properties" do
    it "returns the strikeout position" do
      assert_equal(225, @font.strikeout_position)
    end

    it "returns the strikeout thickness" do
      assert_equal(50, @font.strikeout_thickness)

      emdash = HexaPDF::Font::Type1::CharacterMetrics.new
      emdash.bbox = [0, 200, 1000, 240]
      @font.metrics.character_metrics[:emdash] = emdash
      assert_equal(40, @font.strikeout_thickness)
    end
  end
end
