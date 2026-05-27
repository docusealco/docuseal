# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/type/xref_stream'

describe HexaPDF::Type::XRefStream do
  before do
    @doc = Object.new
    @doc.instance_variable_set(:@version, '1.5')
    def (@doc).deref(obj); obj; end
    def (@doc).wrap(obj, **); obj; end
    @obj = HexaPDF::Type::XRefStream.new({}, oid: 1, document: @doc, stream: '')
  end

  describe "xref_section" do
    it "handles a missing /Index field" do
      @obj[:Size] = 1
      @obj[:W] = [2, 2, 2]
      @obj.stream = [0, 65535, 1].pack('n*')
      section = @obj.xref_section
      assert_equal(1, section.each.to_a.size)
      assert(section[0, 1].free?)
    end

    it "handles the three different field types and ignores unknown types" do
      @obj[:Index] = [0, 4]
      @obj[:W] = [2, 2, 2]
      @obj.stream = [0, 65535, 1, 1, 200, 0, 2, 1, 5, 3, 0, 0].pack('n*')
      section = @obj.xref_section
      assert(section[0, 1].free?)
      assert(section[1, 0].in_use?)
      assert_equal(200, section[1, 0].pos)
      assert(section[2, 0].compressed?)
      assert_equal(1, section[2, 0].objstm)
      assert_equal(5, section[2, 0].pos)
    end

    it "uses the default value for field one if its length is zero" do
      @obj[:Index] = [3, 1]
      @obj[:W] = [0, 1, 1]
      @obj.stream = [200, 0].pack('C*')
      section = @obj.xref_section
      assert(section[3, 0].in_use?)
      assert_equal(200, section[3, 0].pos)
    end

    it "uses the default value for field three if its length is zero" do
      @obj[:Index] = [3, 1]
      @obj[:W] = [1, 1, 0]
      @obj.stream = [1, 200].pack('C*')
      section = @obj.xref_section
      assert(section[3, 0].in_use?)
      assert_equal(200, section[3, 0].pos)
    end

    it "uses the default values for field one/three if their lengths are zero" do
      @obj[:Index] = [3, 1]
      @obj[:W] = [0, 1, 0]
      @obj.stream = [200].pack('C*')
      section = @obj.xref_section
      assert(section[3, 0].in_use?)
      assert_equal(200, section[3, 0].pos)
    end

    it "can handle multiple subsections" do
      @obj[:Index] = [3, 1, 10, 1]
      @obj[:W] = [0, 1, 0]
      @obj.stream = [200, 250].pack('C*')
      section = @obj.xref_section
      assert(section[3, 0].in_use?)
      assert_equal(200, section[3, 0].pos)
      assert(section[10, 0].in_use?)
      assert_equal(250, section[10, 0].pos)
    end

    it "fails if there is not enough data available" do
      @obj[:Index] = [1, 2, 10, 4]
      @obj[:W] = [1, 2, 1]
      @obj.stream = "abcd"
      assert_raises(HexaPDF::MalformedPDFError) { @obj.xref_section }
    end
  end

  describe "trailer" do
    it "returns a dictionary without xref stream specific values" do
      @obj[:Size] = 5
      @obj[:ID] = ["a", "b"]
      @obj[:Root] = 'x'
      @obj[:Index] = [0, 5]
      @obj[:W] = [1, 2, 2]
      dict = @obj.trailer
      assert_equal(4, dict.length)
      assert_equal(5, dict[:Size])
      assert_equal(["a", "b"], dict[:ID])
      assert_equal('x', dict[:Root])
      assert_equal(:XRef, dict[:Type])
    end
  end

  describe "update_with_xref_section_and_trailer" do
    before do
      @section = HexaPDF::XRefSection.new
      @section.add_free_entry(0, 65535)
      @section.add_in_use_entry(1, 0, 200)
      @section.add_compressed_entry(2, 1, 5)
    end

    it "sets all necessary dictionary values" do
      @obj.update_with_xref_section_and_trailer(@section, Size: 100)
      assert_equal(:XRef, @obj.value[:Type])
      assert_equal(100, @obj.value[:Size])
      assert_equal([0, 3], @obj.value[:Index])
      assert_equal([1, 1, 2], @obj.value[:W])

      @section.add_in_use_entry(1, 0, 256**2)
      @obj.update_with_xref_section_and_trailer(@section, Size: 100)
      assert_equal([1, 4, 2], @obj.value[:W])
    end

    it "updates the stream with the new information" do
      @obj.update_with_xref_section_and_trailer(@section, Size: 100)
      section = @obj.xref_section
      @section.each do |oid, gen, data|
        if section[oid, gen] == data
          section.delete(oid)
        else
          flunk("Data for object p#{oid}, #{gen}] is not equal")
        end
      end
      assert_equal(0, section.each.to_a.size)
    end

    it "can write multiple subsections" do
      @section.add_free_entry(10, 1)
      @section.add_in_use_entry(11, 1, 100)
      @obj.update_with_xref_section_and_trailer(@section, Size: 100)
      assert_equal([0, 3, 10, 2], @obj.value[:Index])
    end

    it "fails for unsupported cross-reference entry types" do
      @section.send(:[]=, 3, 0, HexaPDF::XRefSection::Entry.new(:unknown, 3, 0))
      assert_raises(HexaPDF::Error) { @obj.update_with_xref_section_and_trailer(@section, {}) }
    end
  end

  it "sets /Size and /W to dummy values to make validation work" do
    assert(@obj.validate(auto_correct: false))
  end
end
