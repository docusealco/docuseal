# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/xref_section'

describe HexaPDF::XRefSection::Entry do
  it "can describe itself" do
    free = HexaPDF::XRefSection::Entry.new(:free, 1, 2)
    normal = HexaPDF::XRefSection::Entry.new(:in_use, 1, 2, 10)
    compressed = HexaPDF::XRefSection::Entry.new(:compressed, 1, 0, 2, 10)
    assert_match(/1,2 type=free/, free.to_s)
    assert_match(/1,2 type=normal/, normal.to_s)
    assert_match(/1,0 type=compressed/, compressed.to_s)
  end
end

describe HexaPDF::XRefSection do
  before do
    @xref_section = HexaPDF::XRefSection.new
  end

  describe "merge" do
    it "adds all entries from the other xref section, potentially overwriting entries" do
      @xref_section.add_in_use_entry(1, 0, 1)
      xref = HexaPDF::XRefSection.new
      xref.add_in_use_entry(1, 0, 2)
      xref.add_in_use_entry(2, 0, 2)
      assert_equal(1, @xref_section[1, 0].pos)
      assert_nil(@xref_section[2, 0])

      @xref_section.merge!(xref)
      assert_equal(2, @xref_section[1, 0].pos)
      assert_equal(2, @xref_section[2, 0].pos)
    end
  end

  describe "each_subsection" do
    def assert_subsections(result)
      assert_equal(result, @xref_section.each_subsection.map {|s| s.map(&:oid) })
    end

    it "works for newly initialized objects" do
      assert_subsections([[]])
    end

    it "works for a single subsection" do
      @xref_section.add_in_use_entry(1, 0, 0)
      @xref_section.add_in_use_entry(2, 0, 0)
      assert_subsections([[1, 2]])
    end

    it "works for multiple subsections" do
      @xref_section.add_in_use_entry(10, 0, 0)
      @xref_section.add_in_use_entry(11, 0, 0)
      @xref_section.add_in_use_entry(1, 0, 0)
      @xref_section.add_in_use_entry(2, 0, 0)
      @xref_section.add_in_use_entry(20, 0, 0)
      assert_subsections([[1, 2], [10, 11], [20]])
    end

    it "yields a single subsection if the section was marked as the initial one" do
      @xref_section.mark_as_initial_section!
      @xref_section.add_in_use_entry(6, 0, 0)
      @xref_section.add_in_use_entry(7, 0, 0)
      @xref_section.add_in_use_entry(9, 0, 0)
      @xref_section.add_in_use_entry(1, 0, 0)
      @xref_section.add_in_use_entry(2, 0, 0)
      result = @xref_section.each_subsection.map {|s| s.map {|e| [e.oid, e.type] }}
      assert_equal([[[0, :free], [1, :in_use], [2, :in_use],
                     [3, :free], [4, :free], [5, :free],
                     [6, :in_use], [7, :in_use],
                     [8, :free],
                     [9, :in_use]]], result)
    end
  end
end
