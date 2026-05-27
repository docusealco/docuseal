# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/font/cmap/writer'

describe HexaPDF::Font::CMap::Writer do
  before do
    @to_unicode_cmap_data = +<<~EOF
      /CIDInit /ProcSet findresource begin
      12 dict begin
      begincmap
      /CIDSystemInfo
      << /Registry (Adobe)
      /Ordering (UCS)
      /Supplement 0
      >> def
      /CMapName /Adobe-Identity-UCS def
      /CMapType 2 def
      1 begincodespacerange
      <0000> <FFFF>
      endcodespacerange
      2 beginbfchar
      <0060><0090>
      <3A51><d840dc3e>
      endbfchar
      2 beginbfrange
      <0000><005E><0020>
      <1379><137B><90fe>
      endbfrange
      endcmap
      CMapName currentdict /CMap defineresource pop
      end
      end
    EOF
    @cid_cmap_data = +<<~EOF
      %!PS-Adobe-3.0 Resource-CMap
      %%DocumentNeededResources: ProcSet (CIDInit)
      %%IncludeResource: ProcSet (CIDInit)
      %%BeginResource: CMap (Custom)
      %%Title: (Custom Adobe Identity 0)
      %%Version: 1
      /CIDInit /ProcSet findresource begin
      12 dict begin
      begincmap
      /CIDSystemInfo 3 dict dup begin
        /Registry (Adobe) def
        /Ordering (Identity) def
        /Supplement 0 def
      end def
      /CMapName /Custom def
      /CMapType 1 def
      /CMapVersion 1 def
      /WMode 0 def
      1 begincodespacerange
      <0000> <FFFF>
      endcodespacerange
      1 begincidchar
      <0060> 144
      endcidchar
      1 begincidrange
      <0000><005E> 32
      endcidrange
      endcmap
      CMapName currentdict /CMap defineresource pop
      end
      end
      %%EndResource
      %%EOF
    EOF

    @to_unicode_mapping = []
    @cid_mapping = []
    0x00.upto(0x5e) do |i|
      @to_unicode_mapping << [i, 0x20 + i]
      @cid_mapping << [i, 0x20 + i]
    end
    @to_unicode_mapping << [0x60, 0x90]
    @cid_mapping << [0x60, 0x90]
    0x1379.upto(0x137B) do |i|
      @to_unicode_mapping << [i, 0x90FE + i - 0x1379]
    end
    @to_unicode_mapping << [0x3A51, 0x2003E]
  end

  describe "create_to_unicode_cmap" do
    it "creates a correct CMap file" do
      assert_equal(@to_unicode_cmap_data,
                   HexaPDF::Font::CMap.create_to_unicode_cmap(@to_unicode_mapping))
    end

    it "works if the last item is a range" do
      @to_unicode_mapping.pop
      @to_unicode_cmap_data.sub!(/2 beginbfchar/, '1 beginbfchar')
      @to_unicode_cmap_data.sub!(/<3A51><d840dc3e>\n/, '')
      assert_equal(@to_unicode_cmap_data,
                   HexaPDF::Font::CMap.create_to_unicode_cmap(@to_unicode_mapping))
    end

    it "works with only ranges" do
      @to_unicode_mapping.delete_at(-1)
      @to_unicode_mapping.delete_at(0x5f)
      @to_unicode_cmap_data.sub!(/\n2 beginbfchar.*endbfchar/m, '')
      assert_equal(@to_unicode_cmap_data,
                   HexaPDF::Font::CMap.create_to_unicode_cmap(@to_unicode_mapping))
    end

    it "returns an empty CMap if the mapping is empty" do
      assert_equal(@to_unicode_cmap_data.sub(/\d+ beginbfchar.*endbfrange/m, ''),
                   HexaPDF::Font::CMap.create_to_unicode_cmap([]))
    end
  end

  describe "create_cid_cmap" do
    it "creates a correct CMap file" do
      assert_equal(@cid_cmap_data, HexaPDF::Font::CMap.create_cid_cmap(@cid_mapping))
    end

    it "returns an empty CMap if the mapping is empty" do
      assert_equal(@cid_cmap_data.sub(/\d+ begincidchar.*endcidrange/m, ''),
                   HexaPDF::Font::CMap.create_cid_cmap([]))
    end
  end
end
