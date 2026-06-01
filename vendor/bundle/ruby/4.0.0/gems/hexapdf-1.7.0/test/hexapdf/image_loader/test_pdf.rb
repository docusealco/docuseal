# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/document'
require 'hexapdf/image_loader/pdf'

describe HexaPDF::ImageLoader::PDF do
  before do
    @doc = HexaPDF::Document.new
    @loader = HexaPDF::ImageLoader::PDF
    @pdf = File.join(TEST_DATA_DIR, 'minimal.pdf')
  end

  describe "handles?" do
    it "works for PDF files" do
      assert(@loader.handles?(@pdf))
      File.open(@pdf, 'rb') {|file| assert(@loader.handles?(file)) }
    end
  end

  describe "load" do
    it "works for PDF files using a File object" do
      File.open(@pdf, 'rb') do |file|
        form = @loader.load(@doc, file)
        assert_equal(:Form, form[:Subtype])
      end
    end

    it "works for PDF files using a string object and use_stringio=true" do
      @doc.config['image_loader.pdf.use_stringio'] = true
      form = @loader.load(@doc, @pdf)
      assert_equal(:Form, form[:Subtype])
    end

    it "works for PDF files using a string object and use_stringio=false" do
      @doc.config['image_loader.pdf.use_stringio'] = false
      form = @loader.load(@doc, @pdf)
      assert_equal(:Form, form[:Subtype])
    ensure
      ObjectSpace.each_object(File) do |file|
        file.close if file.path == @pdf && !file.closed?
      end
    end
  end
end
