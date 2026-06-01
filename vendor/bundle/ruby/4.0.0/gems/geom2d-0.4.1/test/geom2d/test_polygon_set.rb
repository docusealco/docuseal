# -*- frozen_string_literal: true -*-

require 'test_helper'
require 'geom2d/polygon_set'

describe Geom2D::PolygonSet do
  before do
    @polygon = Geom2D::Polygon([0, 0], [1, 0], [1, 1], [0, 1])
    @ps = Geom2D::PolygonSet(@polygon)
    @polygon2 = Geom2D::Polygon([10, 10], [10, 15], [15, 10])
  end

  it "allows adding polygons" do
    @ps << @polygon2
    assert_equal(2, @ps.nr_of_contours)
  end

  it "allows joining another polygon set" do
    other = Geom2D::PolygonSet(@polygon2)
    result = @ps + other
    assert_equal(2, result.nr_of_contours)
  end

  it "iterates over each segment" do
    @ps << @polygon2
    segments = [Geom2D::Segment([0, 0], [1, 0]), Geom2D::Segment([1, 0], [1, 1]),
                Geom2D::Segment([1, 1], [0, 1]), Geom2D::Segment([0, 1], [0, 0]),
                Geom2D::Segment([10, 10], [10, 15]), Geom2D::Segment([10, 15], [15, 10]),
                Geom2D::Segment([15, 10], [10, 10])]
    assert_equal(segments, @ps.each_segment.to_a)
  end

  it "returns the bounding box" do
    assert_equal([0, 0, 1, 1], @polygon.bbox.to_a)
    assert_equal([0, 0, 0, 0], Geom2D::PolygonSet.new.bbox.to_a)
  end

  it "returns a useful inspection string" do
    assert_equal("PolygonSet[Polygon[(0, 0), (1, 0), (1, 1), (0, 1)]]", @ps.inspect)
  end
end
