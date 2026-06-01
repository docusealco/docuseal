# -*- encoding: utf-8 -*-

require 'test_helper'
require_relative 'common'
require 'hexapdf/font/true_type/table/name'

describe HexaPDF::Font::TrueType::Table::Name do
  before do
    data = [0, 3, 42].pack('n3') <<
      [1, 0, 0, 0, 4, 0].pack('n6') <<
      [0, 3, 1, 0, 8, 4].pack('n6') <<
      [3, 1, 1033, 1, 14, 12].pack('n6') <<
      'hexa'.encode('MACROMAN').b <<
      'hexa'.encode('UTF-16BE').b <<
      'hexapdf'.encode('UTF-16BE').b
    set_up_stub_true_type_font(data)
  end

  describe "initialize" do
    it "reads the data in format 0 from the associated file" do
      table = create_table(:Name)
      assert_equal(0, table.format)
      assert_equal({}, table.language_tags)
      assert_equal('hexa', table[:copyright][0])
      assert_equal(1, table[:copyright][0].platform_id)
      assert_equal(0, table[:copyright][0].encoding_id)
      assert_equal(0, table[:copyright][0].language_id)
      assert_equal('hexa', table[:copyright][1])
      assert_equal(0, table[:copyright][1].platform_id)
      assert_equal(3, table[:copyright][1].encoding_id)
      assert_equal(1, table[:copyright][1].language_id)
      assert_equal('hexapdf', table[:font_family][0])
      assert_equal(3, table[:font_family][0].platform_id)
      assert_equal(1, table[:font_family][0].encoding_id)
      assert_equal(1033, table[:font_family][0].language_id)

      assert_equal(table[0][0], table[0].preferred_record)
      assert_equal(table[:font_family][0], table[:font_family].preferred_record)
    end

    it "reads the data in format 1 from the associated file" do
      @font.io.string[0, 6] = [1, 3, 52].pack('n3')
      @font.io.string[42, 0] = [2, 4, 26, 4, 30].pack('n*')
      @font.io.string << 'ende'.encode('UTF-16BE').b
      table = create_table(:Name)
      assert_equal(1, table.format)
      assert_equal({0x8000 => 'en', 0x8001 => 'de'}, table.language_tags)
    end
  end

  describe "NameRecord" do
    before do
      @table = create_table(:Name)
    end

    describe "platform?" do
      it "returns the correct value" do
        assert(@table[:copyright][0].platform?(:macintosh))
        assert(@table[:copyright][1].platform?(:unicode))
        assert(@table[:font_family][0].platform?(:microsoft))
      end

      it "raises an error when called with an unknown identifier" do
        assert_raises(ArgumentError) { @table[:copyright][0].platform?(:testing) }
      end
    end

    describe "preferred?" do
      it "returns true for names in US English that had been converted to UTF-8" do
        assert(@table[:copyright][0].preferred?)
        refute(@table[:copyright][1].preferred?)
        assert(@table[:font_family][0].preferred?)
      end
    end
  end
end
