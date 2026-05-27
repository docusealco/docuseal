# -*- encoding: utf-8 -*-

require_relative 'common'
require 'hexapdf/filter/flate_decode'

describe HexaPDF::Filter::BrotliDecode do
  include CommonFilterTests

  before do
    @obj = HexaPDF::Filter::BrotliDecode
    @all_test_cases = [["abcdefg".b, Brotli.deflate("abcdefg".b)]]
    @decoded = @all_test_cases[0][0]
    @encoded = @all_test_cases[0][1]
    @encoded_predictor = "\e\r\x00\xF8%\x05\x02\xC2\xC2\x86\x00\x80%".b
    @predictor_opts = {Predictor: 12}
  end

  describe "decoder" do
    it "works for empty input" do
      assert_equal('', collector(@obj.decoder(Fiber.new { "" })))
      assert_equal('', collector(@obj.decoder(Fiber.new {})))
    end

    it "applies the Predictor after decoding" do
      assert_equal(@decoded, collector(@obj.decoder(feeder(@encoded_predictor), @predictor_opts)))
    end
  end

  describe "encoder" do
    it "applies the Predictor before encoding" do
      assert_equal(@encoded_predictor, collector(@obj.encoder(feeder(@decoded), @predictor_opts)))
    end
  end
end
