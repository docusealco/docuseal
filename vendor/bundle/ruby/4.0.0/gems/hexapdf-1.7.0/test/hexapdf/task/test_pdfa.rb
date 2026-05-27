# -*- encoding: utf-8 -*-

require 'stringio'
require 'test_helper'
require 'hexapdf/document'

describe HexaPDF::Task::PDFA do
  before do
    @doc = HexaPDF::Document.new
  end

  it "fails if the given PDF/A level is invalid" do
    assert_raises(ArgumentError) { @doc.task(:pdfa, level: '1a') }
    assert_raises(ArgumentError) { @doc.task(:pdfa, level: '2a') }
    assert_raises(ArgumentError) { @doc.task(:pdfa, level: '3a') }
    assert_raises(ArgumentError) { @doc.task(:pdfa, level: '4e') }
    assert_raises(ArgumentError) { @doc.task(:pdfa, level: 'something') }
  end

  it "removes the standard 14 PDF font loader" do
    @doc.task(:pdfa)
    assert_raises(HexaPDF::Error) { @doc.fonts.add('Helvetia') }
  end

  it "adds the necessary XMP metadata entries before the document is written" do
    @doc.task(:pdfa, level: '3b')
    @doc.write(StringIO.new)
    assert_equal('3', @doc.metadata.property('pdfaid', 'part'))
    assert_equal('B', @doc.metadata.property('pdfaid', 'conformance'))
  end

  it "adds an RGB output intent before the document is written" do
    @doc.task(:pdfa)
    @doc.write(StringIO.new)
    oi = @doc.catalog[:OutputIntents].first
    assert_equal(:GTS_PDFA1, oi[:S])
    assert_equal('sRGB2014.icc', oi[:OutputConditionIdentifier])
    assert_equal('sRGB2014.icc', oi[:Info])
    assert_kind_of(HexaPDF::Stream, oi[:DestOutputProfile])
  end

  it "applies fixes based on the optional fixes argument" do
    file = File.join(TEST_DATA_DIR, 'pdfa', 'mismatching_glyph_widths_cidfont_type2.pdf')

    # Document loaded -> all fixes applied by default
    doc = HexaPDF::Document.open(file)
    doc.task(:pdfa, level: '3b')
    doc.dispatch_message(:complete_objects)
    font = HexaPDF::Font::TrueType::Font.new(StringIO.new(doc.object(10).stream))
    assert_equal(348, font[:hmtx][1].advance_width)

    # Not loaded -> fixes for loaded documents excluded
    doc = HexaPDF::Document.open(file)
    created = HexaPDF::Document.new
    created.pages << created.import(doc.pages[0])
    created.task(:pdfa, level: '3b')
    created.dispatch_message(:complete_objects)
    font_file = created.pages[0].resources.font(:F1).descendant_font[:FontDescriptor][:FontFile2]
    font = HexaPDF::Font::TrueType::Font.new(StringIO.new(font_file.stream))
    assert_equal(346, font[:hmtx][1].advance_width)

    # Explicitly specify to apply all fixes
    created.task(:pdfa, level: '3b', fixes: :all)
    created.dispatch_message(:complete_objects)
    font = HexaPDF::Font::TrueType::Font.new(StringIO.new(font_file.stream))
    assert_equal(348, font[:hmtx][1].advance_width)
  end

  describe "fix_glyph_widths" do
    before do
      @file = File.join(TEST_DATA_DIR, 'pdfa', 'mismatching_glyph_widths_cidfont_type2.pdf')
    end

    it "fixes glyph width inconsistencies between the font and the font dictionary" do
      doc = HexaPDF::Document.open(@file)
      doc.task(:pdfa, level: '3b', fixes: [:fix_glyph_widths])

      font = HexaPDF::Font::TrueType::Font.new(StringIO.new(doc.object(10).stream))
      assert_equal(346, font[:hmtx][1].advance_width)
      doc.dispatch_message(:complete_objects)
      font = HexaPDF::Font::TrueType::Font.new(StringIO.new(doc.object(10).stream))
      assert_equal(348, font[:hmtx][1].advance_width)
    end

    it "works if there is an explicit CIDToGIDMap stream" do
      doc = HexaPDF::Document.open(@file)
      doc.object(5)[:CIDToGIDMap] = doc.wrap({}, stream: [0, 1, 2, 3, 4].pack('n*'))
      doc.task(:pdfa, level: '3b', fixes: [:fix_glyph_widths])
      doc.dispatch_message(:complete_objects)
      font = HexaPDF::Font::TrueType::Font.new(StringIO.new(doc.object(10).stream))
      assert_equal(348, font[:hmtx][1].advance_width)
    end

    it "processes annotation appearances" do
      doc = HexaPDF::Document.new
      doc.pages.add
      doc.annotations.create_rectangle(doc.pages[0], 20, 20, 20, 60).
        regenerate_appearance
      form = doc.pages[0][:Annots][0].create_appearance
      form.canvas.
        font(File.join(TEST_DATA_DIR, 'fonts', 'Ubuntu-Title.ttf'), size: 10).
        text('Hola', at: [0, 0])

      doc = HexaPDF::Document.new(io: StringIO.new(doc.write_to_string))
      font = doc.pages[0][:Annots][0].appearance.resources.font(:F1).descendant_font
      font[:W][1][0] = 10
      doc.task(:pdfa, level: '3b', fixes: [:fix_glyph_widths])
      doc.dispatch_message(:complete_objects)
      font = HexaPDF::Font::TrueType::Font.new(StringIO.new(font[:FontDescriptor][:FontFile2].stream))
      assert_equal(10, font[:hmtx][1].advance_width)
    end
  end
end
