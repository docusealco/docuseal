# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/rectangle'
require 'hexapdf/document'

describe HexaPDF::Rectangle do
  describe "after_data_change" do
    it "fails if the rectangle doesn't contain four numbers, without document" do
      assert_raises(ArgumentError) { HexaPDF::Rectangle.new([1, 2, 3]) }
      assert_raises(ArgumentError) { HexaPDF::Rectangle.new([1, 2, 3, :a]) }
    end

    it "fails if the rectangle doesn't contain four numbers, with document and strict mode" do
      doc = HexaPDF::Document.new(config: {'parser.on_correctable_error' => lambda { true }})
      assert_raises(ArgumentError) { HexaPDF::Rectangle.new([1, 2, 3], document: doc) }
      assert_raises(ArgumentError) { HexaPDF::Rectangle.new([1, 2, 3, :a], document: doc) }
    end

    it "recovers if the rectangle doesn't contain four numbers, with document default mode" do
      doc = HexaPDF::Document.new
      assert_equal([0, 0, 0, 0], HexaPDF::Rectangle.new([1, 2, 3], document: doc).value)
      assert_equal([0, 0, 0, 0], HexaPDF::Rectangle.new([1, 2, 3, :a], document: doc).value)
    end

    it "normalizes the array values" do
      rect = HexaPDF::Rectangle.new([0, 1, 2, 3])
      assert_equal([0, 1, 2, 3], rect.value)

      rect = HexaPDF::Rectangle.new([2, 3, 0, 1])
      assert_equal([0, 1, 2, 3], rect.value)

      rect = HexaPDF::Rectangle.new([0, 3, 2, 1])
      assert_equal([0, 1, 2, 3], rect.value)

      rect = HexaPDF::Rectangle.new([2, 1, 0, 3])
      assert_equal([0, 1, 2, 3], rect.value)
    end
  end

  it "returns individual fields of the rectangle" do
    rect = HexaPDF::Rectangle.new([2, 1, 0, 5])
    assert_equal(0, rect.left)
    assert_equal(2, rect.right)
    assert_equal(1, rect.bottom)
    assert_equal(5, rect.top)
    assert_equal(2, rect.width)
    assert_equal(4, rect.height)
  end

  it "allows setting all fields of the rectangle" do
    rect = HexaPDF::Rectangle.new([2, 1, 0, 5])
    rect.left = 5
    rect.right = 1
    rect.bottom = 2
    rect.top = 3
    assert_equal([5, 2, 1, 3], rect.value)

    rect.width = 10
    assert_equal(15, rect.right)
    rect.height = 10
    assert_equal(12, rect.top)
  end

  describe "validation" do
    it "ensures that it is a correct PDF rectangle" do
      doc = HexaPDF::Document.new
      rect = HexaPDF::Rectangle.new([0, 1, 2, 3], document: doc)
      assert(rect.validate)

      rect.value.shift
      assert(rect.validate)
      assert_equal([0, 0, 0, 0], rect.value)

      rect.value[-1] = :A
      assert(rect.validate)
      assert_equal([0, 0, 0, 0], rect.value)
    end
  end
end
