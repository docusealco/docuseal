# -*- encoding: utf-8 -*-

require_relative 'common'
require 'hexapdf/filter/flate_decode'

describe HexaPDF::Filter::FlateDecode do
  include CommonFilterTests

  before do
    @obj = HexaPDF::Filter::FlateDecode
    @all_test_cases = [["abcdefg".b, "x\xDAKLJNIMK\a\x00\n\xDB\x02\xBD".b]]
    @decoded = @all_test_cases[0][0]
    @encoded = @all_test_cases[0][1]
    @encoded_predictor = "x\xDAcJdbD@\x00\x05\x8F\x00v".b
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

    describe "invalid input is handled as good as possible" do
      def strict_mode
        HexaPDF::GlobalConfiguration['filter.flate.on_error'] = proc { true }
        yield
      ensure
        HexaPDF::GlobalConfiguration['filter.flate.on_error'] = proc { false }
      end

      it "handles completely invalid data" do
        assert_equal('', collector(@obj.decoder(feeder("some data"))))
        assert_raises(HexaPDF::FilterError) do
          strict_mode { collector(@obj.decoder(feeder("some data"))) }
        end
      end

      it "handles missing data" do
        assert_equal('abcdefg', collector(@obj.decoder(feeder(@encoded[0..-2]))))
        assert_raises(HexaPDF::FilterError) do
          strict_mode { collector(@obj.decoder(feeder(@encoded[0..-2]))) }
        end
      end
    end
  end

  describe "encoder" do
    it "applies the Predictor before encoding" do
      assert_equal(@encoded_predictor, collector(@obj.encoder(feeder(@decoded), @predictor_opts)))
    end
  end
end
