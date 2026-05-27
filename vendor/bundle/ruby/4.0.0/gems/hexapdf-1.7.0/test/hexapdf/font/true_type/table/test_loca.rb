# -*- encoding: utf-8 -*-

require 'test_helper'
require_relative 'common'
require 'hexapdf/font/true_type/table/head'
require 'hexapdf/font/true_type/table/loca'

describe HexaPDF::Font::TrueType::Table::Loca do
  before do
    set_up_stub_true_type_font
    head = Object.new
    head.define_singleton_method(:index_to_loc_format) { 0 }
    @font.define_singleton_method(:[]) {|_arg| head }
  end

  describe "initialize" do
    it "reads the data in short format from the associated file" do
      table = create_table(:Loca, [0, 10, 30, 50, 90].pack('n*'))
      assert_equal([0, 20, 60, 100, 180], table.offsets)
      assert_equal(0, table.offset(0))
      assert_equal(100, table.offset(3))
      assert_equal(20, table.length(0))
      assert_equal(80, table.length(3))
    end

    it "reads the data in long format from the associated file" do
      @font[:head].singleton_class.send(:remove_method, :index_to_loc_format)
      @font[:head].define_singleton_method(:index_to_loc_format) { 1 }
      table = create_table(:Loca, [0, 10, 30, 50, 90].pack('N*'))
      assert_equal([0, 10, 30, 50, 90], table.offsets)
    end
  end
end
