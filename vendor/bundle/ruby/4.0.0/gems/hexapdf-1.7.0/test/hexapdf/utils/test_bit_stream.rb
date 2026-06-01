# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/utils/bit_stream'

describe HexaPDF::Utils::BitStreamReader do
  before do
    @reader = HexaPDF::Utils::BitStreamReader.new
  end

  it "allows appending data" do
    assert_equal(0, @reader.remaining_bits)
    @reader << "data"
    assert_equal(32, @reader.remaining_bits)
    @reader << "some"
    assert_equal(64, @reader.remaining_bits)
    @reader.read(4)
    assert_equal(60, @reader.remaining_bits)
    @reader << "more"
    assert_equal(92, @reader.remaining_bits)
  end

  it "allows checking whether a certain number of bits can be read" do
    refute(@reader.read?(1))
    @reader << "data"
    assert(@reader.read?(1))
    assert(@reader.read?(32))
    refute(@reader.read?(33))
  end

  describe "read" do
    it "allows reading any number of bits" do
      @reader << "\xaa" * 8 # 10101010 * 8
      assert_equal(1, @reader.read(1))
      assert_equal(0, @reader.read(1))
      assert_equal(2, @reader.read(2))
      assert_equal(10, @reader.read(4))
      assert_equal(5, @reader.read(3))
      assert_equal((0b01010 << 8) | 0xaa, @reader.read(13))
      assert_equal(5, @reader.read(3))
      assert_equal((0b01010 << 7) | (0xaa >> 1), @reader.read(12))
      assert_equal(2, @reader.read(3))
    end

    it "allows reading many bits" do
      @reader << "\x80" << "\x00" * 20
      assert_equal(2**127, @reader.read(128))
    end

    it "returns nil if enough bits are available" do
      assert_nil(@reader.read(1))
    end
  end
end

describe HexaPDF::Utils::BitStreamWriter do
  before do
    @writer = HexaPDF::Utils::BitStreamWriter.new
  end

  it "allows writing any number of bits" do
    result = @writer.write(1, 1)
    result << @writer.write(0b101, 3)
    result << @writer.write(0xff, 8)
    result << @writer.write(0x5ddd, 15)
    result << @writer.finalize
    assert_equal("\xdf\xfb\xbb\xa0".b, result)
  end
end
