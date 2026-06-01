# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/filter'
require 'stringio'
require 'tempfile'

describe HexaPDF::Filter do
  before do
    @obj = HexaPDF::Filter
    @str = +''
    40.times { @str << [rand(2**32)].pack('N') }
  end

  describe "source_from_proc" do
    it "returns the whole string, once" do
      fib = @obj.source_from_proc { @str }
      assert_equal(@str, collector(fib))
      assert_equal('', collector(fib))
    end

    it "returns the correct length of the fiber" do
      str = "\u{FEFF}Öl"
      fib = @obj.source_from_proc { str }
      assert_equal(6, fib.length)
    end
  end

  describe "source_from_string" do
    it "doesn't modify the given string" do
      str = @str.dup
      @obj.source_from_string(@str).resume.slice!(0, 10)
      assert_equal(str, @str)
    end

    it "returns the whole string" do
      assert_equal(@str, collector(@obj.source_from_string(@str)))
    end

    it "returns the correct size of the fiber" do
      str = "\u{FEFF}Öl"
      fib = @obj.source_from_string(str)
      assert_equal(6, fib.length)
    end
  end

  describe "source_from_io" do
    before do
      @io = StringIO.new(@str.dup)
    end

    def from_io(**opts)
      collector(@obj.source_from_io(@io, **opts))
    end

    it "converts an IO into a source via #source_from_io" do
      assert_equal(@str, from_io)

      assert_equal(@str, from_io(pos: -10))
      assert_equal(@str[10..-1], from_io(pos: 10))
      assert_equal("", from_io(pos: 200))

      assert_equal("", from_io(length: 0))
      assert_equal(@str[0...100], from_io(length: 100))
      assert_equal(@str, from_io(length: -15))
      assert_equal(100, @obj.source_from_io(@io, length: 100).length)

      assert_equal(@str, from_io(chunk_size: -15))
      assert_equal(@str, from_io(chunk_size: 0))
      assert_equal(@str, from_io(chunk_size: 100))
      assert_equal(@str, from_io(chunk_size: 200))

      assert_equal(@str[0...20], from_io(length: 20, chunk_size: 100))
      assert_equal(@str[20...40], from_io(pos: 20, length: 20, chunk_size: 100))
      assert_equal(@str[20...40], from_io(pos: 20, length: 20, chunk_size: 5))
    end

    it "fails if not all requested bytes could be read" do
      assert_raises(HexaPDF::FilterError) { from_io(length: 200) }
    end
  end

  describe "source_from_file" do
    before do
      @file = Tempfile.new('hexapdf-filter', binmode: true)
      @file.write(@str)
      @file.close
    end

    after do
      @file.unlink
    end

    def from_file(**opts)
      @obj.source_from_file(@file.path, **opts)
    end

    it "converts the file into a source fiber" do
      assert_equal(@str, collector(from_file))
      assert_equal(@file.size, from_file.length)

      assert_equal(@str[100..-1], collector(from_file(pos: 100)))
      assert_equal(@str[100..-1].length, from_file(pos: 100).length)

      assert_equal(@str[50..99], collector(from_file(pos: 50, length: 50)))
      assert_equal(50, from_file(length: 50).length)
    end

    it "fails if more bytes are requested than stored in the file" do
      assert_raises(HexaPDF::FilterError) { collector(from_file(length: 200)) }
    end
  end

  it "collects the binary string from a source via #string_from_source" do
    source = @obj.source_from_io(StringIO.new(@str), chunk_size: 50)
    result = @obj.string_from_source(source)
    assert_equal(@str, result)
    assert_equal(Encoding::BINARY, result.encoding)
  end
end
