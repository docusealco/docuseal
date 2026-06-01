# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/utils/bit_field'

class TestBitField

  extend HexaPDF::Utils::BitField

  attr_accessor :data

  bit_field(:data, {bit0: 0, bit1: 1, bit5: 5}, lister: "list", getter: "get", setter: "set",
            unsetter: 'unset')

end

describe HexaPDF::Utils::BitField do
  before do
    @obj = TestBitField.new
  end

  it "allows inspection of the defined bits" do
    assert_equal({bit0: 0, bit1: 1, bit5: 5}, TestBitField::DATA_BIT_MAPPING)
  end

  it "returns all bit names using the lister method" do
    @obj.data = 0b100011
    assert_equal([:bit0, :bit1, :bit5], @obj.list)
    @obj.data = 0b100001
    assert_equal([:bit0, :bit5], @obj.list)
  end

  it "can check whether a given bit is set via the getter method" do
    refute(@obj.get(:bit0))
    @obj.data = 0b000001
    assert(@obj.get(:bit0))
    assert(@obj.get(0))
    refute(@obj.get(:bit1))
    refute(@obj.get(1))
  end

  it "can set a given bit via the setter method" do
    assert_nil(@obj.data)
    @obj.set(:bit0, :bit1, :bit5)
    assert_equal(0b100011, @obj.data)
    @obj.set(:bit0, 5, clear_existing: true)
    assert_equal(0b100001, @obj.data)
  end

  it "can unset a given bit via the unsetter method" do
    @obj.set(:bit0, :bit5)
    assert_equal(0b100001, @obj.data)
    @obj.unset(:bit5)
    assert_equal(0b000001, @obj.data)
  end

  it "fails if an unknown bit name or bit index is used with one of the methods" do
    e = assert_raises(ArgumentError) { @obj.get(10) }
    assert_equal("Invalid bit field name or index '10' for TestBitField#data", e.message)
    e = assert_raises(ArgumentError) { @obj.get(:bit10) }
    assert_equal("Invalid bit field name or index 'bit10' for TestBitField#data", e.message)
  end
end
