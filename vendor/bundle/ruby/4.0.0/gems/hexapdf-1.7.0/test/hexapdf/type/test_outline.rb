# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/document'
require 'hexapdf/type/outline'

describe HexaPDF::Type::Outline do
  before do
    @doc = HexaPDF::Document.new
    @outline = @doc.add({}, type: :Outlines)
  end

  it "delegates add_item to the outline item wrapper" do
    item = @outline.add_item("test", position: :first, text_color: "blue", flags: [:italic])
    assert_equal("test", item.title)
    assert_equal([0, 0, 1], item.text_color.components)
    assert_equal([:italic], item.flags)
  end

  it "recursively iterates over all items by delegating to the outline item wrapper" do
    @outline.add_item("Item1") do |item1|
      item1.add_item("Item2")
      item1.add_item("Item3") do |item3|
        item3.add_item("Item4")
      end
      item1.add_item("Item5")
    end
    assert_equal(%w[Item1 Item2 Item3 Item4 Item5], @outline.each_item.map {|i, _| i.title })
  end

  describe "perform_validation" do
    before do
      @outline_items = 5.times.map { @outline.add_item("Test1") }
    end

    it "fixes a missing /First entry" do
      @outline.delete(:First)
      @outline_items[0][:Prev] = HexaPDF::Reference.new(100)
      called = false
      @outline.validate do |msg, correctable, _|
        called = true
        assert_match(/missing an endpoint reference/, msg)
        assert(correctable)
      end
      assert(called)
    end

    it "fixes a missing /Last entry" do
      @outline.delete(:Last)
      @outline_items[4][:Next] = HexaPDF::Reference.new(100)
      called = false
      @outline.validate do |msg, correctable, _|
        called = true
        assert_match(/missing an endpoint reference/, msg)
        assert(correctable)
      end
      assert(called)
    end

    it "deletes the /Count entry if no /First and /Last entries exist" do
      @outline.delete(:Last)
      @outline.delete(:First)
      assert_equal(5, @outline[:Count])
      @outline.validate do |msg, correctable, _|
        assert_match(/key \/Count set but no items exist/, msg)
        assert(correctable)
      end
      refute(@outline.key?(:Count))

      @outline[:Count] = 0
      assert(@outline.validate(auto_correct: false))
    end
  end
end
