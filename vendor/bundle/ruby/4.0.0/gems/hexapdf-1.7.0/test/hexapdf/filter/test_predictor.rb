# -*- encoding: utf-8 -*-

require_relative 'common'
require 'hexapdf/filter/predictor'

describe HexaPDF::Filter::Predictor do
  module CommonPredictorTests
    def test_decoding_through_decoder_method
      @testcases.each do |name, data|
        assert_equal(data[:source], collector(@obj.decoder(feeder(data[:result].dup), data)),
                     "test case: #{name}")
      end
    end

    def test_encoding_through_encoder_method
      @testcases.each do |name, data|
        assert_equal(data[:result], collector(@obj.encoder(feeder(data[:source].dup), data)),
                     "test case: #{name}")
      end
    end
  end

  before do
    @obj = HexaPDF::Filter::Predictor
  end

  it "encoder fails on invalid Predictor value" do
    data = {Predictor: 5}
    assert_raises(HexaPDF::InvalidPDFObjectError) do
      @obj.encoder(feeder("test"), data)
    end
  end

  it "just returns the source if no processing needs to be done" do
    source = feeder("test")
    assert_same(source, @obj.encoder(source, Predictor: 1))
    assert_same(source, @obj.encoder(source, {}))
  end

  describe "png predictor" do
    include CommonPredictorTests

    before do
      @testcases = {
        'none' => {
          source: [110, 96].pack('C*'),
          result: [0, 110, 96].pack('C*'),
          Predictor: 10,
          Colors: 1,
          BitsPerComponent: 1,
          Columns: 14,
        },
        'sub' => {
          source: [10, 20, 30, 40, 50, 10, 20, 30, 40, 50].pack('C*'),
          result: [1, 10, 10, 10, 10, 10, 1, 10, 10, 10, 10, 10].pack('C*'),
          Predictor: 11,
          Colors: 2,
          BitsPerComponent: 2,
          Columns: 9,
        },
        'up' => {
          source: [10, 20, 30, 40, 50, 20, 30, 40, 50, 60].pack('C*'),
          result: [2, 10, 20, 30, 40, 50, 2, 10, 10, 10, 10, 10].pack('C*'),
          Predictor: 12,
          Colors: 3,
          BitsPerComponent: 4,
          Columns: 3,
        },
        'average' => {
          source: [10, 20, 30, 40, 50, 60, 70, 80, 20, 30, 40, 50, 60, 70, 80, 90].pack('C*'),
          result: [3, 10, 20, 25, 30, 35, 40, 45, 50, 3, 15, 20, 15, 15, 15, 15, 15, 15].pack('C*'),
          Predictor: 13,
          Colors: 4,
          BitsPerComponent: 4,
          Columns: 4,
        },
        'paeth' => {
          source: [10, 20, 30, 40, 50, 60, 70, 80, 20, 30, 40, 50, 60, 70, 80, 90].pack('C*'),
          result: [4, 10, 20, 20, 20, 20, 20, 20, 20, 4, 10, 10, 10, 10, 10, 10, 10, 10].pack('C*'),
          Predictor: 15,
          Colors: 4,
          BitsPerComponent: 4,
          Columns: 4,
        },
      }
    end

    describe "encoder" do
      it "works correctly" do
        @testcases.each do |name, data|
          encoder = @obj.png_execute(:encoder, feeder(data[:source].dup), data[:Predictor],
                                     data[:Colors], data[:BitsPerComponent], data[:Columns])
          assert_equal(data[:result], collector(encoder), "testcase #{name}")
        end
      end

      it "handles a short last row if 'filter.predictor.strict' is false" do
        data = @testcases['up']
        encoder = @obj.png_execute(:encoder, feeder(data[:source][0..-3], 1), data[:Predictor],
                                   data[:Colors], data[:BitsPerComponent], data[:Columns])
        result = collector(encoder)
        assert_equal(1 + 5 + 1 + 3, result.length)
        assert_equal(data[:result][0..-3], result)
      end

      it "fails if the last row is missing data and 'filter.predictor.strict' is true " do
        HexaPDF::GlobalConfiguration['filter.predictor.strict'] = true
        assert_raises(HexaPDF::FilterError) do
          data = @testcases['up']
          encoder = @obj.png_execute(:encoder, feeder(data[:source][0..-2], 1), data[:Predictor],
                                     data[:Colors], data[:BitsPerComponent], data[:Columns])
          collector(encoder)
        end
      ensure
        HexaPDF::GlobalConfiguration['filter.predictor.strict'] = false
      end
    end

    describe "decoder" do
      it "works correctly" do
        @testcases.each do |name, data|
          encoder = @obj.png_execute(:decoder, feeder(data[:result].dup), data[:Predictor],
                                     data[:Colors], data[:BitsPerComponent], data[:Columns])
          assert_equal(data[:source], collector(encoder), "testcase #{name}")
        end
      end

      it "handles a short last row if 'filter.predictor.strict' is false" do
        data = @testcases['up']
        encoder = @obj.png_execute(:decoder, feeder(data[:result][0..-3], 1), data[:Predictor],
                                   data[:Colors], data[:BitsPerComponent], data[:Columns])
        result = collector(encoder)
        assert_equal(5 + 3, result.length)
        assert_equal(data[:source][0..-3], result)
      end

      it "fails if the last row is missing data and 'filter.predictor.strict' is true " do
        HexaPDF::GlobalConfiguration['filter.predictor.strict'] = true
        assert_raises(HexaPDF::FilterError) do
          data = @testcases['up']
          encoder = @obj.png_execute(:decoder, feeder(data[:result][0..-2], 1), data[:Predictor],
                                     data[:Colors], data[:BitsPerComponent], data[:Columns])
          collector(encoder)
        end
      ensure
        HexaPDF::GlobalConfiguration['filter.predictor.strict'] = false
      end
    end
  end

  describe "tiff predictor" do
    include CommonPredictorTests

    before do
      @testcases = {
        'simple' => {
          source: [0b10101010, 0b11111100].pack('C*'),
          result: [0b11111111, 0b10000000].pack('C*'),
          Predictor: 2,
          Colors: 1,
          BitsPerComponent: 1,
          Columns: 14,
        },
        'complex' => {
          source: [0b10101010, 0b11110000, 0b10010100, 0b11010000].pack('C*'),
          result: [0b10101000, 0b01010000, 0b10010110, 0b10000000].pack('C*'),
          Predictor: 2,
          Colors: 3,
          BitsPerComponent: 2,
          Columns: 2,
        },
      }
    end

    describe "encoder" do
      it "works correctly" do
        @testcases.each do |name, data|
          encoder = @obj.tiff_execute(:encoder, feeder(data[:source].dup), data[:Colors],
                                      data[:BitsPerComponent], data[:Columns])
          assert_equal(data[:result], collector(encoder), "testcase #{name}")
        end
      end

      it "fails if data is missing" do
        assert_raises(HexaPDF::FilterError) do
          data = @testcases['simple']
          encoder = @obj.tiff_execute(:encoder, feeder(data[:source][0..-2], 1), data[:Colors],
                                      data[:BitsPerComponent], data[:Columns])
          collector(encoder)
        end
      end
    end

    describe "decoder" do
      it "works correctly" do
        @testcases.each do |name, data|
          decoder = @obj.tiff_execute(:decoder, feeder(data[:result].dup), data[:Colors],
                                      data[:BitsPerComponent], data[:Columns])
          assert_equal(data[:source], collector(decoder), "testcase #{name}")
        end
      end

      it "fails if data is missing" do
        assert_raises(HexaPDF::FilterError) do
          data = @testcases['simple']
          decoder = @obj.tiff_execute(:decoder, feeder(data[:result][0..-2], 1), data[:Colors],
                                      data[:BitsPerComponent], data[:Columns])
          collector(decoder)
        end
      end
    end
  end
end
