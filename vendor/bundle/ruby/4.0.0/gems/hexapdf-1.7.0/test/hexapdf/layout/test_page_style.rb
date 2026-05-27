# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/layout/page_style'
require 'hexapdf/document'

describe HexaPDF::Layout::PageStyle do
  it "allows assigning the page size, orientation, next style and template on initialization" do
    block = lambda {}
    style = HexaPDF::Layout::PageStyle.new(page_size: :A3, orientation: :landscape, next_style: :a, &block)
    assert_equal(:A3, style.page_size)
    assert_equal(:landscape, style.orientation)
    assert_equal(:a, style.next_style)
    assert_same(block, style.template)
  end

  it "uses defaults for all values" do
    style = HexaPDF::Layout::PageStyle.new
    assert_equal(:A4, style.page_size)
    assert_equal(:portrait, style.orientation)
    assert_nil(style.template)
    assert_nil(style.frame)
    assert_nil(style.next_style)
  end

  describe "create_page" do
    before do
      @doc = HexaPDF::Document.new
    end

    it "creates a new page object" do
      style = HexaPDF::Layout::PageStyle.new do |canvas, istyle|
        canvas.rectangle(0, 0, 10, 10).stroke
        istyle.frame = :frame
        istyle.next_style = :other
      end
      page = style.create_page(@doc)
      assert_equal([0, 0, 595.275591, 841.889764], page.box(:media))
      assert_equal("0 0 10 10 re\nS\n", page.contents)
      assert_equal(:frame, style.frame)
      assert_equal(:other, style.next_style)
      assert_equal(0, @doc.pages.count)
    end

    it "works when no template is set" do
      style = HexaPDF::Layout::PageStyle.new
      page1 = style.create_page(@doc)
      frame1 = style.frame
      assert_equal("", page1.contents)
      assert_equal(523.275591, style.frame.width)

      style.create_page(@doc)
      refute_same(frame1, style.frame)
    end

    it "creates a default frame if none is set beforehand or during template execution" do
      style = HexaPDF::Layout::PageStyle.new
      style.create_page(@doc)
      assert_kind_of(HexaPDF::Layout::Frame, style.frame)
      assert_equal(36, style.frame.left)
      assert_equal(36, style.frame.bottom)
      assert_equal(523.275591, style.frame.width)
      assert_equal(769.889764, style.frame.height)
    end
  end

  it "creates new frame objects given a page and a margin specification" do
    doc = HexaPDF::Document.new
    style = HexaPDF::Layout::PageStyle.new
    frame = style.create_frame(style.create_page(doc), [15, 10])
    assert_equal(10, frame.left)
    assert_equal(15, frame.bottom)
    assert_equal(575.275591, frame.width)
    assert_equal(811.889764, frame.height)
  end
end
