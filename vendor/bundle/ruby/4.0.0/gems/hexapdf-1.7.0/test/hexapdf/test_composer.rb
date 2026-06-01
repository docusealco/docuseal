# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/document'
require 'hexapdf/composer'
require 'stringio'

describe HexaPDF::Composer do
  before do
    @composer = HexaPDF::Composer.new
  end

  describe "initialize" do
    it "creates a composer object with default values" do
      assert_kind_of(HexaPDF::Document, @composer.document)
      assert_kind_of(HexaPDF::Type::Page, @composer.page)
      assert_equal(36, @composer.frame.left)
      assert_equal(36, @composer.frame.bottom)
      assert_equal(523.275591, @composer.frame.width)
      assert_equal(769.889764, @composer.frame.height)
      assert_kind_of(HexaPDF::Layout::Style, @composer.style(:base))
    end

    it "allows the customization of the page size" do
      composer = HexaPDF::Composer.new(page_size: [0, 0, 100, 100])
      assert_equal([0, 0, 100, 100], composer.page.box.value)
    end

    it "allows the customization of the page orientation" do
      composer = HexaPDF::Composer.new(page_orientation: :landscape)
      assert_equal([0, 0, 841.889764, 595.275591], composer.page.box.value)
    end

    it "allows the customization of the margin" do
      composer = HexaPDF::Composer.new(margin: [100, 80, 60, 40])
      assert_equal(40, composer.frame.left)
      assert_equal(60, composer.frame.bottom)
      assert_in_delta(475.275591, composer.frame.width)
      assert_equal(681.889764, composer.frame.height)
    end

    it "allows skipping the initial page creation" do
      composer = HexaPDF::Composer.new(skip_page_creation: true)
      assert_nil(composer.page)
      assert_nil(composer.canvas)
      assert_nil(composer.frame)
      assert_nil(composer.page_style(:default))
    end

    it "yields itself" do
      yielded = nil
      composer = HexaPDF::Composer.new {|c| yielded = c }
      assert_same(composer, yielded)
    end
  end

  describe "::create" do
    it "creates, yields, and writes a document" do
      io = StringIO.new
      HexaPDF::Composer.create(io, &:new_page)
      io.rewind
      assert_equal(2, HexaPDF::Document.new(io: io).pages.count)
    end
  end

  it "writes the document to a string" do
    pdf = HexaPDF::Composer.new
    pdf.new_page
    str = pdf.write_to_string
    doc = HexaPDF::Document.new(io: StringIO.new(str))
    assert_equal(2, doc.pages.count)
  end

  describe "new_page" do
    it "creates a new page" do
      c = HexaPDF::Composer.new(page_size: [0, 0, 50, 100], margin: 10)
      c.new_page
      assert_equal([0, 0, 50, 100], c.page.box.value)
      assert_equal(10, c.frame.left)
      assert_equal(10, c.frame.bottom)
    end

    it "uses the named page style for the new page" do
      @composer.page_style(:other, page_size: [0, 0, 100, 100])
      @composer.new_page(:other)
      assert_equal([0, 0, 100, 100], @composer.page.box.value)
    end

    it "sets the next page's style to the next_style value of the used page style" do
      @composer.page_style(:one, page_size: [0, 0, 1, 1]).next_style = :two
      @composer.page_style(:two, page_size: [0, 0, 2, 2]).next_style = :one
      @composer.new_page(:one)
      assert_equal([0, 0, 1, 1], @composer.page.box.value)
      @composer.new_page
      assert_equal([0, 0, 2, 2], @composer.page.box.value)
      @composer.new_page
      assert_equal([0, 0, 1, 1], @composer.page.box.value)
    end

    it "uses the current page style for new pages if no next_style value is set" do
      @composer.page_style(:one, page_size: [0, 0, 1, 1])
      @composer.new_page(:one)
      assert_equal([0, 0, 1, 1], @composer.page.box.value)
      @composer.new_page
      assert_equal([0, 0, 1, 1], @composer.page.box.value)
    end

    it "fails if the specified page style has not been defined" do
      assert_raises(ArgumentError) { @composer.new_page(:unknown) }
    end
  end

  it "returns the current x-position" do
    assert_equal(36, @composer.x)
  end

  it "returns the current y-position" do
    assert_equal(805.889764, @composer.y)
  end

  describe "style" do
    it "delegates to layout.style" do
      @composer.document.layout.style(:base, font_size: 20)
      assert_equal(20, @composer.style(:base).font_size)
      @composer.style(:base, font_size: 30)
      assert_equal(30, @composer.document.layout.style(:base).font_size)
    end
  end

  describe "style?" do
    it "delegates to layout.style?" do
      @composer.document.layout.style(:header, font_size: 20)
      assert(@composer.style?(:header))
    end
  end

  describe "styles" do
    it "delegates to layout.styles" do
      @composer.styles(base: {font_size: 30}, other: {font_size: 40})
      assert_equal([:base, :other], @composer.document.layout.styles.keys)
    end
  end

  describe "page_style" do
    it "returns the page style if no argument or block is given" do
      page_style = @composer.page_style(:default)
      assert_kind_of(HexaPDF::Layout::PageStyle, page_style)
      assert_equal(:A4, page_style.page_size)
    end

    it "sets a page style using the given attributes" do
      @composer.page_style(:other, page_size: :A3)
      assert_equal(:A3, @composer.page_style(:other).page_size)
    end

    it "sets a page style using default attributes but with a block" do
      @composer.page_style(:other) {|_canvas, style| style.frame = :hallo }
      style = @composer.page_style(:other)
      style.create_page(@composer.document)
      assert_equal(:hallo, style.frame)
    end
  end

  describe "text/formatted_text/image/box/method_missing" do
    before do
      test_self = self
      @composer.define_singleton_method(:draw_box) do |arg|
        test_self.instance_variable_set(:@box, arg)
      end
    end

    it "delegates #text to layout.text" do
      @composer.text("Test", width: 10, height: 15, style: {font_size: 20},
                     box_style: {font_size: 30}, line_spacing: 2)
      assert_equal(10, @box.width)
      assert_equal(15, @box.height)
      assert_equal(30, @box.style.font_size)
      items = @box.instance_variable_get(:@items)
      assert_equal(1, items.length)
      assert_same(20, items.first.style.font_size)
    end

    it "delegates #formatted_text to layout.formatted_text" do
      @composer.formatted_text(["Test"], width: 10, height: 15)
      assert_equal(10, @box.width)
      assert_equal(15, @box.height)
      assert_equal(1, @box.instance_variable_get(:@items).length)
    end

    it "delegates #image to layout.image" do
      form = @composer.document.add({Type: :XObject, Subtype: :Form, BBox: [0, 0, 10, 10]})
      @composer.image(form, width: 10)
      assert_equal(10, @box.width)
      assert_equal(0, @box.height)
    end

    it "delegates #box to layout.box" do
      image = @composer.document.images.add(File.join(TEST_DATA_DIR, 'images', 'gray.jpg'))
      @composer.box(:list, width: 20) {|list| list.image(image) }
      assert_equal(20, @box.width)
      assert_same(image, @box.children[0].image)
    end

    it "delegates missing methods to layout if they are box creation methods" do
      @composer.column(width: 10)
      assert_equal(10, @box.width)
    end

    it "fails for missing methods that can't be delegated to layout" do
      assert_raises(NameError) { @composer.unknown_box }
    end

    it "can be asked whether a missing method is supported" do
      assert(@composer.respond_to?(:column))
    end
  end

  describe "draw_box" do
    def create_box(**kwargs)
      HexaPDF::Layout::Box.new(**kwargs) {}
    end

    it "draws the box if it completely fits" do
      @composer.draw_box(create_box(height: 100))
      @composer.draw_box(create_box)
      assert_operators(@composer.canvas.contents,
                       [[:save_graphics_state],
                        [:concatenate_matrix, [1, 0, 0, 1, 36, 705.889764]],
                        [:restore_graphics_state],
                        [:save_graphics_state],
                        [:concatenate_matrix, [1, 0, 0, 1, 36, 36]],
                        [:restore_graphics_state]])
    end

    it "draws the box on a new page if the frame is already full" do
      first_page_canvas = @composer.canvas
      @composer.draw_box(create_box)
      @composer.draw_box(create_box)
      refute_same(first_page_canvas, @composer.canvas)
      assert_operators(@composer.canvas.contents,
                       [[:save_graphics_state],
                        [:concatenate_matrix, [1, 0, 0, 1, 36, 36]],
                        [:restore_graphics_state]])
    end

    it "splits the box across two pages" do
      first_page_contents = @composer.canvas.contents
      @composer.draw_box(create_box(height: 400))

      box = create_box
      box.define_singleton_method(:fit_content) {|*| fit_result.overflow! }
      box.define_singleton_method(:split_content) do |*|
        [box, HexaPDF::Layout::Box.new(height: 100) {}]
      end
      @composer.draw_box(box)
      assert_operators(first_page_contents,
                       [[:save_graphics_state],
                        [:concatenate_matrix, [1, 0, 0, 1, 36, 405.889764]],
                        [:restore_graphics_state],
                        [:save_graphics_state],
                        [:concatenate_matrix, [1, 0, 0, 1, 36, 36]],
                        [:restore_graphics_state]])
      assert_operators(@composer.canvas.contents,
                       [[:save_graphics_state],
                        [:concatenate_matrix, [1, 0, 0, 1, 36, 705.889764]],
                        [:restore_graphics_state]])
    end

    it "finds a new region if splitting didn't work" do
      first_page_contents = @composer.canvas.contents
      @composer.draw_box(create_box(height: 400))
      @composer.draw_box(create_box(height: 100, width: 300, style: {position: :float}))

      box = create_box(width: 400, height: 400)
      @composer.draw_box(box)
      assert_operators(first_page_contents,
                       [[:save_graphics_state],
                        [:concatenate_matrix, [1, 0, 0, 1, 36, 405.889764]],
                        [:restore_graphics_state],
                        [:save_graphics_state],
                        [:concatenate_matrix, [1, 0, 0, 1, 36, 305.889764]],
                        [:restore_graphics_state]])
      assert_operators(@composer.canvas.contents,
                       [[:save_graphics_state],
                        [:concatenate_matrix, [1, 0, 0, 1, 36, 405.889764]],
                        [:restore_graphics_state]])
    end

    it "handles truncated boxes correctly" do
      box = create_box(height: 400, style: {overflow: :truncate})
      box.define_singleton_method(:fit_content) {|*| fit_result.overflow! }
      assert_same(box, @composer.draw_box(box))
    end

    it "returns the last drawn box" do
      box = create_box(height: 400)
      assert_same(box, @composer.draw_box(box))

      split_box = create_box(height: 100)
      box = create_box
      box.define_singleton_method(:fit_content) {|*| fit_result.overflow! }
      box.define_singleton_method(:split_content) {|*| [box, split_box] }
      assert_same(split_box, @composer.draw_box(box))
    end

    it "raises an error if a box doesn't fit onto an empty page" do
      assert_raises(HexaPDF::Error) do
        @composer.draw_box(create_box(height: 800))
      end
    end
  end

  describe "create_stamp" do
    it "creates and returns a form XObject" do
      stamp = @composer.create_stamp(10, 5)
      assert_kind_of(HexaPDF::Type::Form, stamp)
      assert_equal(10, stamp.width)
      assert_equal(5, stamp.height)
    end

    it "allows using a block to draw on the canvas of the form XObject" do
      stamp = @composer.create_stamp(10, 10) do |canvas|
        canvas.line_width(5)
      end
      assert_equal("5 w\n", stamp.canvas.contents)
    end
  end
end
