# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/reference'
require 'hexapdf/object'

describe HexaPDF::Reference do
  it "correctly assigns oid and gen on initialization" do
    r = HexaPDF::Reference.new(5, 7)
    assert_equal(5, r.oid)
    assert_equal(7, r.gen)
  end

  it "raises an error when invalid objects are supplied on initialization" do
    assert_raises(ArgumentError) { HexaPDF::Reference.new('a', 7) }
    assert_raises(ArgumentError) { HexaPDF::Reference.new(5, 'b') }
  end

  it "is sortable w.r.t to other objects implementing #oid and #gen" do
    obj = Object.new
    obj.define_singleton_method(:oid) { 1 }
    obj.define_singleton_method(:gen) { 0 }
    obj.define_singleton_method(:<=>) {|o| HexaPDF::Reference.new(oid, gen) <=> o }
    assert_equal([obj, HexaPDF::Reference.new(1, 1), HexaPDF::Reference.new(5, 7)],
                 [HexaPDF::Reference.new(5, 7), HexaPDF::Reference.new(1, 1), obj].sort)
    assert_nil(HexaPDF::Reference.new(1, 0) <=> 5)
  end

  it "is comparable to objects that have an oid and gen" do
    assert_equal(HexaPDF::Reference.new(5, 7), HexaPDF::Reference.new(5, 7))
    refute_equal(HexaPDF::Reference.new(5, 7), HexaPDF::Reference.new(5, 8))
    refute_equal(HexaPDF::Reference.new(5, 7), HexaPDF::Reference.new(4, 7))
    assert_equal(HexaPDF::Reference.new(5, 7), HexaPDF::Object.new(:data, oid: 5, gen: 7))
  end

  it "behaves correctly as hash key" do
    h = {}
    h[HexaPDF::Reference.new(5, 7)] = true
    assert(h.key?(HexaPDF::Reference.new(5, 7)))
    refute(h.key?(HexaPDF::Reference.new(5, 8)))
  end

  it "shows the PDF serialization as string representation " do
    assert_equal("5 7 R", HexaPDF::Reference.new(5, 7).to_s)
  end

  it "shows oid and gen on inspection" do
    assert_match(/\[5, 7\]/, HexaPDF::Reference.new(5, 7).inspect)
  end
end
