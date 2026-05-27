# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/document'
require 'hexapdf/type/font_simple'

describe HexaPDF::Type::FontSimple do
  before do
    @doc = HexaPDF::Document.new
    cmap = @doc.add({}, stream: <<-EOF)
      2 beginbfchar
      <20> <0041>
      <22> <0042>
      endbfchar
    EOF
    @font_descriptor = @doc.add({Type: :FontDescriptor, FontName: :Embedded, Flags: 0b100,
                                 FontBBox: [0, 1, 2, 3], ItalicAngle: 0, Ascent: 900,
                                 MissingWidth: 500, Descent: -100, CapHeight: 800, StemV: 20})
    @font = @doc.add({Type: :Font, Encoding: :WinAnsiEncoding,
                      BaseFont: :Embedded, FontDescriptor: @font_descriptor, ToUnicode: cmap,
                      FirstChar: 32, LastChar: 34, Widths: [600, 0, 700]},
                     type: HexaPDF::Type::FontSimple)
  end

  it "returns the font descriptor of the font" do
    assert_same(@font_descriptor, @font.font_descriptor)
  end

  describe "encoding" do
    it "fails if /Encoding is absent because encoding_from_font is not implemented" do
      @font.delete(:Encoding)
      assert_raises(RuntimeError) { @font.encoding }
    end

    describe "/Encoding is a name" do
      it "returns a predefined encoding if /Encoding specifies one" do
        assert_equal(HexaPDF::Font::Encoding.for_name(:WinAnsiEncoding), @font.encoding)
      end

      it "fails if /Encoding is an invalid name because encoding_from_font is not implemented" do
        @font[:Encoding] = :SomethingUnknown
        assert_raises(RuntimeError) { @font.encoding }
      end
    end

    describe "/Encoding is a dictionary" do
      before do
        @font[:Encoding] = {}
      end

      describe "no /BaseEncoding is specified" do
        it "fails if the font is embedded because encoding_from_font is not implemented" do
          @font[:FontDescriptor][:FontFile] = 5
          assert_raises(RuntimeError) { @font.encoding }
        end

        it "fails for a symbolic non-embedded font because encoding_from_font is not implemented" do
          @font[:FontDescriptor].flag(:symbolic, clear_existing: true)
          assert_raises(RuntimeError) { @font.encoding }
        end

        it "returns the StandardEncoding for a non-symbolic non-embedded font" do
          @font[:FontDescriptor].flag(clear_existing: true)
          assert_equal(HexaPDF::Font::Encoding.for_name(:StandardEncoding), @font.encoding)
        end
      end

      it "returns the encoding specified by /BaseEncoding" do
        @font[:Encoding] = {BaseEncoding: :WinAnsiEncoding}
        assert_equal(HexaPDF::Font::Encoding.for_name(:WinAnsiEncoding), @font.encoding)
      end

      it "fails if /BaseEncoding is invalid because encoding_from_font is not implemented" do
        @font[:Encoding] = {BaseEncoding: :SomethingUnknown}
        assert_raises(RuntimeError) { @font.encoding }
      end

      it "returns a difference encoding if /Differences is specified" do
        @font[:FontDescriptor].flag(clear_existing: true)
        @font[:Encoding][:Differences] = [32, :A, :B, 34, :Z]
        refute_equal(HexaPDF::Font::Encoding.for_name(:StandardEncoding), @font.encoding)
        assert_equal(:A, @font.encoding.name(32))
        assert_equal(:B, @font.encoding.name(33))
        assert_equal(:Z, @font.encoding.name(34))
      end

      it "fails if the /Differences array contains invalid data" do
        @font[:Encoding][:BaseEncoding] = :WinAnsiEncoding
        @font[:Encoding][:Differences] = [:B, 32, :A, :B, 34, :Z]
        assert_raises(HexaPDF::Error) { @font.encoding }

        @font[:Encoding][:Differences] = [32, "data", :A, :B, 34, :Z]
        assert_raises(HexaPDF::Error) { @font.encoding }
      end
    end

    it "fails if /Encoding contains an invalid value" do
      @font[:Encoding] = 5
      assert_raises(HexaPDF::Error) { @font.encoding }
    end
  end

  describe "decode" do
    it "just returns the bytes of the string since this is a simple 1-byte-per-code font" do
      assert_equal([65, 66], @font.decode("AB"))
    end
  end

  describe "to_utf" do
    it "uses a /ToUnicode CMap if it is available" do
      assert_equal("A", @font.to_utf8(32))
    end

    it "uses the font's encoding to map the code to an UTF-8 string if the /ToUnicode is missing" do
      @font.delete(:ToUnicode)
      assert_equal(" ", @font.to_utf8(32))
    end

    it "swallows errors during retrieving the font's encoding" do
      @font.delete(:ToUnicode)
      @font.delete(:Encoding)
      err = assert_raises(HexaPDF::Error) { @font.to_utf8(32) }
      assert_match(/No Unicode mapping/, err.message)
    end

    it "calls the configured proc if no correct mapping could be found" do
      @font.delete(:ToUnicode)
      err = assert_raises(HexaPDF::Error) { @font.to_utf8(0) }
      assert_match(/No Unicode mapping/, err.message)
    end
  end

  describe "writing_mode" do
    it "is always horizontal" do
      assert_equal(:horizontal, @font.writing_mode)
    end
  end

  describe "width" do
    it "returns the glyph width for a valid code point" do
      assert_equal(600, @font.width(32))
    end

    it "returns the /MissingWidth of a /FontDescriptor if available and the width was not found" do
      assert_equal(500, @font.width(0))
    end

    it "returns 0 for a missing code point when FontDescriptor is not available" do
      @font.delete(:FontDescriptor)
      assert_equal(0, @font.width(0))
    end
  end

  describe "symbolic?" do
    it "return true if the font is symbolic" do
      @font[:FontDescriptor].flag(clear_existing: true)
      refute(@font.symbolic?)

      @font[:FontDescriptor].flag(:symbolic)
      assert(@font.symbolic?)
    end

    it "returns nil if it cannot be determined whether the font is symbolic" do
      @font.delete(:FontDescriptor)
      assert_nil(@font.symbolic?)
    end
  end

  it "defines word spacing as always applicable" do
    assert(@font.word_spacing_applicable?)
  end

  describe "validation" do
    before { assert(@font.validate) }

    it "validates the existence of required keys" do
      @font.delete(:FirstChar)
      refute(@font.validate)
    end

    it "validates the lengths of the /Widths field" do
      @font[:Widths] = [65, 65]
      assert(@font.validate)
      assert_equal([65, 65, 65], @font[:Widths])

      @font[:Widths] = [65, 70]
      assert(@font.validate)
      assert_equal([65, 70, 500], @font[:Widths])

      @font[:Widths] = [65, 70]
      @font.delete(:FontDescriptor)
      assert(@font.validate)
      assert_equal([65, 70, 0], @font[:Widths])

      @font[:Widths] = [65, 65, 70, 90, 100]
      assert(@font.validate)
      assert_equal([65, 65, 70], @font[:Widths])
    end
  end
end
