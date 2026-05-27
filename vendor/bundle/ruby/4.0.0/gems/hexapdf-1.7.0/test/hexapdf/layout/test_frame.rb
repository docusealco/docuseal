# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/layout/frame'
require 'hexapdf/layout/box'
require 'hexapdf/document'

describe HexaPDF::Layout::Frame do
  before do
    @frame = HexaPDF::Layout::Frame.new(5, 10, 100, 150)
  end

  it "allows accessing the context's document" do
    assert_nil(@frame.document)
    context = Minitest::Mock.new
    context.expect(:document, :document)
    assert_equal(:document, HexaPDF::Layout::Frame.new(0, 0, 10, 10, context: context).document)
    context.verify
  end

  it "allows access to the bounding box attributes" do
    assert_equal(5, @frame.left)
    assert_equal(10, @frame.bottom)
    assert_equal(100, @frame.width)
    assert_equal(150, @frame.height)
  end

  it "allows access to the current region attributes" do
    assert_equal(5, @frame.x)
    assert_equal(160, @frame.y)
    assert_equal(100, @frame.available_width)
    assert_equal(150, @frame.available_height)
  end

  it "allows access to the frame's parent boxes" do
    frame = HexaPDF::Layout::Frame.new(5, 10, 100, 150, parent_boxes: [:a])
    assert_equal([:a], frame.parent_boxes)
  end

  it "allows setting the shape of the frame on initialization" do
    shape = Geom2D::Polygon([50, 10], [55, 100], [105, 100], [105, 10])
    frame = HexaPDF::Layout::Frame.new(5, 10, 100, 150, shape: shape)
    assert_equal(shape, frame.shape)
    assert_equal(55, frame.x)
    assert_equal(100, frame.y)
    assert_equal(50, frame.available_width)
    assert_equal(90, frame.available_height)
  end

  describe "child_frame" do
    before do
      @frame = HexaPDF::Layout::Frame.new(10, 10, 100, 100, parent_boxes: [:a])
    end

    it "duplicates the frame setting the parent boxes appropriately" do
      assert_same(@frame.parent_boxes, @frame.child_frame.parent_boxes)
      frame = @frame.child_frame(box: :b)
      assert_equal([:a, :b], frame.parent_boxes)
    end

    it "creates a new frame, optionally adding a parent box" do
      shape = Geom2D::Rectangle(0, 0, 20, 20)
      frame = @frame.child_frame(0, 0, 20, 20, shape: shape)
      assert_same(@frame.parent_boxes, frame.parent_boxes)
      assert_equal(shape, frame.shape)
      frame = @frame.child_frame(0, 0, 20, 20, box: :b)
      assert_equal([:a, :b], frame.parent_boxes)
    end
  end

  it "returns an appropriate width specification object" do
    ws = @frame.width_specification(10)
    assert_kind_of(HexaPDF::Layout::WidthFromPolygon, ws)
  end

  describe "fit and draw" do
    before do
      @frame = HexaPDF::Layout::Frame.new(10, 10, 100, 100)
      @canvas = Minitest::Mock.new
      def @canvas.context
        Object.new.tap do |ctx|
          def ctx.document; Object.new.tap {|doc| def doc.config; Hash.new(false); end } end
        end
      end
    end

    # Creates a box with the given option, storing it in @box, and draws it inside @frame. It is
    # checked whether the box coordinates are pos and whether the frame has the shape given by
    # points.
    def check_box(box_opts, pos, mask, points)
      flow_supported = !box_opts.delete(:doesnt_support_position_flow)
      @box = HexaPDF::Layout::Box.create(**box_opts) {}
      @box.define_singleton_method(:supports_position_flow?) { true } if flow_supported
      @canvas.expect(:translate, nil, pos)
      fit_result = @frame.fit(@box)
      refute_nil(fit_result)
      assert_same(@frame, fit_result.frame)
      @frame.draw(@canvas, fit_result)
      assert_equal(mask, fit_result.mask.bbox.to_a)
      if @frame.shape.respond_to?(:polygons)
        assert_equal(points, @frame.shape.polygons.map(&:to_a))
      else
        assert_equal(points, [@frame.shape.to_a])
      end
      @canvas.verify
    end

    # Removes a 10pt area from the :left, :right or :top.
    def remove_area(*areas)
      areas.each do |area|
        @frame.remove_area(
          case area
          when :left then Geom2D::Rectangle(10, 10, 10, 100)
          when :right then Geom2D::Rectangle(100, 10, 10, 100)
          when :top then Geom2D::Rectangle(10, 100, 100, 10)
          when :bottom then Geom2D::Rectangle(10, 10, 100, 10)
          end
        )
      end
    end

    it "fails if an unkown position value is provided" do
      box = HexaPDF::Layout::Box.create(position: :unknown)
      exception = assert_raises(HexaPDF::Error) { @frame.fit(box) }
      assert_match(/Invalid value 'unknown'/, exception.message)
    end

    describe "absolute position" do
      it "draws the box at the given absolute position" do
        check_box(
          {width: 50, height: 50, position: [10, 10]},
          [20, 20],
          [20, 20, 70, 70],
          [[[10, 10], [110, 10], [110, 110], [10, 110]],
           [[20, 20], [70, 20], [70, 70], [20, 70]]]
        )
      end

      it "determines the available space for #fit by using the space to the right and above" do
        check_box(
          {position: [10, 10]},
          [20, 20],
          [20, 20, 110, 110],
          [[[10, 10], [110, 10], [110, 20], [20, 20], [20, 110], [10, 110]]]
        )
      end
    end

    describe "default position" do
      it "draws the box on the left side" do
        check_box({width: 50, height: 50},
                  [10, 60],
                  [10, 60, 110, 110],
                  [[[10, 10], [110, 10], [110, 60], [10, 60]]])
      end

      it "draws the box on the right side" do
        check_box({width: 50, height: 50, align: :right},
                  [60, 60],
                  [10, 60, 110, 110],
                  [[[10, 10], [110, 10], [110, 60], [10, 60]]])
      end

      it "draws the box in the center" do
        check_box({width: 50, height: 50, align: :center},
                  [35, 60],
                  [10, 60, 110, 110],
                  [[[10, 10], [110, 10], [110, 60], [10, 60]]])
      end

      it "draws the box vertically in the center" do
        check_box({width: 50, height: 50, valign: :center},
                  [10, 35],
                  [10, 35, 110, 110],
                  [[[10, 10], [110, 10], [110, 35], [10, 35]]])
      end

      it "draws the box vertically at the bottom" do
        check_box({width: 50, height: 50, valign: :bottom},
                  [10, 10], [10, 10, 110, 110], [])
      end

      describe "with margin" do
        [:left, :center, :right].each do |hint|
          it "ignores all margins if the box fills the whole frame, with alignment #{hint}" do
            check_box({margin: 10, align: hint},
                      [10, 10], [10, 10, 110, 110], [])
            assert_equal(100, @box.width)
            assert_equal(100, @box.height)
          end

          it "ignores the left/top/right margin if the available bounds coincide with the " \
            "frame's, with alignment #{hint}" do
            check_box({height: 50, margin: 10, align: hint},
                      [10, 60],
                      [10, 50, 110, 110],
                      [[[10, 10], [110, 10], [110, 50], [10, 50]]])
          end

          it "doesn't ignore top margin if the available bounds' top doesn't coincide with the " \
            "frame's top, with alignment #{hint}" do
            remove_area(:top)
            check_box({height: 50, margin: 10, align: hint},
                      [10, 40],
                      [10, 30, 110, 100],
                      [[[10, 10], [110, 10], [110, 30], [10, 30]]])
            assert_equal(100, @box.width)
          end

          it "doesn't ignore left margin if the available bounds' left doesn't coincide with the " \
            "frame's left, with alignment #{hint}" do
            remove_area(:left)
            check_box({height: 50, margin: 10, align: hint},
                      [30, 60],
                      [10, 50, 110, 110],
                      [[[20, 10], [110, 10], [110, 50], [20, 50]]])
            assert_equal(80, @box.width)
          end

          it "doesn't ignore right margin if the available bounds' right doesn't coincide with " \
            "the frame's right, with alignment #{hint}" do
            remove_area(:right)
            check_box({height: 50, margin: 10, align: hint},
                      [10, 60],
                      [10, 50, 110, 110],
                      [[[10, 10], [100, 10], [100, 50], [10, 50]]])
            assert_equal(80, @box.width)
          end
        end

        [:top, :center, :bottom].each do |hint|
          it "ignores all margins if the box fills the whole frame, with vertical alignment #{hint}" do
            check_box({margin: 10, valign: hint},
                      [10, 10], [10, 10, 110, 110], [])
            assert_equal(100, @box.width)
            assert_equal(100, @box.height)
          end

          it "ignores the left/top/bottom margin if the available bounds coincide with the " \
            "frame's, with vertical alignment #{hint}" do
            check_box({width: 50, margin: 10, valign: hint},
                      [10, 10], [10, 10, 110, 110], [])
            assert_equal(100, @box.height)
          end

          it "doesn't ignore top margin if the available bounds' top doesn't coincide with the " \
            "frame's top, with vertical alignment #{hint}" do
            remove_area(:top)
            check_box({width: 50, margin: 10, valign: hint},
                      [10, 10], [10, 10, 110, 100], [])
            assert_equal(80, @box.height)
          end

          it "doesn't ignore left margin if the available bounds' left doesn't coincide with the " \
            "frame's left, with vertical alignment #{hint}" do
            remove_area(:left)
            check_box({width: 50, margin: 10, valign: hint},
                      [30, 10], [10, 10, 110, 110], [])
            assert_equal(100, @box.height)
          end

          it "doesn't ignore bottom margin if the available bounds' bottom doesn't coincide with " \
            "the frame's bottom, with vertical alignment #{hint}" do
            remove_area(:bottom)
            check_box({width: 50, margin: 10, valign: hint},
                      [10, 30], [10, 20, 110, 110], [])
            assert_equal(80, @box.height)
          end
        end

        it "perfectly centers a box horizontally if possible, margins ignored" do
          check_box({width: 50, height: 10, margin: [10, 10, 10, 20], align: :center},
                    [35, 100],
                    [10, 90, 110, 110],
                    [[[10, 10], [110, 10], [110, 90], [10, 90]]])
        end

        it "perfectly centers a box horizontally if possible, margins not ignored" do
          remove_area(:left, :right)
          check_box({width: 40, height: 10, margin: [10, 10, 10, 20], align: :center},
                    [40, 100],
                    [10, 90, 110, 110],
                    [[[20, 10], [100, 10], [100, 90], [20, 90]]])
        end

        it "horizontally centers a box as good as possible when margins aren't equal" do
          remove_area(:left, :right)
          check_box({width: 20, height: 10, margin: [10, 10, 10, 40], align: :center},
                    [65, 100],
                    [10, 90, 110, 110],
                    [[[20, 10], [100, 10], [100, 90], [20, 90]]])
        end

        it "perfectly centers a box vertically if possible, margins ignored" do
          check_box({width: 10, height: 50, margin: [10, 10, 20, 10], valign: :center},
                    [10, 35],
                    [10, 15, 110, 110],
                    [[[10, 10], [110, 10], [110, 15], [10, 15]]])
        end

        it "perfectly centers a box vertically if possible, margins not ignored" do
          remove_area(:top, :bottom)
          check_box({width: 10, height: 40, margin: [10, 10, 20, 10], valign: :center},
                    [10, 40], [10, 20, 110, 100], [])
        end

        it "vertically centers a box as good as possible when margins aren't equal" do
          remove_area(:top, :bottom)
          check_box({width: 10, height: 20, margin: [10, 10, 40, 10], valign: :center},
                    [10, 65],
                    [10, 25, 110, 100],
                    [[[10, 20], [110, 20], [110, 25], [10, 25]]])
        end
      end
    end

    describe "flowing boxes" do
      it "flows inside the frame's outline" do
        remove_area(:left)
        check_box({width: 10, height: 20, margin: 10, position: :flow},
                  [10, 90],
                  [10, 80, 110, 110],
                  [[[20, 10], [110, 10], [110, 80], [20, 80]]])
        assert_equal(10, @box.fit_result.x)
      end

      it "doesn't overwrite fit_result.x" do
        box = HexaPDF::Layout::Box.create(position: :flow) {}
        box.define_singleton_method(:supports_position_flow?) { true }
        box.define_singleton_method(:fit_content) {|*args| fit_result.x = 30; super(*args) }
        fit_result = @frame.fit(box)
        assert_equal(30, fit_result.x)
      end

      it "uses position=default if the box indicates it doesn't support flowing contents" do
        check_box({width: 10, height: 20, margin: 10, position: :flow, doesnt_support_position_flow: true},
                  [10, 90],
                  [10, 80, 110, 110],
                  [[[10, 10], [110, 10], [110, 80], [10, 80]]])
      end
    end

    describe "mask mode" do
      describe "none" do
        it "doesn't remove any area" do
          check_box({width: 50, height: 50, mask_mode: :none},
                    [10, 60],
                    [10, 60, 10, 60],
                    [[[10, 10], [110, 10], [110, 110], [10, 110]]])
        end
      end

      describe "box" do
        it "removes the box area" do
          check_box({width: 50, height: 50, mask_mode: :box},
                    [10, 60],
                    [10, 60, 60, 110],
                    [[[10, 10], [110, 10], [110, 110], [60, 110], [60, 60], [10, 60]]])
        end

        it "ignores the margin if sides are on the frame border" do
          check_box({margin: 10, mask_mode: :box},
                    [10, 10], [10, 10, 110, 110], [])
        end

        it "uses the margin if sides are not on the frame border" do
          remove_area(:left, :right, :top, :bottom)
          check_box({margin: 10, mask_mode: :box},
                    [30, 30], [20, 20, 100, 100], [])
        end
      end

      describe "fill_horizontal" do
        it "removes the horizontal part to the bottom of the box in the current region" do
          remove_area(:left, :right)
          check_box({width: 50, height: 50, mask_mode: :fill_horizontal},
                    [20, 60],
                    [20, 60, 100, 110],
                    [[[20, 10], [100, 10], [100, 60], [20, 60]]])
        end

        it "respects the top and bottom margins for the mask" do
          remove_area(:top, :bottom)
          check_box({width: 50, margin: 10, mask_mode: :fill_horizontal},
                    [10, 30], [10, 20, 110, 100], [])
        end
      end

      describe "fill_frame_horizontal" do
        it "removes the horizontal part to the bottom of the box in the frame" do
          remove_area(:left, :right)
          check_box({width: 50, height: 50, mask_mode: :fill_frame_horizontal},
                    [20, 60],
                    [10, 60, 110, 110],
                    [[[20, 10], [100, 10], [100, 60], [20, 60]]])
        end

        it "respects the bottom margin for the mask" do
          remove_area(:left, :right, :top, :bottom)
          check_box({width: 50, margin: 10, mask_mode: :fill_frame_horizontal},
                    [30, 30], [10, 20, 110, 100], [])
        end
      end

      describe "fill_vertical" do
        it "removes the vertical part covering the box in the current region" do
          check_box({width: 50, height: 50, mask_mode: :fill_vertical, align: :center},
                    [35, 60],
                    [35, 10, 85, 110],
                    [[[10, 10], [35, 10], [35, 110], [10, 110]],
                     [[85, 10], [110, 10], [110, 110], [85, 110]]])
        end

        it "respects the left and right margins for the mask" do
          check_box({width: 50, height: 50, margin: 10, mask_mode: :fill_vertical, align: :center},
                    [35, 60],
                    [25, 10, 95, 110],
                    [[[10, 10], [25, 10], [25, 110], [10, 110]],
                     [[95, 10], [110, 10], [110, 110], [95, 110]]])
        end
      end

      describe "fill" do
        it "removes the current region completely" do
          check_box({width: 50, height: 50, mask_mode: :fill},
                    [10, 60], [10, 10, 110, 110], [])
        end
      end
    end

    it "can't fit the box if there is no available space" do
      @frame.remove_area(Geom2D::Rectangle(0, 0, 110, 110))
      box = HexaPDF::Layout::Box.create
      refute(@frame.fit(box).success?)
    end

    it "doesn't do post-fitting tasks if fitting is a failure" do
      box = HexaPDF::Layout::Box.create(width: 400)
      result = @frame.fit(box)
      assert(result.failure?)
      assert_nil(result.x)
      assert_nil(result.y)
      assert_nil(result.mask)
    end
  end

  describe "split" do
    it "splits the box if necessary" do
      box = HexaPDF::Layout::Box.create(width: 10, height: 10)
      assert_equal([box, nil], @frame.split(@frame.fit(box)))
    end
  end

  describe "find_next_region" do
    # Checks all availability regions of the frame
    def check_regions(frame, regions)
      regions.each_with_index do |region, index|
        assert_equal(region[0], frame.x, "region #{index} invalid x")
        assert_equal(region[1], frame.y, "region #{index} invalid y")
        assert_equal(region[2], frame.available_width, "region #{index} invalid available width")
        assert_equal(region[3], frame.available_height, "region #{index} invalid available height")
        frame.find_next_region
      end
      assert_equal(0, frame.x)
      assert_equal(0, frame.y)
      assert_equal(0, frame.available_width)
      assert_equal(0, frame.available_height)
    end

    # o------+
    # |      |
    # |      |
    # |      |
    # +------+
    it "works for a rectangular region" do
      frame = HexaPDF::Layout::Frame.new(0, 0, 100, 300)
      check_regions(frame, [[0, 300, 100, 300]])
    end

    # o--------+
    # |        |
    # |  +--+  |
    # |  |  |  |
    # |  +--+  |
    # |        |
    # +--------+
    it "works for a region with a hole" do
      frame = HexaPDF::Layout::Frame.new(0, 0, 100, 100)
      frame.remove_area(Geom2D::Rectangle(20, 20, 60, 60))
      check_regions(frame, [[0, 100, 100, 20], [0, 100, 20, 100],
                            [0, 80, 20, 80], [0, 20, 100, 20]])
    end

    # o--+  +--+
    # |  |  |  |
    # |  +--+  |
    # |        |
    # +--------+
    it "works for a u-shaped frame" do
      frame = HexaPDF::Layout::Frame.new(0, 0, 100, 100)
      frame.remove_area(Geom2D::Rectangle(30, 60, 40, 40))
      check_regions(frame, [[0, 100, 30, 100], [0, 60, 100, 60]])
    end

    # o---+     +--+
    # |   |  +--+  |
    # |   +--+     |
    # |            |
    # +----+       |
    # +----+       |
    # |            |
    # +------------+
    it "works for a complicated frame" do
      frame = HexaPDF::Layout::Frame.new(0, 0, 100, 100)
      top_cut = Geom2D::Polygon([20, 100], [20, 80], [40, 80], [40, 90], [60, 90], [60, 100])
      left_cut = Geom2D::Rectangle(0, 20, 30, 20)
      frame.remove_area(Geom2D::PolygonSet(top_cut, left_cut))

      check_regions(frame, [[0, 100, 20, 60], [0, 90, 20, 50], [0, 80, 100, 40],
                            [30, 80, 70, 80], [0, 20, 100, 20]])
    end
  end
end
