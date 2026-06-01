# -*- frozen_string_literal: true -*-

require 'test_helper'
require 'geom2d/point'

describe Geom2D::Point do
  before do
    @point = Geom2D::Point(1, 2)
  end

  describe "Point method" do
    it "creates a point using two numbers" do
      point = Geom2D::Point(1, 2)
      assert_equal([1, 2], point)
    end

    it "creates a point using an array of two numbers" do
      point = Geom2D::Point([1, 2])
      assert_equal([1, 2], point)
    end

    it "returns a given point object" do
      p1 = Geom2D::Point(1, 2)
      p2 = Geom2D::Point(p1)
      assert_same(p1, p2)
    end
  end

  it "returns the x coordinate" do
    assert_equal(1, @point.x)
  end

  it "returns the y coordinate" do
    assert_equal(2, @point.y)
  end

  it "returns a bounding box that only encompasses itself" do
    assert_equal([@point.x, @point.y] * 2, @point.bbox.to_a)
  end

  it "returns the distance from point to point" do
    assert_equal(5, @point.distance(Geom2D::Point(5, 5)))
  end

  describe "unary +/-" do
    it "unary plus returns self" do
      assert_same(@point, +@point)
    end

    it "unary minus returns the point reflected in the origin" do
      assert_equal([-1, -2], -@point)
    end
  end

  describe "+" do
    it "adds a scalar number" do
      assert_equal([3, 4], @point + 2)
    end

    it "adds a point" do
      assert_equal([2, 4], @point + @point)
    end

    it "interpretes an array as point" do
      assert_equal([3, 5], @point + [2, 3])
    end

    it "fails if the argument class is invalid" do
      assert_raises(ArgumentError) { @point + :test }
    end
  end

  describe "-" do
    it "subtracts a scalar number" do
      assert_equal([-1, 0], @point - 2)
    end

    it "subtracts a point" do
      assert_equal([-1, -2], @point - @point * 2)
    end

    it "interprets an array as point" do
      assert_equal([-1, -1], @point - [2, 3])
    end

    it "fails if the argument class is invalid" do
      assert_raises(ArgumentError) { @point - "str" }
    end
  end

  describe "*" do
    it "multiplies a scalar number" do
      assert_equal([5, 10], @point * 5)
    end

    it "performs the dot product with another point" do
      assert_equal(5, @point * @point)
    end

    it "interprets an array as point" do
      assert_equal(8, @point * [2, 3])
    end

    it "fails if the argument class is invalid" do
      assert_raises(ArgumentError) { @point * "str" }
    end
  end

  it "has a dot product which is just the multiplication" do
    assert_equal(@point * [2, 3], @point.dot([2, 3]))
  end

  it "has a wedge product" do
    assert_equal(-1, @point.wedge([2, 3]))
  end

  describe "/" do
    it "divides by a scalar number" do
      assert_equal([0.5, 1], @point / 2)
    end

    it "fails if the argument class is invalid" do
      assert_raises(ArgumentError) { @point / "str" }
    end
  end

  describe "==" do
    it "compares with a point" do
      assert(@point == Geom2D::Point(1, 2))
    end

    it "interpretes an array as point" do
      assert(@point == [1, 2])
    end

    it "returns false for objects with incompatible classes" do
      refute(@point == 5)
    end
  end

  it "destructures like an array" do
    assert_equal(@point, Geom2D::Point(*@point))
  end

  it "returns a useful inspection string" do
    assert_equal("(1, 2)", @point.inspect)
  end
end
