# -*- encoding: utf-8 -*-

require 'test_helper'
require_relative 'common'
require 'hexapdf/font/true_type/table/post'

describe HexaPDF::Font::TrueType::Table::Post do
  before do
    data = [1, 0, 1, 0, -142, 15, 0, 0, 0, 0, 0].pack('n4s>2N5')
    set_up_stub_true_type_font(data)
  end

  describe "initialize" do
    it "reads the format 1 data from the associated file" do
      table = create_table(:Post)
      assert_equal(1, table.format)
      assert_equal(1, table.italic_angle)
      assert_equal(-142, table.underline_position)
      assert_equal(15, table.underline_thickness)
      assert_equal(0, table.is_fixed_pitch)
      refute(table.is_fixed_pitch?)
      assert_equal(0, table.min_mem_type42)
      assert_equal(0, table.max_mem_type42)
      assert_equal(0, table.min_mem_type1)
      assert_equal(0, table.max_mem_type1)
      assert_equal('.notdef', table[0])
      assert_equal('A', table[36])
      assert_equal('Delta', table[168])
      assert_equal('.notdef', table[1000])
    end

    it "reads the format 2 data from the associated file" do
      @font.io.string[0, 2] = [2].pack('n')
      @font.io.string << ([260, 0] + (1..257).to_a.reverse + [258, 259]).pack('n*')
      @font.io.string << [4, "hexa", 3, "pdf"].pack('CA4CA3')
      table = create_table(:Post, @font.io.string)
      assert_equal(2, table.format)
      assert_equal('.notdef', table[0])
      assert_equal('A', table[258 - 36])
      assert_equal('Delta', table[258 - 168])
      assert_equal('hexa', table[258])
      assert_equal('pdf', table[259])
      assert_equal('.notdef', table[1000])
    end

    it "reads the format 3 data from the associated file" do
      @font.io.string[0, 2] = [3].pack('n')
      table = create_table(:Post, @font.io.string)
      assert_equal(3, table.format)
      assert_equal('.notdef', table[0])
      assert_equal('.notdef', table[36])
      assert_equal('.notdef', table[1000])
    end

    it "reads the format 4 data from the associated file" do
      @font.io.string[0, 2] = [4].pack('n')
      @font.io.string << [0x1234, 0x5678].pack('n*')
      table = create_table(:Post, @font.io.string)
      assert_equal(4, table.format)
      assert_equal(0x1234, table[0])
      assert_equal(0x5678, table[1])
      assert_equal(0xFFFF, table[2])
      assert_equal(0xFFFF, table[36])
      assert_equal(0xFFFF, table[1_000_000])
    end

    it "handles unsupported formats" do
      @font.io.string[0, 2] = [5].pack('n')

      @font.config['font.true_type.unknown_format'] = :ignore
      table = create_table(:Post, @font.io.string)
      assert_equal('.notdef', table[0])

      @font.config['font.true_type.unknown_format'] = :raise
      assert_raises(HexaPDF::Error) { create_table(:Post)[0] }
    end
  end
end
