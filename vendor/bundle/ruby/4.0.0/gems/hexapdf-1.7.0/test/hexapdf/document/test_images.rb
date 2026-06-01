# -*- encoding: utf-8 -*-

require 'test_helper'
require 'stringio'
require 'hexapdf/document'

describe HexaPDF::Document::Images do
  before do
    @doc = HexaPDF::Document.new
  end

  describe "add" do
    describe "using a custom image loader" do
      before do
        @loader = Object.new
        @loader.define_singleton_method(:handles?) {|*| true }
        @loader.define_singleton_method(:load) do |doc, s|
          s = HexaPDF::StreamData.new(s) if s.kind_of?(IO)
          doc.add({Type: :XObject, Subtype: :Image}, stream: s)
        end
        @doc.config['image_loader'].unshift(@loader)
      end

      it "adds an image using a filename" do
        data = 'test'
        image = @doc.images.add(data)
        assert_equal(data, image.stream)
        assert_equal(File.absolute_path(data), image.source_path)
      end

      it "adds an image using an IO" do
        File.open(__FILE__, 'rb') do |file|
          image = @doc.images.add(file)
          assert_equal(File.binread(__FILE__), image.stream)
          assert_equal(File.absolute_path(__FILE__), image.source_path)
        end
      end

      it "doesn't add an image twice" do
        data = 'test'
        image = @doc.images.add(data)
        image1 = @doc.images.add(data)
        assert_same(image, image1)
      end
    end

    it "fails if the needed image loader can't be resolved" do
      @doc.config['image_loader'].unshift('SomeUnknownConstantHere')
      exp = assert_raises(HexaPDF::Error) { @doc.images.add(StringIO.new('test')) }
      assert_match(/image loader from configuration/, exp.message)
    end

    it "fails if no image loader is found" do
      exp = assert_raises(HexaPDF::Error) { @doc.images.add(StringIO.new('test')) }
      assert_match(/suitable image loader/, exp.message)
    end
  end

  describe "each" do
    it "iterates over all non-mask images" do
      @doc.add(5)
      images = []
      images << @doc.add({Type: :XObject, Subtype: :Image})
      images << @doc.add({Type: :XObject, Subtype: :Image, Mask: [5, 6]})
      images << @doc.add({Type: :XObject, Subtype: :Image,
                          Mask: @doc.add({Type: :XObject, Subtype: :Image})})
      images << @doc.add({Type: :XObject, Subtype: :Image,
                          SMask: @doc.add({Type: :XObject, Subtype: :Image})})
      assert_equal(images.sort, @doc.images.to_a.sort)
    end
  end
end
