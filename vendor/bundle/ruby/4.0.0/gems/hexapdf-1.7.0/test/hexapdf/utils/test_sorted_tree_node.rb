# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/document'
require 'hexapdf/name_tree_node'
require 'hexapdf/number_tree_node'

describe HexaPDF::Utils::SortedTreeNode do
  before do
    @doc = HexaPDF::Document.new
    @root = @doc.add({}, type: HexaPDF::NameTreeNode)
  end

  def add_multilevel_entries
    item = @doc.add(1)
    @item_ref = HexaPDF::Reference.new(item.oid, item.gen)
    @kid11 = @doc.add({Limits: ['c', 'f'], Names: ['c', @item_ref, 'f', 1]}, type: HexaPDF::NameTreeNode)
    @kid12 = @doc.add({Limits: ['i', 'm'], Names: ['i', 1, 'm', 1]}, type: HexaPDF::NameTreeNode)
    ref = HexaPDF::Reference.new(@kid11.oid, @kid11.gen)
    @kid1 = @doc.add({Limits: ['c', 'm'], Kids: [ref, @kid12]})
    @kid21 = @doc.add({Limits: ['o', 'q'], Names: ['o', 1, 'q', 1]}, type: HexaPDF::NameTreeNode)
    @kid221 = @doc.add({Limits: ['s', 'u'], Names: ['s', 1, 'u', 1]}, type: HexaPDF::NameTreeNode)
    @kid22 = @doc.add({Limits: ['s', 'u'], Kids: [@kid221]}, type: HexaPDF::NameTreeNode)
    @kid2 = @doc.add({Limits: ['o', 'u'], Kids: [@kid21, @kid22]}, type: HexaPDF::NameTreeNode)
    @root[:Kids] = [@kid1, @kid2]
  end

  it "must always be indirect" do
    assert(@root.must_be_indirect?)
  end

  describe "add" do
    it "works with the root node alone" do
      @root.add_entry('c', 1)
      @root.add_entry('a', 2)
      @root.add_entry('e', 3)
      assert_equal(['a', 2, 'c', 1, 'e', 3], @root[:Names].value)
      refute(@root[:Limits])
    end

    it "replaces an existing entry if overwrite is true" do
      assert(@root.add_entry('a', 2))
      assert(@root.add_entry('a', 5))
      assert_equal(['a', 5], @root[:Names].value)
    end

    it "doesn't replace an existing entry if overwrite is false" do
      assert(@root.add_entry('a', 2))
      refute(@root.add_entry('a', 5, overwrite: false))
      assert_equal(['a', 2], @root[:Names].value)
    end

    it "works with one level of intermediate nodes" do
      kid1 = HexaPDF::NameTreeNode.new({Limits: ['m', 'm'], Names: ['m', 1]}, document: @doc)
      kid2 = HexaPDF::NameTreeNode.new({Limits: ['t', 't'], Names: ['t', 1]}, document: @doc)
      @root[:Kids] = [kid1, kid2]
      @root.add_entry('c', 1)
      @root.add_entry('d', 1)
      @root.add_entry('p', 1)
      @root.add_entry('r', 1)
      @root.add_entry('u', 1)
      assert_equal(['c', 'm'], kid1[:Limits].value)
      assert_equal(['c', 1, 'd', 1, 'm', 1], kid1[:Names].value)
      assert_equal(['p', 'u'], kid2[:Limits].value)
      assert_equal(['p', 1, 'r', 1, 't', 1, 'u', 1], kid2[:Names].value)
    end

    it "works with multiple levels of intermediate nodes" do
      add_multilevel_entries
      @root.add_entry('a', 1)
      @root.add_entry('e', 1)
      @root.add_entry('g', 1)
      @root.add_entry('j', 1)
      @root.add_entry('n', 1)
      @root.add_entry('p', 1)
      @root.add_entry('r', 1)
      @root.add_entry('v', 1)
      assert_equal(['a', 'm'], @kid1[:Limits].value)
      assert_equal(['a', 'f'], @kid11[:Limits].value)
      assert_equal(['a', 1, 'c', @item_ref, 'e', 1, 'f', 1], @kid11[:Names].value)
      assert_equal(['g', 'm'], @kid12[:Limits].value)
      assert_equal(['g', 1, 'i', 1, 'j', 1, 'm', 1], @kid12[:Names].value)
      assert_equal(['n', 'v'], @kid2[:Limits].value)
      assert_equal(['n', 'q'], @kid21[:Limits].value)
      assert_equal(['n', 1, 'o', 1, 'p', 1, 'q', 1], @kid21[:Names].value)
      assert_equal(['r', 'v'], @kid22[:Limits].value)
      assert_equal(['r', 'v'], @kid221[:Limits].value)
      assert_equal(['r', 1, 's', 1, 'u', 1, 'v', 1], @kid221[:Names].value)
    end

    it "splits nodes if needed" do
      @doc.config['sorted_tree.max_leaf_node_size'] = 4
      %w[a c e m k i g d b l j f h].each {|key| @root.add_entry(key, 1) }
      refute(@root.value.key?(:Limits))
      refute(@root.value.key?(:Names))
      assert_equal(6, @root[:Kids].size)
      assert_equal(['a', 1, 'b', 1], @root[:Kids][0][:Names].value)
      assert_equal(['a', 'b'], @root[:Kids][0][:Limits].value)
      assert_equal(['c', 1, 'd', 1], @root[:Kids][1][:Names].value)
      assert_equal(['c', 'd'], @root[:Kids][1][:Limits].value)
      assert_equal(['e', 1, 'f', 1], @root[:Kids][2][:Names].value)
      assert_equal(['e', 'f'], @root[:Kids][2][:Limits].value)
      assert_equal(['g', 1, 'h', 1, 'i', 1], @root[:Kids][3][:Names].value)
      assert_equal(['g', 'i'], @root[:Kids][3][:Limits].value)
      assert_equal(['j', 1, 'k', 1], @root[:Kids][4][:Names].value)
      assert_equal(['j', 'k'], @root[:Kids][4][:Limits].value)
      assert_equal(['l', 1, 'm', 1], @root[:Kids][5][:Names].value)
      assert_equal(['l', 'm'], @root[:Kids][5][:Limits].value)
    end

    it "fails if not called on the root node" do
      @root[:Limits] = ['a', 'c']
      assert_raises(HexaPDF::Error) { @root.add_entry('b', 1) }
    end

    it "fails if the key is not a string" do
      assert_raises(ArgumentError) { @root.add_entry(5, 1) }
    end
  end

  describe "find" do
    it "finds the correct entry" do
      add_multilevel_entries
      assert_equal(1, @root.find_entry('i'))
      assert_equal(1, @root.find_entry('q'))
    end

    it "automatically dereferences the entry's value" do
      add_multilevel_entries
      obj = @doc.add(1)
      @kid11[:Names][1] = HexaPDF::Reference.new(obj.oid, obj.gen)
      assert_equal(1, @root.find_entry('c'))
    end

    it "returns nil for non-existing entries" do
      add_multilevel_entries
      assert_nil(@root.find_entry('non'))
    end

    it "works when no entry exists and neither /Names nor /Kids are set" do
      assert_nil(@root.find_entry('non'))
    end

    it "works when no entry exists and /Names is set" do
      @root[:Names] = []
      assert_nil(@root.find_entry('non'))
    end

    it "works when no entry exists and /Kids is set" do
      @root[:Kids] = []
      assert_nil(@root.find_entry('non'))
    end
  end

  describe "delete" do
    it "works with only the root node" do
      %w[a b c d e f g].each {|name| @root.add_entry(name, 1) }
      %w[g b a unknown e d c].each {|name| @root.delete_entry(name) }
      refute(@root.key?(:Kids))
      refute(@root.key?(:Limits))
      assert_equal(['f', 1], @root[:Names].value)
      assert_equal(1, @root.delete_entry('f'))
    end

    it "works with multiple levels of intermediate nodes" do
      add_multilevel_entries
      %w[c f i m unknown o q s u].each {|name| @root.delete_entry(name) }
      refute(@root.value.key?(:Names))
      refute(@root.value.key?(:Limits))
      assert(@root[:Kids].empty?)
    end

    it "works on an uninitalized tree" do
      assert_nil(@root.delete_entry('non'))
    end

    it "fails if not called on the root node" do
      @root[:Limits] = ['a', 'c']
      assert_raises(HexaPDF::Error) { @root.delete_entry('b') }
    end
  end

  describe "each" do
    it "enumerates in the key-value pairs in sorted order" do
      add_multilevel_entries
      assert_equal(['c', 1, 'f', 1, 'i', 1, 'm', 1, 'o', 1, 'q', 1, 's', 1, 'u', 1],
                   @root.each_entry.to_a.flatten)
    end

    it "automatically dereferences the yielded values" do
      add_multilevel_entries
      obj = @doc.add(1)
      @kid11[:Names][1] = HexaPDF::Reference.new(obj.oid, obj.gen)
      assert_equal(['c', 1, 'f', 1], @kid11.each_entry.to_a.flatten)
    end

    it "works on an uninitalized tree" do
      assert_equal([], @root.each_entry.to_a)
    end
  end

  describe "perform_validation" do
    before do
      add_multilevel_entries
    end

    it "checks that all kid objects are indirect objects" do
      assert(@root.validate)

      @root[:Kids][0] = @kid1
      @kid1.oid = 0
      assert(@root.validate do |message, c|
               assert_match(/children.*must be indirect/i, message)
               assert(c)
             end)
      assert(@kid1.indirect?)
    end

    it "checks that leaf node containers have an even number of entries" do
      @kid11[:Names].delete_at(0)
      refute(@kid11.validate do |message, c|
               assert_match(/leaf.*odd number/, message)
               refute(c)
             end)
    end

    it "corrects a root node container with an odd number of entries" do
      @root.value.clear
      @root[:Names] = ['Test']
      assert(@root.validate do |message, c|
        assert_match(/root.*odd number/, message)
        assert(c)
      end)
      assert(@root[:Names].empty?)
    end

    it "checks that the keys are of the correct type" do
      @kid11[:Names][2] = 5
      refute(@kid11.validate do |message, c|
               assert_match(/must be a String object/, message)
               refute(c)
             end)
    end

    it "checks that the keys are correctly sorted" do
      @kid11[:Names][2] = 'a'
      refute(@kid11.validate do |message, c|
               assert_match(/not correctly sorted/, message)
               refute(c)
             end)
    end
  end

  it "works equally well with a NumberTreeNode" do
    root = HexaPDF::NumberTreeNode.new({}, document: @doc)
    root.add_entry(2, 1)
    root.add_entry(1, 2)
    assert_equal([1, 2, 2, 1], root[:Nums].value)
  end
end
