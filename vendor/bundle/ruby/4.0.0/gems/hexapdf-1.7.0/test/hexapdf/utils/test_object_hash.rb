# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/utils/object_hash'

describe HexaPDF::Utils::ObjectHash do
  before do
    @hash = HexaPDF::Utils::ObjectHash.new
  end

  describe "[]" do
    it "works with both an object number and a generation number" do
      @hash[1, 5] = 5
      assert_equal(5, @hash[1, 5])
      assert_nil(@hash[1, 4])
      assert_nil(@hash[2, 5])
    end

    it "works with an object number only" do
      @hash[1, 5] = 5
      assert_equal(5, @hash[1])
      assert_nil(@hash[2])
    end
  end

  describe "[]=" do
    it "allows adding an entry" do
      @hash[1, 5] = 5
      assert_equal(5, @hash[1, 5])
    end

    it "allows overwriting an existing entry for an object number" do
      @hash[1, 0] = 5
      @hash[1, 0] = 6
      assert_equal(6, @hash[1, 0])

      @hash[1, 1] = 5
      assert_equal(5, @hash[1, 1])
      assert_nil(@hash[1, 0])
    end
  end

  describe "entry?" do
    it "checks if an entry for a specific object number exists" do
      refute(@hash.entry?(1))
      @hash[1, 1] = 5
      assert(@hash.entry?(1))
    end

    it "checks if an entry for a specific object and generation number exists" do
      refute(@hash.entry?(1, 1))
      @hash[1, 1] = 5
      assert(@hash.entry?(1, 1))
      refute(@hash.entry?(1, 0))
    end
  end

  it "returns the generation number for an object number with gen_for_oid" do
    assert_nil(@hash.gen_for_oid(1))
    @hash[1, 5] = 5
    assert_equal(5, @hash.gen_for_oid(1))
  end

  it "deletes an entry via delete" do
    @hash[1, 0] = 5
    @hash.delete(1)
    assert_nil(@hash[1])
  end

  describe "each" do
    it "acts as an enumerable object" do
      @hash[1, 0] = 5
      @hash[2, 3] = 6
      @hash[3, 2] = 7
      assert_equal([[1, 0, 5], [2, 3, 6], [3, 2, 7]], @hash.each.to_a)

      @hash.each do |oid, gen, data|
        assert_equal(data, @hash[oid, gen])
      end
    end

    it "allows key insertion during iteration" do
      @hash[1, 0] = 5
      count = 0
      @hash.each { count += 1; @hash[2, 0] = 6 }
      assert_equal(1, count)
    end
  end

  describe "max_oid" do
    it "is zero when no objects are stored" do
      assert_equal(0, @hash.max_oid)
      @hash[1, 0] = 5
      @hash.delete(1)
      assert_equal(0, @hash.max_oid)
    end

    it "changes accordingly when data is inserted" do
      @hash[1, 0] = 5
      assert_equal(1, @hash.max_oid)
      @hash[5, 0] = 5
      assert_equal(5, @hash.max_oid)
      @hash[3, 0] = 5
      assert_equal(5, @hash.max_oid)
    end

    it "changes accordingly when data is deleted" do
      @hash[1, 0] = @hash[3, 0] = @hash[5, 0] = 5
      @hash.delete(1)
      assert_equal(5, @hash.max_oid)
      @hash.delete(5)
      assert_equal(3, @hash.max_oid)
    end
  end

  it "can return a list of all object IDs" do
    @hash[1, 0] = @hash[3, 1] = 7
    assert_equal([3, 1], @hash.oids)
  end
end
