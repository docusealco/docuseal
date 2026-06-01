# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/font/cmap/parser'

describe HexaPDF::Font::CMap::Parser do
  describe "::parse" do
    it "parses CMap data correctly" do
      data = <<~EOF
        /CIDInit /ProcSet findresource begin
        12 dict begin
        begincmap
        /H usecmap
        /CIDSystemInfo
        << /Registry (Adobe)
        /Ordering (UCS)
        /Supplement 0
        >> def
        /CMapName /Adobe-Identity-UCS def
        /CMapType 2 def
        /WMode 0 def
        4 begincodespacerange
        <00>   <20>
        <8140> <9ffc>
        <a0>   <de>
        <e040> <fbec>
        endcodespacerange
        2 begincidchar
        <8143> 8286
        <8144> 8274
        endcidchar
        2 begincidrange
        <8145> <8145> 8123
        <8146> <8148> 9000
        endcidrange
        4 beginbfrange
        <0000> <005E> <0020>
        <1379> <137B> <90FE>
        <005F> <0061> [ <00660066> <00660069> <00660066006C> ]
        <E040> <E041> <D840DC3D>
        endbfrange
        1 beginbfchar
        <3A51> <D840DC3E>
        endbfchar
        endcmap
        CMapName currentdict /CMap defineresource pop
        end
        end
      EOF
      cmap = HexaPDF::Font::CMap.parse(data)
      assert_equal("Adobe", cmap.registry)
      assert_equal("UCS", cmap.ordering)
      assert_equal(0, cmap.supplement)
      assert_equal("Adobe-Identity-UCS", cmap.name)
      assert_equal(0, cmap.wmode)

      # Check mappings from used CMap
      assert_equal([0x2121, 0x7e7e], cmap.read_codes("\x21\x21\x7e\x7e"))
      assert_equal(633, cmap.to_cid(0x2121))
      assert_equal(6455, cmap.to_cid(0x6930))

      # Check codespace ranges
      assert_equal([0, 0x10, 0x20, 33088, 34175, 40956, 160, 205, 222],
                   cmap.read_codes("\x00\x10\x20\x81\x40\x85\x7f\x9f\xfc\xa0\xcd\xde"))

      # Check individual charater mappings
      assert_equal(8286, cmap.to_cid(0x8143))
      assert_equal(8274, cmap.to_cid(0x8144))

      # Check CID ranges
      assert_equal(8123, cmap.to_cid(0x8145))
      assert_equal(9000, cmap.to_cid(0x8146))
      assert_equal(9001, cmap.to_cid(0x8147))
      assert_equal(9002, cmap.to_cid(0x8148))

      # Check unicode mapping
      ((0x20.chr)..(0x7e.chr)).each_with_index do |str, index|
        assert_equal(str, cmap.to_unicode(index))
      end
      assert_equal("\u{90FE}", cmap.to_unicode(0x1379))
      assert_equal("\u{90FF}", cmap.to_unicode(0x137A))
      assert_equal("\u{9100}", cmap.to_unicode(0x137B))
      assert_equal("ff", cmap.to_unicode(0x5F))
      assert_equal("fi", cmap.to_unicode(0x60))
      assert_equal("ffl", cmap.to_unicode(0x61))
      symbol = "\xD8\x40\xDC\x3E".encode("UTF-8", "UTF-16BE")
      assert_equal(symbol, cmap.to_unicode(0xE041))
      assert_equal(symbol, cmap.to_unicode(0x3A51))
      assert_nil(cmap.to_unicode(0xFF))
    end

    it "fails if there is an invalid token inside the bfrange operator" do
      assert_raises(HexaPDF::Error) do
        HexaPDF::Font::CMap.parse("1 beginbfrange <0000> <0001> 5 endbfrange")
      end
    end

    it "fails if the CMap is not correctly structured" do
      assert_raises(HexaPDF::Error) do
        HexaPDF::Font::CMap.parse("1 beginbfchar <0000> <0001>")
      end
    end
  end
end
