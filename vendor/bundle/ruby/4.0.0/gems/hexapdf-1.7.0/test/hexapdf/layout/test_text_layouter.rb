# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/layout'
require 'hexapdf/document'

module TestTextLayouterHelpers
  def boxes(*dims)
    dims.map do |width, height|
      box = HexaPDF::Layout::InlineBox.create(width: width, height: height || 10) {}
      HexaPDF::Layout::TextLayouter::Box.new(box)
    end
  end

  def glue(width)
    HexaPDF::Layout::TextLayouter::Glue.new(HexaPDF::Layout::InlineBox.create(width: width, height: 10) {})
  end

  def penalty(penalty, item = nil)
    if item
      HexaPDF::Layout::TextLayouter::Penalty.new(penalty, item.width, item: item)
    else
      HexaPDF::Layout::TextLayouter::Penalty.new(penalty)
    end
  end

  def assert_box(obj, item)
    assert_kind_of(HexaPDF::Layout::TextLayouter::Box, obj)
    if obj.item.kind_of?(HexaPDF::Layout::InlineBox)
      assert_same(item, obj.item)
    else
      assert_same(item.style, obj.item.style)
      assert_equal(item.items, obj.item.items)
      assert_equal(item.properties, obj.item.properties)
    end
  end

  def assert_glue(obj, fragment)
    assert_kind_of(HexaPDF::Layout::TextLayouter::Glue, obj)
    assert_same(fragment.style, obj.item.style)
    assert_equal(fragment.properties, obj.item.properties)
  end

  def assert_penalty(obj, penalty, item = nil)
    assert_kind_of(HexaPDF::Layout::TextLayouter::Penalty, obj)
    assert_equal(penalty, obj.penalty)
    if item
      assert_same(item.style, obj.item.style)
      assert_equal(item.items, obj.item.items)
      assert_equal(item.properties, obj.item.properties)
    end
  end

  def assert_line_wrapping(result, widths)
    rest, lines = *result
    assert(rest.empty?)
    assert_equal(widths.length, lines.count)
    widths.each_with_index {|width, index| assert_equal(width, lines[index].width) }
  end
end

describe HexaPDF::Layout::TextLayouter::Box do
  it "can describe itself" do
    assert_equal('Box["test"]', HexaPDF::Layout::TextLayouter::Box.new("test").inspect)
  end
end

describe HexaPDF::Layout::TextLayouter::Glue do
  it "can describe itself" do
    assert_equal('Glue["test"]', HexaPDF::Layout::TextLayouter::Glue.new("test", 5, 5).inspect)
  end
end

describe HexaPDF::Layout::TextLayouter::Penalty do
  it "can describe itself" do
    assert_equal('Penalty[100 10 nil]', HexaPDF::Layout::TextLayouter::Penalty.new(100, 10).inspect)
  end
end

