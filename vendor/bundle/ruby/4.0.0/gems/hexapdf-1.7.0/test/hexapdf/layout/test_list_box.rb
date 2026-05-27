# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/document'
require 'hexapdf/layout/list_box'

describe HexaPDF::Layout::ListBox do
  before do
    @doc = HexaPDF::Document.new
    @page = @doc.pages.add
    @frame = HexaPDF::Layout::Frame.new(0, 0, 100, 100, context: @page)
    inline_box = HexaPDF::Layout::InlineBox.create(width: 10, height: 10) {}
    @text_boxes = 5.times.map do
      HexaPDF::Layout::TextBox.new(items: [inline_box] * 15, style: {position: :default})
    end
  end

  def create_box(**kwargs)
    HexaPDF::Layout::ListBox.new(content_indentation: 10, **kwargs)
  end

  def check_box(box, width, height, status: :success, fit_pos: nil)
    result = box.fit(@frame.available_width, @frame.available_height, @frame)
    assert_equal(result.status, status)
    assert_equal(width, box.width, "box width")
    assert_equal(height, box.height, "box height")
    if fit_pos
      results = box.instance_variable_get(:@results)
      results.each_with_index do |item_result, item_index|
        item_result.box_fitter.fit_results.each_with_index do |fit_result, result_index|
          x, y = fit_pos.shift
          assert_equal(x, fit_result.x, "item #{item_index}, result #{result_index}, x")
          assert_equal(y, fit_result.y, "item #{item_index}, result #{result_index}, y")
        end
      end
      assert(fit_pos.empty?)
    end
  end

  describe "initialize" do
    it "creates a new instance with the given arguments" do
      box = create_box(children: [:a], marker_type: :circle, content_indentation: 15,
                       start_number: 4, item_spacing: 20)
      assert_equal([:a], box.children)
      assert_equal(:circle, box.marker_type)
      assert_equal(15, box.content_indentation)
      assert_equal(4, box.start_number)
      assert_equal(20, box.item_spacing)
      assert(box.supports_position_flow?)
    end
  end

  describe "empty?" do
    it "is empty if nothing was fit yet" do
      assert(create_box.empty?)
    end

    it "is empty if nothing could be fit" do
      box = create_box(children: [@text_boxes[0]], width: 5)
      box.fit(@frame.available_width, @frame.available_height, @frame)
      assert(box.empty?)
    end
  end

  describe "fit" do
    [:default, :flow].each do |position|
      it "respects the set initial width, position #{position}" do
        box = create_box(children: @text_boxes[0, 2], width: 55, style: {position: position})
        check_box(box, 55, 80)
      end

      it "respects the set initial height, position #{position}" do
        box = create_box(children: @text_boxes[0, 2], height: 55, style: {position: position})
        check_box(box, 100, 55)
      end

      it "respects the set initial height even when it doesn't fit completely" do
        box = create_box(children: @text_boxes[0, 2], height: 20, style: {position: position})
        check_box(box, 100, 20, status: :overflow)
      end

      it "respects the border and padding around all list items, position #{position}" do
        box = create_box(children: @text_boxes[0, 2],
                         style: {border: {width: [5, 4, 3, 2]}, padding: [5, 4, 3, 2], position: position})
        check_box(box, 100, 76, fit_pos: [[14, 60], [14, 30]])
      end
    end

    it "uses the frame's current cursor position and available width/height when position=:default" do
      @frame.remove_area(Geom2D::Polygon([0, 0], [10, 0], [10, 90], [100, 90], [100, 100], [0, 100]))
      box = create_box(children: @text_boxes[0, 2])
      check_box(box, 90, 40, fit_pos: [[20, 70], [20, 50]])
    end

    it "respects the frame's shape when style position=:flow" do
      @frame.remove_area(Geom2D::Polygon([0, 0], [0, 40], [40, 40], [40, 0]))
      box = create_box(children: @text_boxes[0, 4], style: {position: :flow})
      check_box(box, 100, 90, fit_pos: [[10, 80], [10, 60], [10, 40], [50, 10]])
    end

    it "calculates the correct height if the marker is higher than the content" do
      box = create_box(children: @text_boxes[0, 1], content_indentation: 20,
                       style: {font_size: 30})
      check_box(box, 100, 27, fit_pos: [[20, 80]])
    end

    it "respects the content indentation" do
      box = create_box(children: @text_boxes[0, 1], content_indentation: 30)
      check_box(box, 100, 30, fit_pos: [[30, 70]])
    end

    it "respects the spacing between list items" do
      box = create_box(children: @text_boxes[0, 2], item_spacing: 30)
      check_box(box, 100, 70, fit_pos:  [[10, 80], [10, 30]])
    end

    it "creates a new box for each marker even if the marker is the same" do
      box = create_box(children: @text_boxes[0, 2])
      check_box(box, 100, 40)
      results = box.instance_variable_get(:@results)
      refute_same(results[0].marker, results[1].marker)
    end

    it "fails if not even a part of the first list item fits" do
      box = create_box(children: @text_boxes[0, 2], height: 5)
      check_box(box, 100, 5, status: :failure)
    end

    it "fails for unknown marker types" do
      box = create_box(children: @text_boxes[0, 1], marker_type: :unknown)
      assert_raises(HexaPDF::Error) { box.fit(100, 100, @frame) }
    end
  end

  describe "split" do
    it "splits before a list item if no part of it will fit" do
      box = create_box(children: @text_boxes[0, 3])
      assert(box.fit(100, 22, @frame).overflow?)
      box_a, box_b = box.split
      assert_same(box, box_a)
      assert_equal(:show_first_marker, box_b.split_box?)
      assert_equal(1, box_a.instance_variable_get(:@results)[0].box_fitter.fit_results.size)
      assert_equal(2, box_b.children.size)
      assert_equal(2, box_b.start_number)
    end

    it "splits a list item if some part of it will fit" do
      box = create_box(children: @text_boxes[0, 2])
      assert(box.fit(100, 10, @frame).overflow?)
      box_a, box_b = box.split
      assert_same(box, box_a)
      assert_equal(:hide_first_marker, box_b.split_box?)
      assert_equal(1, box_a.instance_variable_get(:@results)[0].box_fitter.fit_results.size)
      assert_equal(2, box_b.children.size)
      assert_equal(1, box_b.start_number)
    end

    it "splits a list item containg multiple boxes along box lines" do
      box = create_box(children: [@text_boxes[0], @text_boxes[1, 2]])
      assert(box.fit(100, 40, @frame).overflow?)
      box_a, box_b = box.split
      assert_same(box, box_a)
      assert_equal(:hide_first_marker, box_b.split_box?)
      assert_equal(1, box_a.instance_variable_get(:@results)[1].box_fitter.fit_results.size)
      assert_equal(1, box_b.children.size)
      assert_equal(2, box_b.start_number)
    end
  end

  describe "draw" do
    before do
      @canvas = @page.canvas
      draw_block = lambda {|canvas, box| }
      @fixed_size_boxes = 5.times.map { HexaPDF::Layout::Box.new(width: 20, height: 10, &draw_block) }
      @helvetica = @doc.fonts.add('Helvetica')
    end

    it "draws the result" do
      box = create_box(children: @fixed_size_boxes[0, 2],
                       style: {font_size: 11, fill_color: 0.5})
      box.fit(100, 100, @frame)
      box.draw(@canvas, 0, 100 - box.height)
      operators = [
        [:save_graphics_state],
        [:set_font_and_size, [:F1, 11]],
        [:set_device_gray_non_stroking_color, [0.5]],
        [:begin_text],
        [:move_text, [1.15, 92.487]],
        [:show_text, ["\x95".b]],
        [:end_text],
        [:restore_graphics_state],
        [:save_graphics_state],
        [:concatenate_matrix, [1, 0, 0, 1, 10, 90]],
        [:restore_graphics_state],

        [:save_graphics_state],
        [:set_font_and_size, [:F1, 11]],
        [:set_device_gray_non_stroking_color, [0.5]],
        [:begin_text],
        [:move_text, [1.15, 82.487]],
        [:show_text, ["\x95".b]],
        [:end_text],
        [:restore_graphics_state],
        [:save_graphics_state],
        [:concatenate_matrix, [1, 0, 0, 1, 10, 80]],
        [:restore_graphics_state],
      ]
      assert_operators(@canvas.contents, operators)
    end

    it "draws a circle as marker" do
      box = create_box(children: @fixed_size_boxes[0, 1], marker_type: :circle,
                       style: {font_size: 11, fill_color: 0.5})
      box.fit(100, 100, @frame)
      box.draw(@canvas, 0, 100 - box.height)
      operators = [
        [:save_graphics_state],
        [:set_font_and_size, [:F1, 5.5]],
        [:set_text_rise, [-6.111111]],
        [:set_device_gray_non_stroking_color, [0.5]],
        [:begin_text],
        [:move_text, [0.1985, 100]],
        [:show_text, ["m".b]],
        [:end_text],
        [:restore_graphics_state],
        [:save_graphics_state],
        [:concatenate_matrix, [1, 0, 0, 1, 10, 90]],
        [:restore_graphics_state],
      ]
      assert_operators(@canvas.contents, operators)
    end

    it "draws a square as marker" do
      box = create_box(children: @fixed_size_boxes[0, 1], marker_type: :square,
                       style: {font_size: 11, fill_color: 0.5})
      box.fit(100, 100, @frame)
      box.draw(@canvas, 0, 100 - box.height)
      operators = [
        [:save_graphics_state],
        [:set_font_and_size, [:F1, 5.5]],
        [:set_text_rise, [-6.111111]],
        [:set_device_gray_non_stroking_color, [0.5]],
        [:begin_text],
        [:move_text, [0.8145, 100]],
        [:show_text, ["n".b]],
        [:end_text],
        [:restore_graphics_state],
        [:save_graphics_state],
        [:concatenate_matrix, [1, 0, 0, 1, 10, 90]],
        [:restore_graphics_state],
      ]
      assert_operators(@canvas.contents, operators)
    end

    it "draws decimal numbers as marker" do
      box = create_box(children: @fixed_size_boxes[0, 2], marker_type: :decimal,
                       style: {font_size: 11, fill_color: 0.5},
                       content_indentation: 20)
      box.fit(100, 100, @frame)
      box.draw(@canvas, 0, 100 - box.height)
      operators = [
        [:save_graphics_state],
        [:set_font_and_size, [:F1, 11]],
        [:set_device_gray_non_stroking_color, [0.5]],
        [:begin_text],
        [:move_text, [6.75, 92.487]],
        [:show_text, ["1.".b]],
        [:end_text],
        [:restore_graphics_state],
        [:save_graphics_state],
        [:concatenate_matrix, [1, 0, 0, 1, 20, 90]],
        [:restore_graphics_state],

        [:save_graphics_state],
        [:set_font_and_size, [:F1, 11]],
        [:set_device_gray_non_stroking_color, [0.5]],
        [:begin_text],
        [:move_text, [6.75, 82.487]],
        [:show_text, ["2.".b]],
        [:end_text],
        [:restore_graphics_state],
        [:save_graphics_state],
        [:concatenate_matrix, [1, 0, 0, 1, 20, 80]],
        [:restore_graphics_state],
      ]
      assert_operators(@canvas.contents, operators)
    end

    it "allows drawing custom markers" do
      marker = lambda do |_doc, _list_box, _index|
        HexaPDF::Layout::Box.create(width: 10, height: 10) {}
      end
      box = create_box(children: @fixed_size_boxes[0, 1], marker_type: marker)
      box.fit(100, 100, @frame)
      box.draw(@canvas, 0, 100 - box.height)
      operators = [
        [:save_graphics_state],
        [:concatenate_matrix, [1, 0, 0, 1, 0, 90]],
        [:restore_graphics_state],
        [:save_graphics_state],
        [:concatenate_matrix, [1, 0, 0, 1, 10, 90]],
        [:restore_graphics_state],
      ]
      assert_operators(@canvas.contents, operators)
    end

    it "takes a different final location into account" do
      box = create_box(children: @fixed_size_boxes[0, 1])
      box.fit(100, 100, @frame)
      box.draw(@canvas, 20, 10)
      operators = [
        [:save_graphics_state],
        [:concatenate_matrix, [1, 0, 0, 1, 20, -80]],
        [:save_graphics_state],
        [:set_font_and_size, [:F1, 10]],
        [:begin_text],
        [:move_text, [1.5, 93.17]],
        [:show_text, ["\x95".b]],
        [:end_text],
        [:restore_graphics_state],
        [:save_graphics_state],
        [:concatenate_matrix, [1, 0, 0, 1, 10, 90]],
        [:restore_graphics_state],
        [:restore_graphics_state],
      ]
      assert_operators(@canvas.contents, operators)
    end

    it "uses the font set on the list box for the marker" do
      box = create_box(children: @fixed_size_boxes[0, 1],
                       style: {font: @helvetica, font_size: 12})
      box.fit(100, 100, @frame)
      box.draw(@canvas, 0, 100 - box.height)
      assert_operators(@canvas.contents, [:set_font_and_size, [:F1, 12]], range: 1)
      assert_equal(:Helvetica, @canvas.resources.font(:F1)[:BaseFont])
    end

    it "falls back to ZapfDingbats if the set font doesn't contain the necessary symbol" do
      box = create_box(children: @fixed_size_boxes[0, 1], marker_type: :circle,
                       style: {font: @helvetica})
      box.fit(100, 100, @frame)
      box.draw(@canvas, 0, 100 - box.height)
      assert_operators(@canvas.contents, [:set_font_and_size, [:F1, 5]], range: 1)
      assert_equal(:ZapfDingbats, @canvas.resources.font(:F1)[:BaseFont])
    end
  end
end
