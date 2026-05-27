# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/document'
require 'hexapdf/type/annotations/polygon_polyline'

describe HexaPDF::Type::Annotations::PolygonPolyline do
  before do
    @doc = HexaPDF::Document.new
    @annot = @doc.add({Type: :Annot, Subtype: :Polyline, Rect: [0, 0, 0, 0]},
                      type: HexaPDF::Type::Annotations::PolygonPolyline)
  end

  describe "vertices" do
    it "returns the coordinates of the vertices" do
      @annot[:Vertices] = [10, 20, 30, 40, 50, 60]
      assert_equal([10, 20, 30, 40, 50, 60], @annot.vertices)
    end

    it "sets the vertices" do
      assert_same(@annot, @annot.vertices(1, 2, 3, 4, 5, 6))
      assert_equal([1, 2, 3, 4, 5, 6], @annot[:Vertices])
    end

    it "raises an ArgumentError if an uneven number of arguments is provided" do
      assert_raises(ArgumentError) { @annot.vertices(1, 2, 3) }
    end
  end
end
