# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/document'
require 'hexapdf/content'
require 'hexapdf/content/graphic_object'

describe HexaPDF::Content::GraphicObject::Geom2D do
  before do
    @obj = HexaPDF::Content::GraphicObject::Geom2D.new
  end

  it "allows creation via the ::configure method" do
    obj = HexaPDF::Content::GraphicObject::Geom2D.configure(object: Geom2D::Point(5, 5))
    assert_equal(Geom2D::Point(5, 5), obj.object)
  end

  it "creates a default Geom2D drawing support object" do
    obj = HexaPDF::Content::GraphicObject::Geom2D.new
    assert_nil(obj.object)
    assert_equal(1, obj.point_radius)
    assert_equal(false, obj.path_only)
  end

  it "allows configuration of the object" do
    @obj.configure(object: Geom2D::Point(5, 5), point_radius: 3, path_only: true)
    assert_equal(Geom2D::Point(5, 5), @obj.object)
    assert_equal(3, @obj.point_radius)
    assert_equal(true, @obj.path_only)
  end

  describe "draw" do
    before do
      doc = HexaPDF::Document.new
      @canvas = doc.pages.add.canvas
    end

    it "draws a Geom2D::Point onto the canvas" do
      @obj.object = Geom2D::Point(5, 5)
      @obj.draw(@canvas)
      assert_operators(@canvas.contents,
                       [:move_to, :curve_to, :curve_to, :curve_to, :curve_to, :curve_to, :curve_to,
                        :close_subpath, :fill_path_non_zero],
                       only_names: true)
    end

    it "draws a Geom2D::Segment onto the canvas" do
      @obj.object = Geom2D::Segment([5, 6], [10, 11])
      @obj.draw(@canvas)
      assert_operators(@canvas.contents,
                       [[:move_to, [5, 6]], [:line_to, [10, 11]], [:stroke_path]])
    end

    it "draws a Geom2D::Rectangle onto the canvas" do
      @obj.object = Geom2D::Rectangle(5, 6, 20, 50)
      @obj.draw(@canvas)
      assert_operators(@canvas.contents,
                       [[:append_rectangle, [5, 6, 20, 50]], [:stroke_path]])
    end

    it "draws a Geom2D::Polygon onto the canvas" do
      @obj.object = Geom2D::Polygon([5, 6], [10, 11], [7, 9])
      @obj.draw(@canvas)
      assert_operators(@canvas.contents,
                       [[:move_to, [5, 6]], [:line_to, [10, 11]], [:line_to, [7, 9]],
                        [:close_subpath], [:stroke_path]])
    end

    it "draws a Geom2D::PolygonSet onto the canvas" do
      @obj.object = Geom2D::PolygonSet(Geom2D::Polygon([5, 6], [10, 11], [7, 9]),
                                       Geom2D::Polygon([0, 0], [4, 0], [2, 3]))
      @obj.draw(@canvas)
      assert_operators(@canvas.contents,
                       [[:move_to, [5, 6]], [:line_to, [10, 11]], [:line_to, [7, 9]],
                        [:close_subpath],
                        [:move_to, [0, 0]], [:line_to, [4, 0]], [:line_to, [2, 3]],
                        [:close_subpath], [:stroke_path]])
    end

    it "fails for unkown classes" do
      @obj.object = 5
      assert_raises(HexaPDF::Error) { @obj.draw(@canvas) }
    end
  end
end
