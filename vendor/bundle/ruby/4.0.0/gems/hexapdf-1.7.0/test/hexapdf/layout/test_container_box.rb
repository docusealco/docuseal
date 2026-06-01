# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/document'
require 'hexapdf/layout/container_box'

describe HexaPDF::Layout::ContainerBox do
  before do
    @doc = HexaPDF::Document.new
    @frame = HexaPDF::Layout::Frame.new(0, 0, 100, 100)
  end

  def child_box(height: 0, width: 0, **style_properties)
    @doc.layout.box(height: height, width: width, style: style_properties)
  end

  def create_box(children, **kwargs)
    HexaPDF::Layout::ContainerBox.new(children: Array(children), **kwargs)
  end

  def check_box(box, width, height, fit_pos = nil)
    assert(box.fit(@frame.available_width, @frame.available_height, @frame).success?, "box didn't fit")
    assert_equal(width, box.width, "box width")
    assert_equal(height, box.height, "box height")
    if fit_pos
      box_fitter = box.instance_variable_get(:@box_fitter)
      assert_equal(fit_pos.size, box_fitter.fit_results.size)
      fit_pos.each_with_index do |(x, y), index|
        assert_equal(x, box_fitter.fit_results[index].x, "result[#{index}].x")
        assert_equal(y, box_fitter.fit_results[index].y, "result[#{index}].y")
      end
    end
  end

  describe "empty?" do
    it "is empty if nothing is fit yet" do
      assert(create_box([]).empty?)
    end

    it "is empty if no box fits" do
      box = create_box(@doc.layout.box(width: 110))
      box.fit(@frame.available_width, @frame.available_height, @frame)
      assert(box.empty?)
    end

    it "is not empty if at least one box fits" do
      box = create_box(@doc.layout.box(width: 50, height: 20))
      check_box(box, 100, 20)
      refute(box.empty?)
    end
  end

  describe "fit_content" do
    it "fits the children according to their mask_mode, valign, and align style properties" do
      box = create_box([child_box(height: 20),
                        child_box(height: 20, valign: :bottom, mask_mode: :fill_horizontal),
                        child_box(width: 20, align: :right, mask_mode: :fill_vertical)])
      check_box(box, 100, 100, [[0, 80], [0, 0], [80, 20]])
    end

    it "respects the initially set width/height as well as border/padding" do
      box = create_box(child_box(height: 20), height: 50, width: 40,
                       style: {padding: 2, border: {width: 3}})
      check_box(box, 40, 50, [[5, 75]])
    end

    it "fails if splitting is not allowed and the content is too big" do
      box = create_box([child_box(height: 80), child_box(height: 30)])
      box.fit(@frame.available_width, @frame.available_height, @frame)
      assert(box.fit_result.failure?)
    end

    it "splits the box if splitting is allowed and the content is too big" do
      box = create_box([child_box(height: 80), child_box(height: 30)], splitable: true)
      box.fit(@frame.available_width, @frame.available_height, @frame)
      assert(box.fit_result.overflow?)
    end
  end

  describe "split_content" do
    it "assigns the overflown boxes to the split box" do
      box = create_box([child_box(height: 80), child_box(height: 30)], splitable: true)
      box.fit(@frame.available_width, @frame.available_height, @frame)
      assert(box.fit_result.overflow?)
      box_a, box_b = box.split
      assert_same(box, box_a)
      assert(box_b.split_box?)
      assert_equal(1, box_b.children.size)
    end
  end

  describe "draw_content" do
    before do
      @canvas = @doc.pages.add.canvas
    end

    it "draws the result onto the canvas" do
      cbox = @doc.layout.box(height: 20) do |canvas, b|
        canvas.line(0, 0, b.content_width, b.content_height).end_path
      end
      box = create_box(cbox)
      box.fit(100, 100, @frame)
      box.draw(@canvas, 0, 50)
      assert_operators(@canvas.contents, [[:save_graphics_state],
                                          [:concatenate_matrix, [1, 0, 0, 1, 0, 50]],
                                          [:move_to, [0, 0]],
                                          [:line_to, [100, 20]],
                                          [:end_path],
                                          [:restore_graphics_state]])
    end
  end
end
