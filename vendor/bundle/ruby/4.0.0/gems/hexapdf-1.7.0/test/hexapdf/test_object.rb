# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/object'
require 'hexapdf/reference'
require 'hexapdf/document'

describe HexaPDF::Object do
  describe "class.deep_copy" do
    it "handles general, duplicatable classes" do
      x = "test"
      assert_equal("test", HexaPDF::Object.deep_copy(x))
      refute_same(x, HexaPDF::Object.deep_copy(x))
    end

    it "handles arrays" do
      x = [5, 6, [1, 2, 3]]
      y = HexaPDF::Object.deep_copy(x)
      x[2][0] = 4
      assert_equal([5, 6, [1, 2, 3]], y)
    end

    it "handles hashes" do
      x = {a: 5, b: 6, c: {a: 1, b: 2}}
      y = HexaPDF::Object.deep_copy(x)
      x[:c][:a] = 4
      assert_equal({a: 5, b: 6, c: {a: 1, b: 2}}, y)
    end

    it "handles PDF references" do
      x = HexaPDF::Reference.new(1, 2)
      assert_same(x, HexaPDF::Object.deep_copy(x))
    end

    it "handles PDF objects" do
      x = HexaPDF::Object.new("test")
      assert_equal("test", HexaPDF::Object.deep_copy(x))

      x.must_be_indirect = true
      assert_same(x, HexaPDF::Object.deep_copy(x))

      x.must_be_indirect = false
      x.oid = 1
      assert_same(x, HexaPDF::Object.deep_copy(x))
    end
  end

  describe "class.make_direct" do
    before do
      @doc = HexaPDF::Document.new
    end

    it "makes values of wrapped direct objects also direct" do
      obj = HexaPDF::Object.new(5)
      assert_same(obj, HexaPDF::Object.make_direct(obj, @doc))
      obj = HexaPDF::Dictionary.new({a: 5, b: HexaPDF::Object.new(:a, oid: 3, document: @doc)})
      assert_same(obj, HexaPDF::Object.make_direct(obj, @doc))
      assert_equal(:a, obj[:b])
    end

    it "works for simple values" do
      obj = HexaPDF::Object.new(5, oid: 1, document: @doc)
      assert_same(5, HexaPDF::Object.make_direct(obj, @doc))
    end

    it "works for hashes" do
      obj = HexaPDF::Dictionary.new({a: 5, b: HexaPDF::Object.new(:a, oid: 3, document: @doc)},
                                    oid: 1, document: @doc)
      assert_equal({a: 5, b: :a}, HexaPDF::Object.make_direct(obj, @doc))
    end

    it "works for arrays" do
      obj = HexaPDF::PDFArray.new([:b, HexaPDF::Object.new(:a, oid: 3, document: @doc)],
                                  oid: 1, document: @doc)
      assert_equal([:b, :a], HexaPDF::Object.make_direct(obj, @doc))
    end

    it "resolves references" do
      @doc.add(:Test, oid: 1)
      obj = HexaPDF::PDFArray.new([HexaPDF::Reference.new(1, 0)],
                                  oid: 2, document: @doc)
      assert_equal([:Test], HexaPDF::Object.make_direct(obj, @doc))
      assert(@doc.object(1).null?)
    end
  end

  describe "initialize" do
    it "uses a simple value as is" do
      obj = HexaPDF::Object.new(5)
      assert_equal(5, obj.value)
    end

    it "reuses the data object of a HexaPDF::Object" do
      obj = HexaPDF::Object.new(5)
      assert_same(obj.data, HexaPDF::Object.new(obj).data)
    end

    it "uses a provided PDFData structure" do
      obj = HexaPDF::PDFData.new(5)
      assert_equal(obj, HexaPDF::Object.new(obj).data)
    end
  end

  describe "getters and setters" do
    before do
      @obj = HexaPDF::Object.new(5)
    end

    it "can get/set oid" do
      @obj.oid = 7
      assert_equal(7, @obj.oid)
    end

    it "can get/set gen" do
      @obj.gen = 7
      assert_equal(7, @obj.gen)
    end

    it "can get/set the value" do
      @obj.value = :test
      assert_equal(:test, @obj.value)
    end
  end

  it "returns the document or raises an error if none is set" do
    assert_equal(:document, HexaPDF::Object.new(nil, document: :document).document)
    assert_raises(HexaPDF::Error) { HexaPDF::Object.new(nil).document }
  end

  describe "null?" do
    it "works for nil values" do
      assert(HexaPDF::Object.new(nil).null?)
    end
  end

  describe "validate" do
    before do
      @obj = HexaPDF::Object.new(5)
    end

    it "invokes perform_validation correctly" do
      invoked = false
      @obj.define_singleton_method(:perform_validation) { invoked = true }
      assert(@obj.validate)
      assert(invoked)
    end

    it "yields all arguments yieled by perform_validation" do
      invoked = []
      @obj.define_singleton_method(:perform_validation) do |&block|
        block.call("error", true, :object)
      end
      assert(@obj.validate {|*a| invoked << a })
      assert_equal([["error", true, :object]], invoked)
    end

    it "provides self as third argument if none is yielded by perform_validation" do
      invoked = []
      @obj.define_singleton_method(:perform_validation) do |&block|
        block.call("error", true)
      end
      assert(@obj.validate {|*a| invoked << a })
      assert_equal([["error", true, @obj]], invoked)
    end

    it "yields all problems when auto_correct is true" do
      invoked = []
      @obj.define_singleton_method(:perform_validation) do |&block|
        invoked << :before
        block.call("error", false)
        invoked << :after
        block.call("error2", true)
        invoked << :last
      end
      refute(@obj.validate)
      assert_equal([:before, :after, :last], invoked)
    end

    it "stops at the first uncorrectable problem if auto_correct is false" do
      invoked = []
      @obj.define_singleton_method(:perform_validation) do |&block|
        invoked << :before
        block.call("error", false)
        invoked << :after
      end
      refute(@obj.validate(auto_correct: false))
      assert_equal([:before], invoked)
    end

    it "re-raises caught HexaPDF::Error exceptions" do
      @obj.define_singleton_method(:perform_validation) { raise HexaPDF::Error, "Unknown" }
      invoked = []
      assert_raises(HexaPDF::Error) { @obj.validate {|*a| invoked << a } }
    end

    it "catches errors raised in perform_validation and produces an appropriate message" do
      @obj.define_singleton_method(:perform_validation) { raise "Unknown" }
      invoked = []
      refute(@obj.validate {|*a| invoked << a })
      assert_equal([["Unexpected error encountered: Unknown", false, @obj]], invoked)
    end
  end

  it "can represent itself during inspection" do
    obj = HexaPDF::Object.new(5, oid: 5)
    assert_match(/\[5, 0\].*value=5/, obj.inspect)
  end

  it "can be compared to another object, reference or, if not indirect, a simple value" do
    obj = HexaPDF::Object.new(5, oid: 5)

    assert_equal(obj, HexaPDF::Object.new(obj))
    refute_equal(obj, HexaPDF::Object.new(5, oid: 5))
    refute_equal(obj, HexaPDF::Object.new(6, oid: 5))
    refute_equal(obj, HexaPDF::Object.new(5, oid: 1))
    refute_equal(obj, HexaPDF::Object.new(5, oid: 5, gen: 1))

    assert_equal(obj, HexaPDF::Reference.new(5, 0))

    refute_equal(obj, 5)
    obj.data.oid = 0
    assert_equal(obj, 5)
    refute_equal(obj, HexaPDF::Object.new(5))
  end

  it "works correctly as hash key, is interchangable in this regard with Reference objects" do
    hash = {}
    hash[HexaPDF::Reference.new(1)] = :one
    hash[HexaPDF::Object.new(:val, oid: 2)] = :two
    assert_equal(:one, hash[HexaPDF::Reference.new(1, 0)])
    assert_equal(:one, hash[HexaPDF::Object.new(:data, oid: 1)])
    assert_equal(:two, hash[HexaPDF::Reference.new(2)])
    assert_equal(:two, hash[HexaPDF::Object.new(:data, oid: 2)])
  end

  it "is sortable w.r.t to other objects implementing #oid and #gen, like Reference" do
    a = HexaPDF::Object.new(:data, oid: 1)
    b = HexaPDF::Object.new(:data, oid: 1, gen: 1)
    c = HexaPDF::Reference.new(5, 7)
    assert_equal([a, b, c], [b, c, a].sort)
    assert_nil(HexaPDF::Object.new(:data, oid: 1) <=> 5)
  end

  describe "deep_copy" do
    it "creates an independent object" do
      obj = HexaPDF::Object.new({a: "mystring", b: HexaPDF::Reference.new(1, 0), c: 5})
      copy = obj.deep_copy
      refute_same(copy, obj)
      assert_equal(copy.value, obj.value)
      refute_same(copy.value[:a], obj.value[:a])
    end

    it "duplicates the stream if it is a string" do
      obj = HexaPDF::Object.new(nil, stream: "data")
      copy = obj.deep_copy
      refute_same(copy.data.stream, obj.data.stream)
    end
  end

  describe "caching" do
    before do
      @obj = HexaPDF::Object.new({}, document: HexaPDF::Document.new)
    end

    it "can set and return a cached value" do
      assert_equal(:value, @obj.cache(:data, :value))
      assert_equal(:value, @obj.cache(:data, :other))
      assert_equal(:value, @obj.cache(:block) { :value })
      assert_equal(:other, @obj.cache(:data, :other, update: true))
    end

    it "can check for the existence of a cached value" do
      refute(@obj.cached?(:data))
      @obj.cache(:data, :value)
      assert(@obj.cached?(:data))
    end

    it "can clear all cached values" do
      @obj.cache(:data, :value)
      assert(@obj.cached?(:data))
      @obj.clear_cache
      refute(@obj.cached?(:data))
    end
  end

  describe "validation" do
    before do
      @doc = Object.new
      @doc.define_singleton_method(:add) {|obj| obj.oid = 1 }
    end

    it "validates that the object is indirect if it must be indirect" do
      obj = HexaPDF::Object.new(6, document: @doc)

      obj.validate
      assert_equal(0, obj.oid)

      obj.must_be_indirect = true
      obj.validate
      assert_equal(1, obj.oid)
    end
  end
end
