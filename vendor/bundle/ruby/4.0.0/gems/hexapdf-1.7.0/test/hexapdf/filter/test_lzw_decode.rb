# -*- encoding: utf-8 -*-

require_relative 'common'
require 'hexapdf/filter/lzw_decode'

describe HexaPDF::Filter::LZWDecode do
  include CommonFilterTests

  before do
    @obj = HexaPDF::Filter::LZWDecode
    @all_test_cases ||= [["-----A---B".b, "\x80\x0b\x60\x50\x22\x0c\x0c\x85\x01".b],
                         ['abcabcaaaabbbcdeffffffagggggg'.b,
                          "\x80\x18LF8\x14\x10\xC3\a1BLfC)\x9A\x1D\x0F0\x99\xE2Q8\b".b]]
    @decoded = @all_test_cases[0][0]
    @encoded = @all_test_cases[0][1]
    @encoded_predictor = "\x80\x00\x85\xA0 \x04\x12\r\x05\n\x00\x9D\x90p\x10V\x02".b
    @predictor_opts = {Predictor: 12}
  end

  describe "decoder" do
    it "applies the Predictor after decoding" do
      assert_equal(@decoded, collector(@obj.decoder(feeder(@encoded_predictor), @predictor_opts)))
    end

    it "fails if an unknown code is found after CLEAR_TABLE" do
      assert_raises(HexaPDF::FilterError) { @obj.decoder(feeder("\xff\xff")).resume }
    end

    it "fails if an unknown code is found elsewhere" do
      assert_raises(HexaPDF::FilterError) { @obj.decoder(feeder("\x00\x7f\xff\xf0")).resume }
    end

    it "fails if the code size would be more than 12bit" do
      stream = HexaPDF::Utils::BitStreamWriter.new
      result = stream.write(256, 9)
      result << stream.write(65, 9)
      258.upto(510) {|i| result << stream.write(i, 9) }
      511.upto(1022) {|i| result << stream.write(i, 10) }
      1023.upto(2046) {|i| result << stream.write(i, 11) }
      2047.upto(4095) {|i| result << stream.write(i, 12) }
      result << stream.write(96, 12)
      result << stream.finalize
      assert_raises(HexaPDF::FilterError) { @obj.decoder(feeder(result)).resume }
    end
  end

  describe "encoder" do
    it "applies the Predictor before encoding" do
      assert_equal(@encoded_predictor, collector(@obj.encoder(feeder(@decoded), @predictor_opts)))
    end
  end
end
