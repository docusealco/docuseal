# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/document'
require 'hexapdf/type/cid_font'

describe HexaPDF::Type::CIDFont do
  before do
    @doc = HexaPDF::Document.new
    @font = @doc.wrap({Type: :Font, Subtype: :CIDFontType2, W: [1, 2, 3], DW: 100,
                       CIDSystemInfo: {Registry: 'Adobe', Ordering: 'Japan1', Supplement: 1}})
  end

  describe "width" do
    before do
      @font[:W] = [1, [1], 2, [2, 3, 4], 5, 6, 10, 20, [20, 21], 30, 32, 40]
    end

    it "returns the glyph width for a CID defined via the /W array" do
      assert_equal(1, @font.width(1))
      assert_equal(2, @font.width(2))
      assert_equal(3, @font.width(3))
      assert_equal(4, @font.width(4))
      assert_equal(10, @font.width(5))
      assert_equal(10, @font.width(6))
      assert_equal(20, @font.width(20))
      assert_equal(21, @font.width(21))
      assert_equal(40, @font.width(32))
    end

    it "returns the /DW value for CIDs not in the /W array" do
      assert_equal(100, @font.width(100))
      @font.delete(:DW)
      assert_equal(1000, @font.width(100))
    end
  end

  describe "set_widths" do
    it "allows setting the widths" do
      @font.set_widths([[1, 1], [2, 2], [4, 4], [5, 5], [7, 7.1]], default_width: 5.1)
      assert_equal(5, @font[:DW])
      assert_equal([1, [1, 2], 4, [4, 5], 7, [7]], @font[:W].value)
    end

    it "handles an empty widths array correctly" do
      @font.set_widths([], default_width: 100)
      refute(@font.key?(:W))
      assert_equal(100, @font[:DW])

      @font.set_widths([])
      refute(@font.key?(:W))
    end

    it "handles setting /DW to the default value correctly" do
      @font.set_widths([])
      refute(@font.key?(:DW))
      @font.set_widths([[1, 1]])
      refute(@font.key?(:DW))
    end
  end
end
