# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/pdf_array'
require 'hexapdf/reference'
require 'hexapdf/dictionary'

describe HexaPDF::PDFArray do
  def deref(obj)
    if obj.kind_of?(HexaPDF::Reference)
      HexaPDF::Object.new('deref', oid: obj.oid, gen: obj.gen)
    else
      obj
    end
  end

  def add(obj)
    HexaPDF::Object.new(obj, oid: 1)
  end

  def delete(_obj)
  end

  def wrap(obj, type:)
    type.new(obj, document: self)
  end

  before do
    @array = HexaPDF::PDFArray.new([1, HexaPDF::Object.new(:data), HexaPDF::Reference.new(1, 0),
                                    HexaPDF::Dictionary.new({a: 'b'})], document: self)
  end

  describe "after_data_change" do
    it "uses an empty array if nil is provided" do
      array = HexaPDF::PDFArray.new(nil)
      assert_equal([], array.value)
    end
    it "fails if the value is not an array" do
      assert_raises(ArgumentError) { HexaPDF::PDFArray.new(:Name) }
    end
  end

  describe "[]" do
    it "allows retrieving values by index" do
      assert_equal(1, @array[0])
    end

    it "allows retrieving values by start/length" do
      assert_equal([1, :data], @array[0, 2])
    end

    it "allows retrieving values by range" do
      assert_equal([1, :data], @array[0..1])
    end

    it "fetches the value out of a HexaPDF::Object" do
      assert_equal(:data, @array[1])
    end

    it "resolves references and stores the resolved object in place of the reference" do
      assert_equal('deref', @array[2])
      assert_kind_of(HexaPDF::Object, @array.value[2])
    end
  end

  describe "[]=" do
    it "directly stores the value if the stored value is no HexaPDF::Object" do
      @array[0] = 2
      assert_equal(2, @array.value[0])
    end

    it "stores the value in an existing HexaPDF::Object but only if it is not such an object" do
      @array[1] = [4, 5]
      assert_equal([4, 5], @array.value[1].value)

      @array[1] = temp = HexaPDF::Object.new(:other)
      assert_equal(temp, @array.value[1])
    end

    it "doesn't store the value inside the existing object for subclasses of HexaPDF::Object" do
      @array[3] = [4, 5]
      assert_equal([4, 5], @array.value[3])
    end

    it "doesn't store the value inside for HexaPDF::Reference objects" do
      @array[1] = HexaPDF::Reference.new(5, 0)
      assert_kind_of(HexaPDF::Reference, @array.value[1])
    end
  end

  it "allows getting multiple values at once" do
    assert_equal([1, :data, @array[3]], @array.values_at(0, 1, 3))
  end

  it "allows adding values to the end" do
    @array << 5
    assert_equal(5, @array[4])
  end

  it "allows inserting values like Array#insert" do
    @array.insert(1, :a, :b)
    assert_equal([1, :a, :b, :data], @array[0, 4])
  end

  it "allows deleting values at a certain index" do
    @array.delete_at(2)
    assert_equal([1, :data, @array[2]], @array[0, 5])
  end

  it "allows deleting an object" do
    obj = @array.value[1]
    assert_same(obj, @array.delete(obj))
    ref = HexaPDF::Object.new(:test, oid: 1)
    assert_equal(ref, @array.delete(ref))
  end

  describe "slice!" do
    it "allows deleting a single element" do
      @array.slice!(2)
      assert_equal([1, :data, @array[2]], @array[0, 5])
    end

    it "allows deleting elements given by start/length" do
      @array.slice!(1, 2)
      assert_equal([1, @array[1]], @array[0, 5])
    end

    it "allows deleting elements given a range" do
      @array.slice!(1..2)
      assert_equal([1, @array[1]], @array[0, 5])
    end
  end

  describe "reject!" do
    it "allows deleting elements that are selected using a block" do
      assert_same(@array, @array.reject! {|item| item == :data })
      assert_equal([1, "deref", @array[2]], @array.to_a)
    end

    it "returns nil if no elements were deleted" do
      assert_nil(@array.reject! {|item| false })
    end

    it "returns an enumerator if no block is given" do
      assert_kind_of(Enumerator, @array.reject!)
    end
  end

  describe "map!" do
    it "maps elements in-place to the return values of the block" do
      assert_same(@array, @array.map! {|item| 5 })
      assert_equal([5, 5, 5, 5], @array.to_a)
    end

    it "returns an enumerator if no block is given" do
      assert_kind_of(Enumerator, @array.reject!)
    end
  end

  describe "compact!" do
    it "removes all nil elements and returns self" do
      @array << nil
      assert_same(@array, @array.compact!)
      assert_equal(4, @array.size)
    end

    it "returns nil if no elements were removed" do
      assert_nil(@array.compact!)
    end
  end

  describe "index" do
    it "allows getting the index of an element" do
      assert_equal(2, @array.index("deref"))
    end

    it "allows getting the index of the first element for which a block returns true" do
      assert_equal(2, @array.index {|item| item == "deref" })
    end
  end

  it "returns the length of the array" do
    assert_equal(4, @array.length)
  end

  it "allows checking for emptiness" do
    refute(@array.empty?)
    @array.slice!(0, 5)
    assert(@array.empty?)
  end

  describe "each" do
    it "iterates over all elements in the dictionary" do
      data = [1, :data, "deref", @array[3]]
      @array.each {|value| assert_equal(data.shift, value) }
    end
  end

  it "can be converted to a simple array" do
    assert_equal([1, :data, "deref", @array[3]], @array.to_ary)
  end

  describe "perform_validation" do
    it "validates nested objects" do
      @array.value << HexaPDF::PDFArray.new([HexaPDF::Reference.new(1, 0)], document: self)
      assert(@array.validate)
      assert_kind_of(HexaPDF::Object, @array.value[2])
      assert_kind_of(HexaPDF::Object, @array.value.last.value[0])
    end
  end
end
