# -*- frozen_string_literal: true -*-

require 'test_helper'
require 'geom2d/polygon'

describe Geom2D::Polygon do
  before do
    @vertices = [[0, 0], [1, 0], [1, 1], [0, 1]]
    @polygon = Geom2D::Polygon(*@vertices)
  end

  it "creates a polygon using multiple point-like objects" do
    polygon = Geom2D::Polygon(*@vertices)
    assert_equal(@vertices, polygon.to_a)
  end

  it "returns one for the number of contours" do
    assert_equal(1, @polygon.nr_of_contours)
  end

  it "returns the number of vertices" do
    assert_equal(4, @polygon.nr_of_vertices)
  end

  it "returns the i-th vertex" do
    assert_equal([1, 1], @polygon[2])
  end

  it "enumerates the vertices" do
    assert_equal(@vertices, @polygon.each_vertex.to_a)
  end

  it "allows adding points to the end" do
    polygon = Geom2D::Polygon.new
    polygon << [0, 0] << [1, 0]
    assert_equal([[0, 0], [1, 0]], polygon.to_a)
  end

  it "allows removing the last point" do
    @polygon.pop
    assert_equal([[0, 0], [1, 0], [1, 1]], @polygon.to_a)
  end

  it "iterates over each segment" do
    segments = [Geom2D::Segment([0, 0], [1, 0]), Geom2D::Segment([1, 0], [1, 1]),
                Geom2D::Segment([1, 1], [0, 1]), Geom2D::Segment([0, 1], [0, 0])]
    assert_equal(segments, @polygon.each_segment.to_a)
  end

  it "returns the bounding box" do
    assert_equal([5, 5, 10, 10], Geom2D::Polygon([5, 5], [10, 5], [10, 10]).bbox.to_a)
    assert_equal([0, 0, 0, 0], Geom2D::Polygon().bbox.to_a)
  end

  it "returns whether the polygon's vertices are counterclockwise ordered" do
    assert(@polygon.ccw?)
    @polygon.reverse!
    refute(@polygon.ccw?)
    refute(Geom2D::Polygon([2, 2], [20, 5], [10, 3.0]).ccw?)
    assert(Geom2D::Polygon([2, 2], [20, 5], [10, 3.4]).ccw?)
  end

  it "reverses the vertex list" do
    @polygon.reverse!
    assert_equal([[0, 1], [1, 1], [1, 0], [0, 0]], @polygon.to_a)
  end

  it "returns a useful inspection string" do
    assert_equal("Polygon[(0, 0), (1, 0), (1, 1), (0, 1)]", @polygon.inspect)
  end
end
