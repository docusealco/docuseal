# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/content/smart_text_extractor'
require 'hexapdf/document'

describe HexaPDF::Content::SmartTextExtractor::TextRunCollector::TextRun do
  it "has various accessors" do
    text_run = HexaPDF::Content::SmartTextExtractor::TextRunCollector::TextRun.new('s', 1, 2, 3, 5)
    assert_equal('s', text_run.string)
    assert_equal(2, text_run.width)
    assert_equal(3, text_run.height)
  end
end

describe HexaPDF::Content::SmartTextExtractor::TextRunProcessor do
  it "turns glyphs into TextRun objects" do
    processor = HexaPDF::Content::SmartTextExtractor::TextRunProcessor.new
    doc = HexaPDF::Document.new
    page = doc.pages.add
    page.canvas.font('Helvetica', size: 10).
      text('Te', at: [10, 500]).
      text_matrix(0.866, -0.5, 0.5, 0.866, 0, 0).
      text('Te')
    page.process_contents(processor)
    assert_equal([['T', 10, 497.75, 16.11, 509.31], ['e', 16.11, 497.75, 21.67, 509.31],
                  ["T", -1.125, -5.0035, 9.94626, 8.06246],
                  ["e", 4.16626, -7.7835, 14.761220000000002, 5.00746]],
                  processor.text_runs.map(&:to_a))
  end
end

describe HexaPDF::Content::SmartTextExtractor do
  def text_run(str, left, bottom, right, top)
    HexaPDF::Content::SmartTextExtractor::TextRunCollector::TextRun.new(str, left, bottom, right, top)
  end

  def layout_runs(runs, width = 595, height = 842, **options)
    runs = runs.map {|args| text_run(*args) }
    HexaPDF::Content::SmartTextExtractor.layout_text_runs(runs, width, height, **options)
  end

  it "works for a page with no text" do
    assert_equal('', layout_runs([]))
  end

  it "works for a single run on the left side of the page" do
    assert_equal('test', layout_runs([['test', 0, 100, 20, 110]]))
  end

  it "works for a single run not on the left side of the page" do
    assert_equal('test', layout_runs([['test', 50, 100, 70, 110]]))
  end

  it "preserves the relative indent" do
    assert_equal("Hello\n     World", layout_runs([['Hello', 50, 100, 70, 110],
                                                   ['World', 70, 80, 90, 100]]))
  end

  it "combines text runs if they have the same top/bottom and there is less than 1pt between them" do
    x = +'Hello'
    assert_equal('HelloWorld', layout_runs([[x, 50, 100, 60, 110],
                                            ['World', 60, 100, 70, 110]]))
    assert_equal('HelloWorld', x)
  end

  it "preserves the space between two runs" do
    assert_equal('Hello World', layout_runs([['Hello', 50, 100, 70, 110],
                                             ['World', 72, 100, 92, 110]]))
    assert_equal('Hello   World', layout_runs([['Hello', 50, 100, 70, 110],
                                               ['World', 80, 100, 100, 110]]))
 end

  it "inserts a space after very narrow text parts if necessary" do
    assert_equal('Hello World!', layout_runs([['Hello', 50, 100, 60, 110],
                                              ['World!', 63, 100, 87, 110]]))
 end

  it "preserves the visual horizontal ordering of two runs" do
    assert_equal('Hello World', layout_runs([['World', 72, 100, 92, 110],
                                             ['Hello', 50, 100, 70, 110]]))
  end

  it "preserves the visual vertical ordering of two runs" do
    assert_equal("Hello\nWorld", layout_runs([['World', 50, 80, 70, 100],
                                              ['Hello', 50, 100, 70, 110]]))
  end

  it "inserts a single blank line between paragraphs" do
    assert_equal("Hello\nWorld\n\nHere",
                 layout_runs([['Hello', 50, 100, 70, 110],
                              ['World', 50, 90, 70, 100],
                              ['Here', 50, 65, 66, 75]]))
  end

  it "inserts multiply lines for large gaps between paragraphs" do
    assert_equal("Hello\nWorld\nHere\n\n\n\n\n\n\nFoot",
                 layout_runs([['Hello', 50, 100, 70, 110],
                              ['World', 50, 90, 70, 100],
                              ['Here', 50, 80, 70, 90],
                              ['Foot', 50, 10, 66, 20]]))
  end

  it "ignores outliers when calculating the normal line spacing" do
    assert_equal("Hello\nWorld\n\n\n\nHere",
                 layout_runs([['Hello', 50, 100, 70, 110],
                              ['World', 50, 90, 70, 100],
                              ['Here', 50, 50, 70, 60]]))
  end

  it "can use a different line_tolerance_factor" do
    assert_equal("HelloWorld",
                 layout_runs([['Hello', 50, 100, 70, 110],
                              ['World', 50, 90, 70, 100]], line_tolerance_factor: 1))
  end

  it "can use a different paragraph_distance_threshold" do
    assert_equal("Hello\n\nWorld",
                 layout_runs([['Hello', 50, 100, 70, 110],
                              ['World', 50, 90, 70, 100]], paragraph_distance_threshold: 1))
  end

  it "can use a different large_distance_threshold" do
    assert_equal("Hello\nWorld\n\nHere",
                 layout_runs([['Hello', 50, 100, 70, 110],
                              ['World', 50, 90, 70, 100],
                              ['Here', 50, 50, 66, 60]], large_distance_threshold: 8))
  end
end
