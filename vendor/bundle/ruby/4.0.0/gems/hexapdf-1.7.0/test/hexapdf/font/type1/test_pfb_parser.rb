# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/font/type1'

describe HexaPDF::Font::Type1::PFBParser do
  describe "::encoding" do
    it "can extract the encoding specified as StandardEncoding" do
      data = "bla bla bla /Encoding StandardEncoding def bla bla"
      assert_same(HexaPDF::Font::Encoding.for_name(:StandardEncoding),
                  HexaPDF::Font::Type1::PFBParser.encoding(data))
    end

    it "can extract the encoding specified as array" do
      data = <<-EOF
      bla bla bla
      /Encoding 256 array
      0 1 255 {1 index exch /.notdef put} for
      dup 32 /space put
      dup 33 /exclam put
      dup 34 /universal put
      dup 35 /numbersign put
      dup 36 /existential put
      readonly def
      bla bla bla
      EOF
      enc = HexaPDF::Font::Type1::PFBParser.encoding(data)
      assert_equal(:space, enc.name(32))
      assert_equal(:existential, enc.name(36))
    end

    it "fails if the encoding can't be extracted" do
      data = "something without an encoding"
      assert_raises(HexaPDF::Error) { HexaPDF::Font::Type1::PFBParser.encoding(data) }
    end
  end
end
