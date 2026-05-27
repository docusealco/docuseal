# -*- encoding: utf-8 -*-

require 'test_helper'
require_relative 'type1/common'
require 'hexapdf/font/type1_wrapper'
require 'hexapdf/document'

describe HexaPDF::Font::Type1Wrapper do
  before do
    @doc = HexaPDF::Document.new
    @times_wrapper = HexaPDF::Font::Type1Wrapper.new(@doc, FONT_TIMES)
    @symbol_wrapper = HexaPDF::Font::Type1Wrapper.new(@doc, FONT_SYMBOL)
  end

  it "can be used with an existing PDF object" do
    font = @doc.add({Type: :Font, Subtype: :Type1, Encoding: {Differences: [65, :B]},
                     BaseFont: :'Times-Roman'})
    wrapper = HexaPDF::Font::Type1Wrapper.new(@doc, FONT_TIMES, pdf_object: font)
    assert_equal([:B, :E, :A, :S, :T], wrapper.decode_utf8("BEAST").map(&:name))
    assert_equal("A", wrapper.encode(wrapper.glyph(:A)))
    assert_equal("A", wrapper.encode(wrapper.glyph(:B)))
  end

  it "can be asked whether the font is a bold one" do
    refute(@times_wrapper.bold?)
    refute(@symbol_wrapper.bold?)
    assert(@doc.fonts.add("Times", variant: :bold).bold?)
    refute(@doc.fonts.add("Helvetica").bold?)
  end

  it "can be asked whether the font is an italic one" do
    refute(@times_wrapper.italic?)
    refute(@symbol_wrapper.italic?)
    assert(@doc.fonts.add("Times", variant: :italic).italic?)
    assert(@doc.fonts.add("Helvetica", variant: :bold_italic).italic?)
  end

  it "returns 1 for the scaling factor" do
    assert_equal(1, @times_wrapper.scaling_factor)
  end

  describe "decode_*" do
    it "decode_utf8 returns an array of glyph objects" do
      assert_equal([:T, :e, :s, :t], @times_wrapper.decode_utf8("Test").map(&:name))
    end

    it "decode_codepoint returns a single glyph object" do
      assert_equal(:A, @times_wrapper.decode_codepoint(65).name)
    end

    it "falls back to the internal font encoding if the Unicode codepoint is not mapped" do
      assert_equal([:Delta, :Delta], @symbol_wrapper.decode_utf8("D∆").map(&:name))
    end

    it "UTF-8 characters for which no glyph name exists, are mapped to InvalidGlyph objects" do
      glyphs = @times_wrapper.decode_utf8("😁")
      assert_equal(1, glyphs.length)
      assert_kind_of(HexaPDF::Font::InvalidGlyph, glyphs.first)
      assert_equal(+'' << 128_513, glyphs.first.str)
    end
  end

  describe "glyph" do
    it "returns the glyph object for the given name" do
      glyph = @times_wrapper.glyph(:A)
      assert_equal(:A, glyph.name)
      assert_equal("A", glyph.str)
      assert_equal(722, glyph.width)
      assert_equal(15, glyph.x_min)
      assert_equal(0, glyph.y_min)
      assert_equal(706, glyph.x_max)
      assert_equal(674, glyph.y_max)
      refute(glyph.apply_word_spacing?)
      assert(glyph.valid?)
      assert_equal('#<HexaPDF::Font::Type1Wrapper::Glyph font="Times Roman" id=:A "A">',
                   glyph.inspect)
    end

    it "invokes font.on_missing_glyph for missing glyphs" do
      glyph = @times_wrapper.glyph(:ffi)
      assert_kind_of(HexaPDF::Font::InvalidGlyph, glyph)
      assert_equal(:'.notdef', glyph.name)
      assert_equal('ﬃ', glyph.str)
    end
  end

  describe "custom_glyph" do
    it "returns the specified glyph object" do
      glyph = @times_wrapper.custom_glyph(:question, "str")
      assert_equal(:question, glyph.name)
      assert_equal("str", glyph.str)
    end

    it "fails if the provided glyph name is not available for the font" do
      exp = assert_raises(HexaPDF::Error) { @times_wrapper.custom_glyph(:handicap, 'c') }
      assert_match(/Glyph named :handicap not found in font 'Times Roman'/, exp.message)
    end
  end

  describe "encode" do
    describe "uses WinAnsiEncoding as initial encoding for non-symbolic fonts" do
      it "returns the PDF font dictionary using WinAnsiEncoding and encoded glyph" do
        code = @times_wrapper.encode(@times_wrapper.glyph(:a))
        @doc.dispatch_message(:complete_objects)
        assert_equal("a", code)
        assert_equal(:WinAnsiEncoding, @times_wrapper.pdf_object[:Encoding])
      end

      it "fails if an InvalidGlyph is encoded" do
        exp = assert_raises(HexaPDF::MissingGlyphError) { @times_wrapper.encode(@times_wrapper.glyph(:ffi)) }
        assert_match(/No glyph for "ﬃ" in font 'Times Roman'/, exp.message)
      end

      it "fails if the encoding does not support the given glyph" do
        assert_raises(HexaPDF::Error) { @times_wrapper.encode(@times_wrapper.glyph(:uring)) }
      end
    end

    it "uses the font's internal encoding for fonts with the Special character set" do
      code = @symbol_wrapper.encode(@symbol_wrapper.glyph(:plus))
      @doc.dispatch_message(:complete_objects)
      assert_equal("+", code)
      assert_nil(@symbol_wrapper.pdf_object[:Encoding])
    end

    it "uses an empty encoding as initial encoding if a custom encoding is needed" do
      wrapper = HexaPDF::Font::Type1Wrapper.new(@doc, FONT_TIMES, custom_encoding: true)
      code = wrapper.encode(wrapper.glyph(:plus))
      @doc.dispatch_message(:complete_objects)
      assert_equal("\x21", code)
      assert_equal({Differences: [32, :space, :plus]}, wrapper.pdf_object[:Encoding].value)
    end
  end

  describe "creates the necessary PDF dictionaries" do
    it "sets the circular reference" do
      assert_same(@times_wrapper, @times_wrapper.pdf_object.font_wrapper)
    end

    it "makes sure that the PDF dictionaries are indirect" do
      assert(@times_wrapper.pdf_object.indirect?)
    end

    it "handles the case where the font is added but then not used and deleted" do
      @doc.task(:optimize, compact: true)
      assert(@times_wrapper.pdf_object.null?)
      @doc.dispatch_message(:complete_objects)
      assert(@times_wrapper.pdf_object.null?)
    end
  end
end
