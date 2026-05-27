# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/font/true_type/table/directory'

describe HexaPDF::Font::TrueType::Table::Directory do
  before do
    io = StringIO.new("TEST\x00\x02\x00\x00\x00\x00\x00\x00" \
                      "CUST----\x00\x00\x00\x2C\x00\x00\x00\x05" \
                      " TWO----\x00\x00\x00\x31\x00\x00\x00\x05ENTRYENTRY".b)
    @file = Object.new
    @file.define_singleton_method(:io) { io }
    @self_entry = HexaPDF::Font::TrueType::Table::Directory::SELF_ENTRY
  end

  it "has a dummy entry referring to itself" do
    assert_equal(0, @self_entry.offset)
    assert_equal(12, @self_entry.length)
  end

  describe "initialize" do
    it "loads the table entries from the IO" do
      dir = HexaPDF::Font::TrueType::Table::Directory.new(@file, @self_entry)
      entry = dir.entry('CUST')
      assert_equal('CUST', entry.tag)
      assert_equal('----'.unpack1('N'), entry.checksum)
      assert_equal(44, entry.offset)
      assert_equal(5, entry.length)
      assert_equal(['CUST', ' TWO'], dir.table_names)
    end
  end
end
