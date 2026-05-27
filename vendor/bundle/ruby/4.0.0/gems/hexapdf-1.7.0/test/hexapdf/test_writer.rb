# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/writer'
require 'hexapdf/document'
require 'stringio'

describe HexaPDF::Writer do
  before do
    @std_input_io = StringIO.new(<<~EOF.force_encoding(Encoding::BINARY))
      %PDF-1.7
      %\xCF\xEC\xFF\xE8\xD7\xCB\xCD
      1 0 obj
      10
      endobj
      2 0 obj
      20
      endobj
      xref
      0 3
      0000000000 65535 f 
      0000000018 00000 n 
      0000000036 00000 n 
      trailer
      <</Size 3>>
      startxref
      54
      %%EOF
      2 0 obj
      <</Length 10>>stream
      Some data!
      endstream
      endobj
      xref
      2 1
      0000000162 00000 n 
      trailer
      <</Size 3/Prev 54>>
      startxref
      219
      %%EOF
      3 0 obj
      <</Producer(HexaPDF version #{HexaPDF::VERSION})>>
      endobj
      xref
      3 1
      0000000296 00000 n 
      trailer
      <</Size 4/Root<</Type/Catalog>>/Info 3 0 R/Prev 219>>
      startxref
      #{343 + HexaPDF::VERSION.length}
      %%EOF
    EOF

    xref_stream = case HexaPDF::VERSION.length
                  when 5 then "x\xDAcbdlg``b`\xB0\x04\x93\x93\x19\x18\x00\f\x1E\x01\\"
                  when 6 then "x\xDAcbd\xEC```b`\xB0\x04\x93\x93\x18\x18\x00\f*\x01\\"
                  else fail
                  end
    @compressed_input_io = StringIO.new(<<~EOF.force_encoding(Encoding::BINARY))
      %PDF-1.7
      %\xCF\xEC\xFF\xE8\xD7\xCB\xCD
      5 0 obj
      <</Type/ObjStm/N 1/First 4/Filter/FlateDecode/Length 15>>stream
      x\xDA3T0P04P\x00\x00\x04\xA1\x01#
      endstream
      endobj
      2 0 obj
      20
      endobj
      3 0 obj
      <</Size 6/Type/XRef/W[1 1 2]/Index[0 6]/Filter/FlateDecode/DecodeParms<</Columns 4/Predictor 12>>/Length 36>>stream
      x\xDAcb`\xF8\xFF\x9F\x89\x89\x95\x91\x91\xE9\x7F\x19\x03\x03\x13\x83\x10\x90\xF8_\f\x14c\x14bd\x04\x00lk\a 
      endstream
      endobj
      startxref
      141
      %%EOF
      6 0 obj
      <</Producer(HexaPDF version #{HexaPDF::VERSION})>>
      endobj
      2 0 obj
      <</Length 10>>stream
      Some data!
      endstream
      endobj
      4 0 obj
      <</Size 7/Root<</Type/Catalog>>/Info 6 0 R/Prev 141/Type/XRef/W[1 2 2]/Index[2 1 4 1 6 1]/Filter/FlateDecode/DecodeParms<</Columns 5/Predictor 12>>/Length 22>>stream
      #{xref_stream}
      endstream
      endobj
      startxref
      #{443 + HexaPDF::VERSION.length}
      %%EOF
    EOF
  end

  def assert_document_conversion(input_io)
    document = HexaPDF::Document.new(io: input_io)
    document.trailer.info[:Producer] = "unknown"
    output_io = StringIO.new(''.b)
    start_xref_offset, xref_section = HexaPDF::Writer.write(document, output_io)
    assert_kind_of(HexaPDF::XRefSection, xref_section)
    assert_kind_of(Integer, start_xref_offset)
    assert_equal(input_io.string, output_io.string)
  end

  it "writes a complete document" do
    assert_document_conversion(@std_input_io)
    assert_document_conversion(@compressed_input_io)
  end

  describe "write_incremental" do
    it "writes a document in incremental mode" do
      doc = HexaPDF::Document.new(io: @std_input_io)
      doc.pages.add
      output_io = StringIO.new
      HexaPDF::Writer.write(doc, output_io, incremental: true)
      assert_equal(output_io.string[0, @std_input_io.string.length], @std_input_io.string)
      doc = HexaPDF::Document.new(io: output_io)
      assert_equal(4, doc.revisions.count)
      assert_equal(2, doc.revisions.current.each.to_a.size)
    end

    it "uses an xref stream if the document already contains at least one" do
      doc = HexaPDF::Document.new(io: @compressed_input_io)
      doc.pages.add
      output_io = StringIO.new
      HexaPDF::Writer.write(doc, output_io, incremental: true)
      refute_match(/^trailer/, output_io.string)
    end

    it "updates the PDF version using the catalog's /Version entry if necessary" do
      doc = HexaPDF::Document.new(io: @std_input_io)
      doc.version = '2.0'
      output_io = StringIO.new
      HexaPDF::Writer.write(doc, output_io, incremental: true)
      assert_equal('2.0', HexaPDF::Document.new(io: output_io).version)
    end

    it "raises an error if the used encryption was changed" do
      io = StringIO.new
      doc = HexaPDF::Document.new
      doc.encrypt
      doc.write(io)

      doc = HexaPDF::Document.new(io: io)
      doc.encrypt(owner_password: 'test')
      assert_raises(HexaPDF::Error) { doc.write('notused', incremental: true) }
    end
  end

  it "moves modified objects into the last revision" do
    io = StringIO.new
    io2 = StringIO.new

    document = HexaPDF::Document.new
    document.pages.add
    HexaPDF::Writer.new(document, io).write

    document = HexaPDF::Document.new(io: io)
    document.pages.add
    HexaPDF::Writer.new(document, io2).write_incremental

    document = HexaPDF::Document.new(io: io2)
    document.revisions.add
    document.pages.add
    HexaPDF::Writer.new(document, io).write

    document = HexaPDF::Document.new(io: io)
    assert_equal(3, document.revisions.count)
    assert_equal(1, document.revisions.all[0].object(3)[:Kids].length)
    assert_equal(2, document.revisions.all[1].object(3)[:Kids].length)
    assert_equal(3, document.revisions.all[2].object(3)[:Kids].length)
  end

  it "creates an xref stream if no xref stream is in a revision but object streams are" do
    document = HexaPDF::Document.new
    document.add({}, type: HexaPDF::Type::ObjectStream)
    HexaPDF::Writer.new(document, StringIO.new).write
    assert_equal(:XRef, document.object(4).type)
  end

  it "creates an xref stream if a previous revision had one" do
    document = HexaPDF::Document.new
    document.pages.add
    io = StringIO.new
    HexaPDF::Writer.new(document, io).write

    document = HexaPDF::Document.new(io: io)
    document.pages.add
    document.add({}, type: HexaPDF::Type::ObjectStream)
    io2 = StringIO.new
    HexaPDF::Writer.new(document, io2).write_incremental

    document = HexaPDF::Document.new(io: io2)
    document.pages.add
    HexaPDF::Writer.new(document, io).write_incremental

    document = HexaPDF::Document.new(io: io)
    assert_equal(3, document.revisions.count)
    assert(document.revisions.all[0].none? {|obj| obj.type == :XRef })
    assert(document.revisions.all[1].one? {|obj| obj.type == :XRef })
    assert(document.revisions.all[2].one? {|obj| obj.type == :XRef })
  end

  it "doesn't create an xref stream if one was just used for an XRefStm entry" do
    # The following document's structure is built like a typical MS Word created PDF
    input = StringIO.new(<<~EOF.b)
      %PDF-1.2
      %\xCF\xEC\xFF\xE8\xD7\xCB\xCD
      1 0 obj
      <</Type/Catalog/Pages 2 0 R>>
      endobj
      2 0 obj
      <</Type/Pages/Kids[3 0 R]/Count 1>>
      endobj
      3 0 obj
      <</Type/Page/MediaBox[0 0 595 842]/Parent 2 0 R/Resources<<>>>>
      endobj
      5 0 obj
      <</Producer(HexaPDF version 0.35.1)>>
      endobj
      4 0 obj
      <</Root 1 0 R/Info 5 0 R/Size 6/Type/XRef/W[1 1 2]/Index[0 6]/Filter/FlateDecode/DecodeParms<</Columns 4/Predictor 12>>/Length 33>>stream
      x\xDAcb`\xF8\xFF\x9F\x89Q\x88\x91\x91\x89A\x97\x81\x81\x89\xC1\x18D\xB4\x80\x88\xD3\f\f\x00C\xDE\x03\xCF
      endstream
      endobj
      xref
      0 6
      0000000000 65535 f
      0000000018 00000 n
      0000000063 00000 n
      0000000114 00000 n
      0000000246 00000 n
      0000000193 00000 n
      trailer
      <</Root 1 0 R/Info 5 0 R/Size 6>>
      startxref
      443
      %%EOF

      xref
      0 0
      trailer
      <</Root 1 0 R/Info 5 0 R/Prev 443/XRefStm 246>>
      startxref
      629
      %%EOF
    EOF

    document = HexaPDF::Document.new(io: input)
    document.pages.add
    io = StringIO.new
    HexaPDF::Writer.new(document, io).write_incremental

    document = HexaPDF::Document.new(io: io)
    refute(document.trailer.key?(:Type))
  end

  it "raises an error if the class is misused and an xref section contains invalid entries" do
    document = HexaPDF::Document.new
    io = StringIO.new
    writer = HexaPDF::Writer.new(document, io)
    xref_section = HexaPDF::XRefSection.new
    xref_section.add_compressed_entry(1, 2, 3)
    assert_raises(HexaPDF::Error) { writer.send(:write_xref_section, xref_section) }
  end

  it "removes the /XRefStm entry in a trailer" do
    io = StringIO.new
    doc = HexaPDF::Document.new
    doc.trailer[:XRefStm] = 1234
    doc.write(io)
    doc = HexaPDF::Document.new(io: io)
    refute(doc.trailer.key?(:XRefStm))
  end

  it "removes the /Type entry in a non-xref stream trailer" do
    io = StringIO.new
    doc = HexaPDF::Document.new
    doc.trailer[:Type] = :XRef
    doc.write(io)
    doc = HexaPDF::Document.new(io: io)
    refute(doc.trailer.key?(:Type))
  end
end
