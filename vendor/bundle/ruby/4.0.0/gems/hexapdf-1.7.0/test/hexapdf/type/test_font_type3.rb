# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/document'
require 'hexapdf/type/font_type3'

describe HexaPDF::Type::FontType3 do
  before do
    @doc = HexaPDF::Document.new
    @font = @doc.add({Type: :Font, Subtype: :Type3, Encoding: :WinAnsiEncoding,
                      FirstChar: 32, LastChar: 34, Widths: [600, 0, 700],
                      FontBBox: [0, 100, 100, 0], FontMatrix: [0.002, 0, 0, 0.002, 0, 0],
                      CharProcs: {}})
  end

  describe "bounding_box" do
    it "returns the font's bounding box" do
      assert_equal([0, 0, 100, 100], @font.bounding_box)
    end

    it "inverts the y-values if necessary based on /FontMatrix" do
      @font[:FontMatrix][3] *= -1
      assert_equal([0, -100, 100, 0], @font.bounding_box)
    end
  end

  it "returns the glyph scaling factor" do
    assert_equal(0.002, @font.glyph_scaling_factor)
  end

  describe "validation" do
    it "works for valid objects" do
      assert(@font.validate)
    end

    it "fails if the Encoding key is missing" do
      @font.delete(:Encoding)
      refute(@font.validate)
    end
  end
end
