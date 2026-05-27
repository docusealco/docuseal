# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/document'

describe HexaPDF::Document::Layout::ChildrenCollector do
  before do
    @doc = HexaPDF::Document.new
    @collector = HexaPDF::Document::Layout::ChildrenCollector.new(@doc.layout)
  end

  it "provides a convenient ::collect method which just returns the collected children" do
    children = HexaPDF::Document::Layout::ChildrenCollector.collect(@doc.layout) do |collector|
      collector.lorem_ipsum_box
      collector.lorem_ipsum_box
    end
    assert_equal(2, children.size)
    assert_kind_of(HexaPDF::Layout::TextBox, children[0])
    assert_kind_of(HexaPDF::Layout::TextBox, children[1])
  end

  it "allows appending existing boxes" do
    box = @doc.layout.lorem_ipsum_box
    @collector << box
    assert_equal([box], @collector.children)
  end

  it "allows appending an array of boxes created through another children collector" do
    @collector.multiple do |collector|
      collector.lorem_ipsum_box
      collector.lorem_ipsum_box
    end
    assert_equal(1, @collector.children.size)
    assert_equal(2, @collector.children[0].size)
  end

  it "allows appending boxes created by the Layout class" do
    box1 = @collector.lorem_ipsum
    box2 = @collector.lorem_ipsum_box
    box3 = @collector.column
    box4 = @collector.column_box
    assert_equal([box1, box2, box3, box4], @collector.children)
    assert_kind_of(HexaPDF::Layout::TextBox, @collector.children[0])
    assert_kind_of(HexaPDF::Layout::TextBox, @collector.children[1])
    assert_kind_of(HexaPDF::Layout::ColumnBox, @collector.children[2])
    assert_kind_of(HexaPDF::Layout::ColumnBox, @collector.children[3])
  end

  it "can be asked which methods it supports" do
    assert(@collector.respond_to?(:lorem_ipsum))
  end

  it "only allows using box creation methods from the Layout class" do
    assert_raises(NameError) { @collector.style }
  end

  it "raises an error on an unknown method name" do
    assert_raises(NameError) { @collector.unknown_box }
  end
end

describe HexaPDF::Document::Layout::CellArgumentCollector do
  before do
    @args = HexaPDF::Document::Layout::CellArgumentCollector.new(20, 10)
  end

  describe "[]" do
    def check_argument_info(info, rows, cols, args)
      assert_equal(rows, info.rows)
      assert_equal(cols, info.cols)
      assert_equal(args, info.args)
    end

    it "allows assigning to all cells" do
      @args[] = {key: :value}
      check_argument_info(@args.argument_infos.first, 0..19, 0..9, {key: :value})
    end

    it "allows assigning to all columns of a range of rows" do
      @args[1..4] = {key: :value}
      check_argument_info(@args.argument_infos.first, 1..4, 0..9, {key: :value})
    end

    it "allows assigning to the intersection of a range of rows with a range of columns" do
      @args[1..4, 3..5] = {key: :value}
      check_argument_info(@args.argument_infos.first, 1..4, 3..5, {key: :value})
    end

    it "allows selecting a single row or column" do
      @args[1, 3] = {key: :value}
      check_argument_info(@args.argument_infos.first, 1..1, 3..3, {key: :value})
    end

    it "allows using negative indices" do
      @args[-3..-1, -5..-2] = {key: :value}
      check_argument_info(@args.argument_infos.first, 17..19, 5..8, {key: :value})
    end

    it "allows using stepped ranges" do
      @args[(0..-1).step(2)] = {key: :value}
      check_argument_info(@args.argument_infos.first, (0..19).step(2), 0..9, {key: :value})
    end
  end

  describe "retrieve_arguments_for" do
    it "merges all argument hashes, with later defined ones overridding prior ones" do
      @args[] = {key: :value, a: :b}
      @args[3..7] = {a: :c}
      @args[5, 6] = {e: :f}
      assert_equal({key: :value, a: :c, e: :f}, @args.retrieve_arguments_for(5, 6))
    end

    it "deep merges the :cell keys in order of definition" do
      @args[3..7] = {cell: {a: :y, e: :f}}
      @args[] = {cell: {a: :b, c: :d}}
      @args[5, 6] = {cell: {a: :z}}
      assert_equal({cell: {a: :z, c: :d, e: :f}}, @args.retrieve_arguments_for(5, 6))
      assert_equal({cell: {a: :b, c: :d}}, @args.retrieve_arguments_for(1, 2))
    end
  end
