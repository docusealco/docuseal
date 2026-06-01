# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/font_loader'
require 'hexapdf/document'

describe HexaPDF::FontLoader::Standard14 do
  before do
    @doc = HexaPDF::Document.new
    @obj = HexaPDF::FontLoader::Standard14
  end

  it "loads the font if it is a standard PDF built-in font" do
    wrapper = @obj.call(@doc, "Times")
    assert_equal("Times-Roman", wrapper.wrapped_font.font_name)
    wrapper = @obj.call(@doc, "Helvetica", variant: :bold)
    assert_equal("Helvetica-Bold", wrapper.wrapped_font.font_name)
  end

  it "returns nil for unknown fonts" do
    assert_nil(@obj.call(@doc, "Unknown"))
  end

  it "returns a hash with all standard PDF fonts" do
    assert_equal({
                   'Times' => [:none, :bold, :italic, :bold_italic],
                   'Helvetica' => [:none, :bold, :italic, :bold_italic],
                   'Courier' => [:none, :bold, :italic, :bold_italic],
                   'Symbol' => [:none], 'ZapfDingbats' => [:none]
                 },
                 @obj.available_fonts(@doc))
  end
end