describe HexaPDF::Layout::TextLayouter::SimpleTextSegmentation do
  include TestTextLayouterHelpers

  before do
    @doc = HexaPDF::Document.new
    @font = @doc.fonts.add("Times")
    @obj = HexaPDF::Layout::TextLayouter::SimpleTextSegmentation
  end

  def setup_fragment(text, style = {font: @font})
    fragment = HexaPDF::Layout::TextFragment.create(text, style)
    fragment.properties['key'] = :value
    fragment
  end

  it "handles InlineBox objects" do
    input = HexaPDF::Layout::InlineBox.create(width: 10, height: 10) {}
    result = @obj.call([input, input])
    assert_equal(2, result.size)
    assert_box(result[0], input)
    assert_box(result[1], input)
  end

  it "handles plain text" do
    frag = setup_fragment("Testtext")
    result = @obj.call([frag])
    assert_equal(1, result.size)
    assert_box(result[0], frag)
  end

  it "inserts a glue in places where spaces are" do
    frag = setup_fragment("This is a test")
    space = setup_fragment(" ", frag.style)

    result = @obj.call([frag])
    assert_equal(7, result.size)
    assert_glue(result[1], space)
    assert_glue(result[3], space)
    assert_glue(result[5], space)
  end

  it "inserts a glue representing 8 spaces when a tab is encountered" do
    frag = setup_fragment("This\ttest")
    tab = setup_fragment(" " * 8, frag.style)

    result = @obj.call([frag])
    assert_equal(3, result.size)
    assert_glue(result[1], tab)
  end

  it "insert a mandatory break when an Unicode line boundary characters is encountered" do
    frag = setup_fragment("A\rB\r\nC\nD\vE\fF\u{85}G\u{2029}H\u{2028}I\r")
    frag.items << 5 << frag.items[-2]

    result = @obj.call([frag])
    assert_equal(20, result.size)
    [1, 3, 5, 7, 9, 11, 13, 17, 19].each do |index|
      assert_penalty(result[index],
                     HexaPDF::Layout::TextLayouter::Penalty::PARAGRAPH_BREAK)
    end
    assert_penalty(result[15], HexaPDF::Layout::TextLayouter::Penalty::LINE_BREAK)
  end

  it "insert a standard penalty after a hyphen" do
    frag = setup_fragment("hy-phen-a-tion - cool!")

    result = @obj.call([frag])
    assert_equal(12, result.size)
    [1, 3, 5, 9].each do |index|
      assert_penalty(result[index], HexaPDF::Layout::TextLayouter::Penalty::Standard.penalty)
    end
  end

  it "insert a neutral penalty in places where zero-width-spaces are" do
    frag = setup_fragment("zero\u{200B}width\u{200B}space")

    result = @obj.call([frag])
    assert_equal(5, result.size)
    assert_penalty(result[1], 0)
    assert_penalty(result[3], 0)
  end

  it "insert a special penalty for soft-hyphens" do
    frag = setup_fragment("soft\u{00AD}hyphened")
    hyphen = setup_fragment("-", frag.style)

    result = @obj.call([frag])
    assert_equal(3, result.size)
    assert_penalty(result[1], HexaPDF::Layout::TextLayouter::Penalty::Standard.penalty, hyphen)
  end

  it "insert a prohibited break penalty for non-breaking spaces" do
    frag = setup_fragment("soft\u{00A0}hyphened")
    space = setup_fragment(" ", frag.style)

    result = @obj.call([frag])
    assert_equal(3, result.size)
    assert_penalty(result[1], HexaPDF::Layout::TextLayouter::Penalty::ProhibitedBreak.penalty, space)
  end
end

