# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/document'
require 'hexapdf/layout/table_box'

describe HexaPDF::Layout::TableBox::Cell do
  before do
    @frame = HexaPDF::Layout::Frame.new(0, 0, 0, 0)
  end

  def create_cell(**kwargs)
    HexaPDF::Layout::TableBox::Cell.new(row: 1, column: 1, **kwargs)
  end

  describe "initialize" do
    it "creates a new instance with the given arguments" do
      cell = create_cell(children: [:a], row: 5, column: 3, row_span: 7, col_span: 2,
                         style: {background_color: 'blue', padding: 3, border: {width: 3}})
      assert_equal([:a], cell.children)
      assert_equal(5, cell.row)
      assert_equal(3, cell.column)
      assert_equal(7, cell.row_span)
      assert_equal(2, cell.col_span)
      assert_equal('blue', cell.style.background_color)
      assert_equal(3, cell.style.padding.left)
      assert_equal(3, cell.style.border.width.left)
    end

    it "uses defaults for attributes that were not given" do
      cell = create_cell
      assert_equal(1, cell.row_span)
      assert_equal(1, cell.col_span)
    end

    it "uses defaults for the border and padding" do
      cell = create_cell
      assert(cell.style.border.width.simple?)
      assert_equal(1, cell.style.border.width.left)
      assert(cell.style.padding.simple?)
      assert_equal(5, cell.style.padding.left)
    end
  end

  describe "empty?" do
    it "returns true if the cell has not been fit yet" do
      cell = create_cell(children: [:a], style: {border: {width: 0}})
      assert(cell.empty?)
    end

    it "returns true if the cell has no content" do
      cell = create_cell(children: nil, style: {border: {width: 0}})
      cell.fit(100, 100, @frame)
      assert(cell.empty?)
    end
  end

  describe "update_height" do
    it "updates the height to the correct one" do
      cell = create_cell(children: HexaPDF::Layout::Box.create(width: 10, height: 10))
      cell.fit(100, 100, @frame)
      assert_equal(22, cell.height)
      cell.update_height(50)
      assert_equal(50, cell.height)
    end

    it "fails if the given height is smaller than the one determined during #fit" do
      cell = create_cell(children: HexaPDF::Layout::Box.create(width: 10, height: 10))
      cell.fit(100, 100, @frame)
      err = assert_raises(HexaPDF::Error) { cell.update_height(5) }
      assert_match(/at least as big/, err.message)
    end
  end

  describe "fit" do
    it "fits a single box" do
      cell = create_cell(children: HexaPDF::Layout::Box.create(width: 20, height: 10))
      assert(cell.fit(100, 100, @frame).success?)
      assert_equal(100, cell.width)
      assert_equal(22, cell.height)
      assert_equal(32, cell.preferred_width)
      assert_equal(22, cell.preferred_height)
    end

    it "fits a single box with horizontal aligning not being :left" do
      cell = create_cell(children: HexaPDF::Layout::Box.create(width: 20, height: 10, align: :center))
      assert(cell.fit(100, 100, @frame).success?)
      assert_equal(66, cell.preferred_width)
    end

    it "fits multiple boxes" do
      box1 = HexaPDF::Layout::Box.create(width: 20, height: 10)
      box2 = HexaPDF::Layout::Box.create(width: 50, height: 15)
      cell = create_cell(children: [box1, box2])
      assert(cell.fit(100, 100, @frame).success?)
      assert_equal(100, cell.width)
      assert_equal(37, cell.height)
      assert_equal(62, cell.preferred_width)
      assert_equal(37, cell.preferred_height)
    end

    it "fits multiple boxes with horizontal aligning not being :left" do
      box1 = HexaPDF::Layout::Box.create(width: 20, height: 10, align: :center)
      box2 = HexaPDF::Layout::Box.create(width: 50, height: 15)
      cell = create_cell(children: [box1, box2])
      assert(cell.fit(100, 100, @frame).success?)
      assert_equal(66, cell.preferred_width)
    end

    it "fits the cell even if it has no content" do
      cell = create_cell(children: nil)
      assert(cell.fit(100, 100, @frame).success?)
      assert_equal(100, cell.width)
      assert_equal(12, cell.height)
      assert_equal(12, cell.preferred_width)
      assert_equal(12, cell.preferred_height)
    end

    it "respects the set minimum height of the cell" do
      cell = create_cell(children: HexaPDF::Layout::Box.create(width: 20, height: 10), min_height: 30)
      assert(cell.fit(100, 25, @frame).failure?)

      assert(cell.fit(100, 100, @frame).success?)
      assert_equal(30, cell.height)

      cell = create_cell(children: HexaPDF::Layout::Box.create(width: 20, height: 20), min_height: 2)
      assert(cell.fit(100, 100, @frame).success?)
      assert_equal(32, cell.height)
    end

    it "doesn't fit children that are too big" do
      cell = create_cell(children: HexaPDF::Layout::Box.create(width: 300, height: 20))
      assert(cell.fit(100, 100, @frame).failure?)
      cell = create_cell(children: [HexaPDF::Layout::Box.create(width: 300, height: 20)])
      assert(cell.fit(100, 100, @frame).failure?)
    end

    it "doesn't fit anything if the available width or height are too small even if there are no children" do
      cell = create_cell(children: nil)
      assert(cell.fit(10, 100, @frame).failure?)
      assert(cell.fit(100, 10, @frame).failure?)
    end
  end

  describe "draw" do
    before do
      @canvas = HexaPDF::Document.new.pages.add.canvas
    end

    it "draws the boxes at the correct location" do
      draw_block = lambda {|canvas, _| canvas.move_to(0, 0).end_path }
      box1 = HexaPDF::Layout::Box.create(width: 20, height: 10, align: :center, &draw_block)
      box2 = HexaPDF::Layout::Box.create(width: 50, height: 15, &draw_block)
      box = create_cell(children: [box1, box2])
      box.fit(100, 100, @frame)
      box.draw(@canvas, 10, 75)
      operators = [[:save_graphics_state],
                   [:append_rectangle, [10.0, 75.0, 100.0, 37.0]],
                   [:stroke_path],
                   [:restore_graphics_state],
                   [:save_graphics_state],
                   [:concatenate_matrix, [1, 0, 0, 1, 50.0, 96]],
                   [:move_to, [0, 0]],
                   [:end_path],
                   [:restore_graphics_state],
                   [:save_graphics_state],
                   [:concatenate_matrix, [1, 0, 0, 1, 16, 81]],
                   [:move_to, [0, 0]],
                   [:end_path],
                   [:restore_graphics_state]]
      assert_operators(@canvas.contents, operators)
    end

    it "works for a cell without content" do
      box = create_cell(children: nil, style: {border: {width: 0}})
      box.fit(100, 100, @frame)
      box.draw(@canvas, 10, 75)
      assert_operators(@canvas.contents, [])
    end
  end

  it "returns a useful representation when inspecting" do
    cell = create_cell(row: 3, column: 2, row_span: 2, col_span: 3, children: [:a, "b"])
    assert_equal("<Cell (3,2) 2x3 [Symbol, String]>", cell.inspect)
  end
