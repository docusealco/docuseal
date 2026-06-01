# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/document'

describe HexaPDF::Document::Fonts do
  before do
    @doc = HexaPDF::Document.new
    @doc.config['font_loader'] = []
  end

  describe "add" do
    before do
      @doc.config['font_loader'] << lambda do |doc, name, **options|
        assert_equal(@doc, doc)
        if name == :TestFont
          x = Object.new
          x.define_singleton_method(:name) do
            options[:variant] == :bold ? :BoldFont : :NormalFont
          end
          x
        else
          nil
        end
      end
    end

    it "loads the specified font" do
      assert_equal(:NormalFont, @doc.fonts.add(:TestFont).name)
      assert_equal(:BoldFont, @doc.fonts.add(:TestFont, variant: :bold).name)
    end

    it "caches loaded fonts" do
      font = @doc.fonts.add(:TestFont)
      assert_same(font, @doc.fonts.add(:TestFont))
      assert_same(font, @doc.fonts.add(:TestFont, variant: :none))
    end

    it "fails if the requested font is not found" do
      @doc.config['font_loader'] << 'HexaPDF::FontLoader::Standard14'
      error = assert_raises(HexaPDF::Error) { @doc.fonts.add("Unknown") }
      assert_match(/Times \(none/, error.message)
    end

    it "raises an error if a font loader cannot be correctly retrieved" do
      @doc.config['font_loader'][0] = 'UnknownFontLoader'
      assert_raises(HexaPDF::Error) { @doc.fonts.add(:Other) }
    end
  end

  it "returns the configured fonts" do
    @doc.config['font_loader'] << 'HexaPDF::FontLoader::Standard14'
    @doc.config['font_loader'] << 'HexaPDF::FontLoader::FromConfiguration'
    @doc.config['font.map'] = {'Times' => {heavy: 'none', none: 'none'}, 'Other' => {none: 'none'}}
    fonts = @doc.fonts.configured_fonts
    assert_equal([:none], fonts['Symbol'])
    assert_equal([:none, :bold, :italic, :bold_italic, :heavy], fonts['Times'])
    assert_equal([:none], fonts['Other'])
  end
end