# Common tests for fixed and variable width line wrapping. The including class needs to define a
# #call(items, width = 100) method with a default with of 100. The optional block is called after a
# line has been yielded by the line wrapping algorithm.
module CommonLineWrappingTests
  extend Minitest::Spec::DSL

  include TestTextLayouterHelpers

  it "breaks before a box if it doesn't fit onto the line anymore" do
    rest, lines = call(boxes(25, 50, 25, 10))
    assert_line_wrapping([rest, lines], [100, 10])
    lines.each {|line| line.items.each {|item| assert_kind_of(HexaPDF::Layout::InlineBox, item) } }
  end

  it "breaks at a glue and ignores it if it doesn't fit onto the line anymore" do
    result = call(boxes(90) + [glue(20)] + boxes(20))
    assert_line_wrapping(result, [90, 20])
  end

  it "handles spaces at the start of a line" do
    rest, lines = call([glue(15)] + boxes(25, 50))
    assert_line_wrapping([rest, lines], [75])
    assert_equal(25, lines[0].items[0].width)
  end

  it "handles spaces at the end of a line" do
    rest, lines = call(boxes(20, 50) + [glue(10), glue(10)] + boxes(20))
    assert_line_wrapping([rest, lines], [70, 20])
    assert_equal(50, lines[0].items[-1].width)
  end

  it "handles spaces at the end of a line before a mandatory break" do
    rest, lines = call(boxes(20, 50) + [glue(10), penalty(-5000)] + boxes(20))
    assert_line_wrapping([rest, lines], [70, 20])
    assert_equal(50, lines[0].items[-1].width)
  end

  it "handles multiple glue items after another" do
    result = call(boxes(20) + [glue(20), glue(20)] + boxes(20, 50, 20))
    assert_line_wrapping(result, [80, 70])
  end

  it "handles mandatory line breaks" do
    rest, lines = call(boxes(20) + [penalty(-5000)] + boxes(20))
    assert_line_wrapping([rest, lines], [20, 20])
    assert(lines[0].ignore_justification?)
  end

  it "handles breaking at penalties with zero width" do
    result = call(boxes(80) + [penalty(0)] + boxes(10) + [penalty(0)] + boxes(20))
    assert_line_wrapping(result, [90, 20])
  end

  it "handles breaking at penalties with non-zero width if they fit on the line" do
    pitem = penalty(0, boxes(20).first)
    rest, lines = call(boxes(20) + [pitem] + boxes(50) + [glue(10), pitem] + boxes(30))
    assert_line_wrapping([rest, lines], [100, 30])
    assert_same(pitem.item, lines[0].items[-1])
  end

  it "handles breaking at penalties with non-zero width that fit on the line and are followed by 1+ penalties" do
    pitem = penalty(0, boxes(20).first)
    result = call(boxes(80) + [pitem, penalty(0), penalty(0)] + boxes(30))
    assert_line_wrapping(result, [100, 30])
  end

  it "handles penalties with non-zero width if they don't fit on the line" do
    item = boxes(20).first
    result = call(boxes(70) + [glue(10)] + boxes(10) + [penalty(0, item)] + boxes(30))
    assert_line_wrapping(result, [70, 40])
  end

  it "handles breaking at penalties with non-zero width surrounded by glue" do
    item = boxes(20).first
    result = call(boxes(70) + [glue(10)] + [penalty(0, item)] + [glue(30)] + boxes(30))
    assert_line_wrapping(result, [100, 30])
  end

  it "handles prohibited breakpoint penalties with zero width" do
    result = call(boxes(70) + [glue(10)] + boxes(10) + [penalty(5000)] + boxes(30))
    assert_line_wrapping(result, [70, 40])
  end

  it "handles prohibited breakpoint penalties with non-zero width" do
    item = boxes(20).first.item
    result = call(boxes(70) + [glue(10)] + boxes(10) + [penalty(5000, item)] + boxes(30))
    assert_line_wrapping(result, [70, 60])
  end

  it "stops when nil is returned by the block: last item is a box" do
    done = false
    rest, lines = call(boxes(20, 20, 20), 20) { done ? nil : done = true }
    assert_equal(2, rest.count)
    assert_equal(2, lines.count)
  end

  it "stops when nil is returned by the block: last item is a glue" do
    done = false
    items = boxes(20, 15, 20).insert(-2, glue(10))
    rest, = call(items, 20) { done ? nil : done = true }
    assert_equal(3, rest.count)
    assert_equal(15, rest[0].width)
  end

  it "stops when nil is returned by the block: last item is a mandatory break penalty" do
    items = boxes(20, 20).insert(-2, penalty(-5000))
    rest, = call(items, 20) { nil }
    assert_equal(3, rest.count)
  end

  it "stops when nil is returned by the block: works for the last line" do
    done = false
    rest, lines = call(boxes(20, 20), 20) { done ? nil : done = true }
    assert_equal(1, rest.count)
    assert_equal(2, lines.count)
  end

  it "handles items with fill_horizontal correctly" do
    doc = HexaPDF::Document.new
    font = doc.fonts.add("Times")
    box1 = HexaPDF::Layout::TextLayouter::Box.new(
      HexaPDF::Layout::TextFragment.create('.', font: font, fill_horizontal: 1)
    )
    box2 = HexaPDF::Layout::TextLayouter::Box.new(
      HexaPDF::Layout::TextFragment.create('.', font: font, fill_horizontal: 2)
    )
    items = [box1, *boxes(10), box2]
    rest, lines = call(items, 40)
    assert_equal(0, rest.size)
    assert_equal(1, lines.size)

    line = lines.first
    refute_same(items[0].item, line.items[0])
    assert_same(items[1].item, line.items[1])
    refute_same(items[2].item, line.items[2])
    assert_equal(10, line.items[0].width)
    assert_equal(10, line.items[1].width)
    assert_equal(20, line.items[2].width)
  end
