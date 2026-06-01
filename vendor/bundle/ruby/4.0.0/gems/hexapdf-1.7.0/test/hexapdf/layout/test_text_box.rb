# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/document'
require 'hexapdf/layout/text_box'

describe HexaPDF::Layout::TextBox do
  before do
    @frame = HexaPDF::Layout::Frame.new(0, 0, 100, 100)
    @inline_box = HexaPDF::Layout::InlineBox.create(width: 10, height: 10) {}
  end

  def create_box(items, **kwargs)
    HexaPDF::Layout::TextBox.new(items: items, **kwargs)
  end

  describe "initialize" do
    it "takes the inline items to be layed out in the box" do
      box = create_box([], width: 100)
      assert_equal(100, box.width)
    end

    it "supports flowing text around other content" do
      assert(create_box([]).supports_position_flow?)
    end
  end

  it "returns the text contents as string" do
    doc = HexaPDF::Document.new
    font = doc.fonts.add("Times")
    box = create_box([HexaPDF::Layout::TextFragment.create('Test ', font: font), @inline_box,
                      HexaPDF::Layout::TextFragment.create('here', font: font)])
    assert_equal('Test here', box.text)
  end

  describe "fit" do
    it "fits into a rectangular area" do
      box = create_box([@inline_box] * 5, style: {padding: 10})
      assert(box.fit(100, 100, @frame).success?)
      assert_equal(70, box.width)
      assert_equal(30, box.height)
    end

    it "respects the set width and height" do
      box = create_box([@inline_box] * 5, width: 44, height: 50,
                       style: {padding: 10, text_align: :right, text_valign: :bottom})
      assert(box.fit(100, 100, @frame).success?)
      assert_equal(44, box.width)
      assert_equal(50, box.height)
      assert_equal([20, 20, 10], box.instance_variable_get(:@result).lines.map(&:width))
    end

    describe "style option last_line_gap" do
      it "is taken into account" do
        box = create_box([@inline_box] * 5, style: {last_line_gap: true, line_spacing: :double})
        assert(box.fit(100, 100, @frame).success?)
        assert_equal(50, box.width)
        assert_equal(20, box.height)
      end

      it "will have no effect for fixed-height boxes" do
        box = create_box([@inline_box] * 5, height: 40, style: {last_line_gap: true, line_spacing: :double})
        assert(box.fit(100, 100, @frame).success?)
        assert_equal(50, box.width)
        assert_equal(40, box.height)
      end
    end

    it "uses the whole available width when aligning to the center, right or justified" do
      [:center, :right, :justify].each do |align|
        box = create_box([@inline_box], style: {text_align: align})
        assert(box.fit(100, 100, @frame).success?)
        assert_equal(100, box.width)
      end
    end

    it "uses the whole available height when vertically aligning to the center or bottom" do
      [:center, :bottom].each do |valign|
        box = create_box([@inline_box], style: {text_valign: valign})
        assert(box.fit(100, 100, @frame).success?)
        assert_equal(100, box.height)
      end
    end

    it "can fit part of the box" do
      box = create_box([@inline_box] * 20, height: 15)
      assert(box.fit(100, 100, @frame).overflow?)
    end

    it "correctly handles text indentation for split boxes" do
      [{}, {position: :flow}].each do |styles|
        box = create_box([@inline_box] * 202, style: {text_indent: 50, **styles})
        assert(box.fit(100, 100, @frame).overflow?)
        _, box_b = box.split
        assert_equal(107, box_b.instance_variable_get(:@items).length)
        assert(box_b.fit(100, 100, @frame).overflow?)
        _, box_b = box_b.split
        assert_equal(7, box_b.instance_variable_get(:@items).length)
      end
    end

    it "fits an empty text box" do
      box = create_box([])
      assert(box.fit(100, 100, @frame).success?)
    end

    describe "position :flow" do
      it "fits into the frame's outline" do
        @frame.remove_area(Geom2D::Rectangle(0, 80, 20, 20))
        @frame.remove_area(Geom2D::Rectangle(80, 70, 20, 20))
        box = create_box([@inline_box] * 20, style: {position: :flow})
        assert(box.fit(100, 100, @frame).success?)
        assert_equal(100, box.width)
        assert_equal(30, box.height)
      end

      it "respects a set initial height" do
        box = create_box([@inline_box] * 20, height: 13, style: {position: :flow})
        assert(box.fit(100, 100, @frame).overflow?)
        assert_equal(100, box.width)
        assert_equal(13, box.height)
      end

      it "respects top/bottom padding/border" do
        @frame.remove_area(Geom2D::Rectangle(0, 80, 20, 20))
        box = create_box([@inline_box] * 20, style: {position: :flow, padding: 10, border: {width: 2}})
        assert(box.fit(100, 100, @frame).success?)
        assert_equal(124, box.width)
        assert_equal(54, box.height)
        assert_equal([80, 100, 20], box.instance_variable_get(:@result).lines.map(&:width))
      end
    end

    it "fails if no item of the text box fits due to the width" do
      box = create_box([@inline_box])
      assert(box.fit(5, 20, @frame).failure?)
    end

    it "fails if no item of the text box fits due to the height" do
      box = create_box([@inline_box])
      assert(box.fit(20, 5, @frame).failure?)
    end
  end

  describe "split" do
    it "splits the box if necessary when using non-flowing text" do
      box = create_box([@inline_box] * 10)
      box.fit(50, 10, @frame)
      box_a, box_b = box.split
      assert_same(box, box_a)
      refute(box_a.split_box?)
      assert(box_b.split_box?)
      assert_equal(5, box_b.instance_variable_get(:@items).length)
    end

    it "splits the box if necessary when using flowing text that results in a wider box" do
      @frame.remove_area(Geom2D::Polygon.new([[0, 100], [50, 100], [50, 10], [0, 10]]))
      box = create_box([@inline_box] * 60, style: {position: :flow})
      box.fit(50, 100, @frame)
      box_a, box_b = box.split
      assert_same(box, box_a)
      assert_equal(5, box_b.instance_variable_get(:@items).length)
    end
  end

  describe "draw" do
    before do
      @canvas = HexaPDF::Document.new.pages.add.canvas
    end

    it "draws the layed out inline items onto the canvas" do
      inline_box = HexaPDF::Layout::InlineBox.create(width: 10, height: 10,
                                                     border: {width: 1})
      box = create_box([inline_box], width: 100, height: 30, style: {padding: [10, 5]})
      box.fit(100, 100, @frame)

      box.draw(@canvas, 0, 0)
      assert_operators(@canvas.contents, [[:save_graphics_state],
                                          [:restore_graphics_state],
                                          [:save_graphics_state],
                                          [:append_rectangle, [5.5, 10.5, 9.0, 9.0]],
                                          [:stroke_path],
                                          [:restore_graphics_state],
                                          [:save_graphics_state],
                                          [:restore_graphics_state]])
    end

    it "correctly draws borders, backgrounds... for position :flow" do
      @frame.remove_area(Geom2D::Rectangle(0, 0, 40, 100))
      box = create_box([@inline_box], style: {position: :flow, border: {width: 1}})
      box.fit(60, 100, @frame)
      box.draw(@canvas, 40, 88)
      assert_operators(@canvas.contents, [[:save_graphics_state],
                                          [:append_rectangle, [40.5, 88.5, 11.0, 11.0]],
                                          [:stroke_path],
                                          [:restore_graphics_state],
                                          [:save_graphics_state],
                                          [:restore_graphics_state],
                                          [:save_graphics_state],
                                          [:concatenate_matrix, [1, 0, 0, 1, 41, 89]],
                                          [:restore_graphics_state],
                                          [:save_graphics_state],
                                          [:restore_graphics_state]])
    end

    it "draws nothing onto the canvas if the box is empty" do
      box = create_box([])
      box.fit(100, 100, @frame)
      box.draw(@canvas, 5, 5)
      assert_operators(@canvas.contents, [])
    end

    it "raises an error if there is too much content for a set height with overflow=:error" do
      box = create_box([@inline_box] * 20, height: 15)
      box.fit(100, 100, @frame)
      assert_raises(HexaPDF::Error) { box.draw(@canvas, 0, 0) }
    end
  end

  it "is empty if there is a result without any text lines" do
    box = create_box([])
    assert(box.empty?)
    box.fit(100, 100, @frame)
    assert(box.empty?)

    box = create_box([@inline_box])
    box.fit(100, 100, @frame)
    refute(box.empty?)
  end
end
