# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/utils/pdf_doc_encoding'

describe HexaPDF::Utils::PDFDocEncoding do
  before do
    @obj = HexaPDF::Utils::PDFDocEncoding
  end

  describe "convert_to_utf8" do
    it "converts the given string to UTF-8" do
      result = @obj.convert_to_utf8("Testing\x9c\x92".b)
      assert_equal(Encoding::UTF_8, result.encoding)
      assert_equal("Testing\u0153\u2122", result)
    end
  end
end
