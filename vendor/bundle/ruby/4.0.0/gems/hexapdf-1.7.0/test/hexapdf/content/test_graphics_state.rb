# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/content/graphics_state'

# Dummy class used as wrapper so that constant lookup works correctly
class GraphicsStateWrapper < Minitest::Spec

  include HexaPDF::Content

  describe NamedValue do
    before do
      @val = NamedValue.new(:round, 1)
    end

    it "freezes a new object on creation" do
      assert(@val.frozen?)
    end

    it "can be compared to name, value or NamedValue objects" do
      assert_equal(@val, :round)
      assert_equal(@val, 1)
      assert_equal(@val, @val)
    end

    it "returns the value when operands are requested" do
      assert_equal(@val.value, @val.to_operands)
    end
  end

  describe LineCapStyle do
    it "can normalize a style argument" do
      [[:BUTT_CAP, :butt, 0], [:ROUND_CAP, :round, 1],
       [:PROJECTING_SQUARE_CAP, :projecting_square, 2]].each do |const_name, name, value|
        const = LineCapStyle.const_get(const_name)
        assert_equal(const, LineCapStyle.normalize(name))
        assert_equal(const, LineCapStyle.normalize(value))
        assert_equal(const, LineCapStyle.normalize(const))
      end
    end

    it "fails when trying to normalize an invalid argument" do
      assert_raises(ArgumentError) { LineCapStyle.normalize(:invalid) }
    end
  end

  describe LineJoinStyle do
    it "can normalize a style argument" do
      [[:MITER_JOIN, :miter, 0], [:ROUND_JOIN, :round, 1],
       [:BEVEL_JOIN, :bevel, 2]].each do |const_name, name, value|
        const = LineJoinStyle.const_get(const_name)
        assert_equal(const, LineJoinStyle.normalize(name))
        assert_equal(const, LineJoinStyle.normalize(value))
        assert_equal(const, LineJoinStyle.normalize(const))
      end
    end

    it "fails when trying to normalize an invalid argument" do
      assert_raises(ArgumentError) { LineJoinStyle.normalize(:invalid) }
    end
  end

  describe RenderingIntent do
    it "can normalize an intent argument" do
      assert_equal(RenderingIntent::ABSOLUTE_COLORIMETRIC,
                   RenderingIntent.normalize(:AbsoluteColorimetric))
      assert_equal(RenderingIntent::RELATIVE_COLORIMETRIC,
                   RenderingIntent.normalize(:RelativeColorimetric))
      assert_equal(RenderingIntent::PERCEPTUAL,
                   RenderingIntent.normalize(:Perceptual))
      assert_equal(RenderingIntent::SATURATION,
                   RenderingIntent.normalize(:Saturation))
    end

    it "fails when trying to normalize an invalid argument" do
      assert_raises(ArgumentError) { RenderingIntent.normalize(:invalid) }
    end
  end

  describe LineDashPattern do
    it "returns a normalized line dash pattern from various values" do
      assert_equal([[], 0], LineDashPattern.normalize(0).to_operands)
      assert_equal([[5], 0], LineDashPattern.normalize(5).to_operands)
      assert_equal([[5, 3], 2], LineDashPattern.normalize([5, 3], 2).to_operands)
      assert_equal([[5], 1], LineDashPattern.normalize(LineDashPattern.normalize(5, 1)).to_operands)
    end

    it "fails on normalization if an invalid array argument is provided" do
      assert_raises(ArgumentError) { LineDashPattern.normalize(:bla) }
    end

    it "fails on initialization if the phase is negative" do
      assert_raises(ArgumentError) { LineDashPattern.new([], -1) }
    end

    it "fails on initialization if all the dash array values are zero " do
      assert_raises(ArgumentError) { LineDashPattern.new([0, 0], 0) }
    end

    it "fails on initialization if a dash array value is negative" do
      assert_raises(ArgumentError) { LineDashPattern.new([-2, 0], 0) }
    end

    it "can be compared to another line dash pattern object" do
      assert_equal(LineDashPattern.new([2, 3], 0),
                   LineDashPattern.new([2, 3], 0))
      refute_equal(LineDashPattern.new([2, 3], 0),
                   LineDashPattern.new([2, 3], 1))
      refute_equal(LineDashPattern.new([2, 3], 0),
                   LineDashPattern.new([2, 2], 0))
    end

    it "returns the operands needed for the line dash pattern operator" do
      assert_equal([[2, 3], 0], LineDashPattern.new([2, 3], 0).to_operands)
    end
  end

  describe TextRenderingMode do
    it "can normalize a style argument" do
      [[:FILL, 0], [:STROKE, 1], [:FILL_STROKE, 2], [:INVISIBLE, 3], [:FILL_CLIP, 4],
       [:STROKE_CLIP, 5], [:FILL_STROKE_CLIP, 6], [:CLIP, 7]].each do |const_name, value|
        const = TextRenderingMode.const_get(const_name)
        assert_equal(const, TextRenderingMode.normalize(const_name.to_s.downcase.intern))
        assert_equal(const, TextRenderingMode.normalize(value))
        assert_equal(const, TextRenderingMode.normalize(const))
      end
    end

    it "fails when trying to normalize an invalid argument" do
      assert_raises(ArgumentError) { TextRenderingMode.normalize(:invalid) }
    end
  end

  describe GraphicsState do
    before do
      @gs = GraphicsState.new
    end

    it "allows saving and restoring the graphics state" do
      @gs.save
      @gs.line_width = 10
      @gs.restore
      assert_equal(1, @gs.line_width)
    end

    it "fails when restoring the graphics state if the stack is empty" do
      assert_raises(HexaPDF::Error) { @gs.restore }
    end

    it "uses the correct glyph to text space scaling" do
      font = Object.new
      font.define_singleton_method(:glyph_scaling_factor) { 0.002 }
      @gs.font = font
      @gs.font_size = 10
      assert_equal(0.02, @gs.scaled_font_size)
    end
  end

end
