# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/document'
require 'hexapdf/content'
require 'hexapdf/content/graphic_object'

describe HexaPDF::Content::GraphicObject::Arc do
  before do
    @arc = HexaPDF::Content::GraphicObject::Arc.configure(start_angle: -30, end_angle: 30,
                                                          inclination: 90)
  end

  describe "initialize" do
    it "creates a default arc representing the counterclockwise unit circle at the origin" do
      arc = HexaPDF::Content::GraphicObject::Arc.new
      assert_equal(0, arc.cx)
      assert_equal(0, arc.cy)
      assert_equal(1, arc.a)
      assert_equal(1, arc.b)
      assert_equal(0, arc.start_angle)
      assert_equal(360, arc.end_angle)
      assert_equal(0, arc.inclination)
    end
  end

  it "returns the start and end points" do
    x, y = @arc.start_point
    assert_in_delta(0.5, x, 0.00001)
    assert_in_delta(Math.sin(Math::PI / 3), y, 0.00001)

    x, y = @arc.end_point
    assert_in_delta(-0.5, x, 0.00001)
    assert_in_delta(Math.sin(Math::PI / 3), y, 0.00001)
  end

  describe "point_at" do
    it "returns an arbitrary point on the arc" do
      x, y = @arc.point_at(0)
      assert_in_delta(0, x, 0.00001)
      assert_in_delta(1, y, 0.00001)
    end
  end

  describe "configure" do
    it "fails if a == 0 or b == 0" do
      assert_raises(HexaPDF::Error) do
        HexaPDF::Content::GraphicObject::Arc.configure(a: 0)
      end
      assert_raises(HexaPDF::Error) do
        HexaPDF::Content::GraphicObject::Arc.configure(b: 0)
      end
    end
  end

  describe "curves" do
    def assert_curve_values(exp, act)
      assert_in_delta(exp[0], act[0], 0.00001)
      assert_in_delta(exp[1], act[1], 0.00001)
      assert_in_delta(exp[2][:p1][0], act[2][:p1][0], 0.00001)
      assert_in_delta(exp[2][:p1][1], act[2][:p1][1], 0.00001)
      assert_in_delta(exp[2][:p2][0], act[2][:p2][0], 0.00001)
      assert_in_delta(exp[2][:p2][1], act[2][:p2][1], 0.00001)
    end

    it "returns the curves for the arc" do
      arc = HexaPDF::Content::GraphicObject::Arc.configure(end_angle: 180)
      arc.max_curves = 4
      curves = arc.curves
      assert_equal(2, curves.size)
      assert_curve_values([0, 1, {p1: [1, 0.548584], p2: [0.548584, 1]}], curves[0])
      assert_curve_values([-1, 0, {p1: [-0.548584, 1], p2: [-1, 0.548584]}], curves[1])

      arc.configure(clockwise: true)
      curves = arc.curves
      assert_equal(2, curves.size)
      assert_curve_values([0, -1, {p1: [1, -0.548584], p2: [0.548584, -1]}], curves[0])
      assert_curve_values([-1, 0, {p1: [-0.548584, -1], p2: [-1, -0.548584]}], curves[1])
    end
  end

  describe "draw" do
    before do
      @doc = HexaPDF::Document.new
      @page = @doc.pages.add
      @canvas = @page.canvas
    end

    it "draws the arc onto the canvas" do
      @arc.draw(@canvas)
      refute(@page.contents.empty?)
    end

    it "uses the configuration option for max_curves if no value is set" do
      @arc.draw(@canvas)
      assert_equal(@doc.config['graphic_object.arc.max_curves'], @arc.max_curves)
      @arc.max_curves = 2
      @arc.draw(@canvas)
      assert_equal(2, @arc.max_curves)
    end
  end
end
