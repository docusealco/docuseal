# -*- encoding: utf-8 -*-

require_relative 'common'
require 'hexapdf/filter/ascii_hex_decode'

describe HexaPDF::Filter::ASCIIHexDecode do
  include CommonFilterTests

  before do
    @obj = HexaPDF::Filter::ASCIIHexDecode
    @all_test_cases = [['Nov shmoz ka pop.', '4e6f762073686d6f7a206b6120706f702e>']]
    @decoded = @all_test_cases[0][0]
    @encoded = @all_test_cases[0][1]
  end

  describe "decoder" do
    it "ignores whitespace in the input" do
      with_whitespace = @encoded.scan(/./).map {|a| "#{a} \r\t" }.join("\n")
      assert_equal(@decoded, collector(@obj.decoder(feeder(with_whitespace, 1))))
    end

    it "works without the EOD marker" do
      assert_equal(@decoded, collector(@obj.decoder(feeder(@encoded.chop, 5))))
    end

    it "ignores data after the EOD marker" do
      assert_equal(@decoded, collector(@obj.decoder(feeder(@encoded + '4e6f7gzz'))))
    end

    it "assumes the missing char is '0' if the input length is odd" do
      assert_equal(@decoded.chop << ' ', collector(@obj.decoder(feeder(@encoded.chop.chop))))
    end

    it "fails on invalid characters" do
      assert_raises(HexaPDF::FilterError) { @obj.decoder(feeder('f0f0z')).resume }
    end
  end
end
