# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/document'

describe HexaPDF::Document::Pages do
  before do
    @doc = HexaPDF::Document.new
  end

  describe "root" do
    it "returns the root of the page tree" do
      assert_same(@doc.catalog.pages, @doc.pages.root)
    end
  end

  describe "create" do
    it "uses the defaults from the configuration for missing arguments" do
      page = @doc.pages.create
      assert_equal([0, 0, 595.275591, 841.889764], page.box(:media).value)
    end

    it "allows specifying a reference to a predefined page size" do
      page = @doc.pages.create(media_box: :A3)
      assert_equal([0, 0, 841.889764, 1190.551181], page.box(:media).value)
    end

    it "allows specifying the orientation for a predefined page size" do
      page = @doc.pages.create(media_box: :A4, orientation: :landscape)
      assert_equal([0, 0, 841.889764, 595.275591], page.box(:media).value)

      page = @doc.pages.create(orientation: :landscape)
      assert_equal([0, 0, 841.889764, 595.275591], page.box(:media).value)
    end

    it "allows using a media box array" do
      page = @doc.pages.create(media_box: [0, 0, 12, 24], orientation: :landscape)
      assert_equal([0, 0, 12, 24], page.box(:media).value)
    end
  end

  describe "add" do
    it "adds a new empty page when no page is given" do
      page = @doc.pages.add
      assert_equal([page], @doc.pages.root[:Kids].value)
    end

    it "adds a new empty page with the given dimensions" do
      page = @doc.pages.add([0, 0, 20, 20])
      assert_same(page, @doc.pages[0])
      assert_equal([0, 0, 20, 20], @doc.pages[0].box(:media).value)
    end

    it "adds a new empty page with the given page format" do
      page = @doc.pages.add(:A4, orientation: :landscape)
      assert_same(page, @doc.pages[0])
      assert_equal([0, 0, 841.889764, 595.275591], @doc.pages[0].box(:media).value)
    end

    it "adds the given page to the end" do
      page = @doc.pages.add
      new_page = @doc.add({Type: :Page})
      assert_same(new_page, @doc.pages.add(new_page))
      assert_equal([page, new_page], @doc.pages.root[:Kids].value)
    end

    it "fails if an unknown page format is given" do
      assert_raises(HexaPDF::Error) { @doc.pages.add(:A953) }
    end
  end

  describe "<<" do
    it "works like add but always needs a page returns self" do
      page1 = @doc.add({Type: :Page})
      page2 = @doc.add({Type: :Page})
      @doc.pages << page1 << page2
      assert_equal([page1, page2], @doc.pages.root[:Kids].value)
    end
  end

  describe "insert" do
    before do
      @doc.pages.add
      @doc.pages.add
      @doc.pages.add
    end

    it "insert a new page at a given index" do
      page = @doc.pages.insert(2)
      assert_equal(page, @doc.pages.root[:Kids][2])
    end

    it "insert a given page at a given index" do
      new_page = @doc.add({Type: :Page})
      assert_same(new_page, @doc.pages.insert(2, new_page))
      assert_equal(new_page, @doc.pages.root[:Kids][2])
    end
  end

  describe "move" do
    it "moves the page to the given index" do
      first = @doc.pages.add
      second = @doc.pages.add
      @doc.pages.move(first, -1)
      assert_equal([second, first], @doc.pages.each.to_a)
    end
  end

  describe "delete" do
    it "deletes a given page" do
      page1 = @doc.pages.add
      page2 = @doc.pages.add

      @doc.pages.delete(page1)
      assert_equal([page2], @doc.pages.root[:Kids].value)
    end
  end

  describe "delete_at" do
    it "deletes a page at a given index" do
      page1 = @doc.pages.add
      @doc.pages.add
      page3 = @doc.pages.add
      @doc.pages.delete_at(1)
      assert_equal([page1, page3], @doc.pages.root[:Kids].value)
    end
  end

  describe "[]" do
    it "returns the page at the given index" do
      page1 = @doc.pages.add
      page2 = @doc.pages.add
      page3 = @doc.pages.add

      assert_equal(page1, @doc.pages[0])
      assert_equal(page2, @doc.pages[1])
      assert_equal(page3, @doc.pages[2])
      assert_nil(@doc.pages[3])
      assert_equal(page3, @doc.pages[-1])
      assert_equal(page2, @doc.pages[-2])
      assert_equal(page1, @doc.pages[-3])
      assert_nil(@doc.pages[-4])
    end
  end

  describe "each" do
    it "iterates over all pages" do
      page1 = @doc.pages.add
      page2 = @doc.pages.add
      page3 = @doc.pages.add
      assert_equal([page1, page2, page3], @doc.pages.to_a)
    end
  end

  describe "count" do
    it "returns the number of pages in the page tree" do
      assert_equal(0, @doc.pages.count)
      @doc.pages.add
      @doc.pages.add
      @doc.pages.add
      assert_equal(3, @doc.pages.count)
    end
  end

  describe "page_label" do
    it "returns the page label object for the given range start index" do
      11.times { @doc.pages.add }
      @doc.catalog[:PageLabels] = {Nums: [0, {S: :D}, 5, {S: :r, St: 2}, 10, {P: 'A-', S: :a}]}
      assert_equal("1", @doc.pages.page_label(0))
      assert_equal("5", @doc.pages.page_label(4))
      assert_equal("ii", @doc.pages.page_label(5))
      assert_equal("vi", @doc.pages.page_label(9))
      assert_equal("A-a", @doc.pages.page_label(10))
    end

    it "fails if the page index is out of range" do
      assert_raises(ArgumentError) { @doc.pages.page_label(-1) }
      assert_raises(ArgumentError) { @doc.pages.page_label(0) }
    end
  end

  describe "each_labelling_range" do
    before do
      10.times { @doc.pages.add }
    end

    it "returns no entries for an empty or non-existing /PageLabels entry" do
      assert(@doc.pages.each_labelling_range.to_a.empty?)
    end

    it "works for a single page label entry" do
      @doc.catalog[:PageLabels] = {Nums: [0, {S: :r}]}
      result = @doc.pages.each_labelling_range.to_a
      assert_equal([[0, 10, {S: :r}]], result.map {|s, c, l| [s, c, l.value] })
      assert_equal(:lowercase_roman, result[0].last.numbering_style)
    end

    it "works for multiple page label entries" do
      @doc.catalog[:PageLabels] = {Nums: [0, {S: :r}, 2, {S: :D}, 7, {S: :A}]}
      result = @doc.pages.each_labelling_range.to_a
      assert_equal([[0, 2, {S: :r}], [2, 5, {S: :D}], [7, 3, {S: :A}]],
                   result.map {|s, c, l| [s, c, l.value] })
    end

    it "returns a zero or negative count for the last range if there aren't enough pages" do
      assert_equal(10, @doc.pages.count)
      @doc.catalog[:PageLabels] = {Nums: [0, {S: :D}, 10, {S: :r}]}
      assert_equal(0, @doc.pages.each_labelling_range.to_a[-1][1])
      @doc.catalog[:PageLabels][:Nums][2] = 11
      assert_equal(-1, @doc.pages.each_labelling_range.to_a[-1][1])
    end
  end

  describe "add_labelling_range" do
    it "creates a new page label object for the given arguments" do
      label = @doc.pages.add_labelling_range(5, numbering_style: :lowercase_roman,
                                             start_number: 5, prefix: 'a')
      assert_equal({S: :r, St: 5, P: 'a'}, label.value)
      assert_equal(label, @doc.catalog.page_labels.find_entry(5))
    end

    it "adds an entry for the range starting at 0 if it doesn't exist" do
      label = @doc.pages.add_labelling_range(5)
      assert_equal([{S: :D}, label],
                   @doc.catalog.page_labels[:Nums].value.values_at(1, 3))
    end
  end

  describe "delete_labelling_range" do
    before do
      @doc.catalog[:PageLabels] = {Nums: [0, {S: :r}, 5, {S: :D}]}
    end

    it "deletes the labelling range for a given start index" do
      label = @doc.pages.delete_labelling_range(5)
      assert_equal({S: :D}, label)
    end

    it "deletes the labelling range for 0 if it is the last, together with the number tree" do
      @doc.pages.delete_labelling_range(5)
      label = @doc.pages.delete_labelling_range(0)
      assert_equal({S: :r}, label)
      assert_nil(@doc.catalog[:PageLabels])
    end

    it "fails if the range starting at zero is deleted when other ranges still exist" do
      assert_raises(HexaPDF::Error) { @doc.pages.delete_labelling_range(0) }
    end
  end
end
