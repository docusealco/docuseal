# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/document'
require 'hexapdf/task/optimize'

describe HexaPDF::Task::Optimize do
  class TestType < HexaPDF::Dictionary

    define_type :Test
    define_field :Type, type: Symbol, default: type
    define_field :Optional, type: Symbol, default: :Optional

  end

  before do
    HexaPDF::GlobalConfiguration['object.type_map'][:Test] = TestType
    @doc = HexaPDF::Document.new
    @obj1 = @doc.add({Type: :Test, Optional: :Optional})
    @doc.trailer[:Test] = @doc.wrap(@obj1)
    @doc.revisions.add
    @obj2 = @doc.add({Type: :UsedEntry})
    @obj3 = @doc.add({Unused: @obj2})
    @obj4 = @doc.add({Test: :Test})
    @obj1[:Test] = @doc.wrap(@obj4, type: TestType)
  end

  after do
    HexaPDF::GlobalConfiguration['object.type_map'].delete(:Test)
  end

  def assert_objstms_generated
    assert(@doc.revisions.all? {|rev| rev.any? {|obj| obj.type == :ObjStm } })
    assert(@doc.revisions.all? {|rev| rev.any? {|obj| obj.type == :XRef } })
  end

  def assert_xrefstms_generated
    assert(@doc.revisions.all? {|rev| rev.find_all {|obj| obj.type == :XRef }.size == 1 })
  end

  def assert_no_objstms
    assert(@doc.each(only_current: false).all? {|obj| obj.type != :ObjStm })
  end

  def assert_no_xrefstms
    assert(@doc.each(only_current: false).all? {|obj| obj.type != :XRef })
  end

  def assert_default_deleted
    assert(@doc.object(1).key?(:Type))
    refute(@doc.object(1).key?(:Optional))
  end

  describe "compact" do
    it "compacts the document" do
      @doc.task(:optimize, compact: true)
      assert_equal(1, @doc.revisions.count)
      assert_equal(2, @doc.each(only_current: false).to_a.size)
      refute_equal(@obj2, @doc.object(@obj2))
      refute_equal(@obj3, @doc.object(@obj3))
      assert_default_deleted
      assert_equal(2, @obj4.oid)
      assert_equal(@obj1[:Test], @obj4)
    end

    it "compacts and generates object streams" do
      @doc.task(:optimize, compact: true, object_streams: :generate)
      assert_objstms_generated
      assert_default_deleted
    end

    it "compacts and deletes object streams" do
      @doc.add({Type: :ObjStm})
      @doc.task(:optimize, compact: true, object_streams: :delete)
      assert_no_objstms
      assert_default_deleted
    end

    it "compacts and generates xref streams" do
      @doc.task(:optimize, compact: true, xref_streams: :generate)
      assert_xrefstms_generated
      assert_default_deleted
    end

    it "compacts and deletes xref streams" do
      @doc.revisions.all[0].add(@doc.wrap({}, type: HexaPDF::Type::XRefStream,
                                          oid: @doc.revisions.next_oid))
      @doc.revisions.all[1].add(@doc.wrap({}, type: HexaPDF::Type::XRefStream,
                                          oid: @doc.revisions.next_oid))
      @doc.task(:optimize, compact: true, xref_streams: :delete)
      assert_no_xrefstms
      assert_default_deleted
    end
  end

  describe "object_streams" do
    def reload_document_with_objstm_from_io
      io = StringIO.new
      objstm = @doc.add({}, type: HexaPDF::Type::ObjectStream)
      @doc.add({}, type: HexaPDF::Type::XRefStream)
      objstm.add_object(@doc.add({Type: :Test}))
      @doc.write(io, compact: false)
      io.rewind
      @doc = HexaPDF::Document.new(io: io)
    end

    it "generates object streams" do
      210.times { @doc.add(5) }
      objstm = @doc.add({}, type: HexaPDF::Type::ObjectStream)
      reload_document_with_objstm_from_io
      @doc.task(:optimize, object_streams: :generate)
      assert_objstms_generated
      assert_default_deleted
      assert_nil(@doc.object(objstm).value)
      objstms = @doc.revisions.current.find_all {|obj| obj.type == :ObjStm }
      assert_equal(2, objstms.size)
      assert_equal(400, objstms[0].instance_variable_get(:@objects).size)
    end

    it "deletes object and xref streams" do
      reload_document_with_objstm_from_io
      @doc.task(:optimize, object_streams: :delete, xref_streams: :delete)
      assert_no_objstms
      assert_no_xrefstms
      assert_default_deleted
    end

    it "deletes object and generates xref streams" do
      @doc.add({}, type: HexaPDF::Type::ObjectStream)
      xref = @doc.add({}, type: HexaPDF::Type::XRefStream)
      @doc.task(:optimize, object_streams: :delete, xref_streams: :generate)
      assert_no_objstms
      assert_xrefstms_generated
      assert_equal([xref], @doc.revisions.current.find_all {|obj| obj.type == :XRef })
      assert_default_deleted
    end
  end

  describe "xref_streams" do
    it "generates xref streams" do
      @doc.task(:optimize, xref_streams: :generate)
      assert_xrefstms_generated
      assert_default_deleted
    end

    it "reuses an xref stream in generatation mode" do
      @doc.add({}, type: HexaPDF::Type::XRefStream)
      @doc.task(:optimize, xref_streams: :generate)
      assert_xrefstms_generated
    end

    it "deletes xref streams" do
      @doc.add({}, type: HexaPDF::Type::XRefStream)
      @doc.task(:optimize, xref_streams: :delete)
      assert_no_xrefstms
      assert_default_deleted
    end
  end

  describe "compress_pages" do
    it "compresses pages streams" do
      page = @doc.pages.add
      page.contents = "   10  10   m    q            Q    BI /Name   5 ID dataEI   "
      @doc.task(:optimize, compress_pages: true)
      assert_equal("10 10 m\nq\nQ\nBI\n/Name 5 ID\ndataEI\n", page.contents)
    end

    it "uses parser.on_correctable_error to defer a decision regarding invalid operations" do
      page = @doc.pages.add
      page.contents = "10 20-30 m"
      @doc.task(:optimize, compress_pages: true)
      assert_equal("", page.contents)

      @doc.config['parser.on_correctable_error'] = proc { true }
      page.contents = "10 20-30 m"
      assert_raises(HexaPDF::Error) { @doc.task(:optimize, compress_pages: true) }
    end
  end

  describe "prune_page_resources" do
    it "removes all unused XObject references" do
      [false, true].each do |compress_pages|
        page1 = @doc.pages.add
        page1.resources[:XObject] = {}
        page1.resources[:XObject][:test] = @doc.add({})
        page1.resources[:XObject][:used_on_page2] = @doc.add({})
        page1.resources[:XObject][:unused] = @doc.add({})
        page1.contents = "/test Do /InvalidRef Do"
        page2 = @doc.pages.add
        page2.resources[:XObject] = {}
        page2.resources[:XObject][:used_on2] = page1.resources[:XObject][:used_on_page2]
        page2.resources[:XObject][:also_unused] = page1.resources[:XObject][:unused]
        page2.contents = "/used_on2 Do"
        page3 = @doc.pages.add
        page3.contents = "/unused Do   "

        @doc.task(:optimize, prune_page_resources: true, compress_pages: compress_pages)

        assert(page1.resources[:XObject].key?(:test))
        assert(page1.resources[:XObject].key?(:used_on_page2))
        refute(page1.resources[:XObject].key?(:unused))
        assert(page2.resources[:XObject].key?(:used_on2))
        refute(page2.resources[:XObject].key?(:also_unused))
        assert_equal("/unused Do#{compress_pages ? "\n" : '   '}", page3.contents)
      end
    end
  end
end
