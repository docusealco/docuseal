# -*- encoding: utf-8 -*-

require 'test_helper'
require_relative 'common'
require 'hexapdf/font/true_type/table/maxp'

describe HexaPDF::Font::TrueType::Table::Maxp do
  before do
    data = [1, 0, 10, 11, 12, 13, 14, 2, 15, 16, 17, 18, 19, 20, 21, 22].pack('n*')
    set_up_stub_true_type_font(data)
  end

  describe "initialize" do
    it "reads the version 1.0 data from the associated file" do
      table = create_table(:Maxp)
      assert_equal(1, table.version)
      assert_equal(10, table.num_glyphs)
      assert_equal(11, table.max_points)
      assert_equal(12, table.max_contours)
      assert_equal(13, table.max_component_points)
      assert_equal(14, table.max_component_contours)
      assert_equal(15, table.max_twilight_points)
      assert_equal(16, table.max_storage)
      assert_equal(17, table.max_function_defs)
      assert_equal(18, table.max_instruction_defs)
      assert_equal(19, table.max_stack_elements)
      assert_equal(20, table.max_size_of_instructions)
      assert_equal(21, table.max_component_elements)
      assert_equal(22, table.max_component_depth)
    end

    it "reads the version 0.5 data from the associated file" do
      table = create_table(:Maxp, [0, 0x5000, 10].pack('n*'))
      assert_equal(0.3125, table.version)
      assert_equal(10, table.num_glyphs)
      assert_nil(table.max_points)
      assert_nil(table.max_contours)
      assert_nil(table.max_component_points)
      assert_nil(table.max_component_contours)
      assert_nil(table.max_twilight_points)
      assert_nil(table.max_storage)
      assert_nil(table.max_function_defs)
      assert_nil(table.max_instruction_defs)
      assert_nil(table.max_stack_elements)
      assert_nil(table.max_size_of_instructions)
      assert_nil(table.max_component_elements)
      assert_nil(table.max_component_depth)
    end
  end
end
