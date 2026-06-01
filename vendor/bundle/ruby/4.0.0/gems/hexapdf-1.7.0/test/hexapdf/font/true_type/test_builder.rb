# -*- encoding: utf-8 -*-

require 'stringio'
require 'test_helper'
require 'hexapdf/font/true_type'
require 'hexapdf/font/true_type/builder'

describe HexaPDF::Font::TrueType::Builder do
  before do
    font_file = File.join(TEST_DATA_DIR, "fonts", "Ubuntu-Title.ttf")
    @font = HexaPDF::Font::TrueType::Font.new(File.open(font_file))
  end

  after do
    @font.io.close
  end

  it "builds the font file" do
    tables = {
      "loca" => @font[:loca].raw_data << "0",
      "head" => @font[:head].raw_data,
      "glyf" => @font[:glyf].raw_data,
      "maxp" => @font[:maxp].raw_data,
    }
    font_data = HexaPDF::Font::TrueType::Builder.build(tables)
    built_font = HexaPDF::Font::TrueType::Font.new(StringIO.new(font_data))

    assert(built_font[:head].checksum_valid?)
    assert_equal(@font[:glyf].raw_data, built_font[:glyf].raw_data)
    assert(built_font.directory.entry('glyf').offset % 4 == 0)
    assert(built_font[:glyf].checksum_valid?)
    assert_equal(@font[:loca].raw_data << "0", built_font[:loca].raw_data)
    assert(built_font[:loca].checksum_valid?)
    assert(built_font.directory.entry('loca').offset % 4 == 0)
    assert_equal(@font[:maxp].raw_data, built_font[:maxp].raw_data)
    assert(built_font[:maxp].checksum_valid?)
    assert(built_font.directory.entry('maxp').offset % 4 == 0)

    tables = built_font.directory.instance_variable_get(:@tables)
    assert_equal(tables.keys.sort, tables.keys)
  end

  it "allows setting the font version to OTTO for OpenType CFF fonts" do
    tables = {
      "head" => @font[:head].raw_data,
      "maxp" => @font[:maxp].raw_data,
    }
    font_data = HexaPDF::Font::TrueType::Builder.build(tables)
    assert_equal('OTTO', font_data[0, 4])
  end
end
