# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/font/encoding/zapf_dingbats_encoding'

describe HexaPDF::Font::Encoding::ZapfDingbatsEncoding do
  before do
    @enc = HexaPDF::Font::Encoding::ZapfDingbatsEncoding.new
  end

  describe "unicode" do
    it "uses the special ZapfDingbats glyph list" do
      assert_equal("\u2721", @enc.unicode(65))
    end
  end
end
