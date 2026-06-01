# -*- encoding: utf-8 -*-

require 'test_helper'
require 'tempfile'
require 'stringio'
require 'hexapdf/type/file_specification'
require 'hexapdf/document'

describe HexaPDF::Type::FileSpecification do
  before do
    @doc = HexaPDF::Document.new
    @obj = HexaPDF::Type::FileSpecification.new({}, document: @doc)
  end

  it "can be asked whether it is a URL or a file" do
    refute(@obj.url?)
    @obj[:FS] = :URL
    assert(@obj.url?)
  end

  describe "path" do
    it "returns the first useable file spec string" do
      @obj[:DOS] = 'hälo'.b
      assert_equal('hälo'.b, @obj.path)

      @obj[:UF] = 'hälo'
      assert_equal('hälo', @obj.path)
    end

    it "unescapes the path string according to the PDF spec" do
      @obj[:F] = "dir/in\\/out\\too"
      assert_equal('dir/in/out/too', @obj.path)
    end
  end

  describe "path=" do
    it "only sets /UF and /F, deleting /Mac, /Unix, /DOS entries if they exist" do
      @obj[:Unix] = @obj[:Mac] = @obj[:DOS] = 'a'
      @obj.path = 'file/test'
      refute_same(@obj.value[:UF], @obj.value[:F])
      assert_equal('file/test', @obj[:UF])
      assert_equal('file/test', @obj[:F])
      refute(@obj.key?(:Unix))
      refute(@obj.key?(:Mac))
      refute(@obj.key?(:DOS))
    end

    it 'resets the /FS value' do
      @obj[:FS] = :Something
      @obj.path = 'file'
      refute(@obj.key?(:FS))
    end
  end

  describe "url=" do
    it "sets the path and the file system entry" do
      url = 'http://example.com/some?test=ing#done'
      @obj.url = url
      assert_equal(url, @obj.path)
      assert(@obj.url?)
    end

    it "fails if the provided string is not a valid URL" do
      assert_raises(HexaPDF::Error) { @obj.url = "a false \\ URL" }
    end
  end

  describe "embedded_file?" do
    it "checks whether the specification has an embedded file" do
      refute(@obj.embedded_file?)
      @obj[:EF] = {UF: {}}
      assert(@obj.embedded_file?)
    end
  end

  describe "embedded_file_stream" do
    it "returns the associated embedded file stream" do
      assert_nil(@obj.embedded_file_stream)
      @obj[:EF] = {F: 'data'}
      assert_equal('data', @obj.embedded_file_stream)
    end
  end

  describe "embed/unembed" do
    before do
      @file = Tempfile.new('file-embed-test')
      @file.write("embed-test")
      @file.close
    end

    after do
      @file.unlink
    end

    it "requires the name argument when given an IO object" do
      assert_raises(ArgumentError) { @obj.embed(StringIO.new) }
    end

    it "embeds the given file and registers it with the global name registry" do
      stream = @obj.embed(@file.path, mime_type: 'application/xml')
      assert_equal(stream, @obj[:EF][:UF])
      assert_equal(stream, @obj[:EF][:F])
      assert_equal(File.basename(@file.path), @obj.path)
      assert_equal(:'application/xml', stream[:Subtype])
      assert_equal(@obj, @doc.catalog[:Names][:EmbeddedFiles].find_entry(@obj.path))
      assert_equal(:FlateDecode, stream[:Filter])
      assert_equal('embed-test', stream.stream)
    end

    it "embeds the given IO object" do
      @file.open
      stream = @obj.embed(@file, name: 'test')
      assert_equal('embed-test', stream.stream)

      stream = @obj.embed(StringIO.new('test'), name: 'test')
      assert_equal('test', stream.stream)
    end

    it "allows overriding the name" do
      @obj.embed(@file.path, name: 'test')
      assert_equal('test', @obj.path)
      assert_equal(@obj, @doc.catalog[:Names][:EmbeddedFiles].find_entry('test'))
    end

    it "doesn't register the embedded file if instructed to do so" do
      @obj.embed(@file.path, name: 'test', register: false)
      assert_nil(@doc.catalog[:Names])
    end

    it "replaces the value of an already registered name" do
      (@doc.catalog[:Names] ||= {})[:EmbeddedFiles] = {}
      @doc.catalog[:Names][:EmbeddedFiles].add_entry('test', 'data')
      @obj.embed(@file.path, name: 'test')
      assert_equal(@obj, @doc.catalog[:Names][:EmbeddedFiles].find_entry('test'))
    end

    it "unembeds an already embedded file before embedding the new one" do
      @obj.embed(@file.path, name: 'test1')
      @obj.embed(@file.path, name: 'test2')
      assert_equal([['test2', @obj]], @doc.catalog[:Names][:EmbeddedFiles].each_entry.to_a)
    end
  end
end
