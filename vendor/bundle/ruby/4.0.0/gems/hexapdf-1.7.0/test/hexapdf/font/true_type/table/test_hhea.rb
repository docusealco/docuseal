# -*- encoding: utf-8 -*-

require 'test_helper'
require_relative 'common'
require 'hexapdf/font/true_type/table/hhea'

describe HexaPDF::Font::TrueType::Table::Hhea do
  it "reads the data from the associated file" do
    data = [1, 0, 10, 11, 12, 100, 101, 102, 115, 1, 0, 0, 0, 0, 0, 0, 0, 10].pack('n2s>3ns>11n')
    set_up_stub_true_type_font(data)
    table = create_table(:Hhea)

    assert_equal(1, table.version)
    assert_equal(10, table.ascent)
    assert_equal(11, table.descent)
    assert_equal(12, table.line_gap)
    assert_equal(100, table.advance_width_max)
    assert_equal(101, table.min_left_side_bearing)
    assert_equal(102, table.min_right_side_bearing)
    assert_equal(115, table.x_max_extent)
    assert_equal(1, table.caret_slope_rise)
    assert_equal(0, table.caret_slope_run)
    assert_equal(0, table.caret_offset)
    assert_equal(10, table.num_of_long_hor_metrics)
  end
end
