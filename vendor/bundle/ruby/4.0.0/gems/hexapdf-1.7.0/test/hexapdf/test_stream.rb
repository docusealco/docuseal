# -*- encoding: utf-8 -*-

require 'test_helper'
require 'stringio'
require 'tempfile'
require 'hexapdf/configuration'
require 'hexapdf/stream'

describe HexaPDF::StreamData do
  it "fails if no valid source is specified on creation" do
    assert_raises(ArgumentError) { HexaPDF::StreamData.new }
  end

  it "normalizes the filter value" do
    s = HexaPDF::StreamData.new(:source, filter: :test)
    assert_equal([:test], s.filter)
    s = HexaPDF::StreamData.new(:source, filter: [:a, nil, :b])
    assert_equal([:a, :b], s.filter)
    s = HexaPDF::StreamData.new(:source)
    assert_equal([], s.filter)
  end

  it "normalizes the decode_parms value" do
    s = HexaPDF::StreamData.new(:source, decode_parms: :test)
    assert_equal([:test], s.decode_parms)
    s = HexaPDF::StreamData.new(:source, decode_parms: [:a, nil, :b])
    assert_equal([:a, nil, :b], s.decode_parms)
    s = HexaPDF::StreamData.new(:source)
    assert_equal([nil], s.decode_parms)
  end

  describe "fiber" do
    it "returns a duplicate for a FiberDoubleForString source" do
      source = HexaPDF::Filter.source_from_string("str")
      fiber = HexaPDF::StreamData.new(source).fiber
      assert_equal("str", fiber.resume)
      refute_same(source, fiber)
    end

    it "returns a fiber for a Proc source" do
      s = HexaPDF::StreamData.new(proc { :source })
      assert_equal(:source, s.fiber.resume)
    end

    it "returns a fiber for a source specified via a block" do
      s = HexaPDF::StreamData.new { :source }
      assert_equal(:source, s.fiber.resume)
    end

    it "returns a fiber for an IO source" do
      s = HexaPDF::StreamData.new(StringIO.new('source'))
      assert_equal('source', s.fiber.resume)
    end

    it "returns a fiber for a string representing a file name" do
      file = Tempfile.new('hexapdf-stream')
      file.write('source')
      file.close
      s = HexaPDF::StreamData.new(file.path)
      assert_equal('source', s.fiber.resume)
    ensure
      file.unlink
    end
  end

  describe "==" do
    it "compares with other stream data objects" do
      s = HexaPDF::StreamData.new(:source, decode_parms: [:a, nil, :b])
      assert_equal(s, HexaPDF::StreamData.new(:source, decode_parms: [:a, nil, :b]))
      refute_equal(s, HexaPDF::StreamData.new(:source, decode_parms: [:a, :b]))
      refute_equal(s, HexaPDF::StreamData.new(:source, decode_parms: [:a, nil, :b], offset: 5))
    end

    it "returns false if compared with an other object of a different class" do
      refute_equal(:source, HexaPDF::StreamData.new(:source))
    end
  end
end

