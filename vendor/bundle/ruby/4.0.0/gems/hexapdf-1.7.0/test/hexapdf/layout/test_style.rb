# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/document'
require 'hexapdf/layout/style'
require 'hexapdf/layout/text_layouter'
require 'hexapdf/layout/box'

describe HexaPDF::Layout::Style::LineSpacing do
  before do
    @line1 = Object.new
    @line1.define_singleton_method(:y_min) { - 1 }
    @line1.define_singleton_method(:y_max) { 2 }
    @line2 = Object.new
    @line2.define_singleton_method(:y_min) { -3 }
    @line2.define_singleton_method(:y_max) { 4 }
  end

  def line_spacing(type, value = nil)
    HexaPDF::Layout::Style::LineSpacing.new(type: type, value: value)
  end

  it "allows single line spacing" do
    obj = line_spacing(:single)
    assert_equal(:proportional, obj.type)
    assert_equal(1, obj.value)
    assert_equal(1 + 4, obj.baseline_distance(@line1, @line2))
    assert_equal(0, obj.gap(@line1, @line2))
  end

  it "allows double line spacing" do
    obj = line_spacing(:double)
    assert_equal(:proportional, obj.type)
    assert_equal(2, obj.value)
    assert_equal((1 + 4) * 2, obj.baseline_distance(@line1, @line2))
    assert_equal(1 + 4, obj.gap(@line1, @line2))
  end

  it "allows proportional line spacing" do
    obj = line_spacing(:proportional, 1.5)
    assert_equal(:proportional, obj.type)
    assert_equal(1.5, obj.value)
    assert_equal((1 + 4) * 1.5, obj.baseline_distance(@line1, @line2))
    assert_equal((1 + 4) * 0.5, obj.gap(@line1, @line2))
  end

  it "allows using an Integer or Float as type to mean proportional line spacing" do
    obj = line_spacing(2)
    assert_equal(:proportional, obj.type)
    assert_equal(2, obj.value)

    obj = line_spacing(2.5)
    assert_equal(:proportional, obj.type)
    assert_equal(2.5, obj.value)
  end

  it "allows fixed line spacing" do
    obj = line_spacing(:fixed, 7)
    assert_equal(:fixed, obj.type)
    assert_equal(7, obj.value)
    assert_equal(7, obj.baseline_distance(@line1, @line2))
    assert_equal(7 - 1 - 4, obj.gap(@line1, @line2))
  end

  it "allows line spacing using a leading value" do
    obj = line_spacing(:leading, 3)
    assert_equal(:leading, obj.type)
    assert_equal(3, obj.value)
    assert_equal(1 + 4 + 3, obj.baseline_distance(@line1, @line2))
    assert_equal(3, obj.gap(@line1, @line2))
  end

  it "allows using a LineSpacing object as type" do
    obj = line_spacing(line_spacing(:single))
    assert_equal(:proportional, obj.type)
  end

  it "raises an error if a value is needed and none is provided" do
    assert_raises(ArgumentError) { line_spacing(:proportional) }
  end

  it "raises an error if an invalid type is provided" do
    assert_raises(ArgumentError) { line_spacing(:invalid) }
  end
end

describe HexaPDF::Layout::Style::Quad do
  def create_quad(val)
    HexaPDF::Layout::Style::Quad.new(val)
  end

  describe "initialize" do
    it "works with a single value" do
      quad = create_quad(5)
      assert_equal(5, quad.top)
      assert_equal(5, quad.right)
      assert_equal(5, quad.bottom)
      assert_equal(5, quad.left)

      quad = create_quad([5])
      assert_equal(5, quad.top)
      assert_equal(5, quad.right)
      assert_equal(5, quad.bottom)
      assert_equal(5, quad.left)
    end

    it "works with two values" do
      quad = create_quad([5, 2])
      assert_equal(5, quad.top)
      assert_equal(2, quad.right)
      assert_equal(5, quad.bottom)
      assert_equal(2, quad.left)
    end

    it "works with three values" do
      quad = create_quad([5, 2, 7])
      assert_equal(5, quad.top)
      assert_equal(2, quad.right)
      assert_equal(7, quad.bottom)
      assert_equal(2, quad.left)
    end

    it "works with four or more values" do
      quad = create_quad([5, 2, 7, 1, 9])
      assert_equal(5, quad.top)
      assert_equal(2, quad.right)
      assert_equal(7, quad.bottom)
      assert_equal(1, quad.left)
    end

    it "works with a Quad as value" do
      quad = create_quad([5, 2, 7, 1])
      new_quad = create_quad(quad)
      assert_equal(new_quad.top, quad.top)
      assert_equal(new_quad.right, quad.right)
      assert_equal(new_quad.bottom, quad.bottom)
      assert_equal(new_quad.left, quad.left)
    end

    it "works with a Hash as value" do
      quad = create_quad(top: 5, left: 10)
      assert_equal(5, quad.top)
      assert_equal(0, quad.bottom)
      assert_equal(10, quad.left)
      assert_equal(0, quad.right)
      quad.set(right: 7)
      assert_equal(5, quad.top)
      assert_equal(0, quad.bottom)
      assert_equal(10, quad.left)
      assert_equal(7, quad.right)
    end
  end

  it "can be asked if it contains only a single value" do
    assert(create_quad(5).simple?)
    refute(create_quad([5, 2]).simple?)
  end
