# -*- encoding: utf-8 -*-

require 'test_helper'
require_relative 'common'
require 'hexapdf/font/true_type/table/glyf'

describe HexaPDF::Font::TrueType::Table::Glyf do
  before do
    loca = Object.new
    loca.define_singleton_method(:offsets) { @offsets ||= [] }
    loca.define_singleton_method(:offset) {|i| @offsets[i] }
    loca.define_singleton_method(:length) {|i| @offsets[i + 1] - @offsets[i] }
    loca.offsets << 0 << 0
    data = [1, -10, -20, 100, 150].pack('s>5')
    loca.offsets << data.size
    data << [-1, 10, 20, -100, -150].pack('s>5')
    data << [0b00100000, 1, 20, 30].pack('n2C2')
    data << [0b00101001, 2, 20, 30, 40].pack('n2n2n')
    data << [0b01100001, 3, 20, 30, 40, 50].pack('n2n2n2')
    data << [0b10100001, 4, 20, 30, 40, 50, 60, 70].pack('n2n2n4')
    data << [0b00000000, 1, 20, 30].pack('n2C2')
    loca.offsets << data.size
    set_up_stub_true_type_font(data)
    @font.define_singleton_method(:[]) {|_arg| loca }
  end

  describe "initialize" do
    it "reads the data from the associated file" do
      table = create_table(:Glyf)
      glyph = table[0]
      refute(glyph.compound?)
      assert_equal(0, glyph.number_of_contours)
      assert_equal(0, glyph.x_min)
      assert_equal(0, glyph.y_min)
      assert_equal(0, glyph.x_max)
      assert_equal(0, glyph.y_max)

      glyph = table[1]
      refute(glyph.compound?)
      assert_equal(1, glyph.number_of_contours)
      assert_equal(-10, glyph.x_min)
      assert_equal(-20, glyph.y_min)
      assert_equal(100, glyph.x_max)
      assert_equal(150, glyph.y_max)
      assert_same(glyph, table[1])

      glyph = table[2]
      assert(glyph.compound?)
      assert_equal(-1, glyph.number_of_contours)
      assert_equal(10, glyph.x_min)
      assert_equal(20, glyph.y_min)
      assert_equal(-100, glyph.x_max)
      assert_equal(-150, glyph.y_max)
      assert_equal([1, 2, 3, 4, 1], glyph.components)
      assert_equal([12, 18, 28, 40, 56], glyph.component_offsets)
    end
  end
end
