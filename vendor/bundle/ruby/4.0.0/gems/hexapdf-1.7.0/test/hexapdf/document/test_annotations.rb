# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/document'

describe HexaPDF::Document::Annotations do
  before do
    @doc = HexaPDF::Document.new
    @page = @doc.pages.add
    @annots = @doc.annotations
  end

  describe "create" do
    it "fails if the type argument doesn't refer to an implemented method" do
      assert_raises(ArgumentError) { @annots.create(:unknown, @page) }
    end

    it "delegates to the actual create_TYPE implementation" do
      annot = @annots.create(:line, @page, start_point: [0, 0], end_point: [10, 10])
      assert_equal(:Line, annot[:Subtype])
      annot = @annots.create(:rectangle, @page, 10, 20, 30, 40)
      assert_equal(:Square, annot[:Subtype])
    end
  end

  describe "create_line" do
    it "creates an appropriate line annotation object" do
      annot = @annots.create(:line, @page, start_point: [0, 5], end_point: [10, 15])
      assert_equal(:Annot, annot[:Type])
      assert_equal(:Line, annot[:Subtype])
      assert_equal([0, 5, 10, 15], annot.line)
      assert_equal(annot, @page[:Annots].first)
    end
  end

  describe "create_rectangle" do
    it "creates an appropriate square annotation object" do
      annot = @annots.create(:rectangle, @page, 10, 20, 30, 40)
      assert_equal(:Annot, annot[:Type])
      assert_equal(:Square, annot[:Subtype])
      assert_equal([10, 20, 40, 60], annot[:Rect])
      assert_equal(annot, @page[:Annots].first)
    end
  end

  describe "create_ellipse" do
    it "creates an appropriate circle annotation object" do
      annot = @annots.create(:ellipse, @page, 100, 100, a: 30, b: 40)
      assert_equal(:Annot, annot[:Type])
      assert_equal(:Circle, annot[:Subtype])
      assert_equal([70, 60, 130, 140], annot[:Rect])
      assert_equal(annot, @page[:Annots].first)
    end
  end

  describe "create_polyline" do
    it "creates an appropriate polyline annotation object" do
      annot = @annots.create(:polyline, @page, 10, 10, 20, 15)
      assert_equal(:Annot, annot[:Type])
      assert_equal(:PolyLine, annot[:Subtype])
      assert_equal([10, 10, 20, 15], annot.vertices)
      assert_equal(annot, @page[:Annots].first)
    end
  end

  describe "create_polygon" do
    it "creates an appropriate polygon annotation object" do
      annot = @annots.create(:polygon, @page, 10, 10, 20, 15)
      assert_equal(:Annot, annot[:Type])
      assert_equal(:Polygon, annot[:Subtype])
      assert_equal([10, 10, 20, 15], annot.vertices)
      assert_equal(annot, @page[:Annots].first)
    end
  end
end
