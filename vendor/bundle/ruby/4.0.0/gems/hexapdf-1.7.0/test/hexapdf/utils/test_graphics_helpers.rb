# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/utils/graphics_helpers'

describe HexaPDF::Utils::GraphicsHelpers do
  include HexaPDF::Utils::GraphicsHelpers

  describe "calculate_dimensions" do
    it "returns the requested dimensions if both are specified" do
      assert_equal([7, 8], calculate_dimensions(5, 6, rwidth: 7, rheight: 8))
    end

    it "returns the requested width and an adjusted height" do
      assert_equal([10, 12], calculate_dimensions(5, 6, rwidth: 10))
    end

    it "returns the requested width and the given height if width is zero" do
      assert_equal([10, 6], calculate_dimensions(0, 6, rwidth: 10))
    end

    it "returns the requested height and an adjusted width" do
      assert_equal([10, 12], calculate_dimensions(5, 6, rheight: 12))
    end

    it "returns the requested height and the given width if height is zero" do
      assert_equal([5, 12], calculate_dimensions(5, 0, rheight: 12))
    end
  end

  describe "point_on_line" do
    it "returns the correct point" do
      assert_equal([5, 5], point_on_line(0, 0, 10, 10, distance: Math.sqrt(50)))
      assert_equal([5, 5], point_on_line(10, 10, 0, 0, distance: Math.sqrt(50)))
    end
  end
end
