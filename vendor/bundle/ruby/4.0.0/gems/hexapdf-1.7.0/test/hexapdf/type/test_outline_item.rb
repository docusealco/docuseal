# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/document'
require 'hexapdf/type/outline_item'

describe HexaPDF::Type::OutlineItem do
  before do
    @doc = HexaPDF::Document.new
    @item = @doc.add({Title: "root", Count: 0}, type: :XXOutlineItem)
  end

  it "must be an indirect object" do
    assert(@item.must_be_indirect?)
  end

  describe "title" do
    it "returns the set title" do
      @item[:Title] = 'Test'
      assert_equal('Test', @item.title)
    end

    it "sets the title to the given value" do
      @item.title('Test')
      assert_equal('Test', @item[:Title])
    end
  end

  describe "text_color" do
    it "returns the default color if none is set" do
      assert_equal([0, 0, 0], @item.text_color.components)
    end

    it "returns the set color" do
      @item[:C] = [0, 0.5, 1]
      assert_equal([0, 0.5, 1], @item.text_color.components)
    end

    it "sets the text color to the given value" do
      @item.text_color([51, 51, 255])
      assert_equal([0.2, 0.2, 1], @item[:C])
    end

    it "fails if a color in another color space is set" do
      assert_raises(ArgumentError) { @item.text_color(5) }
    end
  end

  describe "destination" do
    it "returns the set destination" do
      @item[:Dest] = [5, :Fit]
      assert_equal([5, :Fit], @item.destination)
    end

    it "sets the destination to the given value" do
      @item.destination(@doc.pages.add)
      assert_equal([@doc.pages[0], :Fit], @item[:Dest])
    end

    it "deletes an existing action entry when setting a value" do
      @item[:A] = {S: :GoTo}
      @item.destination(@doc.pages.add)
      refute(@item.key?(:A))
    end
  end

  describe "action" do
    it "returns the set action" do
      @item[:A] = {S: :GoTo}
      assert_equal({S: :GoTo}, @item.action.value)
    end

    it "sets the action to the given value" do
      @item.action({S: :GoTo})
      assert_equal({S: :GoTo}, @item[:A].value)
    end

    it "deletes an existing destination entry when setting a value" do
      @item[:Dest] = [1, :Fit]
      @item.action({S: :GoTo})
      refute(@item.key?(:Dest))
    end
  end

  describe "level" do
    it "returns 0 for the outline dictionary when treated as an item" do
      assert_equal(0, @item.level)
    end

    it "returns 1 for the root level items" do
      @item[:Parent] = {Type: :Outlines}
      assert_equal(1, @item.level)
    end

    it "returns the correct level for items in the hierarchy" do
      @item[:Parent] = {Title: 'Root elem', Parent: {Type: :Outlines}}
      assert_equal(2, @item.level)
    end
  end

  describe "open?" do
    it "returns true if the outline item is open" do
      refute(@item.open?)
      @item.add_item("test")
      assert_equal(true, @item.open?)
    end

    it "returns false if the outline item is closed" do
      @item.delete(:Count)
      @item.add_item("test")
      assert_equal(false, @item.open?)
    end

    it "returns nil if the outline item doesn't have any child items" do
      assert_nil(@item.open?)
    end
  end

  describe "destination_page" do
    it "returns the page of a set destination" do
      @item[:Dest] = [5, :Fit]
      assert_equal(5, @item.destination_page)
    end

    it "returns the page of a set GoTO action" do
      @item[:A] = {S: :GoTo, D: [5, :Fit]}
      assert_equal(5, @item.destination_page)
    end

    it "returns nil if no destination or action is set" do
      assert_nil(@item.destination_page)
    end

    it "returns nil if an action besides GoTo is set" do
      @item[:A] = {S: :GoToR}
      assert_nil(@item.destination_page)
    end
  end

  describe "add" do
    it "returns the created item" do
      new_item = @item.add_item("Test")
      assert_equal("Test", new_item.title)
      assert_equal(0, new_item[:Count])
      assert_same(@item, new_item[:Parent])
      assert(new_item.indirect?)
    end

    it "sets the item's text color" do
      new_item = @item.add_item("Test", text_color: "red")
      assert_equal([1, 0, 0], new_item.text_color.components)
    end

    it "sets the item's flags" do
      new_item = @item.add_item("Test", flags: [:bold, :italic])
      assert_equal([:italic, :bold], new_item.flags)
    end

    it "doesn't set the item's /Count when it should not be open" do
      new_item = @item.add_item("Test", open: false)
      refute(new_item.key?(:Count))
    end

    it "sets the item's destination if given" do
      new_item = @item.add_item("Test", destination: @doc.pages.add)
      assert_equal([@doc.pages[0], :Fit], new_item.destination)
    end

    it "sets the item's action if given" do
      new_item = @item.add_item("Test", action: {S: :GoTo, D: [1, :Fit]})
      assert_equal({S: :GoTo, D: [1, :Fit]}, new_item.action.value)
    end

    it "yields the item" do
      yielded_item = nil
      new_item = @item.add_item("Test") {|i| yielded_item = i }
      assert_same(new_item, yielded_item)
    end

    it "uses the provided outline item instead of creating a new one" do
      item = @doc.wrap({Dest: [1, :Fit], flags: 1, First: 5, Count: 2}, type: :XXOutlineItem)
      new_item = @item.add_item(item, destination: [2, :Fit])
      assert_same(item, new_item)
      assert_equal([1, :Fit], new_item.destination)
      assert_same(@item, new_item[:Parent])
      refute(new_item.key?(:First))
      assert_equal(0, new_item[:Count])

      item = @doc.wrap({Count: nil}, type: :XXOutlineItem)
      new_item = @item.add_item(item)
      refute(new_item.key?(:Count))

      item = @doc.wrap({Count: -1}, type: :XXOutlineItem)
      new_item = @item.add_item(item)
      refute(new_item.key?(:Count))
    end

    describe "position" do
      it "works for an empty item" do
        new_item = @item.add_item("Test")
        assert_same(new_item, @item[:First])
        assert_same(new_item, @item[:Last])
        assert_nil(new_item[:Next])
        assert_nil(new_item[:Prev])
      end

      it "inserts an item at the last position with at least one existing sub-item" do
        first_item = @item.add_item("Test")
        second_item = @item.add_item("Test", position: :last)
        assert_same(first_item, @item[:First])
        assert_same(second_item, @item[:Last])
        assert_same(second_item, first_item[:Next])
        assert_same(first_item, second_item[:Prev])
      end

      it "inserts an item at the first position with at least one existing sub-item" do
        second_item = @item.add_item("Test")
        first_item = @item.add_item("Test", position: :first)
        assert_same(first_item, @item[:First])
        assert_same(second_item, @item[:Last])
        assert_same(second_item, first_item[:Next])
        assert_same(first_item, second_item[:Prev])
      end

      it "inserts an item at an arbitrary positive index" do
        5.times {|i| @item.add_item("Test#{i}") }
        @item.add_item("Test", position: 3)
        item = @item[:First]
        %w[Test0 Test1 Test2 Test Test3 Test4].each do |title|
          assert_equal(title, item.title)
          item = item[:Next]
        end
      end

      it "inserts an item at an arbitrary negative index" do
        5.times {|i| @item.add_item("Test#{i}") }
        @item.add_item("Test", position: -3)
        item = @item[:First]
        %w[Test0 Test1 Test2 Test Test3 Test4].each do |title|
          assert_equal(title, item.title)
          item = item[:Next]
        end
      end

      it "raises an out of bounds error for invalid integer values" do
        5.times {|i| @item.add_item("Test#{i}") }
        assert_raises(ArgumentError) { @item.add_item("Test", position: 10) }
        assert_raises(ArgumentError) { @item.add_item("Test", position: -10) }
      end

      it "raises an error for an invalid value" do
        assert_raises(ArgumentError) { @item.add_item("Test", position: :luck) }
      end
    end

    it "calculcates the /Count values correctly" do
      [
        [[true, true], [6, 4, 0, 1, 0, 0, 0]],
        [[true, false], [5, 3, 0, -1, 0, 0, 0]],
        [[false, true], [2, -4, 0, 1, 0, 0, 0]],
        [[false, false], [2, -3, 0, -1, 0, 0, 0]],
      ].each do |(states, result)|
        # reset list
        @item[:First] = @item[:Last] = nil
        @item[:Count] = 0

        items = [@item]
        @item.add_item("Document", open: states[0]) do |idoc|
          items << idoc
          items << idoc.add_item("Section 1", open: false)
          idoc.add_item("Section 2", open: states[1]) do |isec|
            items << isec
            items << isec.add_item("Subsection 1")
          end
          items << idoc.add_item("Section 3")
        end
        items << @item.add_item("Summary")
        items.each_with_index {|item, index| assert_equal(result.shift, item[:Count] || 0, "item#{index}") }
      end
    end
  end

  it "recursively iterates over all descendant items" do
    @item.add_item("Item1") do |item1|
      item1.add_item("Item2")
      item1.add_item("Item3") do |item3|
        item3.add_item("Item4")
      end
      item1.add_item("Item5")
    end
    assert_equal(['Item1', 1, 'Item2', 2, 'Item3', 2, 'Item4', 3, 'Item5', 2],
                 @item.each_item.map {|i, l| [i.title, l] }.flatten)
  end

  describe "perform_validation" do
    before do
      @outline_items = 5.times.map { @item.add_item("Test1") }
      @item[:Parent] = @doc.add({})
    end

    it "fixes a missing /First entry" do
      @item.delete(:First)
      @outline_items[0][:Prev] = HexaPDF::Reference.new(100)
      called = false
      @item.validate do |msg, correctable, _|
        called = true
        assert_match(/missing an endpoint reference/, msg)
        assert(correctable)
      end
      assert(called)
    end

    it "fixes a missing /Last entry" do
      @item.delete(:Last)
      @outline_items[4][:Next] = HexaPDF::Reference.new(100)
      called = false
      @item.validate do |msg, correctable, _|
        called = true
        assert_match(/missing an endpoint reference/, msg)
        assert(correctable)
      end
      assert(called)
    end

    it "deletes the /Count entry if no /First and /Last entries exist" do
      @item.delete(:Last)
      @item.delete(:First)
      assert_equal(5, @item[:Count])
      @item.validate do |msg, correctable, _|
        assert_match(/\/Count set but no descendants/, msg)
        assert(correctable)
      end
      refute(@item.key?(:Count))
      assert(@item.validate(auto_correct: false))
    end

    it "fails validation if the previous item's /Next points somewhere else" do
      item = @item[:First][:Next]
      item[:Prev][:Next] = item[:Next]
      item.validate do |msg, correctable, _|
        assert_match(/\/Prev points to item whose \/Next points somewhere else/, msg)
        refute(correctable)
      end
    end

    it "corrects the previous item's missing /Next entry" do
      item = @item[:First][:Next]
      item[:Prev].delete(:Next)
      item.validate do |msg, correctable, _|
        assert_match(/\/Prev points to item without \/Next/, msg)
        assert(correctable)
      end
    end

    it "fails validation if the next item's /Prev points somewhere else" do
      item = @item[:First][:Next]
      item[:Next][:Prev] = item[:Prev]
      item.validate do |msg, correctable, _|
        assert_match(/\/Next points to item whose \/Prev points somewhere else/, msg)
        refute(correctable)
      end
    end

    it "corrects the next item's missing /Prev entry" do
      item = @item[:First][:Next]
      item[:Next].delete(:Prev)
      item.validate do |msg, correctable, _|
        assert_match(/\/Next points to item without \/Prev/, msg)
        assert(correctable)
      end
    end
  end
end
