# -*- encoding: utf-8 -*-

require 'test_helper'
require_relative 'common'
require 'hexapdf/font/true_type/table/hhea'
require 'hexapdf/font/true_type/table/hmtx'

describe HexaPDF::Font::TrueType::Table::Hmtx do
  before do
    data = [1, -2, 3, -4, 5, -6].pack('ns>ns>s>2')
    set_up_stub_true_type_font(data)
    hhea = Object.new
    hhea.define_singleton_method(:num_of_long_hor_metrics) { 2 }
    @font.define_singleton_method(:[]) {|_arg| hhea }
  end

  describe "initialize" do
    it "reads the data from the associated file" do
      table = create_table(:Hmtx)
      assert_equal(3, table[2].advance_width)
      assert_equal(5, table[2].left_side_bearing)
      assert_equal(3, table[3].advance_width)
      assert_equal(-6, table[3].left_side_bearing)
      assert_equal(1, table[0].advance_width)
      assert_equal(-2, table[0].left_side_bearing)
      assert_equal(3, table[1].advance_width)
      assert_equal(-4, table[1].left_side_bearing)
    end
  end
end
