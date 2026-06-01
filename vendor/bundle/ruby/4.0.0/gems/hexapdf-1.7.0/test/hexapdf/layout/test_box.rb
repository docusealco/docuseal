# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/document'
require 'hexapdf/layout/box'

describe HexaPDF::Layout::Box::FitResult do
  it "allows setting the status to failure" do
    result = HexaPDF::Layout::Box::FitResult.new(nil)
    result.overflow!
    refute(result.failure?)
    result.failure!
    assert(result.failure?)
  end

  it "shows the box's mask area on #draw when using debug output" do
    doc = HexaPDF::Document.new(config: {'debug' => true})
    canvas = doc.pages.add.canvas
    box = HexaPDF::Layout::Box.create(width: 20, height: 20) {}
    frame = HexaPDF::Layout::Frame.new(5, 10, 100, 150)
    result = HexaPDF::Layout::Box::FitResult.new(box, frame: frame)
    result.mask = Geom2D::Rectangle(0, 0, 20, 20)
    result.x = result.y = 0
    result.draw(canvas, dx: 10, dy: 15)
    assert_equal(<<~CONTENTS, canvas.contents)
      /OC /P1 BDC
      q
      1 0 0 1 10 15 cm
      0.0 0.501961 0.0 rg
      0.0 0.392157 0.0 RG
      /GS1 gs
      0 0 20 20 re
      B
      Q
      EMC
      q
      1 0 0 1 10 15 cm
      Q
    CONTENTS
    ocg = doc.optional_content.ocgs.first
    assert_equal([['Debug', ['Page 1', ocg]]], doc.optional_content.default_configuration[:Order])
    assert_match(/10,15-20x20/, ocg.name)
  end
end

