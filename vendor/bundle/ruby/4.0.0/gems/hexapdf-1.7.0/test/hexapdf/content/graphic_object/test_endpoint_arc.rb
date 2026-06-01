# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/content/canvas'
require 'hexapdf/content/graphic_object'
require 'hexapdf/document'

describe HexaPDF::Content::GraphicObject::EndpointArc do
  describe "initialize" do
    it "creates a default arc representing a line from the current point to the origin" do
      arc = HexaPDF::Content::GraphicObject::EndpointArc.new
      assert_equal(0, arc.x)
      assert_equal(0, arc.y)
      assert_equal(0, arc.a)
      assert_equal(0, arc.b)
      assert_equal(0, arc.inclination)
      assert(arc.large_arc)
      refute(arc.clockwise)
      assert_nil(arc.max_curves)
    end
  end

  describe "configure" do
    it "changes the values" do
      arc = HexaPDF::Content::GraphicObject::EndpointArc.new
      arc.configure(x: 1, y: 2, a: 3, b: 4, inclination: 5, large_arc: false, clockwise: true,
                    max_curves: 8)
      assert_equal(1, arc.x)
      assert_equal(2, arc.y)
      assert_equal(3, arc.a)
      assert_equal(4, arc.b)
      assert_equal(5, arc.inclination)
      refute(arc.large_arc)
      assert(arc.clockwise)
      assert_equal(8, arc.max_curves)
    end
  end

  describe "draw" do
    before do
      @doc = HexaPDF::Document.new
      @page = @doc.pages.add
    end

    it "draws nothing if the endpoint is the same as the current point" do
      canvas = @page.canvas
      canvas.move_to(50, 50)
      canvas.draw(:endpoint_arc, x: 50, y: 50, a: 50, b: 25)
      assert_equal("50 50 m\n", canvas.contents)
    end

    it "draws only a straight line if either one of the semi-axis is zero" do
      canvas = @page.canvas
      canvas.move_to(50, 50)
      canvas.draw(:endpoint_arc, x: 100, y: 50, a: 0, b: 25)
      assert_equal("50 50 m\n100 50 l\n", canvas.contents)
    end

    it "draws the arc onto the canvas" do
      {
        [false, false] => {cx: 100, cy: 50, a: 50, b: 25, start_angle: 180, end_angle: 270, clockwise: false},
        [false, true] => {cx: 50, cy: 25, a: 50, b: 25, start_angle: 90, end_angle: 0, clockwise: true},
        [true, false] => {cx: 50, cy: 25, a: 50, b: 25, start_angle: 90, end_angle: 360, clockwise: false},
        [true, true] => {cx: 0, cy: 0, a: 40, b: 30, start_angle: 60, end_angle: 120},
      }.each do |(large_arc, clockwise), data|
        @page.delete(:Contents)
        canvas = @page.canvas
        arc = canvas.graphic_object(:arc, **data)
        canvas.draw(arc)
        arc_data = @page.contents

        canvas.contents.clear
        assert(@page.contents.empty?)
        canvas.move_to(*arc.start_point)
        earc = canvas.graphic_object(:endpoint_arc, x: arc.end_point[0], y: arc.end_point[1],
                                     a: data[:a], b: data[:b], inclination: data[:inclination] || 0,
                                     large_arc: large_arc, clockwise: clockwise)
        canvas.draw(earc)
        narc = canvas.graphic_object(:arc, **earc.send(:compute_arc_values, *arc.start_point))
        assert_in_delta(arc.start_point[0], narc.start_point[0], 0.0001)
        assert_in_delta(arc.start_point[1], narc.start_point[1], 0.0001)
        assert_in_delta(arc.end_point[0], narc.end_point[0], 0.0001)
        assert_in_delta(arc.end_point[1], narc.end_point[1], 0.0001)
        assert_equal(arc_data, @page.contents)
      end
    end

    it "draws the correct arc even if it is inclined" do
      canvas = @page.canvas
      canvas.draw(:arc, cx: 25, cy: 0, a: 50, b: 25, start_angle: 90, end_angle: 270,
                  inclination: 90, clockwise: false)
      arc_data = @page.contents

      canvas.contents.clear
      canvas.move_to(0.0, 1e-15)
      canvas.draw(:endpoint_arc, x: 50, y: 0, a: 20, b: 10, inclination: 90, large_arc: false,
                  clockwise: false)
      assert_equal(arc_data, @page.contents)
    end

    it "assigns the max curves to the generated arc" do
      arc = HexaPDF::Content::GraphicObject::EndpointArc.new
      arc.configure(a: 1, b: 1, x: -1, y: 0, max_curves: 10)
      hash = arc.send(:compute_arc_values, 1, 0)
      assert_equal(10, hash[:max_curves])
    end
  end
end
