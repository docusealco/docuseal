# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/revisions'
require 'hexapdf/document'
require 'stringio'

describe HexaPDF::Revisions do
  before do
    @io = StringIO.new(<<~EOF)
      %PDF-1.7
      1 0 obj
      10
      endobj

      2 0 obj
      20
      endobj

      xref
      0 3
      0000000000 65535 f 
      0000000009 00000 n 
      0000000028 00000 n 
      trailer
      << /Size 3 >>
      startxref
      47
      %%EOF

      2 0 obj
      300
      endobj

      3 0 obj
      << /Type /XRef /Size 4 /Index [2 1] /W [1 1 1] /Filter /ASCIIHexDecode /Length 6
      >>stream
      019E00
      endstream
      endobj

      2 0 obj
      200
      endobj

      xref
      2 2
      0000000301 00000 n 
      0000000178 00000 n 
      trailer
      << /Size 4 /Prev 47 >>
      startxref
      321
      %%EOF

      2 0 obj
      400
      endobj

      xref
      2 1
      0000000422 00000 n 
      trailer
      << /Size 4 /Prev 321 /XRefStm 178 >>
      startxref
      442
      %%EOF
    EOF
    @doc = HexaPDF::Document.new(io: @io)
    @revisions = @doc.revisions
  end

  describe "initialize" do
    it "automatically loads all revisions from the underlying IO object" do
      assert_kind_of(HexaPDF::Parser, @revisions.parser)
      assert_equal(20, @revisions.all[0].object(2).value)
      assert_equal(200, @revisions.all[1].object(2).value)
      assert_equal(400, @revisions.all[2].object(2).value)
    end

    it "creates an empty revision when not using initial revisions" do
      revisions = HexaPDF::Revisions.new(@doc)
      assert_equal(1, revisions.all.count)
    end
  end

  it "returns the next free oid" do
    assert_equal(4, @revisions.next_oid)
  end

  describe "object" do
    it "accepts a Reference object as argument" do
      assert_equal(400, @revisions.object(HexaPDF::Reference.new(2, 0)).value)
    end

    it "accepts an object number as arguments" do
      assert_equal(400, @revisions.object(2).value)
    end

    it "returns nil for unknown object references" do
      assert_nil(@revisions.object(100))
    end

    it "returns a null object for freed objects" do
      @revisions.delete_object(2)
      assert(@revisions.object(2).null?)
    end
  end

  describe "object?" do
    it "works with a Reference object as argument" do
      assert(@revisions.object?(HexaPDF::Reference.new(2, 0)))
    end

    it "works with an object number as arguments" do
      assert(@revisions.object?(2))
    end

    it "returns false when no object is found" do
      refute(@revisions.object?(20))
    end

    it "returns true for freed objects" do
      @revisions.delete_object(2)
      assert(@revisions.object?(2))
    end
  end

  describe "add_object" do
    before do
      @obj = HexaPDF::Object.new(5)
    end

    it "adds the object to the current revision" do
      @revisions.add_object(@obj)
      assert_same(@obj, @revisions.current.object(@obj))
    end

    it "returns the added object" do
      obj = @revisions.add_object(@obj)
      assert_same(@obj, obj)
    end

    it "returns the given object if it is already stored in the document" do
      obj = @revisions.add_object(@obj)
      assert_same(obj, @revisions.add_object(obj))
    end

    it "fails if the object number is already associated with another object" do
      @revisions.add_object(@obj)
      assert_raises(HexaPDF::Error) { @revisions.add_object(@doc.wrap(5, oid: @obj.oid)) }
    end

    it "automatically assign an object number for direct objects" do
      assert_equal(4, @revisions.add_object(@obj).oid)
    end
  end

  describe "delete_object" do
    it "works with a Reference object as argument" do
      @revisions.delete_object(@doc.object(2))
      assert(@revisions.object(2).null?)
    end

    it "works with an object number as arguments" do
      @revisions.delete_object(2)
      assert(@revisions.object(2).null?)
    end

    it "deletes an object only in the most recent revision" do
      @revisions.delete_object(2)
      assert_equal(20, @revisions.all[0].object(2).value)
      assert_equal(200, @revisions.all[1].object(2).value)
      assert(@revisions.all[2].object(2).null?)
    end
  end

  describe "each_object" do
    before do
      @obj3 = @revisions.object(3).value
    end

    it "iterates over the current objects" do
      assert_equal([10, 400, @obj3], @revisions.each_object(only_current: true).sort.map(&:value))
    end

    it "iterates over all objects" do
      assert_equal([@obj3, 400, 200, @obj3, 10, 20],
                   @revisions.each_object(only_current: false).map(&:value))
    end

    it "iterates over all loaded objects" do
      assert_equal([@obj3], @revisions.each_object(only_loaded: true).map(&:value))
      assert_equal(400, @revisions.object(2).value)
      assert_equal([400, @obj3], @revisions.each_object(only_loaded: true).sort.map(&:value))
    end

    it "yields the revision as second argument if the block accepts exactly two arguments" do
      data = [@obj3, @revisions.all[-1], 400, @revisions.all[-1], 10, @revisions.all[0]]
      @revisions.each_object do |obj, rev|
        assert_equal(data.shift, obj.value)
        assert_equal(data.shift, rev)
      end
      assert(data.empty?)
    end
  end

  describe "add" do
    it "adds an empty revision as the current revision" do
      rev = @revisions.add
      assert_equal({Size: 4}, rev.trailer.value)
      assert_equal(rev, @revisions.current)
    end
  end

  describe "merge" do
    it "does nothing when only one revision is specified" do
      @revisions.merge(1..1)
      assert_equal(3, @revisions.all.size)
    end

    it "merges the higher into the the lower revision" do
      @revisions.merge
      assert_equal(1, @revisions.all.size)
      assert_equal([10, 400, @doc.object(3).value], @revisions.current.each.to_a.sort.map(&:value))
    end

    it "handles objects correctly that are in multiple revisions" do
      @revisions.current.add(@revisions.all[0].object(1))
      @revisions.merge
      assert_equal(1, @revisions.each.to_a.size)
      assert_equal([10, 400, @doc.object(3).value], @revisions.current.each.to_a.sort.map(&:value))
    end
  end

  it "handles invalid PDFs that have a loop via the xref /Prev or /XRefStm entries" do
    io = StringIO.new(<<~EOF)
      %PDF-1.7
      1 0 obj
      10
      endobj

      xref
      0 2
      0000000000 65535 f 
      0000000009 00000 n 
      trailer
      << /Size 2 /Prev 148>>
      startxref
      28
      %%EOF

      2 0 obj
      300
      endobj

      xref
      2 1
      0000000301 00000 n 
      trailer
      << /Size 3 /Prev 28 /XRefStm 148>>
      startxref
      148
      %%EOF
    EOF
    doc = HexaPDF::Document.new(io: io)
    assert_equal(2, doc.revisions.count)
  end

  it "merges a completely empty revision with just a /XRefStm with the previous revision" do
    io = StringIO.new(<<~EOF) # 2 28 3 47
      %PDF-1.7
      1 0 obj
      10
      endobj
      xref
      0 2
      0000000000 65535 f 
      0000000009 00000 n 
      trailer
      << /Size 2 >>
      startxref
      27
      %%EOF

      2 0 obj
      20
      endobj

      3 0 obj
      << /Type /XRef /Size 4 /Index [2 1] /W [1 1 1] /Filter /ASCIIHexDecode /Length 6
      >>stream
      017600
      endstream
      endobj

      xref
      2 2
      0000000000 65535 f 
      0000000137 00000 n 
      trailer
      << /Size 4 /Prev 27>>
      startxref
      260
      %%EOF

      xref
      0 0
      trailer
      << /Size 4 /Prev 260 /XRefStm 137>>
      startxref
      360
      %%EOF
    EOF
    doc = HexaPDF::Document.new(io: io, config: {'parser.try_xref_reconstruction' => false})
    assert_equal(2, doc.revisions.count)
    assert_equal(10, doc.object(1).value)
    assert_equal(20, doc.object(2).value)
  end

  it "uses the reconstructed revision if errors are found when loading from an IO" do
    io = StringIO.new(<<~EOF)
      %PDF-1.7
      1 0 obj
      10
      endobj

      xref
      0 2
      0000000000 65535 f 
      0000000009 00000 n 
      trailer
      << /Size 5 >>
      startxref
      28
      %%EOF

      2 0 obj
      300
      endobj

      xref
      2 1
      0000000301 00000 n 
        trailer
      << /Size 3 /Prev 100>>
      startxref
      139
      %%EOF
    EOF
    doc = HexaPDF::Document.new(io: io)
    assert_equal(2, doc.revisions.count)
    assert_same(doc.revisions.all[0].trailer.value, doc.revisions.all[1].trailer.value)

    assert_raises(HexaPDF::MalformedPDFError) do
      HexaPDF::Document.new(io: io, config: {'parser.try_xref_reconstruction' => false})
    end
  end

  describe "linearzied PDFs" do
    before  do
      @io = StringIO.new(+<<~EOF)
        %PDF-1.2
        5 0 obj
        <</Linearized 1>>
        endobj
        xref
        5 1
        0000000009 00000 n
        trailer
        <</ID[(a)(b)]/Info 1 0 R/Root 2 0 R/Size 6/Prev 394>>
        %
        1 0 obj
        <</ModDate(D:20221205233910+01'00')/Producer(HexaPDF version 0.27.0)>>
        endobj
        2 0 obj
        <</Type/Catalog/Pages 3 0 R>>
        endobj
        3 0 obj
        <</Type/Pages/Kids[4 0 R]/Count 1>>
        endobj
        4 0 obj
        <</Type/Page/MediaBox[0 0 595 842]/Parent 3 0 R/Resources<<>>>>
        endobj
        xref
        0 5
        0000000000 65535 f 
        0000000133 00000 n 
        0000000219 00000 n 
        0000000264 00000 n 
        0000000315 00000 n 
        trailer
        <</ID[(a)(b)]/Info 1 0 R/Root 2 0 R/Size 5>>
        startxref
        41
        %%EOF
      EOF
    end

    it "merges the two revisions of a linearized PDF into one" do
      doc = HexaPDF::Document.new(io: @io, config: {'parser.try_xref_reconstruction' => false})
      assert(doc.revisions.parser.linearized?)
      assert_equal(1, doc.revisions.count)
      assert_same(5, doc.revisions.current.xref_section.max_oid)
    end

    it "works for a fake linearized PDF where the first xref section isn't actually used" do
      @io.string[-9..-1] = "394\n%%EOF\n"
      doc = HexaPDF::Document.new(io: @io, config: {'parser.try_xref_reconstruction' => false})
      assert(doc.revisions.parser.linearized?)
      assert_equal(1, doc.revisions.count)
      assert_same(4, doc.revisions.current.xref_section.max_oid)
    end
  end
end