describe HexaPDF::Layout::Box do
  before do
    @frame = Object.new
    def @frame.x; 0; end
    def @frame.y; 100; end
    def @frame.bottom; 40; end
    def @frame.width; 150; end
    def @frame.height; 150; end
  end

  def create_box(**args, &block)
    HexaPDF::Layout::Box.new(**args, &block)
  end

  describe "::create" do
    it "passes the block on to #initialize" do
      block = proc {}
      box = HexaPDF::Layout::Box.create(&block)
      assert_same(block, box.instance_eval { @draw_block })
    end

    it "allows specifying a style object" do
      box = HexaPDF::Layout::Box.create(style: {background_color: 20})
      assert_equal(20, box.style.background_color)
    end

    it "allows specifying style properties" do
      box = HexaPDF::Layout::Box.create(background_color: 20)
      assert_equal(20, box.style.background_color)
    end

    it "applies the additional style properties to the style object" do
      box = HexaPDF::Layout::Box.create(style: {background_color: 20}, background_color: 15)
      assert_equal(15, box.style.background_color)
    end

    it "takes content width and height" do
      box = HexaPDF::Layout::Box.create(width: 100, height: 200, content_box: true,
                                        padding: [10, 8, 6, 4],
                                        border: {width: [10, 8, 6, 4]})
      assert_equal(100, box.content_width)
      assert_equal(200, box.content_height)
    end
  end

  describe "initialize" do
    it "takes box width and height" do
      box = create_box(width: 100, height: 200)
      assert_equal(100, box.width)
      assert_equal(200, box.height)
    end

    it "allows passing a Style object or a hash" do
      box = create_box(style: {padding: 20})
      assert_equal(20, box.style.padding.top)

      box = create_box(style: HexaPDF::Layout::Style.new(padding: 20))
      assert_equal(20, box.style.padding.top)
    end

    it "allows setting custom properties" do
      assert_equal({}, create_box(properties: nil).properties)
      assert_equal({'key' => :value}, create_box(properties: {'key' => :value}).properties)
    end
  end

  it "returns false when asking whether it is a split box by default" do
    refute(create_box.split_box?)
  end

  it "doesn't support the position :flow" do
    refute(create_box.supports_position_flow?)
  end

  describe "fit" do
    it "fits a fixed sized box" do
      box = create_box(width: 50, height: 50, style: {padding: 5})
      assert(box.fit(100, 100, @frame).success?)
      assert_equal(50, box.width)
      assert_equal(50, box.height)
      assert_equal(5, box.instance_variable_get(:@fit_x))
      assert_equal(55, box.instance_variable_get(:@fit_y))
    end

    it "uses the maximum available width" do
      box = create_box(height: 50)
      assert(box.fit(100, 100, @frame).success?)
      assert_equal(100, box.width)
      assert_equal(50, box.height)
    end

    it "uses the maximum available height" do
      box = create_box(width: 50)
      assert(box.fit(100, 100, @frame).success?)
      assert_equal(50, box.width)
      assert_equal(100, box.height)
    end

    it "use the frame's width and its remaining height for position=:flow boxes" do
      box = create_box(style: {position: :flow})
      box.define_singleton_method(:supports_position_flow?) { true }
      assert(box.fit(100, 100, @frame).success?)
      assert_equal(150, box.width)
      assert_equal(60, box.height)
    end

    it "uses float comparison" do
      box = create_box(width: 50.0000002, height: 49.9999996)
      assert(box.fit(50, 50, @frame).success?)
      assert_equal(50.0000002, box.width)
      assert_equal(49.9999996, box.height)
    end

    it "works for boxes with no space for the content" do
      box = create_box(height: 1, style: {border: {width: [1, 0, 0]}})
      assert(box.fit(100, 100, @frame).success?)
      assert_equal(1, box.height)
      assert_equal(100, box.width)
    end

    it "fails if position != :flow and its width is greater than the available width" do
      box = create_box(width: 101)
      assert(box.fit(100, 100, @frame).failure?)
    end

    it "fails if position != :flow and its width is greater than the available width" do
      box = create_box(height: 101)
      assert(box.fit(100, 100, @frame).failure?)
    end

    it "fails if position != :flow and the reserved width is greater than the width" do
      box = create_box(height: 100)
      box.style.padding = [0, 100]
      assert(box.fit(150, 150, @frame).failure?)
    end

    it "fails if position != :flow and the reserved height is greater than the height" do
      box = create_box(width: 100)
      box.style.padding = [100, 0]
      assert(box.fit(150, 150, @frame).failure?)
    end

    it "can use the #update_content_width/#update_content_height helper methods" do
      box = create_box
      box.define_singleton_method(:fit_content) do |_aw, _ah, _frame|
        update_content_width { 10 }
        update_content_height { 20 }
        fit_result.success!
      end
      assert(box.fit(100, 100, @frame).success?)
      assert_equal(10, box.width)
      assert_equal(20, box.height)

      box = create_box(width: 30, height: 50)
      box.define_singleton_method(:fit_content) do |_aw, _ah, _frame|
        update_content_width { 10 }
        update_content_height { 20 }
        fit_result.success!
      end
      assert(box.fit(100, 100, @frame).success?)
      assert_equal(30, box.width)
      assert_equal(50, box.height)
    end
  end

  describe "split" do
    it "doesn't need to be split if it completely fits" do
      box = create_box(width: 100, height: 100)
      box.fit(100, 100, @frame)
      assert_equal([box, nil], box.split)
    end

    it "is not split if no part of it fits" do
      box = create_box(width: 150)
      box.fit(100, 100, @frame)
      assert_equal([nil, box], box.split)
    end

    it "is not split if a height for the box is specified and it doesn't completely fit" do
      box = create_box(height: 50)
      box.define_singleton_method(:fit_content) {|*| fit_result.overflow! }
      box.fit(100, 100, @frame)
      assert_equal([box, nil], box.split)
    end

    it "can't be split if it doesn't completely fit as the default implementation " \
      "knows nothing about the content" do
      box = create_box
      box.define_singleton_method(:fit_content) {|*| fit_result.overflow! }
      box.fit(100, 100, @frame)
      assert_equal([nil, box], box.split)
    end
  end

  it "can create a cloned box for splitting" do
    box = create_box
    box.fit(100, 100, @frame)
    cloned_box = box.send(:create_split_box)
    assert(cloned_box.split_box?)
    refute_same(box.fit_result, cloned_box.fit_result)
    assert_equal(0, cloned_box.width)
    assert_equal(0, cloned_box.height)
  end

  describe "draw" do
    before do
      @canvas = HexaPDF::Document.new.pages.add.canvas
    end

    it "draws the box onto the canvas" do
      box = create_box(width: 150, height: 130) do |canvas, _|
        canvas.line_width(15)
      end
      box.style.background_color = 0.5
      box.style.background_alpha = 0.5
      box.style.border(width: 5)
      box.style.padding([10, 20])
      box.style.underlays.add {|canvas, _| canvas.line_width(10) }
      box.style.overlays.add {|canvas, _| canvas.line_width(20) }

      box.draw(@canvas, 5, 5)
      assert_operators(@canvas.contents, [[:save_graphics_state],
                                          [:set_graphics_state_parameters, [:GS1]],
                                          [:set_device_gray_non_stroking_color, [0.5]],
                                          [:append_rectangle, [5, 5, 150, 130]],
                                          [:fill_path_non_zero],
                                          [:restore_graphics_state],
                                          [:save_graphics_state],
                                          [:concatenate_matrix, [1, 0, 0, 1, 5, 5]],
                                          [:save_graphics_state],
                                          [:set_line_width, [10]],
                                          [:restore_graphics_state],
                                          [:restore_graphics_state],
                                          [:save_graphics_state],
                                          [:set_line_width, [5]],
                                          [:append_rectangle, [7.5, 7.5, 145, 125]],
                                          [:stroke_path],
                                          [:restore_graphics_state],
                                          [:save_graphics_state],
                                          [:concatenate_matrix, [1, 0, 0, 1, 30, 20]],
                                          [:set_line_width, [15]],
                                          [:restore_graphics_state],
                                          [:save_graphics_state],
                                          [:concatenate_matrix, [1, 0, 0, 1, 5, 5]],
                                          [:save_graphics_state],
                                          [:set_line_width, [20]],
                                          [:restore_graphics_state],
                                          [:restore_graphics_state]])
    end

    it "draws nothing onto the canvas if the box is empty" do
      box = create_box
      box.draw(@canvas, 5, 5)
      assert_operators(@canvas.contents, [])
      refute(box.style.background_color?)
      refute(box.style.underlays?)
      refute(box.style.border?)
      refute(box.style.overlays?)
    end

    it "raises an error if the style property :overflow is set to error and the box doesn't completely fit" do
      box = create_box(height: 50, style: {overflow: :error})
      box.fit_result.overflow!
      assert_raises(HexaPDF::Error) { box.draw(@canvas, 0, 0) }
    end

    it "wraps the box in optional content markers if the optional_content property is set" do
      box = create_box(properties: {'optional_content' => 'Text'})
      box.draw(@canvas, 0, 0)
      assert_operators(@canvas.contents, [[:begin_marked_content_with_property_list, [:OC, :P1]],
                                          [:end_marked_content]])
    end
  end

  describe "empty?" do
    it "is empty when no drawing operation is specified" do
      assert(create_box.empty?)
      refute(create_box {}.empty?)
      refute(create_box(style: {background_color: [5]}).empty?)
      refute(create_box(style: {border: {width: 1}}).empty?)
      refute(create_box(style: {underlays: [proc {}]}).empty?)
      refute(create_box(style: {overlays: [proc {}]}).empty?)
    end
  end
end
