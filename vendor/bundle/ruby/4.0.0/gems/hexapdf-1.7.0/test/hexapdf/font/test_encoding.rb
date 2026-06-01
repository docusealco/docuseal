# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/font/encoding'

describe HexaPDF::Font::Encoding do
  describe "::for_name" do
    it "returns nil if an unsupported encoding is given" do
      assert_nil(HexaPDF::Font::Encoding.for_name(:some_unknown_encoding))
    end

    it "returns the requested encoding object" do
      assert_kind_of(HexaPDF::Font::Encoding::WinAnsiEncoding,
                     HexaPDF::Font::Encoding.for_name(:WinAnsiEncoding))
      assert_kind_of(HexaPDF::Font::Encoding::MacRomanEncoding,
                     HexaPDF::Font::Encoding.for_name(:MacRomanEncoding))
      assert_kind_of(HexaPDF::Font::Encoding::StandardEncoding,
                     HexaPDF::Font::Encoding.for_name(:StandardEncoding))
      assert_kind_of(HexaPDF::Font::Encoding::MacExpertEncoding,
                     HexaPDF::Font::Encoding.for_name(:MacExpertEncoding))
      assert_kind_of(HexaPDF::Font::Encoding::SymbolEncoding,
                     HexaPDF::Font::Encoding.for_name(:SymbolEncoding))
      assert_kind_of(HexaPDF::Font::Encoding::ZapfDingbatsEncoding,
                     HexaPDF::Font::Encoding.for_name(:ZapfDingbatsEncoding))
    end
  end
end
