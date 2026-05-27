# -*- frozen_string_literal: true -*-

require 'test_helper'
require 'geom2d/bounding_box'

describe Geom2D::BoundingBox do
  before do
    @bbox = Geom2D::BoundingBox.new
  end

  describe "join" do
    it "combines bounding boxes" do
      result = @bbox + Geom2D::BoundingBox.new(5, 5, 10, 10) +
        Geom2D::BoundingBox.new(-2, 8, 15, 9)
      assert_equal([-2, 0, 15, 10], result.to_a)
    end

    it "adjust the bounding box to include the point" do
      result = @bbox + Geom2D::Point(5, 10)
      assert_equal([0, 0, 5, 10], result.to_a)
    end

    it "fails if an invalid argument is given" do
      assert_raises(ArgumentError) { @bbox + :string }
    end
  end

  it "returns the width and height" do
    @bbox += Geom2D::Point(10, 5)
    assert_equal(10, @bbox.width)
    assert_equal(5, @bbox.height)
  end

  it "returns a useful inspection string" do
    assert_equal("BBox[0, 0, 0, 0]", @bbox.inspect)
  end
end
