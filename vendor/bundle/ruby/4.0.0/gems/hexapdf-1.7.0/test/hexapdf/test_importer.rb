# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/importer'
require 'hexapdf/document'

describe HexaPDF::Importer::NullableWeakRef do
  it "returns nil instead of an error when the referred-to object is GCed" do
    refs = []
    obj = nil
    100.times do
      refs << HexaPDF::Importer::NullableWeakRef.new(Object.new)
      ObjectSpace.garbage_collect
      ObjectSpace.garbage_collect
      break if (obj = refs.find {|ref| !ref.weakref_alive? })
    end
    assert_equal("", obj.to_s)
  end
end

describe HexaPDF::Importer do
  class TestClass < HexaPDF::Dictionary; end
  before do
    @source = HexaPDF::Document.new
    obj = @source.add("test")
    @hash = @source.wrap({key: "value"})
    @obj = @source.add({hash: @hash, array: ["one", "two"],
                        ref: HexaPDF::Reference.new(obj.oid, obj.gen),
                        others: [:symbol, 5, 5.5, nil, true, false]})
    @obj[:MySelf] = @obj
    @source.pages.add
    @source.pages.root[:Rotate] = 90
    @dest = HexaPDF::Document.new
    @importer = HexaPDF::Importer.for(@dest)
  end

  describe "::for" do
    it "caches the importer" do
      assert_same(@importer, HexaPDF::Importer.for(@dest))
    end
  end

  describe "::copy" do
    it "copies a complete object including references" do
      obj1 = HexaPDF::Importer.copy(@dest, @obj)
      obj2 = HexaPDF::Importer.copy(@dest, @obj)
      refute_same(obj1, obj2)
      refute_same(obj1[:ref], obj2[:ref])
    end

    it "duplicates the whole document" do
      trailer = HexaPDF::Importer.copy(@dest, @source.trailer, allow_all: true)
      refute_same(@source.catalog, trailer[:Root])
      refute_same(@source.pages.root, trailer[:Root][:Pages])
      assert_equal(90, trailer[:Root][:Pages][:Kids][0][:Rotate])
    end
  end

  describe "import" do
    it "updates the associated document" do
      obj = @importer.import(@obj)
      assert_same(obj.document, @dest)
      obj = @importer.import(@hash)
      assert_same(obj.document, @dest)
    end

    it "imports an object only once" do
      obj = @importer.import(@obj)
      assert_same(obj, @importer.import(@obj))
      assert_equal(2, @dest.each.to_a.size)
    end

    it "re-imports an object that was imported but then deleted" do
      obj = @importer.import(@obj)
      @dest.delete(obj)
      refute_same(obj, @importer.import(@obj))
    end

    it "can import a direct object" do
      assert_nil(@importer.import(nil))
      assert_equal(5, @importer.import(5))
      assert(@dest.object?(@importer.import({key: @obj})[:key]))
    end

    it "determines the source document dynamically" do
      obj = @importer.import(@obj.value)
      assert_equal("test", obj[:ref].value)
    end

    it "copies the data of the imported objects" do
      data = {key: @obj, str: "str"}
      obj = @importer.import(data)
      obj[:str].upcase!
      obj[:key][:hash][:key].upcase!
      obj[:key][:hash][:data] = :value
      obj[:key][:array].unshift
      obj[:key][:array][0].upcase!

      assert_equal("str", data[:str])
      assert_equal("value", @obj[:hash][:key])
      assert_equal(["one", "two"], @obj[:array])
    end

    it "uses already mapped HexaPDF::Object instances instead of mapping them again" do
      hash = @importer.import(@hash)
      assert_kind_of(HexaPDF::Dictionary, hash)
      obj = @importer.import(@obj)
      assert_kind_of(HexaPDF::Dictionary, obj[:hash])
      assert_same(hash, obj[:hash])
    end

    it "uses the class of the argument when directly importing a HexaPDF::Object" do
      src_obj = @source.wrap(@hash, type: TestClass)
      dest_obj = @importer.import(src_obj)
      assert_instance_of(TestClass, dest_obj)
    end

    it "uses the class of the argument when importing an already mapped HexaPDF::Object" do
      @importer.import(@obj) # also maps @hash
      src_obj = @source.wrap(@hash, type: TestClass)
      dest_obj = @importer.import(src_obj)
      assert_instance_of(TestClass, dest_obj)
    end

    it "duplicates the stream if it is a string" do
      src_obj = @source.add({}, stream: 'data')
      dst_obj = @importer.import(src_obj)
      refute_same(dst_obj.data.stream, src_obj.data.stream)
    end

    it "duplicates the stream if it is a FiberDoubleForString, e.g. when using Canvas" do
      src_page = @source.pages[0]
      src_page.canvas.line_width(10)
      dst_page = @importer.import(src_page)
      refute_same(dst_page, src_page)
      refute_same(dst_page[:Contents].data.stream, src_page[:Contents].data.stream)
      src_page.canvas.line_width(20)
      assert_equal("10 w\n", dst_page.contents)
    end

    it "does not import objects of type Catalog or Pages" do
      @obj[:catalog] = @source.catalog
      @obj[:pages] = @source.catalog.pages
      obj = @importer.import(@obj)

      assert_nil(obj[:catalog])
      assert_nil(obj[:pages])
    end

    it "handles null values correctly" do
      @source.add(@hash)
      @source.delete(@hash)
      obj = @importer.import(@obj)
      assert_nil(obj[:hash])
    end

    it "imports Page objects correctly by copying the inherited values" do
      page = @importer.import(@source.pages[0])
      assert_equal(90, page[:Rotate])
    end

    it "works for importing objects from different documents" do
      other_doc = HexaPDF::Document.new
      other_obj = other_doc.add("test")
      imported = @importer.import(other_obj)
      assert_equal("test", imported.value)
    end
  end
end
