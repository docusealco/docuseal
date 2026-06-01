# -*- encoding: utf-8 -*-

require 'test_helper'
require 'stringio'
require 'tempfile'
require 'hexapdf/document'

describe HexaPDF::Document::Files do
  before do
    @doc = HexaPDF::Document.new
    @data = "embed-test"
    @file = Tempfile.new('file-embed-test')
    @file.write(@data)
    @file.close
  end

  after do
    @file.unlink
  end

  describe "add" do
    it "adds a file using a filename and embeds it" do
      spec = @doc.files.add(@file.path)
      assert_equal(File.basename(@file.path), spec.path)
      assert_equal(@data, spec.embedded_file_stream.stream)
    end

    it "adds a reference to a file" do
      spec = @doc.files.add(@file.path, embed: false)
      assert_equal(File.basename(@file.path), spec.path)
      refute(spec.embedded_file?)
    end

    it "adds a file using an IO" do
      @file.open
      spec = @doc.files.add(@file, name: 'test', embed: false)
      assert_equal('test', spec.path)
      assert_equal(@data, spec.embedded_file_stream.stream)
    end

    it "optionally sets the description of the file" do
      spec = @doc.files.add(@file.path, description: 'Some file')
      assert_equal('Some file', spec[:Desc])
    end

    it "optionally sets the MIME type of an embedded file" do
      spec = @doc.files.add(@file.path, mime_type: 'application/pdf')
      assert_equal(:'application/pdf', spec.embedded_file_stream[:Subtype])
    end

    it "requires the name argument when given an IO object" do
      assert_raises(ArgumentError) { @doc.files.add(StringIO.new) }
    end
  end

  describe "each" do
    it "iterates only over named embedded files and file annotations if search=false" do
      @doc.add({Type: :Filespec})
      spec1 = @doc.files.add(__FILE__)
      spec2 = @doc.add({Type: :Filespec})
      @doc.pages.add # page without annot
      @doc.pages.add[:Annots] = [
        {Subtype: :FileAttachment, Rect: [0, 0, 0, 0], FS: HexaPDF::Reference.new(spec1.oid, spec1.gen)},
        {Subtype: :FileAttachment, Rect: [0, 0, 0, 0], FS: spec2},
        {},
      ]
      assert_equal([spec1, spec2], @doc.files.to_a)
    end

    it "iterates over all file specifications of the document if search=true" do
      specs = []
      specs << @doc.add({Type: :Filespec})
      specs << @doc.add({Type: :Filespec})
      assert_equal(specs, @doc.files.each(search: true).to_a)
    end
  end
end
