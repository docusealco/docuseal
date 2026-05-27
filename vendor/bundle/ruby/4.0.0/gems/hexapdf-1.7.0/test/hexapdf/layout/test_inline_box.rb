# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/layout/inline_box'
require 'hexapdf/document'

describe HexaPDF::Layout::InlineBox do
  def inline_box(box, valign: :baseline)
    HexaPDF::Layout::InlineBox.new(box, valign: valign)
  end

  before do
    @box = HexaPDF::Layout::InlineBox.create(width: 10, height: 15, margin: [15, 10])
  end

  describe "initialize" do
    it "needs a box to wrap and an optional alignment on initialization" do
      box = HexaPDF::Layout::Box.create(width: 10, height: 15)
      ibox = inline_box(box)
      assert_equal(box, ibox.box)
      assert_equal(:baseline, ibox.valign)

      ibox = inline_box(box, valign: :top)
      assert_equal(:top, ibox.valign)
    end
  end

  describe "fit_wrapped_box" do
    it "automatically fits the provided box when given a frame" do
      ibox = inline_box(HexaPDF::Document.new.layout.text("test is going good", margin: [5, 10]))
      ibox.fit_wrapped_box(HexaPDF::Layout::Frame.new(0, 0, 50, 50))
      assert_equal(90.84, ibox.width)
      assert_equal(19, ibox.height)
      fit_result = ibox.instance_variable_get(:@fit_result)
      assert_equal(10, fit_result.x)
      assert_equal(5, fit_result.y)
      assert_equal(70.84 + 2 * 10, fit_result.mask.width)
      assert_equal(9 + 2 * 5, fit_result.mask.height)
    end

    it "automatically fits the provided box without a given frame" do
      ibox = inline_box(HexaPDF::Document.new.layout.text("test is going good"))
      ibox.fit_wrapped_box
      assert_equal(70.84, ibox.width)
      assert_equal(9, ibox.height)
    end
  end

  it "draws the wrapped box at the correct position" do
    doc = HexaPDF::Document.new
    canvas = doc.pages.add.canvas
    box = HexaPDF::Layout::InlineBox.create(width: 10, margin: [15, 10]) {}
    box.fit_wrapped_box
    box.draw(canvas, 100, 200)
    assert_equal("q\n1 0 0 1 110 215 cm\nQ\n", canvas.contents)
  end

  it "returns true if the inline box is empty with no drawing operations" do
    assert(@box.empty?)
    refute(HexaPDF::Layout::InlineBox.create(width: 10, height: 15) {}.empty?)
  end

  it "returns the style of the box" do
    assert_same(@box.box.style, @box.style)
  end

  describe "valign" do
    it "has a default value of :baseline" do
      assert_equal(:baseline, @box.valign)
    end

    it "can be changed on creation" do
      box = HexaPDF::Layout::InlineBox.create(width: 10, height: 15, valign: :test)
      assert_equal(:test, box.valign)
    end
  end

  it "returns the width including margins" do
    assert_equal(30, @box.width)
  end

  it "returns the height including margins" do
    assert_equal(45, @box.height)
  end

  it "returns 0 for x_min" do
    assert_equal(0, @box.x_min)
  end

  it "returns width for x_max" do
    assert_equal(@box.width, @box.x_max)
  end

  it "returns 0 for y_min" do
    assert_equal(0, @box.y_min)
  end

  it "returns height for y_max" do
    assert_equal(@box.height, @box.y_max)
  end
end
