# -*- encoding: utf-8 -*-

require 'test_helper'
require_relative '../font/true_type/table/common'
require 'hexapdf/document'
require 'hexapdf/font/true_type_wrapper'
require 'hexapdf/layout/text_shaper'

using HexaPDF::Layout::NumericRefinements

describe HexaPDF::Layout::TextShaper do
  before do
    @doc = HexaPDF::Document.new
    @shaper = HexaPDF::Layout::TextShaper.new
  end

  def setup_fragment(items, **options)
    style = HexaPDF::Layout::Style.new(font: @font, font_size: 20, font_features: options)
    HexaPDF::Layout::TextFragment.new(items, style)
  end

  describe "Type1 font features" do
    before do
      @font = @doc.fonts.add("Times", custom_encoding: true)
    end

    it "handles ligatures" do
      fragment = setup_fragment(@font.decode_utf8('fish fish fi').insert(1, 100).
        insert(0, 100), liga: true)
      @shaper.shape_text(fragment)
      assert_equal([100, :fi, :s, :h, :space, :fi, :s, :h, :space, :fi],
                   fragment.items.map {|item| item.kind_of?(Numeric) ? item : item.id })
    end

    it "handles kerning" do
      fragment = setup_fragment(@font.decode_utf8('fish fish wow').insert(1, 100), kern: true)
      @shaper.shape_text(fragment)
      assert_equal([:f, 100, :i, :s, :h, :space, :f, 20, :i, :s, :h, :space, :w, 10, :o, 25, :w],
                   fragment.items.map {|item| item.kind_of?(Numeric) ? item : item.id })
    end
  end

  describe "TrueType font features" do
    before do
      font_file = File.join(TEST_DATA_DIR, "fonts", "Ubuntu-Title.ttf")
      @wrapped_font = HexaPDF::Font::TrueType::Font.new(File.open(font_file))
      @font = HexaPDF::Font::TrueTypeWrapper.new(@doc, @wrapped_font)
    end

    it "handles kerning" do
      data = [0, 1].pack('n2') <<
        [0, 6 + 8 + 12, 0x1].pack('n3') <<
        [2, 0, 0, 0, 53, 80, -20, 80, 81, -10].pack('n4n2s>n2s>')
      table = create_table(:Kern, data, standalone: true)
      @wrapped_font.instance_eval { @tables[:kern] = table }
      fragment = setup_fragment(@font.decode_utf8('Top Top').insert(1, 100), kern: true)
      @shaper.shape_text(fragment)
      assert_equal([53, [100], 80, [10], 81, 3, 53, [20], 80, [10], 81],
                   fragment.items.map {|item| item.kind_of?(Numeric) ? [item] : item.id })
    end
  end
end
