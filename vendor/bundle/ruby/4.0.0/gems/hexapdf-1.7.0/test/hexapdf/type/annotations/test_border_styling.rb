# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/document'
require 'hexapdf/type/annotations/border_styling'

describe HexaPDF::Type::Annotations::BorderStyling do
  class TestAnnot < HexaPDF::Type::Annotation
    define_field :BS, type: :Border
    define_field :MK, type: :XXAppearanceCharacteristics
    include HexaPDF::Type::Annotations::BorderStyling
  end

  before do
    @doc = HexaPDF::Document.new
    @annot = @doc.wrap({Type: :Annot}, type: TestAnnot)
    @color = HexaPDF::Content::ColorSpace.prenormalized_device_color([1, 0, 1])
  end

  describe "border_style" do
    describe "getter" do
      it "no /Border, /BS or /C|/MK set" do
        @annot.delete(:MK)
        assert_equal([1, nil, :solid, 0, 0], @annot.border_style.to_a)
      end

      it "no /Border, /BS but with /MK empty" do
        @annot[:Subtype] = :Widget
        @annot[:MK] = {}
        assert_equal([1, nil, :solid, 0, 0], @annot.border_style.to_a)
      end

      it "uses the color from /C" do
        @annot[:C] = [1, 0, 1]
        assert_equal([1, @color, :solid, 0, 0], @annot.border_style.to_a)
        @annot[:C] = []
        assert_equal([1, nil, :solid, 0, 0], @annot.border_style.to_a)
      end

      it "uses the color from /MK" do
        @annot[:Subtype] = :Widget
        @annot[:MK] = {BC: [1, 0, 1]}
        assert_equal([1, @color, :solid, 0, 0], @annot.border_style.to_a)
        @annot[:MK][:BC] = []
        assert_equal([1, nil, :solid, 0, 0], @annot.border_style.to_a)
      end

      it "uses the data from /Border" do
        @annot[:Border] = [1, 2, 3, [1, 2]]
        assert_equal([3, nil, [1, 2], 1, 2], @annot.border_style.to_a)
      end

      it "uses the data from /BS, overriding /Border values" do
        @annot[:Border] = [1, 2, 3, [1, 2]]
        @annot[:BS] = {W: 5, S: :D, D: [5, 6]}
        assert_equal([5, nil, [5, 6], 0, 0], @annot.border_style.to_a)

        [[:S, :solid], [:D, [5, 6]], [:B, :beveled], [:I, :inset],
         [:U, :underlined], [:Unknown, :solid]].each do |val, result|
          @annot[:BS] = {S: val, D: [5, 6]}
          assert_equal([1, nil, result, 0, 0], @annot.border_style.to_a)
        end
      end
    end

    describe "setter" do
      it "returns self" do
        assert_equal(@annot, @annot.border_style(width: 1))
      end

      it "sets the color" do
        @annot.border_style(color: [1.0, 51, 1.0])
        assert_equal([1, 0.2, 1], @annot[:C])

        @annot.border_style(color: :transparent)
        assert_equal([], @annot[:C])
      end

      it "sets the color on a widget using /MK" do
        @annot[:Subtype] = :Widget
        @annot.border_style(color: [1.0, 51, 1.0])
        assert_equal([1, 0.2, 1], @annot[:MK][:BC])

        @annot.border_style(color: :transparent)
        assert_equal([], @annot[:MK][:BC])
      end

      it "sets the width" do
        @annot.border_style(width: 2)
        assert_equal(2, @annot[:BS][:W])
      end

      it "sets the style" do
        [[:solid, :S], [[5, 6], :D], [:beveled, :B], [:inset, :I], [:underlined, :U]].each do |val, r|
          @annot.border_style(style: val)
          assert_equal(r, @annot[:BS][:S])
          assert_equal(val, @annot[:BS][:D]) if r == :D
        end
      end

      it "overrides all priorly set values" do
        @annot.border_style(width: 3, style: :inset, color: [1])
        @annot.border_style(width: 5)
        border_style = @annot.border_style
        assert_equal(:solid, border_style.style)
        assert_equal([0], border_style.color.components)
      end

      it "raises an error for an unknown style" do
        assert_raises(ArgumentError) { @annot.border_style(style: :unknown) }
      end
    end
  end
end
