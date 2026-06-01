# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/utils'

describe HexaPDF::Utils do
  include HexaPDF::Utils

  describe "Numeric refinement" do
    using HexaPDF::Utils

    it "converts mm to points" do
      assert_equal(72, 25.4.mm)
    end

    it "converts cm to points" do
      assert_equal(72, 2.54.cm)
    end

    it "converts inch to points" do
      assert_equal(144, 2.inch)
    end
  end

  it "checks floats for equality with a certain precision" do
    assert(float_equal(1.0, 1))
    assert(float_equal(1.0, 1.0000003))
  end

  it "compares floats like the <=> operator" do
    assert_equal(0, float_compare(1.0, 1))
    assert_equal(0, float_compare(1.0, 1.0000003))
    assert_equal(-1, float_compare(1.0, 1.03))
    assert_equal(1, float_compare(1.0, 0.9997))
  end
end