end

describe HexaPDF::Document::Layout do
  before do
    @doc = HexaPDF::Document.new
    @doc.config['font.on_invalid_glyph'] = lambda do |codepoint, _invalid_glyph|
      [@doc.fonts.add('ZapfDingbats').decode_codepoint(codepoint)]
    end
    @layout = @doc.layout
  end

  describe "style" do
    it "creates a new style if it does not exist based on the base argument" do
      @layout.style(:base, font_size: 20)
      assert_equal(20, @layout.style(:newstyle, subscript: true).font_size)
      refute(@layout.style(:base).subscript)
      assert_equal(10, @layout.style(:another_new, base: nil).font_size)
      assert(@layout.style(:yet_another_new, base: :newstyle).subscript)
    end

    it "returns the named style" do
      assert_kind_of(HexaPDF::Layout::Style, @layout.style(:base))
    end

    it "updates the style with the given properties" do
      assert_equal(20, @layout.style(:base, font_size: 20).font_size)
    end
  end

  describe "style?" do
    it "returns true if a given style is defined" do
      assert(@layout.style?(:base))
    end

    it "returns false if a given style is not defined" do
      refute(@layout.style?(:unknown))
    end
  end

  describe "styles" do
    it "returns the existing styles" do
      @layout.style(:test, font_size: 20)
      assert_equal([:base, :test], @layout.styles.keys)
    end

    it "sets multiple styles at once" do
      styles = @layout.styles(
        test: {font_size: 20},
        test2: {font_size: 30},
      )
      assert_same(styles, @layout.styles)
      assert_equal([:base, :test, :test2], @layout.styles.keys)
    end
  end

  describe "resolve_font" do
    it "resolves a font name to a font wrapper" do
      style = @layout.style(:other, font: 'Helvetica')
      @layout.resolve_font(style)
      assert_kind_of(HexaPDF::Font::Type1Wrapper, style.font)
    end

    it "uses the font_bold property when resolving a font name to a font wrapper" do
      style = @layout.style(:other, font: 'Helvetica', font_bold: true)
      @layout.resolve_font(style)
      assert_equal('Helvetica-Bold', style.font.wrapped_font.font_name)
    end

    it "uses the font_italic property when resolving a font name to a font wrapper" do
      style = @layout.style(:other, font: 'Helvetica', font_italic: true)
      @layout.resolve_font(style)
      assert_equal('Helvetica-Oblique', style.font.wrapped_font.font_name)
    end

    it "sets the :base style's font if no font is set" do
      @layout.style(:base, font: 'Helvetica')
      style = @layout.style(:other, base: nil, font_italic: true)
      @layout.resolve_font(style)
      assert_equal('Helvetica-Oblique', style.font.wrapped_font.font_name)
    end

    it "sets the font specified in the config option font.default as fallback" do
      style = @layout.style(:other, base: nil, font_italic: true)
      @layout.resolve_font(style)
      assert_equal('Times-Italic', style.font.wrapped_font.font_name)
    end
  end

  describe "inline_box" do
    it "takes a box as argument" do
      box = HexaPDF::Layout::Box.create(width: 10, height: 10)
      ibox = @layout.inline_box(box)
      assert_same(box, ibox.box)
    end

    it "correctly passes on the valign argument" do
      box = HexaPDF::Layout::Box.create(width: 10, height: 10)
      ibox = @layout.inline_box(box, valign: :top)
      assert_equal(:top, ibox.valign)
    end

    it "can create a box using any box creation method of the Layout class" do
      ibox = @layout.inline_box(:text, "Some text", valign: :bottom, width: 10, background_color: "red")
      assert_equal(:bottom, ibox.valign)
      assert_equal(10, ibox.width)
      assert_equal("red", ibox.box.style.background_color)
    end
  end

  describe "box" do
    it "creates the request box" do
      box = @layout.box(:column, columns: 3, width: 15, height: 30,
                        style: {font_size: 10, box_options: {gaps: 20}},
                        properties: {key: :value})
      assert_equal(15, box.width)
      assert_equal(30, box.height)
      assert_equal([-1, -1, -1], box.columns)
      assert_equal([20], box.gaps)
      assert_equal(10, box.style.font_size)
      assert_equal({key: :value}, box.properties)
    end

    it "allows specifying the box's children via a provided block" do
      box = @layout.box(:column) do |column|
        column.lorem_ipsum
        column.lorem_ipsum
      end
      assert_equal(2, box.children.size)
    end

    it "uses the provided block as drawing block for the base box class if name=:base" do
      block = proc {}
      box = @layout.box(width: 100, &block)
      assert_equal(block, box.instance_variable_get(:@draw_block))
    end

    it "fails if the name is not registered" do
      assert_raises(HexaPDF::Error) { @layout.box(:unknown) }
    end
  end

  describe "text_fragments" do
    it "creates an array of text fragments with fallback glyph support" do
      result = @layout.text_fragments("Tom✂")
      assert_equal(2, result.size)
      assert_equal(@doc.fonts.add('ZapfDingbats'), result[1].style.font)

      @doc.config['font.on_invalid_glyph'] = nil
      assert_equal(1, @layout.text_fragments("Tom✂").size)
    end

    it "uses the standard rules for creating the style object" do
      @layout.style(:named, font_size: 20)
      result = @layout.text_fragments("Test", style: :named)
      assert_equal(20, result[0].style.font_size)
    end

    it "optionally assigns the properties to all fragments" do
      result = @layout.text_fragments("Tom✂", properties: {key: :value})
      assert_equal(:value, result[0].properties[:key])
      assert_equal(:value, result[1].properties[:key])
    end
  end

  describe "text_box" do
    it "creates a text box" do
      box = @layout.text_box("Test✂", width: 10, height: 15, properties: {key: :value})
      assert_equal(10, box.width)
      assert_equal(15, box.height)
      assert_same(@doc.fonts.add("Times"), box.style.font)
      items = box.instance_variable_get(:@items)
      assert_equal(2, items.length)
      assert_same(box.style, items.first.style)
      assert_equal({key: :value}, box.properties)
    end

    it "allows setting of a custom style" do
      style = HexaPDF::Layout::Style.new(font_size: 20, font: ['Times', {variant: :bold}])
      box = @layout.text_box("Test", style: style)
      assert_same(box.style, style)
      assert_same(@doc.fonts.add("Times", variant: :bold), box.style.font)
      assert_equal(20, box.style.font_size)

      box = @layout.text_box("Test", style: {font_size: 20})
      assert_same(@doc.fonts.add("Times"), box.style.font)
      assert_equal(20, box.style.font_size)

      @layout.style(:base, font: ['Times', {variant: :bold}])
      box = @layout.text_box("Test", style: {font_size: 20})
      assert_same(@doc.fonts.add("Times", variant: :bold), box.style.font)
      assert_equal(20, box.style.font_size)

      @layout.style(:named, font_size: 20)
      box = @layout.text_box("Test", style: :named)
      assert_equal(20, box.style.font_size)
    end

    it "updates the used style with the provided options" do
      box = @layout.text_box("Test", style: {subscript: true}, font_size: 20)
      assert_equal(20, box.style.font_size)
    end

    it "allows using a box style different from the text style" do
      style = HexaPDF::Layout::Style.new(font_size: 20)
      box = @layout.text_box("Test", box_style: style)
      refute_same(box.instance_variable_get(:@items).first.style, style)
      assert_same(box.style, style)

      @layout.style(:named, font_size: 20)
      box = @layout.text_box("Test", box_style: :named)
      assert_equal(20, box.style.font_size)
    end

    it "raises an error if the to-be-used style doesn't exist" do
      assert_raises(HexaPDF::Error) { @layout.text_box("Test", style: :unknown) }
    end
  end

  describe "formatted_text" do
    it "creates a text box with the given text" do
      box = @layout.formatted_text_box(["Test✂"], width: 10, height: 15)
      assert_equal(10, box.width)
      assert_equal(15, box.height)
      assert_equal(2, box.instance_variable_get(:@items).length)
    end

    it "allows setting custom properties on the whole box" do
      box = @layout.formatted_text_box([{text: "Test", properties: {key: :novalue}}],
                                       properties: {key: :value})
      assert_equal({key: :value}, box.properties)
    end

    it "allows using a hash with :text key instead of a simple string" do
      box = @layout.formatted_text_box([{text: "Test✂"}])
      items = box.instance_variable_get(:@items)
      assert_equal(2, items.length)
      assert_equal(4, items[0].items.length)
    end

    it "uses an empty string if the :text key for a hash is not specified" do
      box = @layout.formatted_text_box([{font_size: "Test"}])
      items = box.instance_variable_get(:@items)
      assert_equal(0, items[0].items.length)
    end

    it "allows setting a custom base style for all parts" do
      box = @layout.formatted_text_box(["Test", "other"], font_size: 20)
      items = box.instance_variable_get(:@items)
      assert_equal(20, box.style.font_size)
      assert_equal(20, items[0].style.font_size)
      assert_equal(20, items[1].style.font_size)
    end

    it "allows using custom style properties for a single part" do
      box = @layout.formatted_text_box([{text: "Test", font_size: 20}, "test"], text_align: :center)
      items = box.instance_variable_get(:@items)
      assert_equal(10, box.style.font_size)

      assert_equal(20, items[0].style.font_size)
      assert_equal(:center, items[0].style.text_align)

      assert_equal(10, items[1].style.font_size)
      assert_equal(:center, items[1].style.text_align)
    end

    it "allows using a custom style as basis for a single part" do
      box = @layout.formatted_text_box([{text: "Test", style: {font_size: 20}, subscript: true},
                                        "test"], text_align: :center)
      items = box.instance_variable_get(:@items)
      assert_equal(10, box.style.font_size)

      assert_equal(20, items[0].style.font_size)
      assert_equal(:left, items[0].style.text_align)
      assert(items[0].style.subscript)

      assert_equal(10, items[1].style.font_size)
      assert_equal(:center, items[1].style.text_align)
      refute(items[1].style.subscript)
    end

    it "allows specifying a link to an URL via the :link key" do
      box = @layout.formatted_text_box([{text: "Test", link: "URI"}, {link: "URI"}, "test"])
      items = box.instance_variable_get(:@items)
      assert_equal(3, items.length)
      assert_equal(4, items[0].items.length, "text should be Test")
      assert_equal(3, items[1].items.length, "text should be URI")
      assert_equal([:link, {uri: 'URI'}], items[0].style.overlays.instance_variable_get(:@layers)[0])
      refute(items[2].style.overlays?)
    end

    it "allows setting custom properties" do
      box = @layout.formatted_text_box([{text: 'test', properties: {named_dest: 'test'}}])
      items = box.instance_variable_get(:@items)
      assert_equal({named_dest: 'test'}, items[0].properties)
    end

    it "allows adding an inline box" do
      ibox = @layout.inline_box(:base, width: 10, height: 10)
      box = @layout.formatted_text_box([ibox])
      assert_equal(ibox, box.instance_variable_get(:@items).first)
    end

    it "allows creating an inline box through a hash with a :box key" do
      block = lambda {|item| item.box(:base, width: 5, height: 15) }
      box = @layout.formatted_text_box([{box: :column, columns: 1, width: 100, block: block}])
      ibox = box.instance_variable_get(:@items).first
      ibox.fit_wrapped_box(nil)
      assert_equal(100, ibox.width)
      assert_equal(15, ibox.height)
    end

    it "fails if the data array contains unsupported items" do
      assert_raises(ArgumentError) { @layout.formatted_text_box([5]) }
    end
  end

  describe "image_box" do
    it "creates an image box" do
      image_path = File.join(TEST_DATA_DIR, 'images', 'gray.jpg')

      box = @layout.image_box(image_path, width: 10, height: 15, style: {font_size: 20},
                              properties: {key: :value}, subscript: true)
      assert_equal(10, box.width)
      assert_equal(15, box.height)
      assert_equal(20, box.style.font_size)
      assert(box.style.subscript)
      assert_same(@doc.images.add(image_path), box.image)
      assert_equal({key: :value}, box.properties)
    end

    it "allows using a form XObject" do
      form = @doc.add({Type: :XObject, Subtype: :Form, BBox: [0, 0, 10, 10]})
      box = @layout.image_box(form, width: 10)
      assert_equal(10, box.width)
      assert_same(form, box.image)
    end
  end

  describe "table_box" do
    it "creates a table box" do
      box = @layout.table_box([['m']], header: proc { [['a']] },
                              footer: proc { [['b']] }, cell_style: {background_color: "red"},
                              width: 100, height: 300, style: {background_color: "blue"},
                              box_options: {column_widths: [100]},
                              properties: {key: :value}, border: {width: 1})
      assert_equal(100, box.width)
      assert_equal(300, box.height)
      assert_equal("blue", box.style.background_color)
      assert_equal(1, box.style.border.width.left)
      assert_equal({key: :value}, box.properties)
      assert_equal(HexaPDF::Layout::TextBox, box.cells[0, 0].children.class)
      assert_equal([100], box.column_widths)
      assert_equal('a', box.header_cells[0, 0].children)
      assert_equal('b', box.footer_cells[0, 0].children)
    end

    it "doesn't modify the children of cells if they are already in the correct form" do
      image_path = File.join(TEST_DATA_DIR, 'images', 'gray.jpg')
      cell0 = @layout.text('a')
      cell1 = [@layout.text('b'), @layout.image(image_path)]
      box = @layout.table_box([[cell0, cell1]])
      assert_same(cell0, box.cells[0, 0].children)
      assert_same(cell1, box.cells[0, 1].children)
    end

    it "converts cells containing other than Box and Array instances" do
      box = @layout.table_box([['a', 5]])
      assert_kind_of(HexaPDF::Layout::TextBox, box.cells[0, 0].children)
      assert_kind_of(HexaPDF::Layout::TextBox, box.cells[0, 1].children)
    end

    it "allows customizing the creation arguments" do
      box = @layout.table_box([['a']]) do |args|
        args[] = {font_size: 20}
      end
      assert_equal(20, box.cells[0, 0].children.style.font_size)
      refute_equal(20, box.cells[0, 0].style.font_size)
    end

    it "allows styling table cells themselves" do
      box = @layout.table_box([['a', @layout.text('b')]]) do |args|
        args[] = {cell: {background_color: "green"}}
      end
      assert_equal('green', box.cells[0, 0].style.background_color)
      assert_nil(box.cells[0, 0].children.style.background_color)
      assert_equal('green', box.cells[0, 1].style.background_color)
    end
  end

  describe "lorem_ipsum_box" do
    it "creates a standard lorem ipsum box" do
      box = @layout.lorem_ipsum_box(width: 10, height: 15, font_size: 15)
      assert_equal(10, box.width)
      assert_equal(15, box.height)
      items = box.instance_variable_get(:@items)
      assert_equal(HexaPDF::Document::Layout::LOREM_IPSUM.join(" ").size, items[0].items.length)
    end

    it "can use just some sentences from the lorem ipsum text" do
      box = @layout.lorem_ipsum_box(sentences: 1)
      items = box.instance_variable_get(:@items)
      assert_equal(HexaPDF::Document::Layout::LOREM_IPSUM[0].size, items[0].items.length)
    end

    it "can use multiple of the selected sentences" do
      box = @layout.lorem_ipsum_box(sentences: 2, count: 2)
      items = box.instance_variable_get(:@items)
      assert_equal(HexaPDF::Document::Layout::LOREM_IPSUM[0, 2].join(" ").size * 2 + 2, items[0].items.length)
    end
  end

  describe "method_missing" do
    it "resolves to internal methods with the _box suffix, e.g. text_box" do
      box = @layout.text("Test", width: 10, height: 15, properties: {key: :value})
      assert_kind_of(HexaPDF::Layout::TextBox, box)
      assert_equal(10, box.width)
      assert_equal(15, box.height)
      assert_equal({key: :value}, box.properties)
    end

    it "resolves to the box method when a configured name is used" do
      box = @layout.column
      assert_kind_of(HexaPDF::Layout::ColumnBox, box)
      box = @layout.column_box
      assert_kind_of(HexaPDF::Layout::ColumnBox, box)
    end

    it "fails if nothing could be resolved" do
      assert_raises(NameError) { @layout.unknown }
    end
  end

  describe "respond_to_missing?" do
    it "can be asked which methods it supports" do
      assert(@layout.respond_to?(:text))
      assert(@layout.respond_to?(:column))
      refute(@layout.respond_to?(:unknown))
    end
  end
end
