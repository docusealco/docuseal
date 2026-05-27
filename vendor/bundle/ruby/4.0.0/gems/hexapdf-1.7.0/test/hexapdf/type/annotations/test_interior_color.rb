# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/document'
require 'hexapdf/type/annotations/interior_color'

describe HexaPDF::Type::Annotations::InteriorColor do
  class TestAnnot < HexaPDF::Type::Annotation
    define_field :IC, type: HexaPDF::PDFArray
    include HexaPDF::Type::Annotations::InteriorColor
  end

  before do
    @doc = HexaPDF::Document.new
    @annot = @doc.wrap({Type: :Annot}, type: TestAnnot)
  end

  describe "interior_color" do
    it "returns the interior color" do
      assert_nil(@annot.interior_color)
      @annot[:IC] = []
      assert_nil(@annot.interior_color)
      @annot[:IC] = [0.5]
      assert_equal(HexaPDF::Content::ColorSpace.device_color_from_specification(0.5),
                   @annot.interior_color)
    end

    it "sets the interior color" do
      @annot.interior_color(255)
      assert_equal([1.0], @annot[:IC])
      @annot.interior_color(255, 255, 0)
      assert_equal([1.0, 1.0, 0], @annot[:IC])
      @annot.interior_color(:transparent)
      assert_equal([], @annot[:IC])
    end
  end
end
