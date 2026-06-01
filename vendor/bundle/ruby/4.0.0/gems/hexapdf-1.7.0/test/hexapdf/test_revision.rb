# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/revision'
require 'hexapdf/dictionary'
require 'hexapdf/reference'
require 'hexapdf/xref_section'
require 'hexapdf/type/catalog'
require 'stringio'

describe HexaPDF::Revision do
  before do
    @xref_section = HexaPDF::XRefSection.new
    @xref_section.add_in_use_entry(2, 0, 5000)
    @xref_section.add_free_entry(3, 0)
    @xref_section.add_in_use_entry(4, 0, 1000)
    @xref_section.add_in_use_entry(5, 0, 1000)
    @xref_section.add_in_use_entry(6, 0, 5000)
    @xref_section.add_in_use_entry(7, 0, 5000)
    @xref_section.add_in_use_entry(8, 2, 5000)
    @obj = HexaPDF::Object.new(:val, oid: 1, gen: 0)
    @ref = HexaPDF::Reference.new(1, 0)

    @loader = lambda do |entry|
      if entry.type == :free
        HexaPDF::Object.new(nil, oid: entry.oid, gen: entry.gen)
      else
        case entry.oid
        when 2 then HexaPDF::Dictionary.new({Type: :Sig}, oid: entry.oid, gen: entry.gen)
        when 4 then HexaPDF::Dictionary.new({Type: :XRef}, oid: entry.oid, gen: entry.gen)
        when 5 then HexaPDF::Dictionary.new({Type: :ObjStm}, oid: entry.oid, gen: entry.gen)
        when 7 then HexaPDF::Type::Catalog.new({Type: :Catalog}, oid: entry.oid, gen: entry.gen,
                                              document: self)
        when 8 then HexaPDF::Object.new(:DifferentGen, oid: entry.oid, gen: 0)
        when 6 then HexaPDF::Dictionary.new({Array: HexaPDF::PDFArray.new([1, 2])},
                                            oid: entry.oid, gen: entry.gen)
        else HexaPDF::Object.new(:Test, oid: entry.oid, gen: entry.gen)
        end
      end
    end
    @rev = HexaPDF::Revision.new({}, xref_section: @xref_section, loader: @loader)
  end

  it "needs the trailer as first argument on initialization" do
    rev = HexaPDF::Revision.new({})
    assert_equal({}, rev.trailer)
  end

  it "takes an xref section and/or a parser on initialization" do
    rev = HexaPDF::Revision.new({}, loader: @loader, xref_section: @xref_section)
    assert_equal({Type: :Sig}, rev.object(2).value)
  end

  it "returns the next free object number" do
    assert_equal(9, @rev.next_free_oid)
    @obj.oid = 9
    @rev.add(@obj)
    assert_equal(10, @rev.next_free_oid)
  end

  describe "add" do
    it "works correctly" do
      @rev.add(@obj)
      assert(@rev.object?(@ref))
    end

    it "also returns the supplied object" do
      assert_equal(@obj, @rev.add(@obj))
    end

    it "fails if the revision already has an object with the same object number" do
      @rev.add(@obj)
      assert_raises(HexaPDF::Error) { @rev.add(@obj) }
      assert_raises(HexaPDF::Error) { @rev.add(HexaPDF::Object.new(:val, oid: 2)) }
    end

    it "fails if the given object has an object number of zero" do
      assert_raises(HexaPDF::Error) { @rev.add(HexaPDF::Object.new(:val)) }
    end
  end

  describe "xref" do
    it "returns the xref structure" do
      assert_equal(@xref_section[2, 0], @rev.xref(HexaPDF::Reference.new(2, 0)))
      assert_equal(@xref_section[2, 0], @rev.xref(2))
    end

    it "returns nil if no xref entry is found" do
      assert_nil(@rev.xref(@ref))
      assert_nil(@rev.xref(1))
    end
  end

  describe "object" do
    it "returns nil if no object is found" do
      assert_nil(@rev.object(@ref))
      assert_nil(@rev.object(1))
    end

    it "returns an object that was added before" do
      @rev.add(@obj)
      assert_equal(@obj, @rev.object(@ref))
      assert_equal(@obj, @rev.object(1))
    end

    it "loads an object that is defined in the cross-reference section" do
      obj = @rev.object(HexaPDF::Reference.new(2, 0))
      assert_equal({Type: :Sig}, obj.value)
      assert_equal(2, obj.oid)
      assert_equal(0, obj.gen)
    end

    it "loads an object that is defined in the cross-reference section using the object number" do
      obj = @rev.object(2)
      refute_nil(obj)
    end

    it "loads an object that is defined in the cross-reference section with an invalid generation number" do
      obj = @rev.object(HexaPDF::Reference.new(8, 0))
      assert_equal(0, obj.gen)
      assert_equal(:DifferentGen, obj.value)
    end

    it "loads free entries in the cross-reference section as special PDF null objects" do
      obj = @rev.object(HexaPDF::Reference.new(3, 0))
      assert_nil(obj.value)
    end
  end

  describe "update" do
    before do
      @rev.add(@obj)
    end

    it "updates the object if it has the same data instance" do
      x = HexaPDF::Object.new(@obj.data)
      y = @rev.update(x)
      assert_same(x, y)
      refute_same(x, @obj)
      assert_same(x, @rev.object(@ref))
    end

    it "doesn't update the object if it refers to a different data instance" do
      x = HexaPDF::Object.new(:value, oid: 5)
      assert_nil(@rev.update(x))
      x.data.oid = 1
      assert_nil(@rev.update(x))
    end
  end

  describe "delete" do
    before do
      @rev.add(@obj)
    end

    it "deletes objects specified by reference" do
      @rev.delete(@ref, mark_as_free: false)
      refute(@rev.object?(@ref))
      assert(@obj.null?)
      assert_raises(HexaPDF::Error) { @obj.document }
    end

    it "deletes objects specified by object number" do
      @rev.delete(@ref.oid, mark_as_free: false)
      refute(@rev.object?(@ref.oid))
      assert(@obj.null?)
      assert_raises(HexaPDF::Error) { @obj.document }
    end

    it "marks the object as PDF null object when using mark_as_free=true" do
      refute(@obj.null?)
      @rev.delete(@ref)
      assert(@rev.object(@ref).null?)
      assert(@obj.null?)
      assert_raises(HexaPDF::Error) { @obj.document }
      assert_same(@obj.data, @rev.object(@ref).data)
    end
  end

  describe "object iteration" do
    it "iterates over all objects via each" do
      @rev.add(@obj)
      assert_equal([@obj, *(2..8).map {|i| @rev.object(i) }], @rev.each.to_a)
    end

    it "ensures no object is loaded multiple times" do
      obj_2_data = nil
      @rev.add(@obj) # ensures this is yielded first
      @rev.each do |obj|
        if obj == @obj
          obj_2_data = @rev.object(2).data
        elsif obj.oid == 2
          assert_same(obj_2_data, obj.data)
          break
        end
      end
    end

    it "iterates only over loaded objects" do
      obj = @rev.object(2)
      assert_equal([obj], @rev.each(only_loaded: true).to_a)
    end
  end

  it "works without a cross-reference section" do
    rev = HexaPDF::Revision.new({})
    rev.add(@obj)
    assert_equal(@obj, rev.object(@ref))
    assert(rev.object?(@ref))
    assert_equal([@obj], rev.each.to_a)
    rev.delete(@ref, mark_as_free: false)
    refute(rev.object?(@ref))
  end

  describe "each_modified_object" do
    it "returns modified objects" do
      obj = @rev.object(3)
      obj.value = :Other
      @rev.add(@obj)
      deleted = @rev.object(6)
      @rev.delete(6)
      assert_equal([obj, @obj, deleted], @rev.each_modified_object.to_a)
      assert_same(obj, @rev.object(3))
    end

    it "optionally deletes the modified objects from the revision" do
      obj = @rev.object(3)
      obj.value = :other
      assert_equal([obj], @rev.each_modified_object(delete: true).to_a)
      refute_same(obj, @rev.object(3))
    end

    it "ignores object and xref streams that were deleted" do
      @rev.delete(4)
      @rev.delete(5)
      assert_equal([], @rev.each_modified_object.to_a)
    end

    it "handles object and xref streams that were added appropriately depending on the 'all' arg" do
      xref = @rev.add(HexaPDF::Dictionary.new({Type: :XRef}, oid: 20))
      objstm = @rev.add(HexaPDF::Dictionary.new({Type: :ObjStm}, oid: 21))
      assert_equal([], @rev.each_modified_object.to_a)
      assert_equal([xref, objstm], @rev.each_modified_object(all: true).to_a)
    end

    it "doesn't return non-modified objects" do
      @rev.object(2)
      assert_equal([], @rev.each_modified_object.to_a)
    end

    it "doesn't return objects that have modified values just because of reading" do
      obj = @rev.object(7)
      obj.delete(:Type)
      assert_equal([], @rev.each_modified_object.to_a)
    end

    it "doesn't return dictionaries that have direct HexaPDF::Object child objects" do
      obj = @rev.object(6)
      obj[:Array] = HexaPDF::PDFArray.new([1, 2]) # same value but differen #data instance
      assert_equal([], @rev.each_modified_object.to_a)
    end

    it "doesn't return signature objects" do
      obj = @rev.object(2)
      obj[:x] = :y
      assert_equal([], @rev.each_modified_object.to_a)
    end
  end
end
