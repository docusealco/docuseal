# -*- encoding: utf-8 -*-

require 'test_helper'
require 'geom2d'
require 'hexapdf/layout/width_from_polygon'

describe HexaPDF::Layout::WidthFromPolygon do
  def create_width_spec(polygon, offset = 0)
    HexaPDF::Layout::WidthFromPolygon.new(polygon, offset)
  end

  it "respects the offset" do
    ws = create_width_spec(Geom2D::Polygon([0, 0], [0, 10], [10, 5]), 5)
    assert_equal([0, 8], ws.call(0, 1))
  end

  it "works in the case bottom and top line are the same" do
    ws = create_width_spec(Geom2D::Polygon([0, 0], [0, 10], [10, 5]))
    assert_equal([0, 0], ws.call(0, 0))
    assert_equal([0, 0], ws.call(5, 0))
  end

  it "works when the first segment has not the minimal x-value" do
    ws = create_width_spec(Geom2D::Polygon([10, 10], [10, 0], [0, 0], [5, 10]))
    assert_equal([5, 5], ws.call(0, 1))
    assert_equal([2.5, 7.5], ws.call(5, 1))
  end

  it "works when the polygon is specified in counterclockwise order" do
    ws = create_width_spec(Geom2D::Polygon([10, 10], [5, 10], [0, 0], [10, 0]))
    assert_equal([5, 5], ws.call(0, 1))
    assert_equal([2.5, 7.5], ws.call(5, 1))
  end

  it "works for polygons in counterclockwise order with some segments crossing only top or bottom" do
    ws = create_width_spec(Geom2D::PolygonSet(Geom2D::Polygon([55.0, 65.0], [70, 65], [70.0, 50.0],
                                                              [100.0, 50.0], [100.0, 63.0], [120, 63],
                                                              [120, 70], [55, 70])))
    assert_equal([70, 30], ws.call(0, 10))
  end

  it "works if some segments only cross the top line" do
    ws = create_width_spec(Geom2D::Polygon([0, 0], [0, 10], [2, 11], [4, 9], [6, 11], [10, 10],
                                           [10, 0]))
    assert_equal([0, 3, 2, 5], ws.call(1, 2))
  end

  it "works if some segments only cross the bottom line" do
    ws = create_width_spec(Geom2D::Polygon([0, 0], [0, 10], [2, 4], [4, 6], [6, 4], [10, 10],
                                           [10, 0]))
    assert_equal([0, 1, 7, 2], ws.call(3, 2))
  end

  it "works if some non-horizontal segments don't cross the top/bottom line at all" do
    ws = create_width_spec(Geom2D::Polygon([0, 0], [0, 10], [2, 4], [4, 6.5], [6, 6], [10, 10],
                                           [10, 0]))
    assert_equal([0, 1, 6, 3], ws.call(3, 2))
  end

  it "works if there is no available space" do
    ws = create_width_spec(Geom2D::Polygon([0, 0], [0, 10], [5, 9], [10, 10], [10, 0]))
    assert_equal([0, 0], ws.call(0, 2))
  end

  it "works if the first processed segment doesn't cross both lines" do
    ws = create_width_spec(Geom2D::Polygon([0, 5], [0, 0], [10, 0], [10, 10], [5, 10], [5, 5]))
    assert_equal([5, 5], ws.call(4, 2))
  end

  it "works in case of small floating point differences" do
    ws = create_width_spec(Geom2D::Polygon([0, 0], [10, 0], [10, 5.99999999999994], [8, 6], [8, 10],
                                           [6, 10], [6, 5], [0, 5]))
    assert_equal([6, 4], ws.call(4.0, 3.0))
  end

  describe "multiple polygons" do
    it "rectangle in rectangle" do
      ws = create_width_spec(Geom2D::PolygonSet(Geom2D::Polygon([0, 0], [0, 10], [10, 10], [10, 0]),
                                                Geom2D::Polygon([2, 2], [2, 8], [8, 8], [8, 2])))
      assert_equal([0, 2, 6, 2], ws.call(1, 8))
      assert_equal([0, 10], ws.call(0, 2))
      assert_equal([0, 2, 6, 2], ws.call(2, 1))
      assert_equal([0, 2, 6, 2], ws.call(7, 2))
    end

    it "rectangle in rectangle with reverse direction" do
      ws = create_width_spec(Geom2D::PolygonSet(Geom2D::Polygon([0, 0], [0, 10], [10, 10], [10, 0]),
                                                Geom2D::Polygon([2, 8], [2, 2], [8, 2], [8, 8])))
      assert_equal([0, 2, 6, 2], ws.call(7, 2))
      assert_equal([0, 2, 6, 2], ws.call(1, 8))
      assert_equal([0, 10], ws.call(0, 2))
      assert_equal([0, 2, 6, 2], ws.call(2, 1))
    end

    it "first segment of inner polygon is between the lines, polygon crosses both lines" do
      ws = create_width_spec(Geom2D::PolygonSet(Geom2D::Polygon([0, 0], [0, 10], [10, 10], [10, 0]),
                                                Geom2D::Polygon([2, 4], [2, 6], [8, 8], [8, 2])))
      assert_equal([0, 10], ws.call(0, 2))
      assert_equal([0, 5, 3, 2], ws.call(2, 1).map {|f| f.round(5) })
      assert_equal([0, 2, 6, 2], ws.call(3, 4))
    end

    it "first segment of inner polygon is between the lines, polygon crosses one line" do
      ws = create_width_spec(Geom2D::PolygonSet(Geom2D::Polygon([0, 0], [0, 10], [10, 10], [10, 0]),
                                                Geom2D::Polygon([2, 4], [4, 6], [8, 2])))
      assert_equal([0, 2, 5, 3], ws.call(3, 4))
    end

    it "polygon is partly between the lines, maximum between the lines" do
      ws = create_width_spec(Geom2D::PolygonSet(Geom2D::Polygon([0, 0], [0, 10], [10, 10], [10, 0]),
                                                Geom2D::Polygon([2, 4], [2, 6], [8, 8], [9, 5],
                                                                [8, 2])))
      assert_equal([0, 2, 7, 1], ws.call(3, 4))
    end

    it "polygon is partly between the lines, maximum is at an line crossing" do
      ws = create_width_spec(Geom2D::PolygonSet(Geom2D::Polygon([0, 0], [0, 10], [10, 10], [10, 0]),
                                                Geom2D::Polygon([2, 4], [8, 8], [5, 5], [8, 2])))
      assert_equal([0, 2, 5, 3], ws.call(3, 4))
    end
  end
end
