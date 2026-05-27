# -*- frozen_string_literal: true -*-

require 'test_helper'
require 'geom2d/rectangle'

describe Geom2D::Rectangle do
  before do
    @rectangle = Geom2D::Rectangle(10, 20, 100, 50)
  end

  it "creates a rectangle using the bottom-left corner and its width and height" do
    assert_equal(10, @rectangle.x)
    assert_equal(20, @rectangle.y)
    assert_equal(100, @rectangle.width)
    assert_equal(50, @rectangle.height)
  end

  it "returns one for the number of contours" do
    assert_equal(1, @rectangle.nr_of_contours)
  end

  it "returns four for the number of vertices" do
    assert_equal(4, @rectangle.nr_of_vertices)
  end

  it "iterates over all corners of the rectangle" do
    assert_equal([[10, 20], [110, 20], [110, 70], [10, 70]], @rectangle.each_vertex.to_a)
  end

  it "iterates over all four edges of the rectangle" do
    segments = [Geom2D::Segment([10, 20], [110, 20]), Geom2D::Segment([110, 20], [110, 70]),
                Geom2D::Segment([110, 70], [10, 70]), Geom2D::Segment([10, 70], [10, 20])]
    assert_equal(segments, @rectangle.each_segment.to_a)
  end

  it "returns the bounding box" do
    assert_equal([10, 20, 110, 70], @rectangle.bbox.to_a)
  end

  it "returns true when asked whether the corners are counterclockwise ordered" do
    assert(@rectangle.ccw?)
  end

  it "returns the vertices when asked to be converted to an array" do
    assert_equal([[10, 20], [110, 20], [110, 70], [10, 70]], @rectangle.to_ary)
  end

  it "returns a useful inspection string" do
    assert_equal("Rectangle[(10,20),width=100,height=50]", @rectangle.inspect)
  end
end
