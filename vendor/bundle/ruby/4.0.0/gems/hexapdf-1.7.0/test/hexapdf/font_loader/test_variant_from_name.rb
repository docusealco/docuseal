# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/font_loader'
require 'hexapdf/document'

describe HexaPDF::FontLoader::VariantFromName do
  before do
    @doc = HexaPDF::Document.new
    @obj = HexaPDF::FontLoader::VariantFromName
  end

  it "loads the font if the name contains a valid variant" do
    wrapper = @obj.call(@doc, "Helvetica bold")
    assert_equal("Helvetica-Bold", wrapper.wrapped_font.font_name)
    wrapper = @obj.call(@doc, "Helvetica italic")
    assert_equal("Helvetica-Oblique", wrapper.wrapped_font.font_name)
    wrapper = @obj.call(@doc, "Helvetica bold_italic")
    assert_equal("Helvetica-BoldOblique", wrapper.wrapped_font.font_name)
  end

  it "returns nil if the font name contains an unknown variant" do
    assert_nil(@obj.call(@doc, "Helvetica oblique"))
  end

  it "ignores a supplied variant keyword argument" do
    wrapper = @obj.call(@doc, "Helvetica bold", variant: :italic)
    assert_equal("Helvetica-Bold", wrapper.wrapped_font.font_name)
  end

  it "returns nil for unknown fonts" do
    assert_nil(@obj.call(@doc, "Unknown"))
  end
end
