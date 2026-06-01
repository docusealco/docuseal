# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/document'
require 'hexapdf/parser'
require 'stringio'

describe HexaPDF::Parser do
  before do
    @document = HexaPDF::Document.new
    @document.config['parser.try_xref_reconstruction'] = false
    @document.add(@document.wrap(10, oid: 1, gen: 0))
    @document.add(@document.wrap({Recurse: HexaPDF::Reference.new(3)}, oid: 3))

    create_parser(+<<~EOF)
      %PDF-1.7

      1 0 obj
      10
      endobj

      2 0 obj
      [ 5 6 <</Length 10 >> (name) <4E6F762073 686D6F7A20	6B612070
      6F702E>]
      endobj

      3 15 obj<< /Length 1 0 R/Hallo 6/Filter /Fl/DecodeParms<<>> >>stream
      Hallo PDF!endstream
      endobj

      4 0 obj
      <</Type /XRef /Length 3 /W [1 1 1] /Index [1 1] /Size 2 >> stream
      \x01\x0A\x00
      endstream
      endobj

      5 0 obj
      1 0 R
      endobj

      xref
      0 4
      0000000000 65535 f 
      0000000010 00000 n 
      0000000029 00000 n 
      0000000000 65535 f 
      3 2
      0000000556 00000 n 
      0000000308 00000 n
      trailer
      << /Test (now) >>
      startxref
      330
      %%EOF
    EOF
  end

  def create_parser(str)
    @parse_io = StringIO.new(str)
    @parser = HexaPDF::Parser.new(@parse_io, @document)
  end

  describe "linearized?" do
    it "can determine whether a document is linearized" do
      create_parser("%PDF-1.7\n%abcdefgh\n1 0 obj\n<</Linearized 1/H [2 4]/O 1/E 1/N 1/T 1>>\nendobj")
      assert(@parser.linearized?)
    end

    it "returns false if the first object is not a linearization dictionary" do
      create_parser("%PDF-1.7\n%abcdefgh\n1 0 obj\n<</Length 2 0 R>>\nstream\nhallo\nendstream\nendobj")
      refute(@parser.linearized?)
    end

    it "returns false if there is a parse error" do
      create_parser("%PDF-1.7\n%abcdefgh\n1 a obj thing")
      refute(@parser.linearized?)
    end
  end

  describe "parse_indirect_object" do
    it "reads indirect objects sequentially" do
      object, oid, gen, stream = @parser.parse_indirect_object
      assert_equal(1, oid)
      assert_equal(0, gen)
      assert_equal(10, object)
      assert_nil(stream)

      object, oid, gen, stream = @parser.parse_indirect_object
      assert_equal(2, oid)
      assert_equal(0, gen)
      assert_equal([5, 6, {Length: 10}, "name", "Nov shmoz ka pop."], object)
      assert_nil(stream)

      object, oid, gen, stream = @parser.parse_indirect_object
      assert_equal(3, oid)
      assert_equal(15, gen)
      assert_kind_of(HexaPDF::StreamData, stream)
      assert_equal([:Fl], stream.filter)
      assert_equal([{}], stream.decode_parms)
      assert_equal({Length: 10, Hallo: 6, Filter: :Fl, DecodeParms: {}}, object)
    end

    it "handles empty indirect objects by using PDF null for them" do
      create_parser("1 0 obj\nendobj")
      object, * = @parser.parse_indirect_object
      assert_nil(object)
    end

    it "handles keyword stream followed only by CR without LF" do
      create_parser("1 0 obj<</Length 2>> stream\r12\nendstream endobj")
      *, stream = @parser.parse_indirect_object
      assert_equal('12', collector(stream.fiber))
    end

    it "handles keyword stream followed by space and CR or LF" do
      create_parser("1 0 obj<</Length 2>> stream \n12\nendstream endobj")
      *, stream = @parser.parse_indirect_object
      assert_equal('12', collector(stream.fiber))
    end

    it "handles keyword stream followed by space and CR LF" do
      create_parser("1 0 obj<</Length 2>> stream \r\n12\nendstream endobj")
      *, stream = @parser.parse_indirect_object
      assert_equal('12', collector(stream.fiber))
    end

    it "handles invalid indirect object value consisting of number followed by endobj without space" do
      create_parser("1 0 obj 749endobj")
      object, * = @parser.parse_indirect_object
      assert_equal(749, object)
    end

    it "treats indirect objects with invalid values as null objects" do
      create_parser("1 0 obj <</test <end)> > endobj")
      object, * = @parser.parse_indirect_object
      assert_nil(object)
    end

    it "recovers from a stream length value that doesn't reflect the correct length" do
      create_parser("1 0 obj<</Length 4>> stream\n12endstream endobj")
      obj, _, _, stream = @parser.parse_indirect_object
      assert_equal(2, obj[:Length])
      assert_equal('12', collector(stream.fiber))
    end

    it "recovers from an incorrect stream length value which leads to a parsing error" do
      create_parser("1 0 obj<</Length 2>> stream\n12(ab\nendstream endobj")
      obj, _, _, stream = @parser.parse_indirect_object
      assert_equal(5, obj[:Length])
      assert_equal('12(ab', collector(stream.fiber))
    end

    it "recovers from an invalid stream length value" do
      create_parser("1 0 obj<</Length 2 0 R>> stream\n12endstream endobj")
      @document.add([5], oid: 2)
      obj, _, _, stream = @parser.parse_indirect_object
      assert_equal(2, obj[:Length])
      assert_equal('12', collector(stream.fiber))
    end

    it "recovers from a non-existing indirect reference to a stream length value" do
      create_parser("1 0 obj<</Length 2 0 R>> stream\n12(ab\nendstream endobj")
      obj, _, _, stream = @parser.parse_indirect_object
      assert_equal(5, obj[:Length])
      assert_equal('12(ab', collector(stream.fiber))
    end

    it "works even if the keyword endobj is missing or mangled" do
      create_parser("1 0 obj<</Length 4>>5")
      object, * = @parser.parse_indirect_object
      assert_equal({Length: 4}, object)
      create_parser("1 0 obj<</Length 4>>endobjk")
      object, * = @parser.parse_indirect_object
      assert_equal({Length: 4}, object)
    end

    it "recovers in case of an invalid /Filter leading to indirect object recursion" do
      create_parser("1 0 obj<</Length 1/Filter 3 0 R>>stream\n1\nendstream endobj")
      object, * = @parser.parse_indirect_object
      assert_equal({Length: 1}, object)
    end

    it "recovers in case of an invalid /DecodeParms leading to indirect object recursion" do
      create_parser("1 0 obj<</Length 1/DecodeParms 3 0 R>>stream\n1\nendstream endobj")
      object, * = @parser.parse_indirect_object
      assert_equal({Length: 1}, object)
    end

    it "fails if the oid, gen or 'obj' keyword is invalid" do
      create_parser("a 0 obj\n5\nendobj")
      exp = assert_raises(HexaPDF::MalformedPDFError) { @parser.parse_indirect_object }
      assert_match(/No valid object/, exp.message)
      create_parser("1 a obj\n5\nendobj")
      exp = assert_raises(HexaPDF::MalformedPDFError) { @parser.parse_indirect_object }
      assert_match(/No valid object/, exp.message)
      create_parser("1 0 dobj\n5\nendobj")
      exp = assert_raises(HexaPDF::MalformedPDFError) { @parser.parse_indirect_object }
      assert_match(/No valid object/, exp.message)
    end

    it "fails if the value of a stream is not a dictionary" do
      create_parser("1 0 obj\n(fail)\nstream\nendstream\nendobj\n")
      exp = assert_raises(HexaPDF::MalformedPDFError) { @parser.parse_indirect_object }
      assert_match(/stream.*dictionary/, exp.message)
    end

    it "fails if the 'stream' keyword isn't followed by EOL" do
      create_parser("1 0 obj\n<< >>\nstream endstream\nendobj\n")
      exp = assert_raises(HexaPDF::MalformedPDFError) { @parser.parse_indirect_object(0) }
      assert_match(/stream.*followed by LF/, exp.message)
    end

    it "fails if the 'endstream' keyword is missing" do
      create_parser("1 0 obj\n<< >>\nstream\nendobj\n")
      exp = assert_raises(HexaPDF::MalformedPDFError) { @parser.parse_indirect_object(0) }
      assert_match(/stream.*followed by.*endstream/i, exp.message)
    end

    describe "with strict parsing" do
      before do
        @document.config['parser.on_correctable_error'] = proc { true }
      end

      it "fails if an empty indirect object is found" do
        create_parser("1 0 obj\nendobj")
        exp = assert_raises(HexaPDF::MalformedPDFError) { @parser.parse_indirect_object }
        assert_match(/no indirect object value/i, exp.message)
      end

      it "fails if keyword stream is followed only by CR without LF" do
        create_parser("1 0 obj<</Length 2>> stream\r12\nendstream endobj")
        exp = assert_raises(HexaPDF::MalformedPDFError) { @parser.parse_indirect_object }
        assert_match(/not CR alone/, exp.message)
      end

      it "fails if keyword stream is followed by space and CR or LF instead of LF or CR/LF" do
        create_parser("1 0 obj<</Length 2>> stream \n12\nendstream endobj")
        exp = assert_raises(HexaPDF::MalformedPDFError) { @parser.parse_indirect_object }
        assert_match(/followed by space instead/, exp.message)
      end

      it "fails if keyword stream is followed by space and CR LF instead of LF or CR/LF" do
        create_parser("1 0 obj<</Length 2>> stream \r\n12\nendstream endobj")
        exp = assert_raises(HexaPDF::MalformedPDFError) { @parser.parse_indirect_object }
        assert_match(/followed by space instead/, exp.message)
      end

      it "fails for numbers followed by endobj without space" do
        create_parser("1 0 obj 749endobj")
        exp = assert_raises(HexaPDF::MalformedPDFError) { @parser.parse_indirect_object }
        assert_match(/Missing whitespace after number/, exp.message)
      end

      it "fails for invalid values" do
        create_parser("1 0 obj <</test <end)> >endobj")
        exp = assert_raises(HexaPDF::MalformedPDFError) { @parser.parse_indirect_object }
        assert_match(/Invalid value after '1 0 obj'/, exp.message)
      end

      it "fails if the stream length value is invalid" do
        create_parser("1 0 obj<</Length 4>> stream\n12endstream endobj")
        exp = assert_raises(HexaPDF::MalformedPDFError) { @parser.parse_indirect_object }
        assert_match(/invalid stream length/i, exp.message)
      end

      it "fails if the keyword endobj is mangled" do
        create_parser("1 0 obj\n<< >>\nendobjd\n")
        exp = assert_raises(HexaPDF::MalformedPDFError) { @parser.parse_indirect_object }
        assert_match(/keyword endobj/, exp.message)
      end

      it "fails if the keyword endobj is missing" do
        create_parser("1 0 obj\n<< >>")
        exp = assert_raises(HexaPDF::MalformedPDFError) { @parser.parse_indirect_object }
        assert_match(/keyword endobj/, exp.message)
      end

      it "fails if there is data between 'endstream' and 'endobj'" do
        create_parser("1 0 obj\n<< >>\nstream\nendstream\ntest\nendobj\n")
        exp = assert_raises(HexaPDF::MalformedPDFError) { @parser.parse_indirect_object(0) }
        assert_match(/keyword endobj/, exp.message)
      end

      it "fails if an invalid /Filter leads to indirect object recursion" do
        create_parser("1 0 obj<</Length 1/Filter 3 0 R>>stream\n1\nendstream endobj")
        exp = assert_raises(HexaPDF::MalformedPDFError) { @parser.parse_indirect_object }
        assert_match(/Invalid \/Filter/, exp.message)
      end

      it "fails if an invalid /DecodeParms leads to indirect object recursion" do
        create_parser("1 0 obj<</Length 1/DecodeParms 3 0 R>>stream\n1\nendstream endobj")
        exp = assert_raises(HexaPDF::MalformedPDFError) { @parser.parse_indirect_object }
        assert_match(/Invalid \/DecodeParms/, exp.message)
      end
    end
  end

  describe "load_object" do
    before do
      @entry = HexaPDF::XRefSection.in_use_entry(2, 0, 29)
    end

    it "can load an indirect object" do
      obj = @parser.load_object(@entry)
      assert_kind_of(HexaPDF::Object, obj)
      assert_equal(5, obj.value[0])
      assert_equal(2, obj.oid)
      assert_equal(0, obj.gen)
    end

    it "can load a free object" do
      obj = @parser.load_object(HexaPDF::XRefSection.free_entry(0, 0))
      assert_kind_of(HexaPDF::Object, obj)
      assert_nil(obj.value)
    end

    it "can load a compressed object" do
      def (@document).object(_oid)
        obj = Object.new
        def obj.parse_stream
          HexaPDF::Type::ObjectStream::Data.new("5 [1 2]", [1, 2], [0, 2])
        end
        obj
      end

      obj = @parser.load_object(HexaPDF::XRefSection.compressed_entry(2, 3, 1))
      assert_kind_of(HexaPDF::Object, obj)
      assert_equal([1, 2], obj.value)
    end

    it "handles an invalid indirect object offset of 0" do
      obj = @parser.load_object(HexaPDF::XRefSection.in_use_entry(2, 0, 0))
      assert(obj.null?)
      assert_equal(2, obj.oid)
      assert_equal(0, obj.gen)
    end

    it "handles the case of the value of an indirect object being an indirect reference" do
      obj = @parser.load_object(HexaPDF::XRefSection.in_use_entry(5, 0, 308))
      assert_equal(1, obj.oid)
    end

    it "handles the case when generation numbers don't match with a single revision" do
      @entry.gen = 2
      obj = @parser.load_object(@entry)
      assert_equal(2, obj.oid)
      assert_equal(5, obj[0])
    end

    describe "with strict parsing" do
      before do
        @document.config['parser.on_correctable_error'] = proc { true }
      end

      it "raises an error if an indirect object has an offset of 0" do
        exp = assert_raises(HexaPDF::MalformedPDFError) do
          @parser.load_object(HexaPDF::XRefSection.in_use_entry(2, 0, 0))
        end
        assert_match(/has offset 0/, exp.message)
      end

      it "fails if the generation numbers don't match with a single revision" do
        exp = assert_raises(HexaPDF::MalformedPDFError) do
          @entry.gen = 2
          @parser.load_object(@entry)
        end
        assert_match(/oid,gen.*don't match/, exp.message)
      end
    end

    it "fails if another object is found instead of an object stream" do
      def (@document).object(_oid)
        :invalid
      end
      exp = assert_raises(HexaPDF::MalformedPDFError) do
        @parser.load_object(HexaPDF::XRefSection.compressed_entry(2, 1, 1))
      end
      assert_match(/not an object stream/, exp.message)
    end

    it "fails if the xref entry type is invalid" do
      exp = assert_raises(HexaPDF::MalformedPDFError) do
        @parser.load_object(HexaPDF::XRefSection::Entry.new(:invalid))
      end
      assert_match(/invalid cross-reference type/i, exp.message)
    end

    it "fails if the object numbers don't match" do
      exp = assert_raises(HexaPDF::MalformedPDFError) do
        @entry.oid = 5
        @parser.load_object(@entry)
      end
      assert_match(/oid,gen.*don't match/, exp.message)
    end

    it "fails if the generation numbers don't match for multiple revisions" do
      @document.revisions.add
      exp = assert_raises(HexaPDF::MalformedPDFError) do
        @entry.gen = 5
        @parser.load_object(@entry)
      end
      assert_match(/oid,gen.*don't match/, exp.message)
    end
  end

  describe "startxref_offset" do
    it "caches the offset value" do
      assert_equal(330, @parser.startxref_offset)
      @parser.instance_eval { @io.string = @io.string.sub(/330\n/, "309\n") }
      assert_equal(330, @parser.startxref_offset)
    end

    it "returns the correct offset" do
      assert_equal(330, @parser.startxref_offset)
    end

    it "ignores garbage at the end of the file" do
      create_parser("startxref\n5\n%%EOF" + "\nhallo" * 150)
      assert_equal(5, @parser.startxref_offset)
    end

    it "uses the last startxref if there are more than one" do
      create_parser("startxref\n5\n%%EOF\n\nsome garbage\n\nstartxref\n555\n%%EOF\n")
      assert_equal(555, @parser.startxref_offset)
    end

    it "finds the startxref anywhere in file" do
      create_parser("startxref\n5\n%%EOF" + "\nhallo" * 5000)
      assert_equal(5, @parser.startxref_offset)
    end

    it "handles the case where %%EOF is the on the 1. line of the 1024 byte search block" do
      create_parser("startxref\n5\n%%EOF\n" + "h" * 1018)
      assert_equal(5, @parser.startxref_offset)
    end

    it "handles the case where %%EOF is the on the 2. line of the 1024 byte search block" do
      create_parser("startxref\n5\n%%EOF\n" + "h" * 1017)
      assert_equal(5, @parser.startxref_offset)
    end

    it "handles the case of startxref and its value being on the same line" do
      create_parser("startxref 5\n%%EOF")
      assert_equal(5, @parser.startxref_offset)
    end

    it "handles the case of multiple %%EOF and the last one being invalid" do
      create_parser("startxref\n5\n%%EOF\ntartxref\n3\n%%EOF")
      assert_equal(5, @parser.startxref_offset)
    end

    it "fails even in big files when nothing is found" do
      create_parser("\nhallo" * 5000)
      exp = assert_raises(HexaPDF::MalformedPDFError) { @parser.startxref_offset }
      assert_match(/end-of-file marker not found/, exp.message)
    end

    it "fails if the %%EOF marker is missing" do
      create_parser("startxref\n5")
      exp = assert_raises(HexaPDF::MalformedPDFError) { @parser.startxref_offset }
      assert_match(/end-of-file marker not found/, exp.message)

      create_parser("")
      exp = assert_raises(HexaPDF::MalformedPDFError) { @parser.startxref_offset }
      assert_match(/end-of-file marker not found/, exp.message)
    end

    it "fails if the startxref keyword is missing" do
      create_parser("somexref\n5\n%%EOF")
      exp = assert_raises(HexaPDF::MalformedPDFError) { @parser.startxref_offset }
      assert_match(/missing startxref/, exp.message)
    end

    it "fails on strict parsing if the startxref is not in the last part of the file" do
      @document.config['parser.on_correctable_error'] = proc { true }
      create_parser("startxref\n5\n%%EOF" + "\nhallo" * 5000)
      exp = assert_raises(HexaPDF::MalformedPDFError) { @parser.startxref_offset }
      assert_match(/end-of-file marker not found/, exp.message)
    end

    it "fails on strict parsing if the startxref is on the same line as its value" do
      @document.config['parser.on_correctable_error'] = proc { true }
      create_parser("startxref 5\n%%EOF")
      exp = assert_raises(HexaPDF::MalformedPDFError) { @parser.startxref_offset }
      assert_match(/startxref on same line/, exp.message)
    end

    it "fails on strict parsing if there are multiple %%EOF and the last one is invalid" do
      @document.config['parser.on_correctable_error'] = proc { true }
      create_parser("startxref\n5\n%%EOF\ntartxref\n3\n%%EOF")
      exp = assert_raises(HexaPDF::MalformedPDFError) { @parser.startxref_offset }
      assert_match(/missing startxref keyword/, exp.message)
    end
  end

  describe "file_header_version" do
    it "returns the correct version" do
      assert_equal('1.7', @parser.file_header_version)
    end

    it "fails if the header is mangled" do
      create_parser("%PDF-1\n")
      exp = assert_raises(HexaPDF::MalformedPDFError) { @parser.file_header_version }
      assert_match(/file header/, exp.message)
    end

    it "fails if the header is missing" do
      create_parser("no header")
      exp = assert_raises(HexaPDF::MalformedPDFError) { @parser.file_header_version }
      assert_match(/file header/, exp.message)
    end

    it "ignores junk at the beginning of the file and correctly calculates offset" do
      create_parser("junk" * 200 + "\n%PDF-1.4\n")
      assert_equal('1.4', @parser.file_header_version)
      assert_equal(801, @parser.instance_variable_get(:@header_offset))
    end
  end

  it "xref_section?" do
    assert(@parser.xref_section?(@parser.startxref_offset))
    refute(@parser.xref_section?(53))
  end

  describe "parse_xref_section_and_trailer" do
    it "works on a section with multiple sub sections" do
      section, trailer = @parser.parse_xref_section_and_trailer(@parser.startxref_offset)
      assert_equal({Test: 'now'}, trailer)
      assert_equal(HexaPDF::XRefSection.free_entry(0, 65535), section[0, 65535])
      assert_equal(HexaPDF::XRefSection.free_entry(3, 65535), section[3, 65535])
      assert_equal(HexaPDF::XRefSection.in_use_entry(1, 0, 10), section[1])
    end

    it "works for an empty section" do
      create_parser("xref\n0 0\ntrailer\n<</Name /Value >>\n")
      _, trailer = @parser.parse_xref_section_and_trailer(0)
      assert_equal({Name: :Value}, trailer)
    end

    it "handles xref type=n with offset=0" do
      create_parser("xref\n0 2\n0000000000 00000 n \n0000000000 00000 n \ntrailer\n<<>>\n")
      section, _trailer = @parser.parse_xref_section_and_trailer(0)
      assert_equal(HexaPDF::XRefSection.free_entry(1, 0), section[1])
    end

    it "handles xref type=n with gen>65535" do
      create_parser("xref\n0 2\n0000000000 00000 n \n0000000000 65536 n \ntrailer\n<<>>\n")
      section, _trailer = @parser.parse_xref_section_and_trailer(0)
      assert_equal(HexaPDF::XRefSection.free_entry(1, 65536), section[1])
    end

    it "handles xref with missing whitespace at end" do
      create_parser("xref\n0 2\n0000000000 00000 n\n0000000000 65536 n\ntrailer\n<<>>\n")
      section, _trailer = @parser.parse_xref_section_and_trailer(0)
      assert_equal(HexaPDF::XRefSection.free_entry(1, 65536), section[1])
    end

    it "fails if the xref keyword is missing/mangled" do
      create_parser("xTEf\n0 d\n0000000000 00000 n \ntrailer\n<< >>\n")
      exp = assert_raises(HexaPDF::MalformedPDFError) { @parser.parse_xref_section_and_trailer(0) }
      assert_match(/keyword xref/, exp.message)
    end

    it "fails if a sub section header is mangled" do
      create_parser("xref\n0 d\n0000000000 00000 n \ntrailer\n<< >>\n")
      exp = assert_raises(HexaPDF::MalformedPDFError) { @parser.parse_xref_section_and_trailer(0) }
      assert_match(/invalid cross-reference subsection/i, exp.message)
    end

    it "fails if a sub section entry is mangled" do
      create_parser("xref\n0 2\n000a000000 00000 n\n0000000000 65535 n\ntrailer\n<<>>\n")
      exp = assert_raises(HexaPDF::MalformedPDFError) { @parser.parse_xref_section_and_trailer(0) }
      assert_match(/invalid cross-reference entry/i, exp.message)
    end

    it "fails if there is no trailer" do
      create_parser("xref\n0 1\n0000000000 00000 n \n")
      exp = assert_raises(HexaPDF::MalformedPDFError) { @parser.parse_xref_section_and_trailer(0) }
      assert_match(/keyword trailer/i, exp.message)
    end

    it "fails if the trailer is not a PDF dictionary" do
      create_parser("xref\n0 1\n0000000000 00000 n \ntrailer\n(base)")
      exp = assert_raises(HexaPDF::MalformedPDFError) { @parser.parse_xref_section_and_trailer(0) }
      assert_match(/dictionary/, exp.message)
    end

    describe "invalid numbering of main xref section" do
      it "handles the xref if the numbering is off by N" do
        create_parser(" 1 0 obj 1 endobj\n" \
                      "xref\n1 2\n0000000000 65535 f \n0000000001 00000 n \ntrailer\n<<>>\n")
        section, _trailer = @parser.parse_xref_section_and_trailer(17)
        assert_equal(HexaPDF::XRefSection.in_use_entry(1, 0, 1), section[1])
      end

      it "fails if the first entry is not the one for oid=0" do
        create_parser(" 1 0 obj 1 endobj\n" \
                      "xref\n1 2\n0000000000 00005 f \n0000000001 00000 n \ntrailer\n<<>>\n")
        exp = assert_raises(HexaPDF::MalformedPDFError) { @parser.parse_xref_section_and_trailer(17) }
        assert_match(/Main.*invalid numbering/i, exp.message)

        create_parser(" 1 0 obj 1 endobj\n" \
                      "xref\n1 2\n0000000001 00000 n \n0000000001 00000 n \ntrailer\n<<>>\n")
        exp = assert_raises(HexaPDF::MalformedPDFError) { @parser.parse_xref_section_and_trailer(17) }
        assert_match(/Main.*invalid numbering/i, exp.message)
      end

      it "fails if the tested entry position is invalid" do
        create_parser(" 1 0 obj 1 endobj\n" \
                      "xref\n1 2\n0000000000 65535 f \n0000000005 00000 n \ntrailer\n<<>>\n")
        exp = assert_raises(HexaPDF::MalformedPDFError) { @parser.parse_xref_section_and_trailer(17) }
        assert_match(/Main.*invalid numbering/i, exp.message)
      end

      it "fails if the tested entry position's oid doesn't match the corrected entry oid" do
        create_parser(" 2 0 obj 1 endobj\n" \
                      "xref\n1 2\n0000000000 65535 f \n0000000001 00000 n \ntrailer\n<<>>\n")
        exp = assert_raises(HexaPDF::MalformedPDFError) { @parser.parse_xref_section_and_trailer(17) }
        assert_match(/Main.*invalid numbering/i, exp.message)
      end
    end

    describe "with strict parsing" do
      before do
        @document.config['parser.on_correctable_error'] = proc { true }
      end

      it "fails if xref type=n with offset=0" do
        create_parser("xref\n0 2\n0000000000 00000 n \n0000000000 00000 n \ntrailer\n<<>>\n")
        exp = assert_raises(HexaPDF::MalformedPDFError) { @parser.parse_xref_section_and_trailer(0) }
        assert_match(/invalid.*cross-reference entry/i, exp.message)
      end

      it " fails xref type=n with gen>65535" do
        create_parser("xref\n0 2\n0000000000 00000 n \n0000000000 65536 n \ntrailer\n<<>>\n")
        exp = assert_raises(HexaPDF::MalformedPDFError) { @parser.parse_xref_section_and_trailer(0) }
        assert_match(/invalid.*cross-reference entry/i, exp.message)
      end

      it "fails if trailing second whitespace is missing" do
        create_parser("xref\n0 1\n0000000000 00000 n\ntrailer\n<<>>\n")
        exp = assert_raises(HexaPDF::MalformedPDFError) { @parser.parse_xref_section_and_trailer(0) }
        assert_match(/invalid.*cross-reference entry/i, exp.message)
      end

      it "fails if the main cross-reference section has invalid numbering" do
        create_parser("xref\n1 1\n0000000001 00000 n \ntrailer\n<<>>\n")
        exp = assert_raises(HexaPDF::MalformedPDFError) { @parser.parse_xref_section_and_trailer(0) }
        assert_match(/Main.*invalid numbering/i, exp.message)
      end
    end
  end

  describe "load_revision" do
    it "works for a simple cross-reference section" do
      xref_section, trailer = @parser.load_revision(@parser.startxref_offset)
      assert_equal({Test: 'now'}, trailer)
      assert(xref_section[1].in_use?)
    end

    it "works for a cross-reference stream" do
      xref_section, trailer = @parser.load_revision(212)
      assert_equal({Size: 2, Type: :XRef}, trailer)
      assert(xref_section[1].in_use?)
    end

    it "fails if another object is found instead of a cross-reference stream" do
      exp = assert_raises(HexaPDF::MalformedPDFError) { @parser.load_revision(10) }
      assert_match(/not a cross-reference stream/, exp.message)
    end

    it "fails if the cross-reference stream is missing data" do
      @parse_io.string[287..288] = ''
      exp = assert_raises(HexaPDF::MalformedPDFError) { @parser.load_revision(212) }
      assert_match(/missing data/, exp.message)
      assert_equal(212, exp.pos)
    end

    it "fails on strict parsing if the cross-reference stream doesn't contain an entry for itself" do
      @document.config['parser.on_correctable_error'] = proc { true }
      create_parser("2 0 obj\n<</Type/XRef/Length 3/W [1 1 1]/Size 1>>" \
                    "stream\n\x01\x0A\x00\nendstream endobj")
      exp = assert_raises(HexaPDF::MalformedPDFError) { @parser.load_revision(0) }
      assert_match(/entry for itself/, exp.message)
    end
  end

  describe "reconstruct_revision" do
    before do
      @document.config['parser.try_xref_reconstruction'] = true
      @xref = HexaPDF::XRefSection.in_use_entry(1, 0, 100)
    end

    it "can tell us if the cross-reference table was reconstructed" do
      create_parser("1 0 obj\n5\nendobj\ntrailer\n<</Size 1>>")
      @parser.load_object(@xref)
      assert(@parser.reconstructed?)
    end

    it "serially parses the contents" do
      create_parser("1 0 obj\n5 endobj\n1 0 obj\n6\nendobj\ntrailer\n<</Size 1>>")
      assert_equal(6, @parser.load_object(@xref).value)
    end

    it "uses a security handler for decrypting indirect objects if necessary" do
      handler = Minitest::Mock.new
      handler.expect(:decrypt, HexaPDF::Object.new(:result, oid: 1), [HexaPDF::Object])
      @document.instance_variable_set(:@security_handler, handler)
      create_parser("1 0 obj\n6\nendobj\ntrailer\n<</Size 1>>")
      assert_equal(:result, @parser.load_object(@xref).value)
      assert(handler.verify)
    end

    it "ignores parts where the starting line is split across lines" do
      create_parser("1 0 obj\n5\nendobj\n1 0\nobj\n6\nendobj\ntrailer\n<</Size 1>>")
      assert_equal(5, @parser.load_object(@xref).value)
    end

    it "handles the case when the specified object had an xref entry but is not found" do
      create_parser("3 0 obj\n5\nendobj\ntrailer\n<</Size 1>>")
      assert(@parser.load_object(@xref).null?)
    end

    it "handles cases where the line contains an invalid string that exceeds the read buffer" do
      create_parser("(1" + "(abc" * 32188 + "\n1 0 obj\n6\nendobj\ntrailer\n<</Size 1>>")
      assert_equal(6, @parser.load_object(@xref).value)
    end

    it "handles pathalogical cases which contain many opened literal strings" do
      time = Time.now
      create_parser("(1" + "(abc\n" * 10000 + "\n1 0 obj\n6\nendobj\ntrailer\n<</Size 1>>")
      assert_equal(6, @parser.load_object(@xref).value)
      assert(Time.now - time < 0.5, "Xref reconstruction takes too long")
    end

    it "ignores invalid objects" do
      create_parser("1 x obj\n5\nendobj\n1 0 xobj\n6\nendobj\n1 0 obj 4\nendobj\ntrailer\n<</Size 1>>")
      assert_equal(4, @parser.load_object(@xref).value)
    end

    it "handles an invalid object as first object" do
      create_parser("2 0 obj\n(a(b\nendobj\n1 0 obj\n6\nendobj #)(\ntrailer\n<</Size 1>>")
      assert_equal(6, @parser.load_object(@xref).value)
    end

    it "ignores invalid lines" do
      create_parser("1 0 obj\n5\nendobj\nhello there\n1 0 obj\n6\nendobj\ntrailer\n<</Size 1>>")
      assert_equal(6, @parser.load_object(@xref).value)
    end

    it "resets the header offset" do
      create_parser("1 0 obj\n5\nendobj\ntrailer\n<</Size 1>>")
      @parser.instance_variable_set(:@header_offset, 5)
      assert_equal(5, @parser.load_object(@xref).value)
    end

    it "uses the last trailer" do
      create_parser("trailer <</Size 1>>\ntrailer <</Size 2/Prev 342>>")
      assert_equal({Size: 2}, @parser.reconstructed_revision.trailer.value)
    end

    it "uses the first trailer in case of a linearized file" do
      create_parser("1 0 obj\n<</Linearized true>>\nendobj\ntrailer <</Size 1/Prev 34>>\ntrailer <</Size 2>>")
      assert_equal({Size: 1}, @parser.reconstructed_revision.trailer.value)
    end

    it "tries the trailer specified at the startxref position if no other is found" do
      create_parser("1 0 obj\n5\nendobj\nquack xref trailer <</Size 1/Prev 5>>\nstartxref\n22\n%%EOF")
      assert_equal({Size: 1}, @parser.reconstructed_revision.trailer.value)
    end

    it "constructs a trailer with a /Root entry if no valid trailer was found" do
      create_parser("1 0 obj\n<</Type /Catalog/Pages 2 0 R>>\nendobj\nxref trailer <</Size 1/Prev 5\n%%EOF")
      assert_equal({Root: HexaPDF::Reference.new(1, 0)}, @parser.reconstructed_revision.trailer.value)
    end

    it "fails if no valid trailer is found and couldn't be constructed" do
      create_parser("1 0 obj\n5\nendobj\nquack trailer <</Size 1>>\nstartxref\n22\n%%EOF")
      assert_raises(HexaPDF::MalformedPDFError) { @parser.reconstructed_revision.trailer }
    end

    it "fails if no valid trailer is found" do
      create_parser("1 0 obj\n5\nendobj")
      assert_raises(HexaPDF::MalformedPDFError) { @parser.load_object(@xref) }
    end
  end
end
