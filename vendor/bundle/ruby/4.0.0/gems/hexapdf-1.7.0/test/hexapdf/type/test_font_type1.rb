# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/document'
require 'hexapdf/type/font_type1'

describe HexaPDF::Type::FontType1::StandardFonts do
  before do
    @obj = HexaPDF::Type::FontType1::StandardFonts
  end

  it "checks whether a given name corresponds to a standard font via #standard_font?" do
    assert(@obj.standard_font?(:'Times-Roman'))
    assert(@obj.standard_font?(:TimesNewRoman))
    refute(@obj.standard_font?(:LibreSans))
  end

  it "returns the standard PDF name for an alias via #standard_name" do
    assert_equal(:'Times-Roman', @obj.standard_name(:TimesNewRoman))
  end

  describe "font" do
    it "returns the Type1 font object for a given standard name" do
      font = @obj.font(:'Times-Roman')
      assert_equal("Times Roman", font.full_name)
    end

    it "caches the font for reuse" do
      font = @obj.font(:'Times-Roman')
      assert_same(font, @obj.font(:'Times-Roman'))
    end

    it "returns nil if the given name doesn't belong to a standard font" do
      assert_nil(@obj.font(:SomeOtherFont))
    end
  end
end

describe HexaPDF::Type::FontType1 do
  before do
    @doc = HexaPDF::Document.new
    @font = @doc.add({Type: :Font, Subtype: :Type1, Encoding: :WinAnsiEncoding,
                      BaseFont: :'Times-Roman'})

    font_file = @doc.add({}, stream: <<-EOF)
      /Encoding 256 array
      0 1 255 {1 index exch /.notdef put} for
      dup 32 /A put
      dup 34 /B put
      readonly def
    EOF
    font_descriptor = @doc.add({Type: :FontDescriptor, FontName: :Embedded, Flags: 0b100,
                                FontBBox: [0, 1, 2, 3], ItalicAngle: 0, Ascent: 900,
                                Descent: -100, CapHeight: 800, StemV: 20, FontFile: font_file})
    @embedded_font = @doc.add({Type: :Font, Subtype: :Type1, Encoding: :WinAnsiEncoding,
                               BaseFont: :Embedded, FontDescriptor: font_descriptor,
                               FirstChar: 32, LastChar: 34, Widths: [600, 0, 700]})
  end

  it "can create a usable font wrapper for the standard fonts" do
    wrapper = @font.font_wrapper
    assert(wrapper)
    assert_same(@font, wrapper.pdf_object)
    assert_equal(@font[:BaseFont], wrapper.wrapped_font.font_name.intern)
    assert_same(wrapper, @font.font_wrapper)
  end

  describe "encoding" do
    it "returns the the standard font's encoding" do
      @font.delete(:Encoding)
      assert_equal(HexaPDF::Font::Encoding.for_name(:StandardEncoding), @font.encoding)
    end

    it "uses the encoding of the embedded font when necessary" do
      @embedded_font.delete(:Encoding)
      assert_equal({32 => :A, 34 => :B}, @embedded_font.encoding.code_to_name)
    end

    it "fails if the encoding needs to be read from the font but is is not embedded" do
      @embedded_font.delete(:Encoding)
      @embedded_font[:FontDescriptor].delete(:FontFile)
      assert_raises(HexaPDF::Error) { @embedded_font.encoding }
    end
  end

  describe "width" do
    it "returns the glyph width when using a standard font" do
      assert_equal(250, @font.width(32))
    end

    it "defers to its superclass for all other cases" do
      assert_equal(600, @embedded_font.width(32))
    end
  end

  describe "bounding_box" do
    it "returns the bounding box for a standard font" do
      font = HexaPDF::Type::FontType1::StandardFonts.font(:'Times-Roman')
      assert_equal(font.bounding_box, @font.bounding_box)
    end

    it "defers to its superclass for all other cases" do
      assert_equal([0, 1, 2, 3], @embedded_font.bounding_box)
    end

    it "returns nil for non-standard fonts without bounding box information" do
      @embedded_font[:FontDescriptor].delete(:FontBBox)
      assert_nil(@embedded_font.bounding_box)
    end
  end

  describe "symbolic?" do
    it "return true for the standard fonts Symbol and ZapfDingbats" do
      @font[:BaseFont] = :Symbol
      assert(@font.symbolic?)

      @font[:BaseFont] = :ZapfDingbats
      assert(@font.symbolic?)
    end

    it "defers to its superclass for all other cases" do
      assert(@embedded_font.symbolic?)
    end

    it "returns nil if it cannot be determined whether the font is symbolic" do
      @embedded_font.delete(:FontDescriptor)
      assert_nil(@embedded_font.symbolic?)
    end
  end

  describe "validation" do
    it "allows empty fields for standard fonts" do
      assert(@font.validate)
    end

    it "requires that the FontDescriptor key is set for non-standard fonts" do
      assert(@embedded_font.validate)
      @embedded_font.delete(:FontDescriptor)
      refute(@embedded_font.validate)
    end

    it "ensures a correct Symbol value for the /Encoding key" do
      @font[:Encoding] = :Other
      refute(@font.validate)
    end

    it "works around certain invalid PDFs with a /SymbolEncoding value for /Encoding" do
      @font[:Encoding] = :SymbolEncoding
      @font[:BaseFont] = :Symbol
      assert(@font.validate)
      refute(@font.key?(:Encoding))
    end

    it "works around certain invalid PDFs with a /StandardEncoding value for /Encoding" do
      @font[:Encoding] = :StandardEncoding
      assert(@font.validate)
      assert(:WinAnsiEncoding, @font[:Encoding][:BaseEncoding])
      assert_equal([39, :quoteright, 96, :quoteleft], @font[:Encoding][:Differences][0, 4])
    end
  end
end