end

describe HexaPDF::Layout::TableBox::Cells do
  def create_cells(data, cell_style = nil)
    HexaPDF::Layout::TableBox::Cells.new(data, cell_style: cell_style)
  end

  describe "intialize" do
    it "works with simple data" do
      cells = create_cells([[:a]])
      assert_equal(1, cells.number_of_columns)
      assert_equal(1, cells.number_of_rows)
      assert_equal(:a, cells[0, 0].children)

      cells = create_cells([[:a, :b, :c]])
      assert_equal(3, cells.number_of_columns)
      assert_equal(1, cells.number_of_rows)
      assert_equal(:a, cells[0, 0].children)
      assert_equal(:b, cells[0, 1].children)
      assert_equal(:c, cells[0, 2].children)

      cells = create_cells([[:a], [:b], [:c]])
      assert_equal(1, cells.number_of_columns)
      assert_equal(3, cells.number_of_rows)
      assert_equal(:a, cells[0, 0].children)
      assert_equal(:b, cells[1, 0].children)
      assert_equal(:c, cells[2, 0].children)

      cells = create_cells([[:a, :b], [:c, :d, :e], [:f]])
      assert_equal(3, cells.number_of_columns)
      assert_equal(3, cells.number_of_rows)
      assert_equal(:a, cells[0, 0].children)
      assert_equal(:b, cells[0, 1].children)
      assert_nil(cells[0, 2])
      assert_equal(:c, cells[1, 0].children)
      assert_equal(:d, cells[1, 1].children)
      assert_equal(:e, cells[1, 2].children)
      assert_equal(:f, cells[2, 0].children)
      assert_nil(cells[2, 1])
      assert_nil(cells[2, 2])
    end

    it "can handle column spans" do
      cells = create_cells([[{col_span: 2, content: :a}, :b], [:c, {col_span: 3, content: :d}]])
      assert_equal(4, cells.number_of_columns)
      assert_equal(2, cells.number_of_rows)
      assert_equal(:a, cells[0, 0].children)
      assert_same(cells[0, 0], cells[0, 1])
      assert_equal(:b, cells[0, 2].children)
      assert_equal(:c, cells[1, 0].children)
      assert_equal(:d, cells[1, 1].children)
      assert_same(cells[1, 1], cells[1, 2])
      assert_same(cells[1, 1], cells[1, 3])
    end

    it "can handle row spans" do
      cells = create_cells([[{row_span: 2, content: :a}, :b], [{row_span: 2, content: :c}], [:d]])
      assert_equal(2, cells.number_of_columns)
      assert_equal(3, cells.number_of_rows)
      assert_equal(:a, cells[0, 0].children)
      assert_equal(:b, cells[0, 1].children)
      assert_same(cells[0, 0], cells[1, 0])
      assert_equal(:c, cells[1, 1].children)
      assert_equal(:d, cells[2, 0].children)
      assert_same(cells[1, 1], cells[2, 1])
    end

    it "can handle column and row spans concurrently" do
      cells = create_cells([[:a, {col_span: 2, content: :b}, :c],
                            [{col_span: 2, row_span: 2, content: :d}, :e, :f],
                            [{row_span: 2, content: :g}, :h],
                            [:i, :j, :k]])
      assert_equal(:a, cells[0, 0].children)
      assert_equal(:b, cells[0, 1].children)
      assert_same(cells[0, 1], cells[0, 2])
      assert_equal(:c, cells[0, 3].children)
      assert_equal(:d, cells[1, 0].children)
      assert_same(cells[1, 0], cells[1, 1])
      assert_equal(:e, cells[1, 2].children)
      assert_equal(:f, cells[1, 3].children)
      assert_same(cells[1, 0], cells[2, 0])
      assert_same(cells[1, 0], cells[2, 1])
      assert_equal(:g, cells[2, 2].children)
      assert_equal(:h, cells[2, 3].children)
      assert_equal(:i, cells[3, 0].children)
      assert_equal(:j, cells[3, 1].children)
      assert_same(cells[2, 2], cells[3, 2])
      assert_equal(:k, cells[3, 3].children)
    end

    it "sets the correct information on the created cells" do
      cells = create_cells([[:a, {col_span: 2, content: :b, min_height: 30}],
                            [{col_span: 2, row_span: 2, content: :c}, {row_span: 2, content: :d}]])
      assert_equal(0, cells[0, 0].row)
      assert_equal(0, cells[0, 0].column)
      assert_equal(1, cells[0, 0].row_span)
      assert_equal(1, cells[0, 0].col_span)
      assert_equal(0, cells[0, 1].row)
      assert_equal(1, cells[0, 1].column)
      assert_equal(1, cells[0, 1].row_span)
      assert_equal(2, cells[0, 1].col_span)
      assert_equal(30, cells[0, 1].instance_variable_get(:@min_height))
      assert_equal(1, cells[1, 0].row)
      assert_equal(0, cells[1, 0].column)
      assert_equal(2, cells[1, 0].row_span)
      assert_equal(2, cells[1, 0].col_span)
      assert_equal(1, cells[1, 2].row)
      assert_equal(2, cells[1, 2].column)
      assert_equal(2, cells[1, 2].row_span)
      assert_equal(1, cells[1, 2].col_span)
    end

    it "allows setting cell styles and properties" do
      cells = create_cells([[{content: :a, background_color: 'black', properties: {'x' => 'y'}}]])
      assert_equal('black', cells[0, 0].style.background_color)
      assert_equal('y', cells[0, 0].properties['x'])
    end

    it "allows setting styles for all cells using a hash as first item in data" do
      cells = create_cells([{background_color: 'black'}, [:a, :b], [:c, :d]])
      assert_equal('black', cells[0, 0].style.background_color)
      assert_equal('black', cells[1, 0].style.background_color)
    end

    it "allows setting styles for all cells using a proc as first item in data" do
      block = lambda {|cell| cell.style.background_color = 'black' if cell.row == 0 }
      cells = create_cells([block, [:a, :b], [:c, :d]])
      assert_equal('black', cells[0, 0].style.background_color)
      assert_nil(cells[1, 0].style.background_color)
    end

    it "allows setting styles for all cells using a hash as the cell_style argument" do
      cells = create_cells([[:a, :b], [:c, :d]], {background_color: 'black'})
      assert_equal('black', cells[0, 0].style.background_color)
      assert_equal('black', cells[1, 0].style.background_color)
    end

    it "allows setting styles for all cells using a proc as the cell_style argument" do
      block = lambda {|cell| cell.style.background_color = 'black' if cell.row == 0 }
      cells = create_cells([[:a, :b], [:c, :d]], block)
      assert_equal('black', cells[0, 0].style.background_color)
      assert_nil(cells[1, 0].style.background_color)
    end

    it "only uses the styling informtion from data if a cell_style argument is also provided" do
      cells = create_cells([{background_color: 'yellow'}, [:a, :b], [:c, :d]], {background_color: 'black'})
      assert_equal('yellow', cells[0, 0].style.background_color)
    end

    it "makes sure that cell styling information overrides global styling information" do
      block = lambda do |cell|
        cell.style.background_color = 'yellow'
        cell.properties['key'] = :value
      end
      cells = create_cells([block, [{background_color: 'black', properties: {'key' => 5}, content: :a}, :b],
                            [:c, :d]])
      assert_equal('black', cells[0, 0].style.background_color)
      assert_equal(5, cells[0, 0].properties['key'])
    end
  end

  describe "each_row" do
    it "allows iterating over rows" do
      cells = create_cells([[:a, :b], [:c], [:d, :e]])
      assert_equal([[:a, :b], [:c], [:d, :e]], cells.each_row.map {|cols| cols.map(&:children) })
    end
  end

  describe "style" do
    it "assigns the style properties to all cells" do
      cells = create_cells([[:a, :b], [:c, :d]])
      cells.style(background_color: 'blue')
      assert_equal('blue', cells[0, 0].style.background_color)
      assert_equal('blue', cells[0, 1].style.background_color)
      assert_equal('blue', cells[1, 0].style.background_color)
      assert_equal('blue', cells[1, 1].style.background_color)
    end

    it "calls the given block for all cells" do
      cells = create_cells([[:a, :b], [:c, :d]])
      cells.style(background_color: 'blue') {|cell| cell.style.background_color = 'red' if cell.row == 0 }
      assert_equal('red', cells[0, 0].style.background_color)
      assert_equal('red', cells[0, 1].style.background_color)
      assert_equal('blue', cells[1, 0].style.background_color)
      assert_equal('blue', cells[1, 1].style.background_color)
    end
  end

  #fit_rows and draw_rows are tested through TableBox#fit/#draw
