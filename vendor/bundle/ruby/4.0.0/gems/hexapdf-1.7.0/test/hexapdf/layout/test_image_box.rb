# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/document'
require 'hexapdf/layout/image_box'

describe HexaPDF::Layout::ImageBox do
  before do
    @image = HexaPDF::Stream.new({Subtype: :Image}, stream: '')
    @image.define_singleton_method(:width) { 40 }
    @image.define_singleton_method(:height) { 20 }
    @frame = Object.new
    def @frame.x; 0; end
    def @frame.y; 100; end
  end

  def create_box(**kwargs)
    HexaPDF::Layout::ImageBox.new(image: @image, **kwargs)
  end

  describe "initialize" do
    it "takes the image to be displayed" do
      box = create_box
      assert_equal(@image, box.image)
    end
  end

  describe "fit" do
    it "fits with fixed dimensions" do
      box = create_box(width: 50, height: 30, style: {padding: [10, 4, 6, 2]})
      assert(box.fit(100, 100, @frame).success?)
      assert_equal(50, box.width)
      assert_equal(30, box.height)
    end

    it "fits with a fixed width" do
      box = create_box(width: 60, style: {padding: [10, 4, 6, 2]})
      assert(box.fit(100, 100, @frame).success?)
      assert_equal(60, box.width)
      assert_equal(43, box.height)
    end

    it "fits with a fixed height" do
      box = create_box(height: 40, style: {padding: [10, 4, 6, 2]})
      assert(box.fit(100, 100, @frame).success?)
      assert_equal(54, box.width)
      assert_equal(40, box.height)
    end

    it "fits with auto-scaling to available space" do
      box = create_box(style: {padding: [10, 4, 6, 2]})
      assert(box.fit(100, 100, @frame).success?)
      assert_equal(100, box.width)
      assert_equal(63, box.height)

      assert(box.fit(100, 30, @frame).success?)
      assert_equal(34, box.width)
      assert_equal(30, box.height)
    end

    it "fails if one of the calculated dimensions is larger than the available space" do
      box = create_box(height: 60)
      assert(box.fit(100, 100, @frame).failure?)
    end
  end

  it "always returns false for empty?" do
    refute(create_box.empty?)
  end

  describe "draw" do
    it "draws the image" do
      box = create_box(height: 40, style: {padding: [10, 4, 6, 2]})
      box.fit(100, 100, @frame)

      @canvas = HexaPDF::Document.new.pages.add.canvas
      box.draw(@canvas, 0, 0)
      assert_operators(@canvas.contents, [[:save_graphics_state],
                                          [:concatenate_matrix, [48, 0, 0, 24, 2, 6]],
                                          [:paint_xobject, [:XO1]],
                                          [:restore_graphics_state]])
    end
  end
end
