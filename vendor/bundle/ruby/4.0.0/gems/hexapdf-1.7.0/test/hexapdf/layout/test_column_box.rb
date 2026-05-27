# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/document'
require 'hexapdf/layout/column_box'

describe HexaPDF::Layout::ColumnBox do
  before do
    @frame = HexaPDF::Layout::Frame.new(0, 0, 100, 100)
    inline_box = HexaPDF::Layout::InlineBox.create(width: 10, height: 10) {}
    @text_boxes = 5.times.map do
      HexaPDF::Layout::TextBox.new(items: [inline_box] * 15, style: {position: :default})
    end
    draw_block = lambda do |canvas, _box|
      canvas.move_to(0, 0).end_path
    end
    @fixed_size_boxes = 15.times.map { HexaPDF::Layout::Box.new(width: 20, height: 10, &draw_block) }
  end

  def create_box(**kwargs)
    HexaPDF::Layout::ColumnBox.new(gaps: 10, **kwargs)
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

  describe "initialize" do
    it "creates a new instance with the given arguments" do
      box = create_box(children: [:a], columns: 3, gaps: 10, equal_height: false)
      assert_equal([:a], box.children)
      assert_equal([-1, -1, -1], box.columns)
      assert_equal([10], box.gaps)
      assert_equal(false, box.equal_height)
      assert(box.supports_position_flow?)
    end
  end

  describe "empty?" do
    it "is empty if nothing is fit yet" do
      assert(create_box.empty?)
    end

    it "is empty if no box fits" do
      box = create_box(children: [@fixed_size_boxes[0]], columns: [10])
      box.fit(@frame.available_width, @frame.available_height, @frame)
      assert(box.empty?)
    end

    it "is not empty if at least one box fits" do
      box = create_box(children: [@fixed_size_boxes[0]], columns: [30])
      check_box(box, 30, 10)
      refute(box.empty?)
    end
  end

  describe "fit" do
    [:default, :flow].each do |position|
      it "respects the set initial width, position #{position}" do
        box = create_box(children: @text_boxes[0..1], width: 50, style: {position: position})
        check_box(box, 50, 80)

        box = create_box(columns: 1, children: @fixed_size_boxes[0..0], width: 50,
                         style: {position: position})
        check_box(box, 50, 10)
      end

      it "respects the set initial height, position #{position}" do
        box = create_box(children: @text_boxes[0..1], height: 50, equal_height: false,
                         style: {position: position})
        check_box(box, 100, 50)

        box = create_box(children: @text_boxes[0..1], height: 50, equal_height: true,
                         style: {position: position})
        check_box(box, 100, 50)
      end

      it "respects the border and padding around all columns, position #{position}" do
        box = create_box(children: @fixed_size_boxes[0, 3],
                         style: {border: {width: [5, 4, 3, 2]}, padding: [5, 4, 3, 2], position: position})
        check_box(box, 100, 36, [[4, 80], [4, 70], [53, 80]])
      end
    end

    it "uses the frame's current cursor position and available width/height when style position=:default" do
      @frame.remove_area(Geom2D::Polygon([0, 0], [10, 0], [10, 90], [100, 90], [100, 100], [0, 100]))
      box = create_box(children: @fixed_size_boxes[0, 4])
      check_box(box, 90, 20, [[10, 80], [10, 70], [60, 80], [60, 70]])
    end

    it "respects the frame's shape when style position=:flow" do
      @frame.remove_area(Geom2D::Polygon([30, 65], [70, 65], [70, 35], [30, 35]))
      box = create_box(children: @text_boxes[0, 3], style: {position: :flow})
      check_box(box, 100, 70, [[0, 70], [0, 60], [0, 30], [55, 80], [55, 70], [70, 30]])
    end

    it "allows fitting the contents to fill the columns instead of equalizing the height" do
      box = create_box(children: @fixed_size_boxes, equal_height: false)
      check_box(box, 100, 100, [[0, 90], [0, 80], [0, 70], [0, 60], [0, 50], [0, 40], [0, 30],
                                [0, 20], [0, 10], [0, 0], [55, 90], [55, 80], [55, 70],
                                [55, 60], [55, 50]])
    end

    describe "columns calculations" do
      it "works for a single column with a specified width" do
        box = create_box(children: @fixed_size_boxes[0..0], columns: [50])
        check_box(box, 50, 10, [[0, 90]])
      end

      it "works for multiple columns with specified widths" do
        box = create_box(children: @fixed_size_boxes[0..1], columns: [50, 30])
        check_box(box, 90, 10, [[0, 90], [60, 90]])
      end

      it "works for a single column with auto-width" do
        box = create_box(children: @fixed_size_boxes[0..0], columns: [-5])
        check_box(box, 100, 10, [[0, 90]])
      end

      it "works for multiple columns with auto-widths" do
        box = create_box(children: @fixed_size_boxes[0..1], columns: [-2, -1])
        check_box(box, 100, 10, [[0, 90], [70, 90]])
      end

      it "works for mixed columns with specified widths and auto-widths" do
        box = create_box(children: @fixed_size_boxes[0..2], columns: [20, -1, -2])
        check_box(box, 100, 10, [[0, 90], [30, 90], [60, 90]])
      end

      it "cycles the gap array" do
        box = create_box(children: @fixed_size_boxes[0..3], columns: 4, gaps: [5, 10])
        check_box(box, 100, 10, [[0, 90], [25, 90], [55, 90], [80, 90]])
      end

      it "fails if the necessary width is larger than the available one" do
        box = create_box(children: @fixed_size_boxes[0..2], columns: 4, gaps: [40])
        assert(box.fit(100, 100, @frame).failure?)
      end
    end
  end

  it "splits the children if they are too big to fill the colums" do
    box = create_box(children: @fixed_size_boxes, width: 50)
    assert(box.fit(100, 50, @frame).overflow?)
    box_a, box_b = box.split
    assert_same(box, box_a)
    assert(box_b.split_box?)
    assert_equal(5, box_b.children.size)
  end

  describe "draw_content" do
    before do
      @canvas = HexaPDF::Document.new.pages.add.canvas
    end

    it "draws the result onto the canvas" do
      box = create_box(children: @fixed_size_boxes)
      assert(box.fit(100, 100, @frame).success?)
      box.draw(@canvas, 0, 100 - box.height)
      operators = 90.step(to: 20, by: -10).map do |y|
        [[:save_graphics_state],
         [:concatenate_matrix, [1, 0, 0, 1, 0, y]],
         [:move_to, [0, 0]],
         [:end_path],
         [:restore_graphics_state]]
      end
      operators.concat(90.step(to: 30, by: -10).map do |y|
        [[:save_graphics_state],
         [:concatenate_matrix, [1, 0, 0, 1, 55, y]],
         [:move_to, [0, 0]],
         [:end_path],
         [:restore_graphics_state]]
      end)
      operators.flatten!(1)
      assert_operators(@canvas.contents, operators)
    end

    it "takes a different final location into account" do
      box = create_box(children: @fixed_size_boxes[0, 2], style: {padding: [2, 4, 6, 8]})
      assert(box.fit(100, 100, @frame).success?)
      box.draw(@canvas, 20, 10)
      operators = [
        [:save_graphics_state],
        [:concatenate_matrix, [1, 0, 0, 1, 20, -72]],
        [:save_graphics_state],
        [:concatenate_matrix, [1, 0, 0, 1, 8, 88]],
        [:move_to, [0, 0]],
        [:end_path],
        [:restore_graphics_state],
        [:save_graphics_state],
        [:concatenate_matrix, [1, 0, 0, 1, 57, 88]],
        [:move_to, [0, 0]],
        [:end_path],
        [:restore_graphics_state],
        [:restore_graphics_state],
      ]
      assert_operators(@canvas.contents, operators)
    end
  end
end
