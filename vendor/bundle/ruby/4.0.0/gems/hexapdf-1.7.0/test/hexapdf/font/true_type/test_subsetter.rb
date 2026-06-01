# -*- encoding: utf-8 -*-

require 'test_helper'
require 'stringio'
require 'hexapdf/font/true_type'

describe HexaPDF::Font::TrueType::Subsetter do
  before do
    font_file = File.join(TEST_DATA_DIR, "fonts", "Ubuntu-Title.ttf")
    @font = HexaPDF::Font::TrueType::Font.new(File.open(font_file))
    @subsetter = HexaPDF::Font::TrueType::Subsetter.new(@font)
  end

  after do
    @font.io.close
  end

  it "adds glyphs to the subset" do
    assert_equal(1, @subsetter.use_glyph(5))
    assert_equal(2, @subsetter.use_glyph(6))
    assert_equal(1, @subsetter.use_glyph(5))
  end

  it "returns the subset glyph ID for already subset glyphs" do
    assert_nil(@subsetter.subset_glyph_id(5))
    value = @subsetter.use_glyph(5)
    assert_equal(value, @subsetter.subset_glyph_id(5))
  end

  it "doesn't use certain subset glyph IDs for performance reasons" do
    1.upto(93) {|i| @subsetter.use_glyph(i) }
    # glyph 0, 93 used glyph, 4 special glyphs
    assert_equal(1 + 93 + 4, @subsetter.instance_variable_get(:@glyph_map).size)
    1.upto(12) {|i| assert_equal(i, @subsetter.subset_glyph_id(i), "id=#{i}") }
    13.upto(38) {|i| assert_equal(i + 1, @subsetter.subset_glyph_id(i), "id=#{i}") }
    39.upto(88) {|i| assert_equal(i + 3, @subsetter.subset_glyph_id(i), "id=#{i}") }
    89.upto(93) {|i| assert_equal(i + 4, @subsetter.subset_glyph_id(i), "id=#{i}") }
  end

  it "creates the subset font file" do
    gid = @font[:cmap].preferred_table[0x41]
    @subsetter.use_glyph(gid)
    subset = HexaPDF::Font::TrueType::Font.new(StringIO.new(@subsetter.build_font))

    assert(Time.now - subset[:head].modified < 10)
    assert_equal(2, subset[:maxp].num_glyphs)
    assert_equal(2, subset[:hhea].num_of_long_hor_metrics)
    assert_equal(3, subset[:loca].offsets.length)

    assert_equal(subset[:hmtx][0], @font[:hmtx][0])
    assert_equal(subset[:hmtx][1], @font[:hmtx][gid])

    assert_equal(subset[:glyf][1].raw_data, @font[:glyf][gid].raw_data)
  end

  it "correctly subsets compound glyphs" do
    font_file = "/usr/share/fonts/truetype/noto/NotoSansMono-Regular.ttf"
    skip unless File.exist?(font_file)

    begin
      @font = HexaPDF::Font::TrueType::Font.new(File.open(font_file))
      @subsetter = HexaPDF::Font::TrueType::Subsetter.new(@font)

      @subsetter.use_glyph(@font[:cmap].preferred_table['ë'.ord])
      subset = HexaPDF::Font::TrueType::Font.new(StringIO.new(@subsetter.build_font))

      assert_equal(5, subset[:maxp].num_glyphs)
      assert_equal([2, 3], subset[:glyf][1].components)
      assert_equal([4], subset[:glyf][3].components)
    ensure
      @font.io.close
    end
  end
end
