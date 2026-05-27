# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/content/transformation_matrix'

describe HexaPDF::Content::TransformationMatrix do
  before do
    @matrix = HexaPDF::Content::TransformationMatrix.new
  end

  describe "initialize" do
    it "initializes to the identity matrix" do
      assert_equal(1, @matrix.a)
      assert_equal(0, @matrix.b)
      assert_equal(0, @matrix.c)
      assert_equal(1, @matrix.d)
      assert_equal(0, @matrix.e)
      assert_equal(0, @matrix.f)
    end

    it "can use arbitrary values" do
      @matrix = HexaPDF::Content::TransformationMatrix.new(2, 3, 4, 5, 6, 7)
      assert_equal(2, @matrix.a)
      assert_equal(3, @matrix.b)
      assert_equal(4, @matrix.c)
      assert_equal(5, @matrix.d)
      assert_equal(6, @matrix.e)
      assert_equal(7, @matrix.f)
    end
  end

  it "correctly evaluates a point" do
    assert_equal([2, 3], @matrix.evaluate(2, 3))
  end

  it "correctly translates the matrix" do
    @matrix.translate(5, 10)
    assert_equal([7, 13], @matrix.evaluate(2, 3))
  end

  it "correctly rotates the matrix" do
    @matrix.rotate(90)
    assert_equal([-3, 2], @matrix.evaluate(2, 3))
  end

  it "correctly scales the matrix" do
    @matrix.scale(5, 10)
    assert_equal([10, 30], @matrix.evaluate(2, 3))
  end

  it "correctly skews the matrix" do
    assert_equal([2, 5], @matrix.dup.skew(45, 0).evaluate(2, 3))
    assert_equal([5, 3], @matrix.dup.skew(0, 45).evaluate(2, 3))
  end

  it "can be compared to another matrix" do
    assert_equal(HexaPDF::Content::TransformationMatrix.new, @matrix)
    refute_equal(HexaPDF::Content::TransformationMatrix.new(5), @matrix)
  end

  it "allows the conversion of the matrix into an array" do
    assert_equal([1, 0, 0, 1, 0, 0], @matrix.to_a)
  end
end