end

describe HexaPDF::Layout::Style::Border do
  def create_border(**args)
    HexaPDF::Layout::Style::Border.new(**args)
  end

  it "has accessors for with, color and style that return Quads" do
    border = create_border
    assert_kind_of(HexaPDF::Layout::Style::Quad, border.width)
    assert_kind_of(HexaPDF::Layout::Style::Quad, border.color)
    assert_kind_of(HexaPDF::Layout::Style::Quad, border.style)
  end

  it "has an accessor for the draw-on-bounds option" do
    border = create_border
    refute(border.draw_on_bounds)
    border.draw_on_bounds = true
    assert(border.draw_on_bounds)
  end

  it "can be duplicated" do
    border = create_border
    copy = border.dup
    border.width.top = 10
    border.color.top = :red
    border.style.top = :dotted
    border.draw_on_bounds = true
    assert_equal(0, copy.width.top)
    assert_equal(0, copy.color.top)
    assert_equal(:solid, copy.style.top)
    refute(copy.draw_on_bounds)
  end

  it "can be asked whether a border is defined" do
    assert(create_border.none?)
    refute(create_border(width: 5).none?)
  end

  describe "draw" do
    before do
      @canvas = HexaPDF::Document.new.pages.add.canvas
    end

    it "draws nothing if no border is defined" do
      border = create_border
      border.draw(@canvas, 0, 0, 100, 100)
      assert_operators(@canvas.contents, [])
    end

    describe "simple - same width, color and style on all sides" do
      it "works with style solid" do
        border = create_border(width: 10, color: 0.5, style: :solid)
        border.draw(@canvas, 0, 0, 100, 100)
        assert_operators(@canvas.contents, [[:save_graphics_state],
                                            [:set_device_gray_stroking_color, [0.5]],
                                            [:set_line_width, [10]],
                                            [:append_rectangle, [5, 5, 90, 90]],
                                            [:stroke_path],
                                            [:restore_graphics_state]])
      end

      it "works with style dashed" do
        border = create_border(width: 10, color: 0.5, style: :dashed)
        border.draw(@canvas, 0, 0, 200, 300)
        ops = [[:save_graphics_state],
               [:set_device_gray_stroking_color, [0.5]],
               [:set_line_width, [10]],
               [:set_line_cap_style, [2]],
               [:set_line_dash_pattern, [[10, 20], 25]],
               [:move_to, [0, 295]], [:line_to, [200, 295]],
               [:move_to, [200, 5]], [:line_to, [0, 5]],
               [:stroke_path],
               [:set_line_dash_pattern, [[10, 18], 23]],
               [:move_to, [195, 300]], [:line_to, [195, 0]],
               [:move_to, [5, 0]], [:line_to, [5, 300]],
               [:stroke_path],
               [:restore_graphics_state]]
        assert_operators(@canvas.contents, ops)
      end

      it "works with style dashed_round" do
        border = create_border(width: 10, color: 0.5, style: :dashed_round)
        border.draw(@canvas, 0, 0, 200, 300)
        ops = [[:save_graphics_state],
               [:set_device_gray_stroking_color, [0.5]],
               [:set_line_width, [10]],
               [:set_line_cap_style, [1]],
               [:set_line_dash_pattern, [[10, 20], 25]],
               [:move_to, [0, 295]], [:line_to, [200, 295]],
               [:move_to, [200, 5]], [:line_to, [0, 5]],
               [:stroke_path],
               [:set_line_dash_pattern, [[10, 18], 23]],
               [:move_to, [195, 300]], [:line_to, [195, 0]],
               [:move_to, [5, 0]], [:line_to, [5, 300]],
               [:stroke_path],
               [:restore_graphics_state]]
        assert_operators(@canvas.contents, ops)
      end

      it "works with style dotted" do
        border = create_border(width: 10, color: 0.5, style: :dotted)
        border.draw(@canvas, 0, 0, 100, 200)
        ops = [[:save_graphics_state],
               [:set_device_gray_stroking_color, [0.5]],
               [:set_line_width, [10]],
               [:set_line_cap_style, [1]],
               [:set_line_dash_pattern, [[0, 18], 13]],
               [:move_to, [0, 195]], [:line_to, [100, 195]],
               [:move_to, [100, 5]], [:line_to, [0, 5]],
               [:stroke_path],
               [:set_line_dash_pattern, [[0, 19], 14]],
               [:move_to, [95, 200]], [:line_to, [95, 0]],
               [:move_to, [5, 0]], [:line_to, [5, 200]],
               [:stroke_path],
               [:restore_graphics_state]]
        assert_operators(@canvas.contents, ops)
      end

      it "works if the border is drawn on the bounds" do
        border = create_border(width: 10, color: 0.5, style: :solid, draw_on_bounds: true)
        border.draw(@canvas, 0, 0, 100, 100)
        assert_operators(@canvas.contents, [[:save_graphics_state],
                                            [:set_device_gray_stroking_color, [0.5]],
                                            [:set_line_width, [10]],
                                            [:append_rectangle, [0, 0, 100, 100]],
                                            [:stroke_path],
                                            [:restore_graphics_state]])
      end
    end

    describe "complex borders where edges have different width/color/style values" do
      it "works correctly for the top border" do
        border = create_border(width: [10, 0, 0, 0], color: 0.5, style: :dashed)
        border.draw(@canvas, 0, 0, 200, 300)
        ops = [[:save_graphics_state],
               [:save_graphics_state],
               [:move_to, [0, 300]], [:line_to, [200, 300]],
               [:line_to, [200, 290]], [:line_to, [0, 290]],
               [:clip_path_non_zero], [:end_path],
               [:set_device_gray_stroking_color, [0.5]],
               [:set_line_width, [10]],
               [:set_line_cap_style, [2]],
               [:set_line_dash_pattern, [[10, 20], 25]],
               [:move_to, [0, 295]], [:line_to, [200, 295]],
               [:stroke_path],
               [:restore_graphics_state],
               [:restore_graphics_state]]
        assert_operators(@canvas.contents, ops)
      end

      it "works correctly for the right border" do
        border = create_border(width: [0, 10, 0, 0], color: 0.5, style: :dashed)
        border.draw(@canvas, 0, 0, 200, 300)
        ops = [[:save_graphics_state],
               [:save_graphics_state],
               [:move_to, [200, 300]], [:line_to, [200, 0]],
               [:line_to, [190, 0]], [:line_to, [190, 300]],
               [:clip_path_non_zero], [:end_path],
               [:set_device_gray_stroking_color, [0.5]],
               [:set_line_width, [10]],
               [:set_line_cap_style, [2]],
               [:set_line_dash_pattern, [[10, 18], 23]],
               [:move_to, [195, 300]], [:line_to, [195, 0]],
               [:stroke_path],
               [:restore_graphics_state],
               [:restore_graphics_state]]
        assert_operators(@canvas.contents, ops)
      end

      it "works correctly for the bottom border" do
        border = create_border(width: [0, 0, 10, 0], color: 0.5, style: :dashed)
        border.draw(@canvas, 0, 0, 200, 300)
        ops = [[:save_graphics_state],
               [:save_graphics_state],
               [:move_to, [200, 0]], [:line_to, [0, 0]],
               [:line_to, [0, 10]], [:line_to, [200, 10]],
               [:clip_path_non_zero], [:end_path],
               [:set_device_gray_stroking_color, [0.5]],
               [:set_line_width, [10]],
               [:set_line_cap_style, [2]],
               [:set_line_dash_pattern, [[10, 20], 25]],
               [:move_to, [200, 5]], [:line_to, [0, 5]],
               [:stroke_path],
               [:restore_graphics_state],
               [:restore_graphics_state]]
        assert_operators(@canvas.contents, ops)
      end

      it "works correctly for the left border" do
        border = create_border(width: [0, 0, 0, 10], color: 0.5, style: :dashed)
        border.draw(@canvas, 0, 0, 200, 300)
        ops = [[:save_graphics_state],
               [:save_graphics_state],
               [:move_to, [0, 0]], [:line_to, [0, 300]],
               [:line_to, [10, 300]], [:line_to, [10, 0]],
               [:clip_path_non_zero], [:end_path],
               [:set_device_gray_stroking_color, [0.5]],
               [:set_line_width, [10]],
               [:set_line_cap_style, [2]],
               [:set_line_dash_pattern, [[10, 18], 23]],
               [:move_to, [5, 0]], [:line_to, [5, 300]],
               [:stroke_path],
               [:restore_graphics_state],
               [:restore_graphics_state]]
        assert_operators(@canvas.contents, ops)
      end

      it "works with all values combined" do
        border = create_border(width: [20, 10, 40, 30], color: [0, 0.25, 0.5, 0.75],
                               style: [:solid, :dashed, :dashed_round, :dotted])
        border.draw(@canvas, 0, 0, 100, 200)
        ops = [[:save_graphics_state],
               [:save_graphics_state],
               [:move_to, [0, 200]], [:line_to, [100, 200]],
               [:line_to, [90, 180]], [:line_to, [30, 180]], [:clip_path_non_zero], [:end_path],
               [:set_line_width, [20]],
               [:move_to, [0, 190]], [:line_to, [100, 190]], [:stroke_path],
               [:restore_graphics_state], [:save_graphics_state],
               [:move_to, [100, 200]], [:line_to, [100, 0]],
               [:line_to, [90, 40]], [:line_to, [90, 180]], [:clip_path_non_zero], [:end_path],
               [:set_device_gray_stroking_color, [0.25]], [:set_line_width, [10]],
               [:set_line_cap_style, [2]], [:set_line_dash_pattern, [[10, 20], 25]],
               [:move_to, [95, 200]], [:line_to, [95, 0]], [:stroke_path],
               [:restore_graphics_state], [:save_graphics_state],
               [:move_to, [100, 0]], [:line_to, [0, 0]],
               [:line_to, [30, 40]], [:line_to, [90, 40]], [:clip_path_non_zero], [:end_path],
               [:set_device_gray_stroking_color, [0.5]], [:set_line_width, [40]],
               [:set_line_cap_style, [1]], [:set_line_dash_pattern, [[40, 0], 20]],
               [:move_to, [100, 20]], [:line_to, [0, 20]], [:stroke_path],
               [:restore_graphics_state], [:save_graphics_state],
               [:move_to, [0, 0]], [:line_to, [0, 200]],
               [:line_to, [30, 180]], [:line_to, [30, 40]], [:clip_path_non_zero], [:end_path],
               [:set_device_gray_stroking_color, [0.75]], [:set_line_width, [30]],
               [:set_line_cap_style, [1]], [:set_line_dash_pattern, [[0, 42.5], 27.5]],
               [:move_to, [15, 0]], [:line_to, [15, 200]], [:stroke_path],
               [:restore_graphics_state], [:restore_graphics_state]]
        assert_operators(@canvas.contents, ops)
      end

      it "works if the border is drawn on the bounds" do
        border = create_border(width: [20, 10, 40, 30], draw_on_bounds: true)
        border.draw(@canvas, 0, 0, 100, 200)
        ops = [[:save_graphics_state],
               [:save_graphics_state],
               [:move_to, [-15, 210]], [:line_to, [105, 210]],
               [:line_to, [95, 190]], [:line_to, [15, 190]], [:clip_path_non_zero], [:end_path],
               [:set_line_width, [20]],
               [:move_to, [-15, 200]], [:line_to, [105, 200]], [:stroke_path],
               [:restore_graphics_state], [:save_graphics_state],
               [:move_to, [105, 210]], [:line_to, [105, -20]],
               [:line_to, [95, 20]], [:line_to, [95, 190]], [:clip_path_non_zero], [:end_path],
               [:set_line_width, [10]],
               [:move_to, [100, 210]], [:line_to, [100, -20]], [:stroke_path],
               [:restore_graphics_state], [:save_graphics_state],
               [:move_to, [105, -20]], [:line_to, [-15, -20]],
               [:line_to, [15, 20]], [:line_to, [95, 20]], [:clip_path_non_zero], [:end_path],
               [:set_line_width, [40]],
               [:move_to, [105, 0]], [:line_to, [-15, 0]], [:stroke_path],
               [:restore_graphics_state], [:save_graphics_state],
               [:move_to, [-15, -20]], [:line_to, [-15, 210]],
               [:line_to, [15, 190]], [:line_to, [15, 20]], [:clip_path_non_zero], [:end_path],
               [:set_line_width, [30]],
               [:move_to, [0, -20]], [:line_to, [0, 210]], [:stroke_path],
               [:restore_graphics_state], [:restore_graphics_state]]
        assert_operators(@canvas.contents, ops)
      end
    end

    describe "border width greater than edge length" do
      it "works for solid borders" do
        border = create_border(width: 100, style: :solid)
        border.draw(@canvas, 0, 0, 10, 10)
        assert_operators(@canvas.contents, [[:save_graphics_state],
                                            [:set_line_width, [100]],
                                            [:append_rectangle, [0, 0, 10, 10]],
                                            [:clip_path_non_zero], [:end_path],
                                            [:append_rectangle, [50, 50, -90, -90]],
                                            [:stroke_path],
                                            [:restore_graphics_state]])
      end

      it "works for dashed borders" do
        border = create_border(width: 100, style: :dashed)
        border.draw(@canvas, 0, 0, 10, 10)
        assert_operators(@canvas.contents, [[:save_graphics_state],
                                            [:set_line_width, [100]],
                                            [:set_line_cap_style, [2]],
                                            [:append_rectangle, [0, 0, 10, 10]],
                                            [:clip_path_non_zero], [:end_path],
                                            [:set_line_dash_pattern, [[100, 0], 50]],
                                            [:move_to, [0, -40]], [:line_to, [10, -40]],
                                            [:move_to, [10, 50]], [:line_to, [0, 50]],
                                            [:stroke_path],
                                            [:move_to, [-40, 10]], [:line_to, [-40, 0]],
                                            [:move_to, [50, 0]], [:line_to, [50, 10]],
                                            [:stroke_path],
                                            [:restore_graphics_state]])
      end
      it "works for dashed-round borders" do
        border = create_border(width: 100, style: :dashed_round)
        border.draw(@canvas, 0, 0, 10, 10)
        assert_operators(@canvas.contents, [[:save_graphics_state],
                                            [:set_line_width, [100]],
                                            [:set_line_cap_style, [1]],
                                            [:append_rectangle, [0, 0, 10, 10]],
                                            [:clip_path_non_zero], [:end_path],
                                            [:set_line_dash_pattern, [[100, 0], 50]],
                                            [:move_to, [0, -40]], [:line_to, [10, -40]],
                                            [:move_to, [10, 50]], [:line_to, [0, 50]],
                                            [:stroke_path],
                                            [:move_to, [-40, 10]], [:line_to, [-40, 0]],
                                            [:move_to, [50, 0]], [:line_to, [50, 10]],
                                            [:stroke_path],
                                            [:restore_graphics_state]])
      end
      it "works for dotted borders" do
        border = create_border(width: 100, style: :dotted)
        border.draw(@canvas, 0, 0, 10, 10)
        assert_operators(@canvas.contents, [[:save_graphics_state],
                                            [:set_line_width, [100]],
                                            [:set_line_cap_style, [1]],
                                            [:append_rectangle, [0, 0, 10, 10]],
                                            [:clip_path_non_zero], [:end_path],
                                            [:set_line_dash_pattern, [[0, 1], 0]],
                                            [:move_to, [0, -40]], [:line_to, [10, -40]],
                                            [:move_to, [10, 50]], [:line_to, [0, 50]],
                                            [:stroke_path],
                                            [:move_to, [-40, 10]], [:line_to, [-40, 0]],
                                            [:move_to, [50, 0]], [:line_to, [50, 10]],
                                            [:stroke_path],
                                            [:restore_graphics_state]])
      end
    end

    it "raises an error if an invalid style is provided" do
      assert_raises(ArgumentError) do
        create_border(width: 1, color: 0, style: :unknown).draw(@canvas, 0, 0, 10, 10)
      end
    end
  end
