# -*- frozen_string_literal: true -*-

require 'test_helper'
require 'geom2d/algorithms'
require 'geom2d/point'

describe Geom2D::Algorithms do
  describe "ccw" do
    before do
      @p1 = Geom2D::Point(1, 2)
      @p2 = Geom2D::Point(3, 4)
    end

    it "returns 1 for counterclockwise turn" do
      assert_equal(1, Geom2D::Algorithms.ccw(@p1, @p2, Geom2D::Point(0, 3)))
    end

    it "returns -1 for clockwise turn" do
      assert_equal(-1, Geom2D::Algorithms.ccw(@p1, @p2, Geom2D::Point(2, 0)))
    end

    it "returns 0 for collinear points" do
      assert_equal(0, Geom2D::Algorithms.ccw(@p1, @p2, @p2 + (@p2 - @p1)))
    end
  end
end