end

describe HexaPDF::Layout::TextLayouter::SimpleLineWrapping do
  before do
    @obj = HexaPDF::Layout::TextLayouter::SimpleLineWrapping
    @mock_frame = nil
  end

  describe "fixed width wrapping" do
    include CommonLineWrappingTests

    def call(items, width = 100, &block)
      lines = []
      block ||= proc { true }
      rest = @obj.call(items, proc { width }, @mock_frame) do |line, item|
        lines << line; block.call(line, item)
      end
      [rest, lines]
    end
  end

  describe "variable width wrapping" do
    include CommonLineWrappingTests

    def call(items, width = 100, &block)
      lines = []
      block ||= proc { true }
      rest = @obj.call(items, proc {|_| width }, @mock_frame) do |line, i|
        lines << line; block.call(line, i)
      end
      [rest, lines]
    end

    it "handles changing widths" do
      height = 0
      width_block = lambda do |line|
        case height + line.height
        when 0..10 then 60
        when 11..20 then 40
        when 21..30 then 20
        else 60
        end
      end
      lines = []
      rest = @obj.call(boxes([20, 10], [10, 10], [20, 15], [40, 10]), width_block, @mock_frame) do |line|
        height += line.height
        lines << line
        true
      end
      assert(rest.empty?)
      assert_equal(3, lines.size)
      assert_equal(30, lines[0].width)
      assert_equal(20, lines[1].width)
      assert_equal(40, lines[2].width)
    end

    it "handles changing widths when breaking on a penalty" do
      height = 0
      width_block = lambda do |line|
        case height + line.height
        when 0..10 then 80
        else 50
        end
      end
      lines = []
      item = HexaPDF::Layout::InlineBox.create(width: 20, height: 10) {}
      items = boxes([20, 10]) + [penalty(0, item)] + boxes([40, 15])
      rest = @obj.call(items, width_block, @mock_frame) do |line|
        height += line.height
        lines << line
        true
      end
      assert(rest.empty?)
      assert_equal(2, lines.size)
      assert_equal(40, lines[0].width)
      assert_equal(40, lines[1].width)
      assert_equal(25, height)
    end
  end
end

