# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/document'
require 'hexapdf/type/page_label'

describe HexaPDF::Type::PageLabel do
  before do
    @doc = HexaPDF::Document.new
    @page_label = @doc.wrap({Type: :PageLabel})
  end

  describe "construct_label" do
    it "returns an empty label if nothing is set" do
      assert_equal('', @page_label.construct_label(0))
    end

    it "returns the prefix if no numbering style is set" do
      @page_label.prefix('hello')
      assert_equal('hello', @page_label.construct_label(0))
    end

    it "works for decimal numbers" do
      @page_label.numbering_style(:decimal)
      assert_equal("10", @page_label.construct_label(9))
    end

    it "works for uppercase letters" do
      @page_label.numbering_style(:uppercase_letters)
      assert_equal("J", @page_label.construct_label(9))
      assert_equal("AJ", @page_label.construct_label(35))
    end

    it "works for lowercase letters" do
      @page_label.numbering_style(:lowercase_letters)
      assert_equal("a", @page_label.construct_label(0))
      assert_equal("aa", @page_label.construct_label(26))
    end

    it "works for uppercase roman numerals" do
      @page_label.numbering_style(:uppercase_roman)
      assert_equal("X", @page_label.construct_label(9))
    end

    it "works for lowercase roman numerals" do
      @page_label.numbering_style(:lowercase_roman)
      assert_equal("i", @page_label.construct_label(0))
      assert_equal("iv", @page_label.construct_label(3))
    end

    it "combines the prefix with the numeric portion" do
      @page_label.prefix('hello-')
      @page_label.numbering_style(:decimal)
      assert_equal('hello-1', @page_label.construct_label(0))
      assert_equal('hello-101', @page_label.construct_label(100))
    end
  end

  describe "numbering_style" do
    it "returns the set numbering style" do
      assert_equal(:none, @page_label.numbering_style)
      @page_label[:S] = :D
      assert_equal(:decimal, @page_label.numbering_style)
    end

    it "sets the numbering style to the given value" do
      @page_label.numbering_style(:decimal)
      assert_equal(:D, @page_label[:S])
      @page_label.numbering_style(:none)
      assert_nil(@page_label[:S])
    end

    it "returns :none for an unknown numbering style" do
      @page_label[:S] = :d
      assert_equal(:none, @page_label.numbering_style)
    end

    it "fails if the given value is not mapped to a numbering_style" do
      assert_raises(ArgumentError) { @page_label.numbering_style("Nomad") }
      assert_raises(ArgumentError) { @page_label.numbering_style(:unknown) }
    end
  end

  describe "prefix" do
    it "returns the set prefix" do
      assert_nil(@page_label.prefix)
      @page_label[:P] = 'Prefix'
      assert_equal('Prefix', @page_label.prefix)
    end

    it "sets the prefix to the given value" do
      @page_label.prefix('Hallo')
      assert_equal('Hallo', @page_label[:P])
    end
  end

  describe "start_number" do
    it "returns the set start number" do
      assert_equal(1, @page_label.start_number)
      @page_label[:St] = 5
      assert_equal(5, @page_label.start_number)
    end

    it "set the start number to the given value" do
      @page_label.start_number(5)
      assert_equal(5, @page_label[:St])
    end

    it "fails if the provided value is not an integer" do
      assert_raises(ArgumentError) { @page_label.start_number("6") }
    end

    it "fails if the value is lower than 1" do
      assert_raises(ArgumentError) { @page_label.start_number("-1") }
      assert_raises(ArgumentError) { @page_label.start_number("0") }
    end
  end
end
