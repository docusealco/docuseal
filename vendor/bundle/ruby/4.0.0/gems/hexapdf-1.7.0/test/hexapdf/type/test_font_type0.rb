# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/document'
require 'hexapdf/type/font_type0'

describe HexaPDF::Type::FontType0 do
  before do
    @doc = HexaPDF::Document.new
    @fd = @doc.add({Type: :FontDescriptor, FontBBox: [0, 1, 2, 3]})
    @cid_font = @doc.wrap({Type: :Font, Subtype: :CIDFontType2, W: [633, [100]], FontDescriptor: @fd,
                           CIDSystemInfo: {Registry: 'Adobe', Ordering: 'Japan1', Supplement: 1}})
    @font = @doc.wrap({Type: :Font, Subtype: :Type0, Encoding: :H, DescendantFonts: [@cid_font]})
  end

  it "returns the correct writing mode" do
    assert_equal(:horizontal, @font.writing_mode)
    font = @doc.wrap({Type: :Font, Subtype: :Type0, Encoding: :V})
    assert_equal(:vertical, font.writing_mode)
  end

  it "resolves the descendant font object correctly" do
    assert_equal(@cid_font, @font.descendant_font)
    @doc.clear_cache
    @font[:DescendantFonts] = [@cid_font.value]
    assert_equal(@cid_font.value, @font.descendant_font.value)
  end

  it "returns the font descriptor of the descendant font" do
    assert_same(@fd, @font.font_descriptor)
  end

  it "uses the descendant font for getting the width of a code point" do
    assert_equal(100, @font.width(0x2121))
  end

  it "uses the descendant font for getting the bounding box" do
    assert_equal([0, 1, 2, 3], @font.bounding_box)
  end

  it "uses the descendant font for determining whether the font is embedded" do
    refute(@font.embedded?)
    @cid_font[:FontDescriptor][:FontFile2] = 5
    assert(@font.embedded?)
  end

  it "uses the descendant font for returning the embedded font file" do
    @cid_font[:FontDescriptor][:FontFile2] = 5
    assert_equal(5, @font.font_file)
  end

  describe "word_spacing_applicable?" do
    it "returns false if code point 32 is not a single-byte code point" do
      refute(@font.word_spacing_applicable?)
    end

    it "returns true if code point 32 is a single-byte code point" do
      @font[:Encoding] = @doc.wrap({}, stream: <<-EOF)
        begincodespacerange
        <00> <ff>
        endcodespacerange
      EOF
      assert(@font.word_spacing_applicable?)
    end
  end

  describe "handling of /Encoding value" do
    it "can use predefined CMaps" do
      assert_equal([0x2121], @font.decode("\x21\x21"))
    end

    it "can use custom CMaps" do
      @font[:Encoding] = @doc.wrap({}, stream: <<-EOF)
      begincodespacerange
      <00> <ff>
      endcodespacerange
      EOF
      assert_equal([0x41], @font.decode("\x41"))
    end

    it "raises an error if the /Encoding value is invalid" do
      @font.delete(:Encoding)
      assert_raises(HexaPDF::Error) { @font.decode("a") }
    end
  end

  describe "decode" do
    it "allows reading CIDs from string using the encoding CMap" do
      assert_equal([0x2121, 0x7e7e], @font.decode("\x21\x21\x7e\x7e"))
    end

    it "fails if the string contains invalid codes" do
      assert_raises(HexaPDF::Error) { @font.decode("a") }
    end
  end

  describe "to_utf" do
    it "uses the /ToUnicode CMap if it is available" do
      @font[:ToUnicode] = @doc.add({}, stream: <<-EOF)
      2 beginbfchar
      <20> <0041>
      endbfchar
      EOF
      assert_equal("A", @font.to_utf8(32))
    end

    describe "it uses a predefined UCS2 CMap" do
      it "for predefined CMaps except Identity-H/-V" do
        assert_equal("?", @font.to_utf8(32))
      end

      it "for CMaps with predefined character collections" do
        @font[:Encoding] = @doc.add({}, stream: "")
        assert_equal("?", @font.to_utf8(32))
      end
    end

    it "calls the configured proc if no mapping is available" do
      @font[:Encoding] = :'Identity-H'
      @cid_font[:CIDSystemInfo][:Registry] = :Unknown
      assert_raises(HexaPDF::Error) { @font.to_utf8(32) }
    end
  end
end