end

describe HexaPDF::Layout::Style::Layers do
  before do
    @layers = HexaPDF::Layout::Style::Layers.new
    value = Object.new
    value.define_singleton_method(:new) {|*| :new }
    @config = Object.new
    @config.define_singleton_method(:constantize) {|*| value }
  end

  it "can be initialized with an array of layers" do
    data = [lambda {}, [:test]]
    layers = HexaPDF::Layout::Style::Layers.new(data)
    assert_equal([data[0], :new], layers.enum_for(:each, @config).to_a)
  end

  it "can be duplicated" do
    copy = @layers.dup
    @layers.add(lambda {})
    assert(copy.none?)
  end

  describe "add and each" do
    it "can use a given block" do
      block = proc { true }
      @layers.add(&block)
      assert_equal([block], @layers.enum_for(:each, {}).to_a)
    end

    it "can use a given proc" do
      block = proc { true }
      @layers.add(block)
      assert_equal([block], @layers.enum_for(:each, {}).to_a)
    end

    it "can store a reference" do
      @layers.add(:link, option: :value)
      assert_equal([:new], @layers.enum_for(:each, @config).to_a)
    end

    it "fails if neither a block nor a name is given when adding a layer" do
      assert_raises(ArgumentError) { @layers.add }
    end
  end

  it "can determine whether layers are defined" do
    assert(@layers.none?)
    @layers.add {}
    refute(@layers.none?)
  end

  it "draws the layers onto a canvas" do
    box = Object.new
    value = nil
    klass = Class.new
    klass.send(:define_method, :initialize) {|**args| @args = args }
    klass.send(:define_method, :call) do |canvas, _|
      value = @args
      canvas.line_width(5)
    end
    canvas = HexaPDF::Document.new.pages.add.canvas
    canvas.context.document.config['style.layers_map'][:test] = klass

    @layers.draw(canvas, 10, 15, box)
    @layers.add {|canv, ibox| assert_equal(box, ibox); canv.line_width(10) }
    @layers.add(:test, option: :value)
    @layers.draw(canvas, 10, 15, box)
    ops = [[:save_graphics_state],
           [:concatenate_matrix, [1, 0, 0, 1, 10, 15]],
           [:save_graphics_state],
           [:set_line_width, [10]],
           [:restore_graphics_state],
           [:save_graphics_state],
           [:set_line_width, [5]],
           [:restore_graphics_state],
           [:restore_graphics_state]]
    assert_operators(canvas.contents, ops)
    assert_equal({option: :value}, value)
  end
