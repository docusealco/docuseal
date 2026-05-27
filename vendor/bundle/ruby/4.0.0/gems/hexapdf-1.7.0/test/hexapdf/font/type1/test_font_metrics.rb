# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/font/type1'

describe HexaPDF::Font::Type1::FontMetrics do
  before do
    @metrics = HexaPDF::Font::Type1::FontMetrics.new
  end

  describe "weight_class" do
    it "converts known weight names" do
      @metrics.weight = 'Bold'
      assert_equal(700, @metrics.weight_class)
    end

    it "returns 0 for unknown weight names" do
      @metrics.weight = 'Unknown'
      assert_equal(0, @metrics.weight_class)
    end
  end
end
