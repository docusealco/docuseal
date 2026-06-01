# -*- frozen_string_literal: true -*-

require 'test_helper'
require 'geom2d/segment'

describe Geom2D::Segment do
  before do
    @point = Geom2D::Point(1, 2)
    @line = Geom2D::Segment(@point, [3, 4])
  end

  describe "Segment method" do
    it "creates a line using two point-like objects" do
      line = Geom2D::Segment(@point, [3, 4])
      assert_equal(@point, line.start_point)
      assert_equal([3, 4], line.end_point)
    end

    it "creates a line using a point and a vector" do
      line = Geom2D::Segment(@point, vector: [5, 5])
      assert_equal(@point, line.start_point)
      assert_equal(@point + [5, 5], line.end_point)
    end

    it "fails if only one argument is given" do
      assert_raises(ArgumentError) { Geom2D::Segment(@point) }
    end
  end

  it "returns the start point" do
    assert_equal(@point, @line.start_point)
  end

  it "returns the end point" do
    assert_equal([3, 4], @line.end_point)
  end

  it "checks whether the segment is degenerate, i.e. only a point" do
    refute(@line.degenerate?)
    assert(Geom2D::Segment([5, 5], [5, 5]))
  end

  it "checks whether the segment is vertical" do
    refute(@line.vertical?)
    assert(Geom2D::Segment([5, 5], [5, 10]).vertical?)
  end

  it "checks whether the segment is horizontal" do
    refute(@line.horizontal?)
    assert(Geom2D::Segment([5, 5], [10, 5]).horizontal?)
  end

  it "returns the minimum (left bottom) point" do
    assert_equal(@line.start_point, @line.min)
    @line.reverse!
    assert_equal(@line.end_point, @line.min)
  end

  it "returns the maximum (right top) point" do
    assert_equal(@line.end_point, @line.max)
    @line.reverse!
    assert_equal(@line.start_point, @line.max)
  end

  it "returns the length" do
    assert_equal(Math.sqrt(8), @line.length)
  end

  it "returns the direction" do
    assert_equal([2, 2], @line.direction)
  end

  it "returns the slope" do
    assert_equal(1, @line.slope)
  end

  it "returns the y-axes intercept" do
    assert_equal(1, @line.y_intercept)
  end

  describe "for vertical segments" do
    before do
      @line = Geom2D::Segment([0, 0], [0, 2])
    end

    it "returns infinity for the slope" do
      assert_equal(Float::INFINITY, @line.slope)
    end

    it "returns nil for the y-axes intercept" do
      assert_nil(@line.y_intercept)
    end
  end

  it "reverses the direction of the segment" do
    @line.reverse!
    assert_equal(@point, @line.end_point)
    assert_equal([3, 4], @line.start_point)
  end

  describe "intersect" do
    def assert_intersection(expected, result)
      case expected
      when nil then assert_nil(expected)
      when Array, Geom2D::Point then assert_equal(expected, result)
      else
        assert_equal(expected.min, result.start_point)
        assert_equal(expected.max, result.end_point)
      end
    end

    def check_intersection(result, line1, line2)
      assert_intersection(result, line1.intersect(line2))
      assert_intersection(result, line2.intersect(line1))
      line2.reverse!
      assert_intersection(result, line1.intersect(line2))
      assert_intersection(result, line2.intersect(line1))
      line1.reverse!
      assert_intersection(result, line1.intersect(line2))
      assert_intersection(result, line2.intersect(line1))
      line2.reverse!
      assert_intersection(result, line1.intersect(line2))
      assert_intersection(result, line2.intersect(line1))
    end

    describe "general lines" do
      it "returns nil for non-intersecting lines" do
        line1 = Geom2D::Segment([0, 0], [10, 0])
        line2 = Geom2D::Segment([3, 2], [10, 10])
        check_intersection(nil, line1, line2)
      end

      it "returns one point for lines with a common endpoint" do
        line1 = Geom2D::Segment([0, 0], [10, 0])
        line2 = Geom2D::Segment([0, 0], [10, 10])
        check_intersection([0, 0], line1, line2)
      end

      it "returns one point for lines where an endpoint lies inside the other line" do
        line1 = Geom2D::Segment([0, 0], [10, 0])
        line2 = Geom2D::Segment([5, 0], [10, 10])
        check_intersection([5, 0], line1, line2)
      end

      it "returns one point for general intersection" do
        line1 = Geom2D::Segment([0, 0], [10, 0])
        line2 = Geom2D::Segment([5, 5], [5, -5])
        check_intersection([5, 0], line1, line2)
      end
    end

    describe "parallel lines" do
      it "returns nil for non collinear lines" do
        line1 = Geom2D::Segment([0, 0], [10, 0])
        line2 = Geom2D::Segment([0, 2], [10, 2])
        check_intersection(nil, line1, line2)
      end

      it "returns nil for collinear lines with no overlap" do
        line1 = Geom2D::Segment([0, 0], [10, 0])
        line2 = Geom2D::Segment([12, 0], [20, 0])
        check_intersection(nil, line1, line2)
      end

      it "returns one point for collinear lines which have one common end point" do
        line1 = Geom2D::Segment([0, 0], [10, 0])
        line2 = Geom2D::Segment([10, 0], [20, 0])
        check_intersection([10, 0], line1, line2)
      end

      it "returns inside segment for lines with no common end/start points" do
        line1 = Geom2D::Segment([0, 0], [10, 0])
        line2 = Geom2D::Segment([5, 0], [8, 0])
        check_intersection(line2, line1, line2)
      end

      it "returns inside segment for lines with common start points" do
        line1 = Geom2D::Segment([0, 0], [10, 0])
        line2 = Geom2D::Segment([0, 0], [8, 0])
        check_intersection(line2, line1, line2)
      end

      it "returns inside segment for lines with common end points" do
        line1 = Geom2D::Segment([0, 0], [10, 0])
        line2 = Geom2D::Segment([2, 0], [10, 0])
        check_intersection(line2, line1, line2)
      end

      it "returns inside segment for identical lines" do
        line1 = Geom2D::Segment([0, 0], [10, 0])
        check_intersection(line1, line1, line1)
      end

      it "returns overlapping segment for lines with no common end/start points" do
        line1 = Geom2D::Segment([0, 0], [10, 0])
        line2 = Geom2D::Segment([5, 0], [15, 0])
        result = Geom2D::Segment([5, 0], [10, 0])
        check_intersection(result, line1, line2)
      end
    end
  end

  describe "unary +/-" do
    it "unary plus returns self" do
      assert_same(@line, +@line)
    end

    it "unary minus returns the line reflected in the origin" do
      reflection = -@line
      assert_equal(-@line.start_point, reflection.start_point)
      assert_equal(-@line.end_point, reflection.end_point)
    end
  end

  describe "+" do
    it "adds a vector to translate the line" do
      translated = @line + @point
      assert_equal([2, 4], translated.start_point)
      assert_equal([4, 6], translated.end_point)
    end

    it "fails if the argument class is invalid" do
      assert_raises(ArgumentError) { @line + 5 }
    end
  end

  describe "-" do
    it "subtracts a vector to translate the line" do
      translated = @line - @point
      assert_equal([0, 0], translated.start_point)
      assert_equal([2, 2], translated.end_point)
    end

    it "fails if the argument class is invalid" do
      assert_raises(ArgumentError) { @line - 5 }
    end
  end

  describe "==" do
    it "compares to segments by comparing their endpoints" do
      assert_equal(Geom2D::Segment([0, 0], [0, 1]), Geom2D::Segment([0, 0], [0, 1]))
      refute_equal(Geom2D::Segment([0, 0], [0, 1]), Geom2D::Segment([0, 1], [0, 0]))
    end

    it "returns false for objects with incompatible classes" do
      refute_equal(@line, @point)
    end
  end

  it "returns a useful inspection string" do
    assert_equal("Segment[(1, 2)-(3, 4)]", @line.inspect)
  end
end
