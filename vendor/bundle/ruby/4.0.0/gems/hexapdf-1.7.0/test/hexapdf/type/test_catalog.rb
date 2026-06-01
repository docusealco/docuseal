# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/document'
require 'hexapdf/type/catalog'

describe HexaPDF::Type::Catalog do
  before do
    @doc = HexaPDF::Document.new
    @catalog = @doc.add({Type: :Catalog})
  end

  it "must always be indirect" do
    @catalog.must_be_indirect = false
    assert(@catalog.must_be_indirect?)
  end

  it "creates the page tree on access" do
    assert_nil(@catalog[:Pages])
    pages = @catalog.pages
    assert_equal(:Pages, pages.type)
  end

  it "creates the name dictionary on access" do
    assert_nil(@catalog[:Names])
    names = @catalog.names
    assert_equal(:XXNames, names.type)
    other = @catalog.names
    assert_same(other, names)
  end

  it "uses or creates the document outline on access" do
    @catalog[:Outlines] = {}
    assert_equal(:Outlines, @catalog.outline.type)

    @catalog.delete(:Outlines)
    outline = @catalog.outline
    assert_equal(:Outlines, outline.type)
    assert_same(outline, @catalog.outline)
  end

  it "uses or creates the optional content properties dictionary on access" do
    @catalog[:OCProperties] = hash = {}
    assert_equal(:XXOCProperties, @catalog.optional_content.type)
    assert_same(hash, @catalog.optional_content.value)

    @catalog.delete(:OCProperties)
    oc = @catalog.optional_content
    assert_equal([], oc[:OCGs])
    assert_equal(:XXOCConfiguration, oc[:D].type)
  end

  describe "acro_form" do
    it "returns an existing form object" do
      @catalog[:AcroForm] = :test
      assert_equal(:test, @catalog.acro_form)
    end

    it "returns an existing form object even if create: true" do
      @catalog[:AcroForm] = :test
      assert_equal(:test, @catalog.acro_form(create: true))
    end

    it "creates a new AcroForm object with defaults if create: true" do
      form = @catalog.acro_form(create: true)
      assert_kind_of(HexaPDF::Type::AcroForm::Form, form)
      assert(form[:DA])
    end
  end

  describe "page_labels" do
    it "returns an existing page labels number tree" do
      @catalog[:PageLabels] = {Nums: []}
      assert_equal({Nums: []}, @catalog.page_labels.value)
    end

    it "returns an existing page labels number tree even if create: true" do
      obj = @catalog[:PageLabels] = {Nums: []}
      assert_same(obj, @catalog.page_labels(create: true).value)
    end

    it "creates a new page labels number tree if create: true" do
      tree = @catalog.page_labels(create: true)
      assert_kind_of(HexaPDF::NumberTreeNode, tree)
    end
  end

  describe "validation" do
    it "creates the page tree if necessary" do
      refute(@catalog.validate(auto_correct: false))
      assert(@catalog.validate)
    end
  end
end