end

describe HexaPDF::Layout::Style::LinkLayer do
  describe "initialize" do
    it "fails if more than one possible target is chosen" do
      assert_raises(ArgumentError) { HexaPDF::Layout::Style::LinkLayer.new(dest: true, uri: true) }
      assert_raises(ArgumentError) { HexaPDF::Layout::Style::LinkLayer.new(dest: true, file: true) }
      assert_raises(ArgumentError) { HexaPDF::Layout::Style::LinkLayer.new(dest: true, action: true) }
      assert_raises(ArgumentError) { HexaPDF::Layout::Style::LinkLayer.new(uri: true, file: true) }
      assert_raises(ArgumentError) { HexaPDF::Layout::Style::LinkLayer.new(uri: true, action: true) }
      assert_raises(ArgumentError) { HexaPDF::Layout::Style::LinkLayer.new(file: true, action: true) }
    end

    it "fails if an invalid border is provided" do
      assert_raises(ArgumentError) { HexaPDF::Layout::Style::LinkLayer.new(border: 5) }
    end
  end

  describe "call" do
    before do
      @canvas = HexaPDF::Document.new.pages.add.canvas
      @canvas.translate(10, 10)
      @box = HexaPDF::Layout::Box.new(width: 15, height: 10)
    end

    def call_link(hash)
      link = HexaPDF::Layout::Style::LinkLayer.new(**hash)
      link.call(@canvas, @box)
      @canvas.context[:Annots]&.first
    end

    it "does nothing if the context is not a page object" do
      @canvas = HexaPDF::Document.new.add({Type: :XObject, Subtype: :Form, BBox: [0, 0, 1, 1]}).canvas
      assert_nil(call_link(dest: true))
    end

    it "sets general values like /Rect and /QuadPoints" do
      annot = call_link(dest: true)
      assert_equal(:Link, annot[:Subtype])
      assert_equal([10, 10, 25, 20], annot[:Rect].value)
      assert_equal([10, 10, 25, 10, 25, 20, 10, 20], annot[:QuadPoints].value)
    end

    it "removes the border by default" do
      annot = call_link(dest: true)
      assert_equal([0, 0, 0], annot[:Border].value)
    end

    it "uses a default border if no specific border style is specified" do
      annot = call_link(dest: true, border: true)
      assert_equal([0, 0, 1], annot[:Border].value)
    end

    it "uses the specified border" do
      annot = call_link(dest: true, border: [10, 10, 2])
      assert_equal([10, 10, 2], annot[:Border].value)
    end

    it "uses the specified border color" do
      annot = call_link(dest: true, border_color: "red")
      assert_equal([1.0, 0, 0], annot[:C].value)
    end

    it "works when the border color is transparent" do
      annot = call_link(dest: true, border_color: [])
      assert_equal([], annot[:C].value)
    end

    it "works for simple destinations" do
      annot = call_link(dest: [@canvas.context, :FitH])
      assert_equal([@canvas.context, :FitH], annot[:Dest].value)
      assert_nil(annot[:A])
    end

    it "works for URIs" do
      annot = call_link(uri: "test.html")
      assert_equal({S: :URI, URI: "test.html"}, annot[:A].value)
      assert_nil(annot[:Dest])
    end

    it "works for files" do
      annot = call_link(file: "local-file.pdf")
      assert_equal({S: :Launch, F: "local-file.pdf", NewWindow: true}, annot[:A].value)
      assert_nil(annot[:Dest])
    end

    it "works for actions" do
      annot = call_link(action: {Type: :Action, S: :SetOCGState})
      assert_equal({Type: :Action, S: :SetOCGState}, annot[:A].value)
      assert_nil(annot[:Dest])
    end

    it "works for destinations set via the 'link' custom box property" do
      @box.properties['link'] = [@canvas.context, :FitH]
      annot = call_link({})
      assert_equal([@canvas.context, :FitH], annot[:Dest].value)
      assert_nil(annot[:A])
    end
  end
