# -*- frozen_string_literal: true -*-

require 'test_helper'
require 'geom2d/utils/sorted_list'

describe Geom2D::Utils::SortedList do
  before do
    @list = Geom2D::Utils::SortedList.new {|a, b| a < b }
  end

  describe "insert" do
    it "inserts a value and returns surrounding values" do
      ppv, pv, nv = @list.insert(1)
      assert_nil(ppv)
      assert_nil(pv)
      assert_nil(nv)
    end

    it "uses the comparator for choosing the place to insert the value" do
      @list.insert(10)
      @list.insert(5)
      @list.insert(8)
      ppv, pv, nv = @list.insert(9)
      assert_equal([5, 8, 10], [ppv, pv, nv])
      assert_equal([5, 8, 9, 10], @list.to_a)
    end
  end

  it "deletes a value from the list and returns the neighbouring values" do
    @list.push(8).push(5).push(3).push(4).push(6)
    assert_equal([6, nil], @list.delete(8))
    assert_equal([nil, 4], @list.delete(3))
    assert_equal([4, 6], @list.delete(5))
  end

  it "returns whether it is empty" do
    assert(@list.empty?)
    @list.insert(5)
    refute(@list.empty?)
    @list.delete(5)
    assert(@list.empty?)
  end

  it "returns the last value in the list" do
    @list.insert(5)
    assert_equal(5, @list.last)
    @list.insert(10)
    assert_equal(10, @list.last)
    @list.insert(6)
    assert_equal(10, @list.last)
  end

  it "pops the top value of the list" do
    @list.push(8).push(5)
    assert_equal(8, @list.pop)
  end

  it "clears the whole list" do
    @list.push(8).push(5)
    @list.clear
    assert(@list.empty?)
  end

  it "can be inspected" do
    @list.push(8).push(5)
    assert_match(/[5, 8]/, @list.inspect)
  end
end
