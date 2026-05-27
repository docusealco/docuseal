# -*- encoding: utf-8 -*-

require 'test_helper'
require_relative 'common'
require 'hexapdf/font/true_type/table/cmap'

describe HexaPDF::Font::TrueType::Table::Cmap do
  before do
    f0 = [0, 262, 0].pack('n3') + (0..255).to_a.pack('C*')
    data = [0, 3].pack('n2') << [
      [0, 1, 28],
      [3, 1, 28 + f0.length],
      [1, 0, 28],
    ].map {|a| a.pack('n2N') }.join << f0 << [10, 22, 0, 0, 2, 10, 13].pack('nN2N2n2')
    set_up_stub_true_type_font(data)
  end

  describe "initialize" do
    it "reads the data from the associated file" do
      table = create_table(:Cmap)
      assert_equal(0, table.version)
      assert_equal(3, table.tables.length)
    end

    it "ignores unknown subtable when the config option is set to :ignore" do
      table = create_table(:Cmap, [0, 1].pack('n2') << [3, 1, 12].pack('n2N') << "\x00\x03")
      assert_equal(0, table.tables.length)
    end

    it "raises an error when an unsupported subtable is found and the option is set to :raise" do
      data = [0, 1].pack('n2') << [3, 1, 12].pack('n2N') << "\x00\x03"
      @font.config['font.true_type.unknown_format'] = :raise
      assert_raises(HexaPDF::Error) { create_table(:Cmap, data) }
    end

    it "loads data from subtables with identical offsets only once" do
      table = create_table(:Cmap)
      assert_same(table.tables[0].gid_map, table.tables[2].gid_map)
      refute_same(table.tables[0].gid_map, table.tables[1].gid_map)
    end
  end

  it "returns the preferred table" do
    table = create_table(:Cmap)
    assert_equal(table.tables[1], table.preferred_table)
  end
end