describe HexaPDF::Layout::TextLayouter do
  include TestTextLayouterHelpers

  before do
    @doc = HexaPDF::Document.new
    @font = @doc.fonts.add("Times")
    @style = HexaPDF::Layout::Style.new(font: @font)
  end

  describe "initialize" do
    it "can use a Style object" do
      style = HexaPDF::Layout::Style.new(font: @font, font_size: 20)
      layouter = HexaPDF::Layout::TextLayouter.new(style)
      assert_equal(20, layouter.style.font_size)
    end

    it "can use a style options" do
      layouter = HexaPDF::Layout::TextLayouter.new(font: @font, font_size: 20)
      assert_equal(20, layouter.style.font_size)
    end
  end

  describe "fit" do
    before do
      @layouter = HexaPDF::Layout::TextLayouter.new(@style)
    end

    it "does nothing if there are no items" do
      result = @layouter.fit([], 100, 100)
      assert_equal(:success, result.status)
      assert_equal(0, result.height)
    end

    it "handles text indentation" do
      items = boxes([20, 20], [20, 20], [20, 20]) +
        [penalty(HexaPDF::Layout::TextLayouter::Penalty::PARAGRAPH_BREAK)] +
        boxes([40, 20]) + [glue(20)] +
        boxes(*([[20, 20]] * 4)) + [penalty(HexaPDF::Layout::TextLayouter::Penalty::LINE_BREAK)] +
        boxes(*([[20, 20]] * 4))
      @style.text_indent = 20

      [60, proc { 60 }].each do |width|
        result = @layouter.fit(items, width, 200)
        assert_equal([40, 20, 40, 60, 20, 60, 20], result.lines.map(&:width))
        assert_equal([20, 0, 20, 0, 0, 0, 0], result.lines.map(&:x_offset))
        assert(result.remaining_items.empty?)
        assert_equal(:success, result.status)
      end

      result = @layouter.fit(boxes([20, 20], [20, 20], [20, 20], [20, 20]), 60, 200,
                             apply_first_text_indent: false)
      assert_equal([60, 20], result.lines.map(&:width))
    end

    it "fits using a limited height" do
      result = @layouter.fit(boxes(*([[20, 20]] * 100)), 20, 100)
      assert_equal(95, result.remaining_items.count)
      assert_equal(:height, result.status)
      assert_equal(100, result.height)
    end

    it "takes line spacing into account when calculating the height" do
      @style.line_spacing = :double
      result = @layouter.fit(boxes(*([[20, 20]] * 5)), 20, 200)
      assert(result.remaining_items.empty?)
      assert_equal(:success, result.status)
      assert_equal(20 * (5 + 4), result.height)
    end

    it "takes line spacing into account with variable width" do
      @style.line_spacing = :double
      width_block = lambda {|l, h| l + h <= 90 ? 40 : 20 }
      result = @layouter.fit(boxes(*([[20, 20]] * 6)), width_block, 170)
      assert(result.remaining_items.empty?)
      assert_equal(:success, result.status)
      assert_line_wrapping([[], result.lines], [40, 40, 20, 20])
      assert_equal(140, result.height)
    end

    it "handles empty lines if the break penalties don't have an item" do
      items = boxes([20, 20]) + [penalty(-5000)] + boxes([30, 20]) + [penalty(-5000)] * 2 +
        boxes([20, 20]) + [penalty(-5000)] * 2
      result = @layouter.fit(items, 30, 100)
      assert(result.remaining_items.empty?)
      assert_equal(:success, result.status)
      assert_equal(5, result.lines.count)
      assert_equal(20 + 20 + 9 + 20 + 9, result.height)
    end

    it "handles penalties with non-zero width at end of line if they don't fit" do
      items = boxes([17.21, 9]) + [penalty(50, boxes([3.33]).first)] + boxes([30, 9])
      result = @layouter.fit(items, 20.5, 100)
      assert_equal(3, result.remaining_items.size)
    end

    it "handles line breaks in combination with multiple parts per line" do
      items = boxes([20, 20]) + [penalty(-5000)] +
        boxes([20, 20], [20, 20], [20, 20]) + [penalty(-5000)] +
        [penalty(-5000)] +
        boxes([20, 20])
      result = @layouter.fit(items, [0, 40, 0, 40, 0, 40], 100)
      assert_equal(:success, result.status)
      assert_equal([20, 40, 20, 0, 20], result.lines.map(&:width))
      assert_equal([20, 20, 0, 6.83, 22.17], result.lines.map(&:y_offset))
    end

    describe "fixed width and too wide item" do
      it "single part per line" do
        result = @layouter.fit(boxes([20, 20], [50, 20]), 30, 100)
        assert_equal(1, result.remaining_items.count)
        assert_equal(:box_too_wide, result.status)
        assert_equal(20, result.height)
      end

      it "multiple parts per line, one fits" do
        result = @layouter.fit(boxes([20, 20], [40, 20], [40, 20], [10, 20]),
                               [0, 30, 0, 50, 0, 30, 0, 30], 100)
        assert_equal(0, result.remaining_items.count)
        assert_equal([20, 40, 0, 0, 0, 50], result.lines.map(&:width))
        assert_equal([0, 30, 80, 110, 0, 30], result.lines.map(&:x_offset))
        assert_equal([20, 0, 0, 0, 20, 0], result.lines.map(&:y_offset))
        assert_equal(:success, result.status)
        assert_equal(40, result.height)
      end

      it "multiple parts per line, none fits" do
        result = @layouter.fit(boxes([20, 20], [50, 20]), [0, 30, 0, 30, 0, 30], 100)
        assert_equal(1, result.remaining_items.count)
        assert_equal(:box_too_wide, result.status)
        assert_equal(20, result.height)
      end
    end

    describe "variable width" do
      it "single part per line, searches for vertical offset if the first item is too wide" do
        width_block = lambda do |height, _|
          case height
          when 0..20 then 10
          else 40
          end
        end
        result = @layouter.fit(boxes([20, 18]), width_block, 100)
        assert(result.remaining_items.empty?)
        assert_equal(:success, result.status)
        assert_equal(1, result.lines.count)
        assert_equal(42, result.lines[0].y_offset)
        assert_equal(42, result.height)
      end

      it "single part per line, searches for vertical offset if an item is too wide" do
        width_block = lambda do |height, line_height|
          if (40..60).cover?(height) || (40..60).cover?(height + line_height)
            10
          else
            40
          end
        end
        result = @layouter.fit(boxes(*([[20, 18]] * 7)), width_block, 100)
        assert_equal(1, result.remaining_items.count)
        assert_equal(:height, result.status)
        assert_equal(3, result.lines.count)
        assert_equal(18, result.lines[0].y_offset)
        assert_equal(18, result.lines[1].y_offset)
        assert_equal(48, result.lines[2].y_offset)
        assert_equal(84, result.height)
      end

      it "multiple parts per line, reset line because of line height change during first part" do
        width_block = lambda do |height, line_height|
          if height == 0 && line_height <= 10
            [0, 40, 0, 40]
          elsif height == 0 && line_height > 10
            [0, 30, 0, 40]
          else
            [0, 60]
          end
        end
        result = @layouter.fit(boxes([20, 10], [20, 10], [20, 18], [20, 10]), width_block, 100)
        assert_equal(:success, result.status)
        assert_equal(0, result.remaining_items.count)
        assert_equal(3, result.lines.count)
        assert_equal([20, 40, 20], result.lines.map(&:width))
        assert_equal([18, 0, 10], result.lines.map(&:y_offset))
        assert_equal(28, result.height)
      end

      it "multiple parts per line, reset line because of line height change after first part" do
        width_block = lambda do |height, line_height|
          if height == 0 && line_height <= 10
            [0, 40, 0, 40]
          elsif height == 0 && line_height > 10
            [0, 30, 0, 40]
          else
            [0, 60]
          end
        end
        result = @layouter.fit(boxes([20, 10], [15, 10], [10, 10], [12, 18], [20, 10]),
                               width_block, 100)
        assert_equal(:success, result.status)
        assert_equal(0, result.remaining_items.count)
        assert_equal(3, result.lines.count)
        assert_equal([20, 37, 20], result.lines.map(&:width))
        assert_equal([18, 0, 10], result.lines.map(&:y_offset))
        assert_equal(28, result.height)
      end
    end

    describe "breaking into parts of a too wide text fragment" do
      before do
        @str = " Thisisaverylongstring"
        @frag = HexaPDF::Layout::TextFragment.create(@str, font: @font)
      end

      it "arranges the parts if single parts fit into the available space" do
        result = @layouter.fit([@frag], 20, 100)
        assert(result.remaining_items.empty?)
        assert_equal(:success, result.status)
        assert_equal(@str.strip.length, result.lines.sum {|l| l.items.sum {|i| i.items.count } })
        assert_equal(45, result.height)
      end

      it "works even if a single part doesn't fit" do
        result = @layouter.fit([@frag], 1, 100)
        assert_equal(@str.strip.length, result.remaining_items.count)
        assert_equal(:box_too_wide, result.status)
      end

      it "works if the parts of the broken fragment are used in another .fit call" do
        text = "This is a long string to test"
        frag = HexaPDF::Layout::TextFragment.create(text, font: @font)
        result = @layouter.fit([frag], lambda {|h, _| h > 17 ? 0 : 25 }, 20)
        refute(result.remaining_items.empty?)
        assert_equal(:height, result.status)
        assert_equal(["This", "is a"],
                     result.lines.map {|l| l.items.map {|tf| tf.items.map(&:str).join }.join })

        # Simulating a split text box where the second part is tried to fit into same remaining
        # space
        result = @layouter.fit(result.remaining_items, 25, 1)

        # Now fit into next available space
        result = @layouter.fit(result.remaining_items, 25, 100)
        assert_equal(["long", "string", "to test"],
                     result.lines.map {|l| l.items.map {|tf| tf.items.map(&:str).join }.join })
      end
    end

    describe "horizontal alignment" do
      before do
        @items = boxes(*[[20, 20]] * 4) + [glue(10), penalty(-5000)]
      end

      it "aligns the contents to the left" do
        @style.text_align = :left
        result = @layouter.fit(@items, 100, 100)
        assert_equal(0, result.lines[0].x_offset)
        assert_equal(80, result.lines[0].width)
        result = @layouter.fit(@items, proc { 100 }, 100)
        assert_equal(0, result.lines[0].x_offset)
        assert_equal(80, result.lines[0].width)
      end

      it "aligns the contents to the center" do
        @style.text_align = :center
        result = @layouter.fit(@items, 100, 100)
        assert_equal(10, result.lines[0].x_offset)
        result = @layouter.fit(@items, proc { 100 }, 100)
        assert_equal(10, result.lines[0].x_offset)
      end

      it "aligns the contents to the right" do
        @style.text_align = :right
        result = @layouter.fit(@items, 100, 100)
        assert_equal(20, result.lines[0].x_offset)
        result = @layouter.fit(@items, proc { 100 }, 100)
        assert_equal(20, result.lines[0].x_offset)
      end
    end

    describe "vertical alignment" do
      before do
        @items = boxes(*[[20, 20]] * 4)
      end

      it "aligns the contents to the top" do
        @style.text_valign = :top
        result = @layouter.fit(@items, 40, 100)
        assert_equal(result.lines[0].y_max, result.lines[0].y_offset)
        assert_equal(40, result.height)
      end

      it "aligns the contents to the center" do
        @style.text_valign = :center
        result = @layouter.fit(@items, 40, 100)
        assert_equal((100 - 40) / 2 + 20, result.lines[0].y_offset)
        assert_equal(70, result.height)
      end

      it "aligns the contents to the bottom" do
        @style.text_valign = :bottom
        result = @layouter.fit(@items, 40, 100)
        assert_equal(100 - 20 * 2 + 20, result.lines[0].y_offset)
        assert_equal(100, result.height)
      end

      it "doesn't vertically align when layouting in variable-width mode" do
        @style.text_valign = :bottom
        result = @layouter.fit(@items, proc { 40 }, 100)
        assert_equal(result.lines[0].y_max, result.lines[0].y_offset)
        assert_equal(40, result.height)
      end
    end

    it "post-processes lines for justification if needed" do
      frag10 = HexaPDF::Layout::TextFragment.create(" ", font: @font)
      frag10.items.freeze
      frag10b = HexaPDF::Layout::TextLayouter::Box.new(frag10)
      frag20 = HexaPDF::Layout::TextFragment.create(" ", font: @font, font_size: 20)
      frag20b = HexaPDF::Layout::TextLayouter::Box.new(frag20)
      items = boxes(20, 20, 20, 20, 30).insert(1, frag10b).insert(3, frag20b).insert(5, frag10b)
      # Width of spaces: 2.5 * 2 + 5 = 10  (from AFM file, adjusted for font size)
      # Line width: 20 * 4 + width_of_spaces = 90
      # Missing width: 100 - 90 = 10
      # -> Each space must be doubled!

      @style.text_align = :justify
      result = @layouter.fit(items, 100, 100)
      assert(result.remaining_items.empty?)
      assert_equal(:success, result.status)
      assert_equal(9, result.lines[0].items.count)
      assert_in_delta(100, result.lines[0].width)
      assert_equal(-250, result.lines[0].items[1].items[0])
      assert_equal(-250, result.lines[0].items[4].items[0])
      assert_equal(-250, result.lines[0].items[6].items[0])
      assert_equal(30, result.lines[1].width)
    end
  end

  describe "Result#draw" do
    def assert_positions(content, positions)
      processor = HexaPDF::TestUtils::OperatorRecorder.new
      HexaPDF::Content::Parser.new.parse(content, processor)
      result = processor.recorded_ops
      leading = (result.select {|name, _| name == :set_leading } || [0]).map(&:last).flatten.first
      pos = [0, 0]
      result.select! do |name, _|
        name == :set_text_matrix || name == :move_text || name == :move_text_next_line
      end.map! do |name, ops|
        case name
        when :set_text_matrix then pos = ops[-2, 2]
        when :move_text then pos = ops
        when :move_text_next_line then pos[1] -= leading
        end
        pos.dup
      end
      positions.each_with_index do |(x, y), index|
        assert_in_delta(x, result[index][0], 0.00001)
        assert_in_delta(y, result[index][1], 0.00001)
      end
    end

    before do
      @frag = HexaPDF::Layout::TextFragment.create("This is some more text.\n" \
                                                   "This is some more text.", font: @font)
      @width = HexaPDF::Layout::TextFragment.create("This is some   ", font: @font).width
      @layouter = HexaPDF::Layout::TextLayouter.new
      @canvas = @doc.pages.add.canvas

      @line1w = HexaPDF::Layout::TextFragment.create("This is some", font: @font).width
      @line2w = HexaPDF::Layout::TextFragment.create("more text.", font: @font).width
    end

    it "respects the x- and y-offsets" do
      top = 100
      @layouter.style.text_valign = :center
      @layouter.style.text_align = :center

      result = @layouter.fit([@frag], @width, top)
      result.draw(@canvas, 5, top)

      initial_baseline = top - result.lines.first.y_offset
      assert_positions(@canvas.contents,
                       [[5 + (@width - @line1w) / 2, initial_baseline],
                        [5 + (@width - @line2w) / 2, initial_baseline - @frag.height],
                        [5 + (@width - @line1w) / 2, initial_baseline - @frag.height * 2],
                        [5 + (@width - @line2w) / 2, initial_baseline - @frag.height * 3]])
    end

    it "makes sure that text fragments don't pollute the graphics state for inline boxes" do
      inline_box = HexaPDF::Layout::InlineBox.create(width: 10, height: 10) {|c, _| c.text("A") }
      result = @layouter.fit([@frag, inline_box], 200, 100)
      assert_raises(HexaPDF::Error) { result.draw(@canvas, 0, 0) } # bc font should be reset to nil
    end

    it "doesn't do unnecessary work for consecutive text fragments with same style" do
      @layouter.fit([@frag], 200, 100).draw(@canvas, 0, 0)
      assert_operators(@canvas.contents, [[:save_graphics_state],
                                          [:set_leading, [9.0]],
                                          [:set_font_and_size, [:F1, 10]],
                                          [:begin_text],
                                          [:move_text, [0, -6.83]],
                                          [:show_text, ["This is some more text."]],
                                          [:move_text_next_line],
                                          [:show_text, ["This is some more text."]],
                                          [:end_text],
                                          [:restore_graphics_state]])
    end

    it "doesn't do unnecessary work for placeholder boxes" do
      box1 = HexaPDF::Layout::InlineBox.create(width: 10, height: 20)
      box2 = HexaPDF::Layout::InlineBox.create(width: 30, height: 40) { @canvas.line_width(2) }
      @layouter.fit([box1, box2], 200, 100).draw(@canvas, 0, 0)
      assert_operators(@canvas.contents, [[:save_graphics_state],
                                          [:restore_graphics_state],
                                          [:save_graphics_state],
                                          [:concatenate_matrix, [1, 0, 0, 1, 10, -40]],
                                          [:set_line_width, [2]],
                                          [:restore_graphics_state],
                                          [:save_graphics_state],
                                          [:restore_graphics_state]])
    end
  end
end
