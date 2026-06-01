# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/font/encoding/glyph_list'

describe HexaPDF::Font::Encoding::GlyphList do
  before do
    @list = HexaPDF::Font::Encoding::GlyphList.new
  end

  describe ".new" do
    it "only ever creates one instance" do
      assert_same(@list, HexaPDF::Font::Encoding::GlyphList.new)
    end
  end

  describe "name_to_unicode" do
    it "maps known glyph names to their unicode equivalent" do
      assert_equal("A", @list.name_to_unicode(:A))
      assert_equal("9", HexaPDF::Font::Encoding::GlyphList.name_to_unicode(:nine))
      assert_equal("\u05da\u05b8", @list.name_to_unicode(:finalkafqamats))
    end

    it "parses the whole file" do
      assert_equal("ズ", @list.name_to_unicode(:zukatakana))
    end

    it "maps special uniXXXX names to unicode values" do
      assert_equal("A", @list.name_to_unicode(:uni0041))
      assert_equal("\u1234", @list.name_to_unicode(:uni1234))
    end

    it "maps special uXXXX[XX] names to unicode values" do
      assert_equal("A", @list.name_to_unicode(:u0041))
      assert_equal(+'' << "1F000".hex, @list.name_to_unicode(:u1F000))
    end

    it "maps Zapf Dingbats glyph names to their unicode" do
      assert_equal("A", @list.name_to_unicode(:A, zapf_dingbats: true))
      assert_equal("\u275e", @list.name_to_unicode(:a100, zapf_dingbats: true))
    end

    it "returns nil for unknown glyph names" do
      assert_nil(@list.name_to_unicode(:MyUnknownGlyphName))
      assert_nil(@list.name_to_unicode(:a100))
    end
  end

  describe "unicode_to_name" do
    it "maps codepoints to names" do
      assert_equal(:space, @list.unicode_to_name(" "))
      assert_equal(:A, HexaPDF::Font::Encoding::GlyphList.unicode_to_name("A"))
      assert_equal(:odieresis, @list.unicode_to_name("ö"))
      assert_equal(:finalkafqamats, @list.unicode_to_name("\u05da\u05b8"))
      assert_equal(:'.notdef', @list.unicode_to_name("ABCDEFG"))
    end

    it "maps Zapf Dingbats codepoints to names" do
      assert_equal(:'.notdef', @list.unicode_to_name("\u2710"))
      assert_equal(:a105, @list.unicode_to_name("\u2710", zapf_dingbats: true))
    end
  end
end
