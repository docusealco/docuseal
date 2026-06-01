# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/document'
require 'hexapdf/type/annotations/line_ending_styling'

describe HexaPDF::Type::Annotations::LineEndingStyling do
  class TestAnnotLineEndingStyling < HexaPDF::Type::Annotation
    define_field :LE, type: HexaPDF::PDFArray, default: [:None, :None]
    include HexaPDF::Type::Annotations::LineEndingStyling
  end

  before do
    @doc = HexaPDF::Document.new
    @annot = @doc.wrap({Type: :Annot}, type: TestAnnotLineEndingStyling)
  end

  describe "line_ending_style" do
    it "returns the current style" do
      assert_kind_of(HexaPDF::Type::Annotations::Line::LineEndingStyle, @annot.line_ending_style)
      assert_equal([:none, :none], @annot.line_ending_style.to_a)
      @annot[:LE] = [:Diamond, :OpenArrow]
      assert_equal([:diamond, :open_arrow], @annot.line_ending_style.to_a)
      @annot[:LE] = [:Diamond, :Unknown]
      assert_equal([:diamond, :none], @annot.line_ending_style.to_a)
    end

    it "sets the style" do
      assert_same(@annot, @annot.line_ending_style(start_style: :OpenArrow))
      assert_equal([:OpenArrow, :None], @annot[:LE])
      assert_same(@annot, @annot.line_ending_style(end_style: :open_arrow))
      assert_equal([:OpenArrow, :OpenArrow], @annot[:LE])
      assert_same(@annot, @annot.line_ending_style(start_style: :circle, end_style: :ClosedArrow))
      assert_equal([:Circle, :ClosedArrow], @annot[:LE])
    end

    it "raises an error for unknown styles" do
      assert_raises(ArgumentError) { @annot.line_ending_style(start_style: :unknown) }
      assert_raises(ArgumentError) { @annot.line_ending_style(end_style: :unknown) }
    end
  end
end