describe HexaPDF::Stream do
  before do
    @document = Struct.new(:config).new
    @document.config = HexaPDF::Configuration.with_defaults
    @document.instance_variable_set(:@version, '1.2')
    def (@document).unwrap(obj); obj; end
    def (@document).wrap(obj, *); obj; end
    def (@document).deref(obj); obj; end

    @stm = HexaPDF::Stream.new({}, oid: 1, document: @document)
  end

  it "#initialize accepts the stream keyword" do
    stm = HexaPDF::Stream.new({}, document: @document, stream: 'other')
    assert_equal('other', stm.stream)
  end

  it "must always be indirect" do
    @stm.must_be_indirect = false
    assert(@stm.must_be_indirect?)
  end

  describe "stream=" do
    it "allows assigning nil" do
      @stm.stream = nil
      assert_equal('', @stm.raw_stream)
      assert_equal('', @stm.stream)
      assert_equal(Encoding::BINARY, @stm.stream.encoding)
    end

    it "allows assigning a string" do
      @stm.stream = 'hallo'
      assert_equal('hallo', @stm.raw_stream)
      assert_equal('hallo', @stm.stream)
    end

    it "retains the encoding if a String is assigned" do
      @stm.stream = 'hallo'
      assert_equal(Encoding::UTF_8, @stm.stream.encoding)
      @stm.stream = 'hallo'.encode('ISO-8859-1')
      assert_equal(Encoding::ISO_8859_1, @stm.stream.encoding)
    end

    it "allows assigning a StreamData object" do
      @stmdata = HexaPDF::StreamData.new(StringIO.new('testing'))
      @stm.stream = @stmdata
      assert_equal(@stmdata, @stm.raw_stream)
      assert_equal('testing', @stm.stream)
      assert_equal(Encoding::BINARY, @stm.stream.encoding)
    end

    it "fails on any object class other than String, StreamData, NilClass" do
      assert_raises(ArgumentError) { @stm.stream = 5 }
    end
  end

  describe "stream" do
    it "doesn't allow changing the returned value directly" do
      @stm.stream = 'data'
      @stm.stream.upcase!
      assert_equal('data', @stm.stream)

      @stm.stream = HexaPDF::StreamData.new { "data" }
      @stm.stream.upcase!
      assert_equal('data', @stm.stream)
    end
  end

  def encoded_data(str, encoders = [])
    map = @document.config['filter.map']
    tmp = feeder(str)
    encoders.each {|e| tmp = Object.const_get(map[e]).encoder(tmp) }
    collector(tmp)
  end

  describe "stream_decoder" do
    it "works with a string stream" do
      @stm.stream = 'testing'
      result = collector(@stm.stream_decoder)
      assert_equal('testing', result)
      assert_equal(Encoding::BINARY, result.encoding)
    end

    it "works with an IO object inside StreamData" do
      io = StringIO.new(encoded_data('testing', [:A85, :AHx]))
      @stm.stream = HexaPDF::StreamData.new(io, filter: [:AHx, :A85])
      assert_equal('testing', collector(@stm.stream_decoder))
    end

    it "works with a Proc object inside StreamData" do
      @stm.stream = HexaPDF::StreamData.new(proc { 'testing' })
      assert_equal('testing', collector(@stm.stream_decoder))
    end

    it "fails if an unknown filter name is used" do
      @stm.stream = HexaPDF::StreamData.new(feeder('testing'), filter: [:Unknown])
      assert_raises(HexaPDF::Error) { @stm.stream_decoder }
    end
  end

  describe "stream_encoder" do
    it "uses the :Filter and :DecodeParms entries of the value attribute correctly" do
      @stm.value[:Filter] = nil
      @stm.stream = 'test'
      assert_equal('test', collector(@stm.stream_encoder))

      @stm.value[:Filter] = :AHx
      @stm.stream = 'test'
      assert_equal('74657374>', collector(@stm.stream_encoder))

      @stm.value[:Filter] = [:AHx, :Fl]
      @stm.value[:DecodeParms] = nil
      @stm.stream = 'abcdefg'
      assert_equal("78da4b4c4a4e494d4b07000adb02bd>", collector(@stm.stream_encoder))

      @stm.value[:Filter] = [:AHx, :Fl]
      @stm.value[:DecodeParms] = [nil, {Predictor: 12}]
      @stm.stream = 'abcdefg'
      assert_equal("78da634a6462444000058f0076>", collector(@stm.stream_encoder))

      @stm.value[:Filter] = [:AHx, nil, :Fl]
      @stm.value[:DecodeParms] = [nil, nil, {Predictor: 10}]
      @stm.stream = 'abcdefg'
      assert_equal("78da6348644862486648614865486348070012fa02bd>", collector(@stm.stream_encoder))
    end

    it "decodes a StreamData stream before encoding" do
      @stm.value[:Filter] = :AHx
      data_proc = proc { encoded_data('test', [:A85, :AHx]) }
      @stm.stream = HexaPDF::StreamData.new(data_proc, filter: [:AHx, :A85])
      assert_equal('74657374>', collector(@stm.stream_encoder))
    end

    it "decodes only what is necessary of a StreamData stream on encoding" do
      @stm.value[:Filter] = :AHx
      data_proc = proc { encoded_data('test', [:AHx, :A85]) }
      @stm.stream = HexaPDF::StreamData.new(data_proc, filter: [:A85, :AHx])
      assert_equal('74657374>', collector(@stm.stream_encoder))

      @stm.value[:Filter] = [:Unknown]
      @stm.stream = HexaPDF::StreamData.new(proc { 'test' }, filter: [:Unknown])
      assert_equal('test', collector(@stm.stream_encoder))
    end
  end

  describe "set_filter" do
    it "sets correct filter values without decode parameters" do
      @stm.set_filter(:Test)
      assert_equal(:Test, @stm.value[:Filter])
      refute(@stm.value.key?(:DecodeParms))

      @stm.set_filter([:Test, :Test1])
      assert_equal([:Test, :Test1], @stm.value[:Filter])
      refute(@stm.value.key?(:DecodeParms))
    end

    it "sets correct filter/decode parameter values" do
      @stm.set_filter([:Test, :Test], :Other)
      assert_equal([:Test, :Test], @stm.value[:Filter])
      assert_equal(:Other, @stm.value[:DecodeParms])

      @stm.set_filter([:Test, :Test], [:Other, :Other])
      assert_equal([:Test, :Test], @stm.value[:Filter])
      assert_equal([:Other, :Other], @stm.value[:DecodeParms])
    end

    it "deletes the /Filter and/or decode parameters values when arguments are nil" do
      @stm.set_filter(:Test, :Other)
      @stm.set_filter(nil, :Other)
      refute(@stm.value.key?(:Filter))
      refute(@stm.value.key?(:DecodeParms))

      @stm.set_filter(:Test, :Other)
      @stm.set_filter(:Test, nil)
      assert_equal(:Test, @stm[:Filter])
      refute(@stm.value.key?(:DecodeParms))
    end
  end

  describe "validation" do
    it "validates the /Filter entry" do
      assert(@stm.validate)

      @stm.set_filter(:FlateDecode)
      assert(@stm.validate(auto_correct: false))
      assert_equal(:FlateDecode, @stm[:Filter])

      @stm.set_filter(:AHx)
      assert(@stm.validate(auto_correct: true))
      assert_equal(:ASCIIHexDecode, @stm[:Filter])

      @stm.set_filter([:FlateDecode, :AHx])
      assert(@stm.validate(auto_correct: true))
      assert_equal([:FlateDecode, :ASCIIHexDecode], @stm[:Filter])
    end
  end
end
