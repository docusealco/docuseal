# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/document'

describe HexaPDF::Layout::Line::HeightCalculator do
  before do
    @calc = HexaPDF::Layout::Line::HeightCalculator.new
  end

  it "simulate the height as if an item was added" do
    @calc << HexaPDF::Layout::InlineBox.create(width: 10, height: 20, valign: :baseline) {}
    assert_equal([0, 20, 0, 0], @calc.result)
    new_item = HexaPDF::Layout::InlineBox.create(width: 10, height: 30, valign: :top) {}
    assert_equal([-10, 20, 30], @calc.simulate_height(new_item))
    assert_equal([0, 20, 0, 0], @calc.result)
  end
end

describe HexaPDF::Layout::Line do
  before do
    @doc = HexaPDF::Document.new
    @font = @doc.fonts.add("Times", custom_encoding: true)
    @line = HexaPDF::Layout::Line.new
  end

  def setup_fragment(text)
    HexaPDF::Layout::TextFragment.create(text, font: @font, font_size: 10)
  end

  def setup_box(width, height, valign = :baseline)
    HexaPDF::Layout::InlineBox.create(width: width, height: height, valign: valign) {}
  end

  describe "initialize" do
    it "allows setting the items of the line fragment" do
      frag1 = setup_fragment("Hello")
      frag2 = HexaPDF::Layout::TextFragment.new(frag1.items.slice!(3, 2), frag1.style)
      line = HexaPDF::Layout::Line.new([frag1, frag2])
      assert_equal(1, line.items.count)
      assert_equal(5, line.items[0].items.count)
    end
  end

  describe "add" do
    it "adds items to the line" do
      @line << :test << :other
      assert_equal([:test, :other], @line.items)
    end

    it "combines text fragments if possible" do
      frag1 = setup_fragment("Home")
      frag2 = HexaPDF::Layout::TextFragment.new(frag1.items[2, 2], frag1.style)
      frag3 = HexaPDF::Layout::TextFragment.new(frag1.items[2, 2], frag1.style,
                                                properties: {'key' => :value})
      @line << setup_fragment("o") << :other << frag1 << frag2 << frag3
      assert_equal(4, @line.items.length)
      assert_equal(6, @line.items[-2].items.length)
    end

    it "duplicates the first of two combinable text fragments if its items are frozen" do
      frag1 = setup_fragment("Home")
      frag2 = HexaPDF::Layout::TextFragment.new(frag1.items.slice!(2, 2), frag1.style)
      frag1.items.freeze
      frag2.items.freeze

      @line << setup_fragment("o") << frag1 << frag2 << :other
      assert_equal(3, @line.items.length)
      assert_equal(4, @line.items[-2].items.length)
    end
  end

  describe "with text fragments" do
    before do
      @frag_h = setup_fragment("H")
      @frag_y = setup_fragment("y")
      @line << @frag_h << @frag_y << @frag_h
    end

    it "calculates the various x/y values correctly" do
      assert_equal(@frag_h.x_min, @line.x_min)
      assert_equal(@frag_h.width + @frag_y.width + @frag_h.x_max, @line.x_max)
      assert_equal(@frag_y.y_min, @line.y_min)
      assert_equal(@frag_h.y_max, @line.y_max)
      assert_equal(@frag_y.y_min, @line.text_y_min)
      assert_equal(@frag_h.y_max, @line.text_y_max)
      assert_equal(2 * @frag_h.width + @frag_y.width, @line.width)
      assert_equal(@frag_h.y_max - @frag_y.y_min, @line.height)
    end

    describe "and with inline boxes" do
      it "x_min is correct if an inline box is the first item" do
        @line.items.unshift(setup_box(10, 10))
        assert_equal(0, @line.x_min)
      end

      it "x_max is correct if an inline box is the last item" do
        @line << setup_box(10, 10)
        assert_equal(@line.width, @line.x_max)
      end

      it "doesn't change text_y_min/text_y_max" do
        text_y_min, text_y_max = @line.text_y_min, @line.text_y_max
        @line << setup_box(10, 30, :text_top) << setup_box(10, 30, :text_bottom)
        @line.clear_cache
        assert_equal(text_y_min, @line.text_y_min)
        assert_equal(text_y_max, @line.text_y_max)
      end

      it "y values are not changed if all boxes are smaller than the text's height" do
        *y_values = @line.y_min, @line.y_max, @line.text_y_min, @line.text_y_max
        @line << setup_box(10, 5, :baseline)
        @line.clear_cache
        assert_equal(y_values, [@line.y_min, @line.y_max, @line.text_y_min, @line.text_y_max])
      end

      it "changes y_max to fit if baseline boxes are higher than the text" do
        y_min = @line.y_min
        box = setup_box(10, 50, :baseline)
        @line.add(box)

        @line.clear_cache
        assert_equal(50, @line.y_max)
        assert_equal(y_min, @line.y_min)
      end

      it "changes y_max to fit if text_bottom boxes are higher than the text" do
        y_min = @line.y_min
        box = setup_box(10, 50, :text_bottom)
        @line.add(box)

        @line.clear_cache
        assert_equal(50 + @line.text_y_min, @line.y_max)
        assert_equal(y_min, @line.y_min)
      end

      it "changes y_max to fit if bottom boxes are higher than the text" do
        y_min = @line.y_min
        box = setup_box(10, 50, :bottom)
        @line.add(box)

        @line.clear_cache
        assert_equal(50 + @line.text_y_min, @line.y_max)
        assert_equal(y_min, @line.y_min)
      end

      it "changes y_min to fit if text_top/top boxes are higher than the text" do
        y_max = @line.y_max
        box = setup_box(10, 50, :text_top)
        @line.add(box)

        @line.clear_cache
        assert_equal(@line.text_y_max - 50, @line.y_min)
        assert_equal(y_max, @line.y_max)

        box.instance_variable_set(:@valign, :top)
        @line.clear_cache
        assert_equal(@line.text_y_max - 50, @line.y_min)
        assert_equal(y_max, @line.y_max)
      end

      it "changes y_min/y_max to fit if boxes are aligned in both directions" do
        @line << setup_box(10, 20, :text_top) <<
          setup_box(10, 20, :text_bottom) <<
          setup_box(10, 20, :top) <<
          setup_box(10, 70, :bottom)
        assert_equal(@line.text_y_max - 20, @line.y_min)
        assert_equal(@line.text_y_max - 20 + 70, @line.y_max)
      end
    end
  end

  it "fails when accessing a vertical measurement if an item uses an invalid valign value" do
    @line << setup_box(10, 20, :invalid)
    assert_raises(HexaPDF::Error) { @line.y_min }
  end

  describe "each" do
    it "iterates over all items and yields them with their offset values" do
      @line << setup_fragment("H") <<
        setup_box(10, 10, :top) <<
        setup_box(10, 10, :text_top) <<
        setup_box(10, 10, :baseline) <<
        setup_box(10, 10, :text_bottom) <<
        setup_box(10, 10, :bottom)
      result = [
        [@line.items[0], 0, 0],
        [@line.items[1], @line.items[0].width, @line.y_max - 10],
        [@line.items[2], @line.items[0].width + 10, @line.text_y_max - 10],
        [@line.items[3], @line.items[0].width + 20, 0],
        [@line.items[4], @line.items[0].width + 30, @line.text_y_min],
        [@line.items[5], @line.items[0].width + 40, @line.y_min],
      ]
      assert_equal(result, @line.to_enum(:each).map {|*a| a })
    end

    it "fails if an item uses an invalid valign value" do
      @line << setup_box(10, 10, :invalid)
      assert_raises(HexaPDF::Error) { @line.each {} }
    end
  end

  it "allows ignoring line justification" do
    refute(@line.ignore_justification?)
    @line.ignore_justification!
    assert(@line.ignore_justification?)
  end
end
