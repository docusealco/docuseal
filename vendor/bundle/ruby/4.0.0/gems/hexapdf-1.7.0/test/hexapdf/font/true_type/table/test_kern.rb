# -*- encoding: utf-8 -*-

require 'test_helper'
require_relative 'common'
require 'hexapdf/font/true_type/table/kern'

describe HexaPDF::Font::TrueType::Table::Kern do
  describe "table format 0" do
    before do
      data = [0, 2].pack('n2')
      data << [0, 6, 0x101].pack('n3')
      data << [0, 6 + 8 + 24, 0x1].pack('n3')
      data << [4, 0, 0, 0, 1, 2, 10, 2, 3, -30, 3, 4, 32767, 4, 5, -32768].pack('n4n2s>n2s>n2s>n2s>')
      set_up_stub_true_type_font(data)
    end

    it "reads the data from the associated file" do
      table = create_table(:Kern)
      assert_equal(0, table.version)
      assert_equal(1, table.subtables.length)

      subtable = table.horizontal_kerning_subtable
      assert(subtable.horizontal?)
      refute(subtable.minimum_values?)
      refute(subtable.cross_stream?)
      assert_equal(10, subtable.kern(1, 2))
      assert_equal(-30, subtable.kern(2, 3))
      assert_equal(32767, subtable.kern(3, 4))
      assert_equal(-32768, subtable.kern(4, 5))
      assert_nil(subtable.kern(1, 3))
      assert_nil(subtable.kern(6, 3))
    end

    it "raises an error for unknown formats if configured" do
      @font.config['font.true_type.unknown_format'] = :raise
      assert_raises(HexaPDF::Error) { create_table(:Kern) }
    end
  end

  describe "table format 1" do
    before do
      data = [1, 0, 2].pack('n2N')
      data << [8 + 8, 0xC001, 0, 0, 0, 0, 0].pack('Nn6')
      data << [8 + 8 + 6, 0xC000, 0].pack('Nnn')
      data << [1, 0, 0, 0, 1, 2, 10].pack('n4n2s>')
      set_up_stub_true_type_font(data)
    end

    it "reads the data from the associated file" do
      table = create_table(:Kern)
      assert_equal(1, table.version)
      assert_equal(1, table.subtables.length)

      subtable = table.subtables.first
      refute(subtable.horizontal?)
      refute(subtable.minimum_values?)
      assert(subtable.cross_stream?)
      assert_equal(10, subtable.kern(1, 2))
    end
  end
end
