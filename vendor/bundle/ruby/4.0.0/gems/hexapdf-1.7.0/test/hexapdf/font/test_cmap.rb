# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/font/cmap'

describe HexaPDF::Font::CMap do
  before do
    @cmap = HexaPDF::Font::CMap.new
  end

  describe "using another CMap" do
    it "uses all mappings of the other CMap" do
      other = HexaPDF::Font::CMap.new
      other.add_codespace_range(0x00..0x80)
      other.add_codespace_range(0x81..0x9f, 0x40..0xfc)
      other.add_cid_mapping(0x40, 2000)
      other.add_cid_range(0x50, 0x60, 3000)
      other.add_unicode_mapping(0x40, "A")
      @cmap.use_cmap(other)

      assert_equal([0, 0x80, 0x8140], @cmap.read_codes("\x0\x80\x81\x40"))
      assert_equal(2000, @cmap.to_cid(0x40))
      assert_equal(3000, @cmap.to_cid(0x50))
      assert_equal(3016, @cmap.to_cid(0x60))
      assert_equal("A", @cmap.to_unicode(0x40))
    end
  end

  describe "predefined CMaps" do
    it "can check if there is a predefined CMap for a certain name" do
      assert(HexaPDF::Font::CMap.predefined?('H'))
      refute(HexaPDF::Font::CMap.predefined?('Z'))
    end

    it "returns a predefined CMap using ::for_name" do
      cmap = HexaPDF::Font::CMap.for_name('GB-EUC-H')
      assert_equal("Adobe", cmap.registry)
      assert_equal("GB1", cmap.ordering)
      assert_equal(0, cmap.supplement)
      assert_equal('GB-EUC-H', cmap.name)
    end

    it "fails in a non-existent CMap file should be parsed" do
      assert_raises(HexaPDF::Error) { HexaPDF::Font::CMap.for_name('unknown') }
    end
  end

  describe "add codespace ranges and read codes" do
    before do
      @cmap.add_codespace_range(0x00..0x80)
      @cmap.add_codespace_range(0x81..0x9f, 0x40..0xfc)
      @cmap.add_codespace_range(0xa0..0xde)
      @cmap.add_codespace_range(0xe0..0xfb, 0x40..0xec)
    end

    it "can read valid character codes" do
      assert_equal([0, 0x40, 0x80, 33088, 34175, 40956, 160, 205, 222],
                   @cmap.read_codes("\x00\x40\x80\x81\x40\x85\x7f\x9f\xfc\xa0\xcd\xde"))
    end

    it "fails if the first byte is not valid" do
      assert_raises(HexaPDF::Error) { @cmap.read_codes("\xdf") }
    end

    it "fails if a byte following the first one is not valid" do
      assert_raises(HexaPDF::Error) { @cmap.read_codes("\x82\x10") }
    end

    it "fails if too few bytes for a valid code are available" do
      assert_raises(HexaPDF::Error) { @cmap.read_codes("\x82") }
    end
  end

  describe "CID definition and retrieval" do
    it "allows adding and retrieving mappings from individual codes to CIDs" do
      @cmap.add_cid_mapping(57, 90)
      assert_equal(90, @cmap.to_cid(57))
    end

    it "allows adding and retrieving mappings from code ranges to CIDs" do
      @cmap.add_cid_range(20, 40, 100)
      @cmap.add_cid_range(30, 35, 10)
      assert_equal(100, @cmap.to_cid(20))
      assert_equal(120, @cmap.to_cid(40))
      assert_equal(10, @cmap.to_cid(30))
      assert_equal(15, @cmap.to_cid(35))
    end

    it "returns 0 for unknown code-to-CID mappings" do
      assert_equal(0, @cmap.to_cid(57))
    end
  end

  describe "Unicode mapping and retrieval" do
    it "allows adding and retrieving a code-to-unicode mapping" do
      @cmap.add_unicode_mapping(20, "ABC")
      assert_equal("ABC", @cmap.to_unicode(20))
    end

    it "allows adding a code range to unicode mapping and retrieving the values" do
      @cmap.add_unicode_range_mapping(20, 30, [65])
      @cmap.add_unicode_range_mapping(40, 41, [0xD840, 0xDC3D])
      assert_equal("A", @cmap.to_unicode(20))
      assert_equal("K", @cmap.to_unicode(30))
      assert_equal("𠀾", @cmap.to_unicode(41))
    end

    it "returns nil for unknown mappings" do
      assert_nil(@cmap.to_unicode(20))
    end
  end
end