end

describe HexaPDF::Layout::Style do
  before do
    @style = HexaPDF::Layout::Style.new
    @style.font = Object.new.tap do |obj|
      obj.define_singleton_method(:pdf_object) do
        Object.new.tap {|pdf| pdf.define_singleton_method(:glyph_scaling_factor) { 0.001 } }
      end
    end
  end

  describe "self.create" do
    it "returns the provided style argument" do
      assert_same(@style, HexaPDF::Layout::Style.create(@style))
    end

    it "creates a new Style object based on the passed hash" do
      style = HexaPDF::Layout::Style.create(font_size: 10, fill_color: 'green')
      assert_equal(10, style.font_size)
      assert_equal('green', style.fill_color)
    end

    it "creates an empty Style object if nil is passed" do
      assert_kind_of(HexaPDF::Layout::Style, HexaPDF::Layout::Style.create(nil))
    end

    it "raises an error if an invalid object is provided" do
      assert_raises(ArgumentError) { HexaPDF::Layout::Style.create(5) }
    end
  end

  it "can assign values on initialization" do
    style = HexaPDF::Layout::Style.new(font_size: 10)
    assert_equal(10, style.font_size)
  end

  describe "initialize_copy" do
    it "can be duplicated" do
      @style.font_features[:kerning] = true
      @style.padding.top = 10
      @style.margin.top = 10
      @style.border.width.top = 10
      @style.overlays.add(lambda {})
      @style.underlays.add(lambda {})

      copy = @style.dup
      @style.font_features[:kerning] = false
      @style.padding.top = 5
      @style.margin.top = 5
      @style.border.width.top = 5
      @style.overlays.add(lambda {})
      @style.underlays.add(lambda {})

      assert_equal({kerning: true}, copy.font_features)
      assert_equal(10, copy.padding.top)
      assert_equal(10, copy.margin.top)
      assert_equal(10, copy.border.width.top)
      assert_equal(1, copy.underlays.instance_variable_get(:@layers).size)
      assert_equal(1, copy.overlays.instance_variable_get(:@layers).size)
    end

    it "resets the cache" do
      @style.horizontal_scaling(200)
      assert_equal(2.0, @style.scaled_horizontal_scaling)
      assert_equal(-1.06, @style.scaled_item_width(53))

      style = @style.dup
      style.horizontal_scaling(100)
      assert_equal(2.0, @style.scaled_horizontal_scaling)
      assert_equal(-1.06, @style.scaled_item_width(53))
      assert_equal(1.0, style.scaled_horizontal_scaling)
      assert_equal(-0.53, style.scaled_item_width(53))
    end
  end

  describe "each_property" do
    it "yields all set properties with their values" do
      @style.font_size = 5
      @style.line_spacing = 1.2
      assert_equal(0.005, @style.scaled_font_size)
      assert_equal([[:font, @style.font], [:font_size, 5], [:horizontal_scaling, 100],
                    [:line_spacing, @style.line_spacing]],
                   @style.each_property.to_a.sort)
    end
  end

  describe "merge" do
    it "merges all set properties" do
      @style.font_size = 5
      @style.line_spacing = 1.2
      new_style = HexaPDF::Layout::Style.new
      new_style.update(font_size: 3, line_spacing: {type: :fixed, value: 2.5})
      new_style.merge(@style)
      assert_equal(5, new_style.font_size)
      assert_equal(:proportional, new_style.line_spacing.type)
      assert_equal(1.2, new_style.line_spacing.value)
    end
  end

  it "has several simple and dynamically generated properties with default values" do
    @style = HexaPDF::Layout::Style.new
    assert_raises(HexaPDF::Error) { @style.font }
    assert_equal(10, @style.font_size)
    assert_nil(@style.line_height)
    assert_equal(0, @style.character_spacing)
    assert_equal(0, @style.word_spacing)
    assert_equal(100, @style.horizontal_scaling)
    assert_equal(0, @style.text_rise)
    assert_equal({}, @style.font_features)
    assert_equal(HexaPDF::Content::TextRenderingMode::FILL, @style.text_rendering_mode)
    assert_equal([0], @style.fill_color.components)
    assert_equal(1, @style.fill_alpha)
    assert_equal([0], @style.stroke_color.components)
    assert_equal(1, @style.stroke_alpha)
    assert_equal(1, @style.stroke_width)
    assert_equal(HexaPDF::Content::LineCapStyle::BUTT_CAP, @style.stroke_cap_style)
    assert_equal(HexaPDF::Content::LineJoinStyle::MITER_JOIN, @style.stroke_join_style)
    assert_equal(10.0, @style.stroke_miter_limit)
    assert_equal(:left, @style.text_align)
    assert_equal(:top, @style.text_valign)
    assert_equal(0, @style.text_indent)
    assert_nil(@style.background_color)
    assert_equal(1, @style.background_alpha)
    assert(@style.padding.simple?)
    assert_equal(0, @style.padding.top)
    assert(@style.margin.simple?)
    assert_equal(0, @style.margin.top)
    assert(@style.border.none?)
    assert_equal([[], 0], @style.stroke_dash_pattern.to_operands)
    assert_equal([:proportional, 1], [@style.line_spacing.type, @style.line_spacing.value])
    refute(@style.subscript)
    refute(@style.superscript)
    refute(@style.last_line_gap)
    refute(@style.fill_horizontal)
    assert_equal(:error, @style.overflow)
    assert_kind_of(HexaPDF::Layout::Style::Layers, @style.underlays)
    assert_kind_of(HexaPDF::Layout::Style::Layers, @style.overlays)
    assert_equal(:default, @style.position)
    assert_equal(:left, @style.align)
    assert_equal(:top, @style.valign)
    assert_equal(:default, @style.mask_mode)
    assert_equal({}, @style.box_options)
  end

  it "allows using a non-standard setter for generated properties" do
    @style.padding = [5, 3]
    assert_equal(5, @style.padding.top)
    assert_equal(3, @style.padding.left)

    @style.stroke_dash_pattern(5, 2)
    assert_equal([[5], 2], @style.stroke_dash_pattern.to_operands)

    @style.line_spacing(HexaPDF::Layout::Style::LineSpacing.new(type: :double))
    assert_equal([:proportional, 2], [@style.line_spacing.type, @style.line_spacing.value])
  end

  it "allows checking for valid values" do
    error = assert_raises(ArgumentError) { @style.text_align = :none }
    assert_match(/not a valid text_align value \(:left, :center, :right, :justify\)/, error.message)
  end

  it "allows checking whether a property has been set or accessed" do
    refute(@style.text_align?)
    assert_equal(:left, @style.text_align)
    assert(@style.text_align?)

    refute(@style.text_valign?)
    @style.text_valign = :bottom
    assert(@style.text_valign?)
  end

  it "has several dynamically generated properties with default values that take blocks" do
    assert_equal(HexaPDF::Layout::TextLayouter::SimpleTextSegmentation,
                 @style.text_segmentation_algorithm)
    assert_equal(HexaPDF::Layout::TextLayouter::SimpleLineWrapping,
                 @style.text_line_wrapping_algorithm)

    block = proc { :y }
    @style.text_segmentation_algorithm(&block)
    assert_equal(block, @style.text_segmentation_algorithm)

    @style.text_segmentation_algorithm(:callable)
    assert_equal(:callable, @style.text_segmentation_algorithm)
  end

  describe "methods for some derived and cached values" do
    before do
      wrapped_font = Object.new
      wrapped_font.define_singleton_method(:ascender) { 600 }
      wrapped_font.define_singleton_method(:descender) { -100 }
      font = Object.new
      font.define_singleton_method(:scaling_factor) { 1 }
      font.define_singleton_method(:wrapped_font) { wrapped_font }
      font.define_singleton_method(:pdf_object) do
        obj = Object.new
        obj.define_singleton_method(:glyph_scaling_factor) { 0.001 }
        obj
      end
      @style.font = font
    end

    it "computes them correctly" do
      @style.horizontal_scaling(200).character_spacing(1).word_spacing(2)
      assert_equal(0.02, @style.scaled_font_size)
      assert_equal(2, @style.scaled_character_spacing)
      assert_equal(4, @style.scaled_word_spacing)
      assert_equal(2, @style.scaled_horizontal_scaling)

      assert_equal(6, @style.scaled_font_ascender)
      assert_equal(-1, @style.scaled_font_descender)
    end

    it "computes item widths correctly" do
      @style.horizontal_scaling(200).character_spacing(1).word_spacing(2)

      assert_equal(-1.0, @style.scaled_item_width(50))

      obj = Object.new
      obj.define_singleton_method(:width) { 100 }
      obj.define_singleton_method(:apply_word_spacing?) { true }
      assert_equal(8, @style.scaled_item_width(obj))
    end

    it "handles subscript" do
      @style.subscript = false
      assert_equal(10, @style.calculated_font_size)
      assert_equal(0, @style.calculated_text_rise)
      @style.subscript = true
      assert_in_delta(5.83, @style.calculated_font_size)
      assert_in_delta(0.00583, @style.scaled_font_size, 0.000001)
      assert_in_delta(-2.00, @style.calculated_text_rise)
    end

    it "handles superscript" do
      @style.superscript = false
      assert_equal(10, @style.calculated_font_size)
      assert_equal(0, @style.calculated_text_rise)
      @style.superscript = true
      assert_in_delta(5.83, @style.calculated_font_size)
      assert_in_delta(3.30, @style.calculated_text_rise)
    end

    it "handles underline" do
      @style.font.wrapped_font.define_singleton_method(:underline_position) { -100 }
      @style.font.wrapped_font.define_singleton_method(:underline_thickness) { 10 }
      @style.text_rise = 10
      assert_in_delta(-1.05 + 10, @style.calculated_underline_position)
      assert_equal(0.1, @style.calculated_underline_thickness)
    end

    it "handles strikeout" do
      @style.font.wrapped_font.define_singleton_method(:strikeout_position) { 300 }
      @style.font.wrapped_font.define_singleton_method(:strikeout_thickness) { 10 }
      @style.text_rise = 10
      assert_in_delta(2.95 + 10, @style.calculated_strikeout_position)
      assert_equal(0.1, @style.calculated_strikeout_thickness)
    end
  end

  it "can clear cached values" do
    assert_equal(0.01, @style.scaled_font_size)
    @style.font_size = 20
    assert_equal(0.01, @style.scaled_font_size)
    @style.clear_cache
    assert_equal(0.02, @style.scaled_font_size)
  end
end
