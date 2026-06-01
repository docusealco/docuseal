# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/document'
require 'hexapdf/type/annotations/markup_annotation'

describe HexaPDF::Type::Annotations::MarkupAnnotation do
  before do
    @doc = HexaPDF::Document.new
    @annot = HexaPDF::Type::Annotations::MarkupAnnotation.new({Subtype: :Text, Rect: [0, 0, 1, 1]},
                                                              document: @doc)
  end

  describe "validation" do
    it "needs IRT set if RT is set" do
      assert(@annot.validate)

      @annot[:RT] = :R
      refute(@annot.validate)
    end
  end
end
