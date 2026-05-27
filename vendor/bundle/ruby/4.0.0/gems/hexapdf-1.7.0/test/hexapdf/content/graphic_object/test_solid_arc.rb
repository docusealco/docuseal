# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/document'
require 'hexapdf/content'
require 'hexapdf/content/graphic_object'

describe HexaPDF::Content::GraphicObject::SolidArc do
  describe "initialize" do
    it "creates a default solid arc representing the disk at the origin" do
      arc = HexaPDF::Content::GraphicObject::SolidArc.configure
      assert_equal(0, arc.cx)
      assert_equal(0, arc.cy)
      assert_equal(0, arc.inner_a)
      assert_equal(0, arc.inner_b)
      assert_equal(1, arc.outer_a)
      assert_equal(1, arc.outer_b)
      assert_equal(0, arc.start_angle)
      assert_equal(0, arc.end_angle)
      assert_equal(0, arc.inclination)
    end
  end

  describe "configure" do
    it "changes the values" do
      arc = HexaPDF::Content::GraphicObject::SolidArc.new
      arc.configure(cx: 1, cy: 2, inner_a: 3, inner_b: 4, outer_a: 5, outer_b: 6,
                    start_angle: 7, end_angle: 8, inclination: 9)
      assert_equal(1, arc.cx)
      assert_equal(2, arc.cy)
      assert_equal(3, arc.inner_a)
      assert_equal(4, arc.inner_b)
      assert_equal(5, arc.outer_a)
      assert_equal(6, arc.outer_b)
      assert_equal(7, arc.start_angle)
      assert_equal(8, arc.end_angle)
      assert_equal(9, arc.inclination)
    end
  end

  describe "draw" do
    before do
      @doc = HexaPDF::Document.new
      @doc.config['graphic_object.arc.max_curves'] = 4
      @page = @doc.pages.add
      @canvas = @page.canvas
    end

    it "draws a disk" do
      @canvas.draw(:solid_arc)
      assert_operators(@canvas.contents,
                       [:move_to, :curve_to, :curve_to, :curve_to, :curve_to, :close_subpath],
                       only_names: true)
    end

    it "draws a sector" do
      @canvas.draw(:solid_arc, end_angle: 90)
      assert_operators(@canvas.contents, [:move_to, :line_to, :curve_to, :close_subpath],
                       only_names: true)
    end

    it "draws an annulus" do
      @canvas.draw(:solid_arc, inner_a: 5, inner_b: 5)
      assert_operators(@canvas.contents,
                       [:move_to, :curve_to, :curve_to, :curve_to, :curve_to, :close_subpath,
                        :move_to, :curve_to, :curve_to, :curve_to, :curve_to, :close_subpath],
                       only_names: true)
    end

    it "draws an annular sector" do
      @canvas.draw(:solid_arc, inner_a: 5, inner_b: 5, end_angle: 90)
      assert_operators(@canvas.contents, [:move_to, :curve_to, :line_to, :curve_to, :close_subpath],
                       only_names: true)
    end
  end
end
