# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/document'
require 'hexapdf/type/annotations/border_effect'

describe HexaPDF::Type::Annotations::BorderEffect do
  class TestAnnot < HexaPDF::Type::Annotation
    define_field :BE, type: :XXBorderEffect
    include HexaPDF::Type::Annotations::BorderEffect
  end

  before do
    @doc = HexaPDF::Document.new
    @annot = @doc.wrap({Type: :Annot}, type: TestAnnot)
  end

  describe "border_effect" do
    it "returns :none if no border effect is set" do
      assert_equal(:none, @annot.border_effect)
      @annot[:BE] = {}
      assert_equal(:none, @annot.border_effect)
      @annot[:BE] = {S: :S}
      assert_equal(:none, @annot.border_effect)
      @annot[:BE] = {S: :K}
      assert_equal(:none, @annot.border_effect)
    end

    it "returns cloud(y|ier|iest) if /S is /C and depending on /I" do
      @annot[:BE] = {S: :C}
      assert_equal(:cloudy, @annot.border_effect)
      @annot[:BE][:I] = 0
      assert_equal(:cloudy, @annot.border_effect)
      @annot[:BE][:I] = 1
      assert_equal(:cloudier, @annot.border_effect)
      @annot[:BE][:I] = 2
      assert_equal(:cloudiest, @annot.border_effect)
      @annot[:BE][:I] = 3
      assert_equal(:cloudy, @annot.border_effect)
    end

    it "sets the /BE entry appropriately" do
      @annot.border_effect(:none)
      refute(@annot.key?(:BE))
      @annot.border_effect(nil)
      refute(@annot.key?(:BE))
      @annot.border_effect(:cloudy)
      assert_equal({S: :C, I: 0}, @annot[:BE])
      @annot.border_effect(:cloudier)
      assert_equal({S: :C, I: 1}, @annot[:BE])
      @annot.border_effect(:cloudiest)
      assert_equal({S: :C, I: 2}, @annot[:BE])
    end

    it "raises an error if the given type is unknown" do
      assert_raises(ArgumentError) { @annot.border_effect(:unknown) }
    end
  end
end
