# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/content/canvas_composer'
require 'hexapdf/document'

describe HexaPDF::Content::CanvasComposer do
  before do
    @doc = HexaPDF::Document.new
    @page = @doc.pages.add
    @canvas = @page.canvas
    @composer = @canvas.composer
  end

  describe "initialize" do
    it "creates the necessary objects like frame for doing the work" do
      assert_equal(@page.box.width, @composer.frame.width)
      assert_equal(@page.box.height, @composer.frame.height)
    end

    it 'allows specifying a value for the margin' do
      composer = @canvas.composer(margin: [10, 30])
      assert_equal(@page.box.width - 60, composer.frame.width)
      assert_equal(@page.box.height - 20, composer.frame.height)
    end
  end

  it "provides easy access to the global styles" do
    assert_same(@doc.layout.style(:base), @composer.style(:base))
  end

  describe "draw_box" do
    def create_box(**kwargs)
      HexaPDF::Layout::Box.new(**kwargs) {}
    end

    it "draws the box if it completely fits" do
      @composer.draw_box(create_box(height: 100))
      @composer.draw_box(create_box)
      assert_operators(@composer.canvas.contents,
                       [[:save_graphics_state],
                        [:concatenate_matrix, [1, 0, 0, 1, 0, 741.889764]],
                        [:restore_graphics_state],
                        [:save_graphics_state],
                        [:concatenate_matrix, [1, 0, 0, 1, 0, 0]],
                        [:restore_graphics_state]])
    end

    it "splits the box if possible" do
      @composer.draw_box(create_box(width: 300, height: 300, style: {position: :float}))
      box = create_box(style: {mask_mode: :box})
      box.define_singleton_method(:fit_content) {|*| fit_result.overflow! }
      box.define_singleton_method(:split_content) { [box, HexaPDF::Layout::Box.new(height: 100) {}] }
      @composer.draw_box(box)
      assert_operators(@composer.canvas.contents,
                       [[:save_graphics_state],
                        [:concatenate_matrix, [1, 0, 0, 1, 0, 541.889764]],
                        [:restore_graphics_state],
                        [:save_graphics_state],
                        [:concatenate_matrix, [1, 0, 0, 1, 300, 0]],
                        [:restore_graphics_state],
                        [:save_graphics_state],
                        [:concatenate_matrix, [1, 0, 0, 1, 0, 441.889764]],
                        [:restore_graphics_state]])
    end

    it "finds a new region if splitting doesn't work" do
      @composer.draw_box(create_box(width: 400, height: 100, style: {position: :float}))
      @composer.draw_box(create_box(width: 400, height: 100))
      assert_operators(@composer.canvas.contents,
                       [[:save_graphics_state],
                        [:concatenate_matrix, [1, 0, 0, 1, 0, 741.889764]],
                        [:restore_graphics_state],
                        [:save_graphics_state],
                        [:concatenate_matrix, [1, 0, 0, 1, 0, 641.889764]],
                        [:restore_graphics_state]])
    end

    it "handles truncated boxes correctly" do
      box = create_box(height: 400, style: {overflow: :truncate})
      box.define_singleton_method(:fit_content) {|*| fit_result.overflow! }
      assert_same(box, @composer.draw_box(box))
    end

    it "returns the last drawn box" do
      box = create_box(height: 400)
      assert_same(box, @composer.draw_box(box))
    end

    it "raises an error if the frame is full" do
      @composer.draw_box(create_box)
      exception = assert_raises(HexaPDF::Error) { @composer.draw_box(create_box(height: 10)) }
      assert_match(/Frame.*full/, exception.message)
    end

    it "raises an error if a new region cannot be found after splitting" do
      @composer.draw_box(create_box(height: 400))
      exception = assert_raises(HexaPDF::Error) { @composer.draw_box(create_box(height: 500)) }
      assert_match(/Frame.*full/, exception.message)
    end
  end

  describe "method_missing" do
    it "delegates box methods to @document.layout" do
      box = @composer.column(width: 100)
      assert_equal(100, box.width)
    end

    it "fails for missing methods that can't be delegated to @document.layout" do
      assert_raises(NameError) { @composer.unknown_box }
    end
  end

  it "can be asked whether a missing method is supported" do
    assert(@composer.respond_to?(:column))
  end
end
