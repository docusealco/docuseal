# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/font/invalid_glyph'

describe HexaPDF::Font::InvalidGlyph do
  before do
    font = Object.new
    font.define_singleton_method(:missing_glyph_id) { 0 }
    font.define_singleton_method(:full_name) { "Test Roman" }
    font_wrapper = Object.new
    font_wrapper.define_singleton_method(:wrapped_font) { font }
    @glyph = HexaPDF::Font::InvalidGlyph.new(font_wrapper, "str")
  end

  it "returns the missing glyph id for id/name" do
    assert_equal(0, @glyph.id)
    assert_equal(0, @glyph.name)
  end

  it "returns 0 for all glyph dimensions" do
    assert_equal(0, @glyph.x_min)
    assert_equal(0, @glyph.x_max)
    assert_equal(0, @glyph.y_min)
    assert_equal(0, @glyph.y_max)
  end

  it "doesn't allow the application of word spacing" do
    refute(@glyph.apply_word_spacing?)
  end

  it "returns false when asked whether it is valid" do
    refute(@glyph.valid?)
  end

  it "returns true if the glyph represents a control character" do
    refute(@glyph.control_char?)
    assert(HexaPDF::Font::InvalidGlyph.new(nil, "\n"))
    assert(HexaPDF::Font::InvalidGlyph.new(nil, "\u{8203}"))
  end

  it "can represent itself for debug purposes" do
    assert_equal('#<HexaPDF::Font::InvalidGlyph font="Test Roman" id=0 "str">',
                 @glyph.inspect)
  end
end
