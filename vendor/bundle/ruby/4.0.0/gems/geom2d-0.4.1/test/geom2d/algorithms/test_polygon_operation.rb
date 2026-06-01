# -*- frozen_string_literal: true -*-

require 'test_helper'
require 'geom2d/algorithms/polygon_operation'

describe Geom2D::Algorithms::PolygonOperation::SweepEvent do
  before do
    @klass = Geom2D::Algorithms::PolygonOperation::SweepEvent
    @left = @klass.new(true, Geom2D::Point(5, 3), :subject)
    @right = @klass.new(false, Geom2D::Point(8, 5), :subject, @left)
    @left.other_event = @right
  end

  describe "below?/above?" do
    before do
      @point_above = Geom2D::Point(6, 5)
      @point_below = Geom2D::Point(6, 3)
    end

    it "works for the left endpoint event" do
      assert(@left.below?(@point_above))
      assert(@left.above?(@point_below))
    end

    it "works for the right endpoint event" do
      assert(@right.below?(@point_above))
      assert(@right.above?(@point_below))
    end
  end

  it "detects vertical segments" do
    assert(@klass.new(false, Geom2D::Point(5, 8), :subject, @left).vertical?)
  end
end

describe Geom2D::Algorithms::PolygonOperation do
  def assert_op(result, op, subject = @ps, clipping = @qs)
    alg_result = Geom2D::Algorithms::PolygonOperation.run(subject, clipping, op)
    result_segments = result.each_segment.to_a
    alg_result_segments = alg_result.each_segment.to_a
    assert_equal(result_segments.size, alg_result_segments.size)
    0.upto(result_segments.size - 1) do |i|
      assert_equal(result_segments[i], alg_result_segments[i])
    end
  end

  it "doesn't work if edges of the same polygon overlap" do
    ps = Geom2D::PolygonSet.new([Geom2D::Polygon([0, 0], [5, 0], [5, 5], [0, 5], [0, 0], [2, 0])])
    assert_raises(RuntimeError) { assert_op(ps, :union, ps, ps) }
  end

  describe "trivial operation" do
    before do
      @p = Geom2D::Polygon([0, 0], [10, 0], [10, 10], [0, 10])
      @set = Geom2D::PolygonSet.new([@p])
      @empty = Geom2D::PolygonSet.new
    end

    it "subject is empty" do
      assert_op(@set, :union, @empty, @set)
      assert_op(@empty, :intersection, @empty, @set)
      assert_op(@set, :xor, @empty, @set)
      assert_op(@empty, :difference, @empty, @set)
    end

    it "clipping is empty" do
      assert_op(@set, :union, @set, @empty)
      assert_op(@empty, :intersection, @set, @empty)
      assert_op(@set, :xor, @set, @empty)
      assert_op(@set, :difference, @set, @empty)
    end

    it "bounding boxes are not intersecting" do
      set2 = Geom2D::PolygonSet(Geom2D::Polygon([15, 15], [20, 15], [20, 20], [15, 20]))
      assert_op(@set + set2, :union, @set, set2)
      assert_op(@empty, :intersection, @set, set2)
      assert_op(@set + set2, :xor, @set, set2)
      assert_op(@set, :difference, @set, set2)
    end
  end

  #       +-----+
  #       |Qout |
  #       |     |
  #  +----+-----+-----+
  #  |    |Qin,P|     |
  #  |    |     |     |
  #  |    +-----+     |
  #  |                |
  #  |       P        |
  #  +----------------+
  describe "complete overlapping edges" do
    before do
      @p = Geom2D::Polygon([0, 0], [10, 0], [10, 10], [0, 10], [0, 0])
      @ps = Geom2D::PolygonSet.new([@p])
      @q_in = Geom2D::Polygon([3, 10], [3, 5], [8, 5], [8, 10])
      @qs_in = Geom2D::PolygonSet.new([@q_in])
      @q_out = Geom2D::Polygon([3, 10], [3, 15], [8, 15], [8, 10])
      @qs_out = Geom2D::PolygonSet.new([@q_out])
    end

    it "union" do
      @qs = @qs_in
      result = Geom2D::Polygon([0, 0], [10, 0], [10, 10], [0, 10])
      assert_op(result, :union)

      @qs = @qs_out
      result = Geom2D::Polygon([0, 0], [10, 0], [10, 10], [8, 10], [8, 15], [3, 15], [3, 10], [0, 10])
      assert_op(result, :union)
    end

    it "intersection" do
      @qs = @qs_in
      result = Geom2D::Polygon([3, 5], [8, 5], [8, 10], [3, 10])
      assert_op(result, :intersection)

      @qs = @qs_out
      result = Geom2D::Polygon()
      assert_op(result, :intersection)
    end

    it "xor" do
      @qs = @qs_in
      result = Geom2D::Polygon([0, 0], [10, 0], [10, 10], [8, 10], [8, 5], [3, 5], [3, 10], [0, 10])
      assert_op(result, :xor)

      @qs = @qs_out
      result = Geom2D::Polygon([0, 0], [10, 0], [10, 10], [8, 10], [8, 15], [3, 15], [3, 10], [0, 10])
      assert_op(result, :xor)
    end

    it "difference" do
      @qs = @qs_in
      result = Geom2D::Polygon([0, 0], [10, 0], [10, 10], [8, 10], [8, 5], [3, 5], [3, 10], [0, 10])
      assert_op(result, :difference)

      @qs = @qs_out
      result = Geom2D::Polygon([0, 0], [10, 0], [10, 10], [0, 10])
      assert_op(result, :difference)
    end
  end

  #    +-----+--------------+-----+
  #     \ Q /                \ P /
  #      \ /                  \ /
  #       X       P,Q          X
  #      / \                  / \
  #     / P \                / Q \
  #    +-----+--------------+-----+
  describe "partial overlapping edges" do
    before do
      @p = Geom2D::Polygon([0, 0], [10, 0], [15, 10], [5, 10])
      @ps = Geom2D::PolygonSet.new([@p])
      @q = Geom2D::Polygon([0, 10], [5, 0], [15, 0], [10, 10])
      @qs = Geom2D::PolygonSet.new([@q])
    end

    it "union" do
      result = Geom2D::Polygon([0, 0], [15, 0], [12.5, 5], [15, 10], [0, 10], [2.5, 5])
      assert_op(result, :union)
    end

    it "intersection" do
      result = Geom2D::Polygon([2.5, 5], [5, 0], [10, 0], [12.5, 5], [10, 10], [5, 10])
      assert_op(result, :intersection)
    end

    it "xor" do
      left = Geom2D::Polygon([0, 0], [5, 0], [2.5, 5], [5, 10], [0, 10], [2.5, 5])
      right = Geom2D::Polygon([10, 0], [15, 0], [12.5, 5], [15, 10], [10, 10], [12.5, 5])
      assert_op(Geom2D::PolygonSet(left, right), :xor)
    end

    it "difference" do
      left = Geom2D::Polygon([0, 0], [5, 0], [2.5, 5])
      right = Geom2D::Polygon([10, 10], [12.5, 5], [15, 10])
      assert_op(Geom2D::PolygonSet(left, right), :difference)
    end
  end

  #   +------+------+
  #   |  Q   |      |
  #   |      |      |
  #   +------+      |
  #   |             |
  #   |     P       |
  #   +-------------+
  describe "overlapping corner" do
    before do
      @p = Geom2D::Polygon([0, 0], [10, 0], [10, 10], [0, 10])
      @ps = Geom2D::PolygonSet.new([@p])
      @q = Geom2D::Polygon([0, 10], [5, 10], [5, 5], [0, 5])
      @qs = Geom2D::PolygonSet.new([@q])
    end

    it "union" do
      result = Geom2D::Polygon([0, 0], [10, 0], [10, 10], [0, 10])
      assert_op(result, :union)
    end

    it "intersection" do
      result = Geom2D::Polygon([0, 5], [5, 5], [5, 10], [0, 10])
      assert_op(result, :intersection)
    end

    it "difference" do
      result = Geom2D::Polygon([0, 0], [10, 0], [10, 10], [5, 10], [5, 5], [0, 5])
      assert_op(result, :difference)
    end
  end

  describe "self-intersecting polygon" do
    it "intersection" do
      p1 = Geom2D::Polygon([0, 20], [0, 2], [15, -1], [15, 18])
      @ps = Geom2D::PolygonSet.new([p1])
      q1 = Geom2D::Polygon([1, 11], [13, 17], [13, 11], [1, 17])
      q2 = Geom2D::Polygon([2, 3], [11, 3], [11, 9])
      q3 = Geom2D::Polygon([3, 8], [3, 5], [8, 5])
      @qs = Geom2D::PolygonSet.new([q1, q2, q3])
      result = Geom2D::PolygonSet(
        Geom2D::Polygon([1, 11], [7, 14], [1, 17]),
        Geom2D::Polygon([2, 3], [11, 3], [11, 9], [6.421052631578, 5.947368421052], [8, 5], [5, 5],
                        [6.421052631578, 5.947368421052], [3, 8], [3, 5], [5, 5]),
        Geom2D::Polygon([7, 14], [13, 11], [13, 17])
      )
      assert_op(result, :intersection)
    end
  end
end