end

describe HexaPDF::Layout::TableBox do
  before do
    @doc = HexaPDF::Document.new
    @page = @doc.pages.add
    @frame = HexaPDF::Layout::Frame.new(0, 0, 160, 100, context: @page)
    @draw_block = lambda {|canvas, _box| canvas.move_to(0, 0).end_path }
    @fixed_size_boxes = 15.times.map { HexaPDF::Layout::Box.new(width: 20, height: 10, &@draw_block) }
  end

  def create_box(**kwargs)
    HexaPDF::Layout::TableBox.new(cells: [@fixed_size_boxes[0, 2], @fixed_size_boxes[2, 2]], **kwargs)
  end

  def check_box(box, fit_status, width, height, cell_data = nil)
    assert_equal(fit_status, box.fit(@frame.available_width, @frame.available_height, @frame).status)
    assert_equal(width, box.width, "box width")
    assert_equal(height, box.height, "box height")
    if cell_data
      cells = box.cells.each_row.to_a.flatten
      assert_equal(cells.size, cell_data.size)
      cell_data.each_with_index do |(left, top, cwidth, cheight), index|
        cell = cells[index]
        if left.nil?
          assert_nil(cell.left, "cell #{index} left")
        else
          assert_equal(left, cell.left, "cell #{index} left")
        end
        if top.nil?
          assert_nil(cell.top, "cell #{index} top")
        else
          assert_equal(top, cell.top, "cell #{index} top")
        end
        assert_equal(cwidth, cell.width, "cell #{index} width")
        assert_equal(cheight, cell.height, "cell #{index} height")
      end
    end
    box
  end

  def cell_infos(cells)
    cells.each_row.map {|cols| cols.map {|c| [c.left, c.top, c.width, c.height] } }.flatten(1)
  end

  describe "initialize" do
    it "creates a new instance with the default arguments" do
      box = create_box(cells: [[:a, :b], [:c]])
      assert_equal([[:a, :b], [:c]], box.cells.each_row.map {|cols| cols.map(&:children) })
      assert_equal([], box.column_widths)
      assert_nil(box.header_cells)
      assert_nil(box.footer_cells)
      assert_equal(0, box.start_row_index)
      assert_equal(-1, box.last_fitted_row_index)
      refute(box.supports_position_flow?)
    end

    it "creates a new instance with the given arguments" do
      header = lambda {|_| [[:h1, :h2]] }
      footer = lambda {|_| [[:f1], [:f2]] }
      box = create_box(cells: [[:a, :b], [:c]], column_widths: [-2, -1], header: header, footer: footer,
                       cell_style: {background_color: 'black'})
      assert_equal([[:a, :b], [:c]], box.cells.each_row.map {|cols| cols.map(&:children) })
      assert_equal([[:h1, :h2]], box.header_cells.each_row.map {|cols| cols.map(&:children) })
      assert_equal([[:f1], [:f2]], box.footer_cells.each_row.map {|cols| cols.map(&:children) })
      assert_equal([-2, -1], box.column_widths)
      [box.cells[0, 0], box.header_cells[0, 0], box.footer_cells[0, 0]].each do |cell|
        assert_equal('black', cell.style.background_color)
      end
    end

    it "also applies the cell_style information to header and footer cells of split boxes" do
      header = lambda {|_| [[nil]] }
      footer = lambda {|_| [[nil]] }
      box = create_box(header: header, footer: footer, cells: [[nil], [nil]],
                       cell_style: {background_color: 'black'})
      assert(box.fit(100, 40, @frame).overflow?)
      box_a, box_b = box.split
      assert_same(box_a, box)
      assert_equal('black', box_b.header_cells[0, 0].style.background_color)
      assert_equal('black', box_b.footer_cells[0, 0].style.background_color)
    end

    it "allows providing a Cells instance instead of an array of arrays" do
      box = create_box(cells: HexaPDF::Layout::TableBox::Cells.new([[:a, :b]]))
      assert_equal(:a, box.cells[0, 0].children)
    end
  end

  describe "empty?" do
    it "is empty if nothing is fit yet" do
      assert(create_box.empty?)
    end

    it "is empty if not as single row fits" do
      box = create_box(column_widths: [5])
      box.fit(@frame.available_width, @frame.available_height, @frame)
      assert(box.empty?)
    end

    it "is not empty if at least one box fits" do
      box = create_box
      box.fit(@frame.available_width, @frame.available_height, @frame)
      refute(box.empty?)
    end
  end

  describe "fit" do
    it "respects the set initial width" do
      box = create_box(width: 50)
      box.fit(@frame.available_width, @frame.available_height, @frame)
      assert_equal(50, box.width)
    end

    it "respects the set initial height" do
      box = create_box(height: 50)
      box.fit(@frame.available_width, @frame.available_height, @frame)
      assert_equal(50, box.height)
    end

    it "respects the border and padding" do
      box = create_box(column_widths: [40, 40], style: {border: {width: [5, 4, 3, 2]}, padding: [5, 4, 3, 2]})
      box.fit(@frame.available_width, @frame.available_height, @frame)
      assert_equal(93, box.width)
      assert_equal(61, box.height)
    end

    it "cannot fit the table if the specified column widths are greater than the available width" do
      box = create_box(column_widths: [200])
      assert(box.fit(@frame.available_width, @frame.available_height, @frame).failure?)
    end

    it "fits a simple table" do
      check_box(create_box, :success, 160, 45,
                [[0, 0, 79.5, 22], [79.5, 0, 79.5, 22], [0, 22, 79.5, 22], [79.5, 22, 79.5, 22]])
    end

    it "fits a table with column and row spans" do
      cells = [[@fixed_size_boxes[0], {col_span: 2, content: @fixed_size_boxes[1]}, @fixed_size_boxes[2]],
               [{col_span: 2, row_span: 2, content: @fixed_size_boxes[3]}, *@fixed_size_boxes[4, 2]],
               [{row_span: 2, content: @fixed_size_boxes[6]}, @fixed_size_boxes[7]],
               @fixed_size_boxes[8, 3]]
      check_box(create_box(cells: cells), :success, 160, 89,
                [[0, 0, 39.75, 22], [39.75, 0, 79.5, 22], [39.75, 0, 79.50, 22], [119.25, 0, 39.75, 22],
                 [0, 22, 79.5, 44], [0, 22, 79.5, 44], [79.5, 22, 39.75, 22], [119.25, 22, 39.75, 22],
                 [0, 22, 79.5, 44], [0, 22, 79.5, 44], [79.5, 44, 39.75, 44], [119.25, 44, 39.75, 22],
                 [0, 66, 39.75, 22], [39.75, 66, 39.75, 22], [79.5, 44, 39.75, 44], [119.25, 66, 39.75, 22]])
    end

    describe "row spans" do
      # ----------
      # | a | b  |
      # | a |    |
      # | a |----|
      # | a | c  |
      # | a |    |
      # ----------
      it "works if content of a row span cell is larger than the rows" do
        cells = [[{row_span: 2, content: @fixed_size_boxes[0..2]}, @fixed_size_boxes[3]],
                 [@fixed_size_boxes[4]]]
        check_box(create_box(cells: cells, cell_style: {padding: 0, border: {width: 0}}),
                  :success, 160, 30,
                  [[0, 0, 80, 30], [80, 0, 80, 15], [0, 0, 80, 30], [80, 15, 80, 15]])
      end

      # ----------
      # | a | b  |
      # |   |----|
      # |   | c  |
      # ----------
      it "works if content of a row span cell is smaller than the rows" do
        cells = [[{row_span: 2, content: @fixed_size_boxes[0]}, @fixed_size_boxes[3]],
                 [@fixed_size_boxes[4]]]
        check_box(create_box(cells: cells, cell_style: {padding: 0, border: {width: 0}}),
                  :success, 160, 20,
                  [[0, 0, 80, 20], [80, 0, 80, 10], [0, 0, 80, 20], [80, 10, 80, 10]])
      end

      # -----------------
      # | a | b | c | d |
      # | a | b |---| d |
      # | a | b | e |   |
      # | a |   | e |   |
      # --------| e |   |
      # | f | g | e |   |
      # ----------------
      it "works if multiple, possibly overlapping row spans are involved" do
        cells = [[{row_span: 2, content: @fixed_size_boxes[0..2]},
                  {row_span: 2, content: @fixed_size_boxes[3..4]},
                  @fixed_size_boxes[5],
                  {row_span: 3, content: @fixed_size_boxes[6..7]}],
                 [{row_span: 2, content: @fixed_size_boxes[8, 3]}],
                 [@fixed_size_boxes[11], @fixed_size_boxes[12]]]
        check_box(create_box(cells: cells, cell_style: {padding: 0, border: {width: 0}}),
                  :success, 160, 40,
                  [[0, 0, 40, 30], [40, 0, 40, 30], [80, 0, 40, 10], [120, 0, 40, 40],
                   [0, 0, 40, 30], [40, 0, 40, 30], [80, 10, 40, 30], [120, 0, 40, 40],
                   [0, 30, 40, 10], [40, 30, 40, 10], [80, 10, 40, 30], [120, 0, 40, 40]])
      end
    end

    it "fits a table with header rows" do
      result = [[0, 0, 80, 10], [80, 0, 80, 10], [0, 10, 80, 10], [80, 10, 80, 10]]
      header = lambda {|_| [@fixed_size_boxes[10, 2], @fixed_size_boxes[12, 2]] }
      box = create_box(header: header, cell_style: {padding: 0, border: {width: 0}})
      box = check_box(box, :success, 160, 40, result)
      assert_equal(result, cell_infos(box.header_cells))
    end

    it "fits a table with footer rows" do
      result = [[0, 0, 80, 10], [80, 0, 80, 10], [0, 10, 80, 10], [80, 10, 80, 10]]
      footer = lambda {|_| [@fixed_size_boxes[10, 2], @fixed_size_boxes[12, 2]] }
      box = create_box(footer: footer, cell_style: {padding: 0, border: {width: 0}})
      box = check_box(box, :success, 160, 40, result)
      assert_equal(result, cell_infos(box.footer_cells))
    end

    it "fits a table with header and footer rows" do
      result = [[0, 0, 80, 10], [80, 0, 80, 10], [0, 10, 80, 10], [80, 10, 80, 10]]
      cell_creator = lambda {|_| [@fixed_size_boxes[10, 2], @fixed_size_boxes[12, 2]] }
      box = create_box(header: cell_creator, footer: cell_creator,
                       cell_style: {padding: 0, border: {width: 0}})
      box = check_box(box, :success, 160, 60, result)
      assert_equal(result, cell_infos(box.header_cells))
      assert_equal(result, cell_infos(box.footer_cells))
    end

    it "fails if the header or footer rows don't fit" do
      cells_creator = lambda {|_| [@fixed_size_boxes[10, 2]] }
      [{header: cells_creator}, {footer: cells_creator}].each do |args|
        box = create_box(**args, cell_style: {padding: 0, border: {width: 0}})
        assert(box.fit(100, 15, @frame).failure?)
      end
    end

    it "partially fits a table if not enough height is available" do
      box = create_box(height: 10, cell_style: {padding: 0, border: {width: 0}})
      check_box(box, :overflow, 160, 10,
                [[0, 0, 80, 10], [80, 0, 80, 10], [nil, nil, 80, 0], [nil, nil, 0, 0]])
    end
  end

  describe "split" do
    it "splits the table if some rows could not be fit into the available region" do
      box = create_box
      assert(box.fit(100, 25, @frame).overflow?)
      box_a, box_b = box.split
      assert_same(box_a, box)
      assert(box_b.split_box?)

      assert_equal(0, box_a.start_row_index)
      assert_equal(0, box_a.last_fitted_row_index)
      assert_equal(1, box_b.start_row_index)
      assert_equal(-1, box_b.last_fitted_row_index)
    end

    it "splits the table correctly when row spans and a too-high cell are involved" do
      cells = [[@fixed_size_boxes[0], @fixed_size_boxes[1]],
               [{row_span: 2, content: @fixed_size_boxes[2]}, @fixed_size_boxes[3]],
               [HexaPDF::Layout::Box.new(width: 20, height: 150, &@draw_block)]]
      box = create_box(cells: cells)

      assert(box.fit(100, 100, @frame).overflow?)
      box_a, box_b = box.split
      assert_same(box_a, box)
      assert(box_b.split_box?)
      assert_equal(0, box_a.start_row_index)
      assert_equal(0, box_a.last_fitted_row_index)
      assert_equal(1, box_b.start_row_index)
      assert_equal(-1, box_b.last_fitted_row_index)

      assert(box_b.fit(100, 100, @frame).failure?)
      box_c, box_d = box_b.split
      assert_nil(box_c)
      assert_same(box_d, box_b)
      assert(box_d.split_box?)
      assert_equal(1, box_d.start_row_index)
      assert_equal(-1, box_d.last_fitted_row_index)
    end

    it "splits a table with a header or a footer" do
      cells_creator = lambda {|_| [@fixed_size_boxes[10, 2]] }
      [{header: cells_creator}, {footer: cells_creator}].each do |args|
        box = create_box(**args)
        assert(box.fit(100, 50, @frame).overflow?)
        box_a, box_b = box.split
        assert_same(box_a, box)

        assert_equal(0, box_a.start_row_index)
        assert_equal(0, box_a.last_fitted_row_index)
        assert_equal(1, box_b.start_row_index)
        assert_equal(-1, box_b.last_fitted_row_index)
        assert_nil(box_b.instance_variable_get(:@special_cells_fit_not_successful))
        if args.key?(:header)
          refute_same(box_a.header_cells, box_b.header_cells)
        else
          refute_same(box_a.footer_cells, box_b.footer_cells)
        end
      end
    end
  end

  describe "draw_content" do
    before do
      @canvas = @page.canvas
    end

    it "draws the result onto the canvas" do
      box = create_box
      box.fit(100, 100, @frame)
      box.draw(@canvas, 20, 10)
      operators = [[:save_graphics_state],
                   [:append_rectangle, [20.5, 32.5, 49.5, 22.0]],
                   [:stroke_path],
                   [:restore_graphics_state],
                   [:save_graphics_state],
                   [:concatenate_matrix, [1, 0, 0, 1, 26.5, 38.5]],
                   [:move_to, [0, 0]],
                   [:end_path],
                   [:restore_graphics_state],
                   [:save_graphics_state],
                   [:append_rectangle, [70.0, 32.5, 49.5, 22.0]],
                   [:stroke_path],
                   [:restore_graphics_state],
                   [:save_graphics_state],
                   [:concatenate_matrix, [1, 0, 0, 1, 76.0, 38.5]],
                   [:move_to, [0, 0]],
                   [:end_path],
                   [:restore_graphics_state],
                   [:save_graphics_state],
                   [:append_rectangle, [20.5, 10.5, 49.5, 22.0]],
                   [:stroke_path],
                   [:restore_graphics_state],
                   [:save_graphics_state],
                   [:concatenate_matrix, [1, 0, 0, 1, 26.5, 16.5]],
                   [:move_to, [0, 0]],
                   [:end_path],
                   [:restore_graphics_state],
                   [:save_graphics_state],
                   [:append_rectangle, [70.0, 10.5, 49.5, 22.0]],
                   [:stroke_path],
                   [:restore_graphics_state],
                   [:save_graphics_state],
                   [:concatenate_matrix, [1, 0, 0, 1, 76.0, 16.5]],
                   [:move_to, [0, 0]],
                   [:end_path],
                   [:restore_graphics_state]]
      assert_operators(@canvas.contents, operators)
    end

    it "correctly works for split boxes" do
      box = create_box(cell_style: {padding: 0, border: {width: 0}})
      assert(box.fit(100, 10, @frame).overflow?)
      _, split_box = box.split
      assert(split_box.fit(100, 100, @frame).success?)

      box.draw(@canvas, 20, 10)
      split_box.draw(@canvas, 0, 50)
      operators = [[:save_graphics_state],
                   [:concatenate_matrix, [1, 0, 0, 1, 20.0, 10]],
                   [:move_to, [0, 0]],
                   [:end_path],
                   [:restore_graphics_state],
                   [:save_graphics_state],
                   [:concatenate_matrix, [1, 0, 0, 1, 70.0, 10]],
                   [:move_to, [0, 0]],
                   [:end_path],
                   [:restore_graphics_state],
                   [:save_graphics_state],
                   [:concatenate_matrix, [1, 0, 0, 1, 0, 50]],
                   [:move_to, [0, 0]],
                   [:end_path],
                   [:restore_graphics_state],
                   [:save_graphics_state],
                   [:concatenate_matrix, [1, 0, 0, 1, 50.0, 50]],
                   [:move_to, [0, 0]],
                   [:end_path],
                   [:restore_graphics_state]]
      assert_operators(@canvas.contents, operators)
    end

    it "correctly works for tables with headers and footers" do
      box = create_box(header: lambda {|_| [@fixed_size_boxes[10, 1]] },
                       footer: lambda {|_| [@fixed_size_boxes[12, 1]] },
                       cell_style: {padding: 0, border: {width: 0}})
      assert(box.fit(100, 100, @frame).success?)
      box.draw(@canvas, 20, 10)
      operators = [[:save_graphics_state],
                   [:concatenate_matrix, [1, 0, 0, 1, 20, 40]],
                   [:move_to, [0, 0]],
                   [:end_path],
                   [:restore_graphics_state],
                   [:save_graphics_state],
                   [:concatenate_matrix, [1, 0, 0, 1, 20, 30]],
                   [:move_to, [0, 0]],
                   [:end_path],
                   [:restore_graphics_state],
                   [:save_graphics_state],
                   [:concatenate_matrix, [1, 0, 0, 1, 70.0, 30]],
                   [:move_to, [0, 0]],
                   [:end_path],
                   [:restore_graphics_state],
                   [:save_graphics_state],
                   [:concatenate_matrix, [1, 0, 0, 1, 20, 20]],
                   [:move_to, [0, 0]],
                   [:end_path],
                   [:restore_graphics_state],
                   [:save_graphics_state],
                   [:concatenate_matrix, [1, 0, 0, 1, 70.0, 20]],
                   [:move_to, [0, 0]],
                   [:end_path],
                   [:restore_graphics_state],
                   [:save_graphics_state],
                   [:concatenate_matrix, [1, 0, 0, 1, 20.0, 10]],
                   [:move_to, [0, 0]],
                   [:end_path],
                   [:restore_graphics_state]]
      assert_operators(@canvas.contents, operators)
    end
  end
end
