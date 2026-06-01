# -*- encoding: utf-8 -*-

require 'test_helper'
require 'stringio'
require 'hexapdf/font/true_type/font'
require_relative 'common'

describe HexaPDF::Font::TrueType::Font do
  before do
    @io = StringIO.new("OTTO\x00\x02\x00 \x00\x01\x00\x00" \
                       "TESTDATA\x00\x00\x00\x2C\x00\x00\x00\x04" \
                       "head`\x11?\xFA\x00\x00\x00\x30\x00\x00\x00\x36" \
                       "DATA" \
                       "\x00\x00\x00\x01\x01\x02\x03\x04]\t}\x85_\x0F<\xF5#{"\x00" * 38}\x00\x00".b)
    @font = HexaPDF::Font::TrueType::Font.new(@io)
    @font.config['font.true_type.table_mapping'][:TEST] = TrueTypeTestTable.name
  end

  describe "build" do
    it "creates a font file from the tables" do
      assert_equal(@io.string, @font.build)

      result = @io.string.dup
      result[16, 4] = result[44, 4] = 'OTHR'
      result[56, 4] = "F\xE3\x95c".b
      assert_equal(result, @font.build('TEST' => 'OTHR'))
    end
  end

  describe "[]" do
    it "returns a named table" do
      table = @font[:TEST]
      assert_equal('DATA', table.data)
    end

    it "always returns the same table instance" do
      assert_same(@font[:TEST], @font[:TEST])
    end

    it "returns a generic table if no mapping exists" do
      @font.config['font.true_type.table_mapping'].delete(:TEST)
      assert_kind_of(HexaPDF::Font::TrueType::Table, @font[:TEST])
    end

    it "returns nil if the named table doesn't exist in the file" do
      assert_nil(@font[:OTHE])
    end
  end

  describe "getter methods" do
    before do
      font_file = File.join(TEST_DATA_DIR, "fonts", "Ubuntu-Title.ttf")
      @font = HexaPDF::Font::TrueType::Font.new(File.open(font_file))
    end

    it "returns the postscript name" do
      assert_equal("Ubuntu-Title", @font.font_name)
    end

    it "returns the full name" do
      assert_equal("Ubuntu-Title", @font.full_name)
    end

    it "returns the family name" do
      assert_equal("Ubuntu-Title", @font.family_name)
    end

    it "returns the font's weight" do
      assert_equal(400, @font.weight)
    end

    it "returns the font's bounding box" do
      assert_equal([-35, -187, 876, 801], @font.bounding_box)
    end

    it "returns the font's cap height" do
      @font[:'OS/2'].cap_height = 832
      assert_equal(832, @font.cap_height)
    end

    it "returns the font's x height" do
      @font[:'OS/2'].x_height = 642
      assert_equal(642, @font.x_height)
    end

    it "returns the font's ascender" do
      assert_equal(800, @font.ascender)
      @font[:'OS/2'].typo_ascender = nil
      assert_equal(801, @font.ascender)
    end

    it "returns the font's descender" do
      assert_equal(-200, @font.descender)
      @font[:'OS/2'].typo_descender = nil
      assert_equal(-187, @font.descender)
    end

    it "returns the font's italic angle" do
      assert_equal(0.0, @font.italic_angle)
    end

    it "returns the font's dominant vertical stem width" do
      assert_equal(80, @font.dominant_vertical_stem_width)
    end

    it "returns the underline position" do
      assert_equal(-125, @font.underline_position)
    end

    it "returns the underline thickness" do
      assert_equal(50, @font.underline_thickness)
    end

    it "returns the strikeout position" do
      assert_equal(256, @font.strikeout_position)
    end

    it "returns the strikeout thickness" do
      assert_equal(48, @font.strikeout_thickness)
    end
  end

  it "is able to return the ID of the missing glyph" do
    assert_equal(0, @font.missing_glyph_id)
  end

  it "returns the features available for a font" do
    assert(@font.features.empty?)
  end
end
