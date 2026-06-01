# -*- encoding: utf-8 -*-

require 'test_helper'
require_relative 'common'
require 'hexapdf/font/type1'
require 'hexapdf/data_dir'
require 'tempfile'
require 'stringio'

describe HexaPDF::Font::Type1::AFMParser do
  describe "::parse" do
    before do
      @file = Tempfile.new('hexapdf-afm')
      @file.write("StartFontMetrics 4.1\nFontName Test\nEndFontMetrics\nFontName Other\n")
      @file.close
    end

    after do
      @file.unlink
    end

    it "can work with file names" do
      assert_equal('Test', HexaPDF::Font::Type1::AFMParser.parse(@file.path).font_name)
    end

    it "can work with IO streams" do
      @file.open
      assert_equal('Test', HexaPDF::Font::Type1::AFMParser.parse(@file).font_name)
    end
  end

  it "can parse the 14 core PDF font files" do
    Dir[File.join(HexaPDF.data_dir, 'afm', '*.afm')].each do |file|
      metrics = HexaPDF::Font::Type1::AFMParser.parse(file)
      basename = File.basename(file, '.*')
      assert_equal(basename, metrics.font_name, basename)
      assert_equal(basename.sub(/-.*/, ''), metrics.family_name, basename)
      refute(metrics.character_metrics.empty?, basename)
    end
  end

  it "parses until EOF if no end token is found" do
    io = StringIO.new("StartFontMetrics 4.1\nFontName Test")
    assert_equal('Test', HexaPDF::Font::Type1::AFMParser.parse(io).font_name)
  end

  it "extracts kerning and ligature information" do
    metrics = FONT_TIMES.metrics
    glyph = metrics.character_metrics[:f]
    assert_equal([20, 0, 383, 683], glyph.bbox)
    assert_equal(-20, metrics.kerning_pairs.dig(:f, :i))
    assert_equal(:fi, metrics.ligature_pairs.dig(:f, :i))
  end

  it "calculates an ascender and descender value from the font bounding box if necessary" do
    metrics = HexaPDF::Font::Type1::AFMParser.parse(File.join(HexaPDF.data_dir, 'afm/Symbol.afm'))
    assert_equal(metrics.bounding_box[1], metrics.descender)
    assert_equal(metrics.bounding_box[3], metrics.ascender)
  end

  it "fails if the file doesn't start with the correct line" do
    file = StringIO.new("some\nthing")
    assert_raises(HexaPDF::Error) { HexaPDF::Font::Type1::AFMParser.parse(file) }
  end
end
