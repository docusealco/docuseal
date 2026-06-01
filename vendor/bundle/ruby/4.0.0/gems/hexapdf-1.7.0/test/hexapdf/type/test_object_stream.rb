# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/type/object_stream'

describe HexaPDF::Type::ObjectStream::Data do
  before do
    @data = HexaPDF::Type::ObjectStream::Data.new("5 [1 2]", [1, 5], [0, 2])
  end

  it "returns the correct [object, oid] pair for a given index" do
    assert_equal([5, 1], @data.object_by_index(0))
    assert_equal([[1, 2], 5], @data.object_by_index(1))
  end

  it "fails if the index is out of bounds" do
    assert_raises(ArgumentError) { @data.object_by_index(5) }
    assert_raises(ArgumentError) { @data.object_by_index(-1) }
  end
end

describe HexaPDF::Type::ObjectStream do
  before do
    @doc = Object.new
    @doc.instance_variable_set(:@version, '1.5')
    @doc.define_singleton_method(:revisions) do
      rev1 = Object.new
      def rev1.trailer; {Encrypt: HexaPDF::Object.new({}, oid: 10)}; end
      rev2 = Object.new
      def rev2.trailer; {Encrypt: HexaPDF::Object.new({}, oid: 9)}; end
      @revisions ||= [rev1, rev2]
    end
    @doc.define_singleton_method(:trailer) { revisions.last.trailer }
    @obj = HexaPDF::Type::ObjectStream.new({N: 2, First: 8}, oid: 1, document: @doc,
                                           stream: "1 0 5 2 5 [1 2]")
  end

  it "parses an associated stream the first time the stored objects are accessed" do
    assert_nil(@obj.instance_variable_get(:@objects))
    assert_equal(0, @obj.object_index(HexaPDF::Reference.new(1, 0)))
    assert_equal(1, @obj.object_index(HexaPDF::Reference.new(5, 0)))
  end

  it "correctly parses stream data" do
    data = @obj.parse_stream
    assert_equal([5, 1], data.object_by_index(0))
    assert_equal([[1, 2], 5], data.object_by_index(1))
  end

  it "allows adding and deleting objects as well as determining their index" do
    @obj.add_object(5)
    @obj.add_object(7)
    @obj.add_object(9)
    @obj.add_object(5)
    assert_equal(2, @obj.object_index(5))
    assert_equal(3, @obj.object_index(7))
    assert_equal(4, @obj.object_index(9))

    @obj.delete_object(5)
    @obj.delete_object(5)
    assert_equal(2, @obj.object_index(9))
    assert_equal(3, @obj.object_index(7))
    assert_nil(@obj.object_index(5))

    @obj.delete_object(7)
    @obj.delete_object(9)
    assert_nil(@obj.object_index(7))
  end

  describe "write objects to stream" do
    before do
      @obj.delete_object(HexaPDF::Reference.new(1))
      @obj.delete_object(HexaPDF::Reference.new(5))
      @revision = Object.new
      def @revision.object(obj); obj; end
    end

    it "processes allowed objects" do
      @obj.add_object(HexaPDF::Object.new(5, oid: 1))
      @obj.add_object(HexaPDF::Object.new([1, 2], oid: 5))

      @obj.write_objects(@revision)
      assert_equal(2, @obj.value[:N])
      assert_equal(8, @obj.value[:First])
      assert_equal("1 0 5 2 5 [1 2] ", @obj.stream)
    end

    it "doesn't allow null objects" do
      @obj.add_object(HexaPDF::Object.new(nil, oid: 7))
      @obj.write_objects(@revision)
      assert_equal(0, @obj.value[:N])
      assert_equal(0, @obj.value[:First])
      assert_equal("", @obj.stream)
    end

    it "doesn't allow objects with gen not 0" do
      @obj.add_object(HexaPDF::Object.new(:will_be_deleted, oid: 3, gen: 1))
      @obj.write_objects(@revision)
      assert_equal(0, @obj.value[:N])
      assert_equal(0, @obj.value[:First])
      assert_equal("", @obj.stream)
    end

    it "doesn't allow an encryption dictionary to be compressed" do
      @obj.add_object(@doc.trailer[:Encrypt])
      @obj.add_object(@doc.revisions[0].trailer[:Encrypt])
      @obj.write_objects(@revision)
      assert_equal(0, @obj.value[:N])
      assert_equal(0, @obj.value[:First])
      assert_equal("", @obj.stream)
    end

    it "doesn't allow the Catalog entry to be compressed" do
      @doc.trailer.delete(:Encrypt)
      @obj.add_object(HexaPDF::Dictionary.new({Type: :Catalog}, oid: 8))
      @obj.write_objects(@revision)
      assert_equal(0, @obj.value[:N])
      assert_equal(0, @obj.value[:First])
      assert_equal("", @obj.stream)
    end

    it "doesn't allow signature dictionaries to be compressed" do
      @obj.add_object(HexaPDF::Dictionary.new({Type: :Sig}, oid: 1))
      @obj.add_object(HexaPDF::Dictionary.new({Type: :DocTimeStamp}, oid: 2))
      @obj.add_object(HexaPDF::Dictionary.new({ByteRange: [], Contents: ''}, oid: 3))
      @obj.write_objects(@revision)
      assert_equal(0, @obj.value[:N])
      assert_equal("", @obj.stream)
    end
  end

  describe "perform_validation" do
    it "fails validation if gen != 0" do
      assert(@obj.validate(auto_correct: false))
      @obj.gen = 1
      refute(@obj.validate(auto_correct: false) do |msg, correctable|
        assert_match(/invalid generation/, msg)
        refute(correctable)
      end)
    end

    it "sets the /N and /First entries to dummy values so that validation works" do
      @obj = HexaPDF::Type::ObjectStream.new({}, oid: 1, document: @doc)
      assert(@obj.validate(auto_correct: false))
      assert_equal(0, @obj[:N])
      assert_equal(0, @obj[:First])
    end
  end
end
