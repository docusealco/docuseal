# -*- encoding: utf-8 -*-

require 'test_helper'
require 'geom2d/polygon'
require 'hexapdf/layout/box_fitter'
require 'hexapdf/layout'

describe HexaPDF::Layout::BoxFitter do
  before do
    shape = Geom2D::Polygon([0, 0], [100, 0], [100, 90], [10, 90], [10, 80], [0, 80])
    frames = [
      HexaPDF::Layout::Frame.new(0, 0, 100, 100, shape: shape),
      HexaPDF::Layout::Frame.new(100, 100, 50, 50),
    ]
    @box_fitter = HexaPDF::Layout::BoxFitter.new(frames)
  end

  def fit_box(count, width: 10, height: 10)
    ibox = HexaPDF::Layout::InlineBox.create(width: width, height: height) {}
    @box_fitter.fit(HexaPDF::Layout::TextBox.new(items: [ibox] * count))
  end

  def check_result(*pos, content_heights:, success: true, boxes_remain: false)
    pos.each_slice(2).with_index do |(x, y), index|
      assert_equal(x, @box_fitter.fit_results[index].x, "x #{index}")
      assert_equal(y, @box_fitter.fit_results[index].y, "y #{index}")
    end
    assert_equal(content_heights, @box_fitter.content_heights)
    success ? assert(@box_fitter.success?) : refute(@box_fitter.success?)
    rboxes = @box_fitter.remaining_boxes.empty?
    boxes_remain ? refute(rboxes) : assert(rboxes)
  end

  it "successfully places boxes only in one frame" do
    fit_box(20)
    fit_box(20)
    check_result(10, 60, 0, 40, content_heights: [50, 0])
  end

  it "successfully places boxes in multiple frames, without splitting" do
    fit_box(1, height: 80)
    fit_box(1, height: 40)
    check_result(10, 10, 100, 110, content_heights: [80, 40])
  end

  it "successfully places boxes in multiple framess, with splitting" do
    fit_box(63)
    fit_box(30)
    fit_box(10)
    check_result(10, 20, 0, 0, 100, 130, 100, 110, content_heights: [90, 40])
  end

  it "correctly handles truncated boxes" do
    box = HexaPDF::Layout::Box.new(height: 50) {}
    box.define_singleton_method(:fit_content) {|*| fit_result.overflow! }
    @box_fitter.fit(box)
    check_result(10, 40, content_heights: [50, 0])
  end

  it "fails when some boxes can't be fitted" do
    fit_box(9)
    fit_box(70)
    fit_box(40)
    fit_box(20)
    check_result(10, 80, 0, 10, 0, 0, 100, 100, success: false, boxes_remain: true,
                 content_heights: [90, 50])
    assert_equal(2, @box_fitter.remaining_boxes.size)
  end
end
