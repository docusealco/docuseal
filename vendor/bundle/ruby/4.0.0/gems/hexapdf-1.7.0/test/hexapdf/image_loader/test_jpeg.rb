# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/document'
require 'hexapdf/image_loader/jpeg'

describe HexaPDF::ImageLoader::JPEG do
  before do
    @images = Dir.glob(File.join(TEST_DATA_DIR, 'images', '*.jpg'))
    @doc = HexaPDF::Document.new
    @loader = HexaPDF::ImageLoader::JPEG
  end

  describe "handles?" do
    it "works for jpeg files" do
      @images.each do |image|
        assert(@loader.handles?(image))
        File.open(image, 'rb') {|file| assert(@loader.handles?(file)) }
      end
    end
  end

  describe "load" do
    it "can work with an IO stream instead of a file" do
      jpeg = @images.grep(/rgb\.jpg/).first
      File.open(jpeg, 'rb') do |file|
        image = @loader.load(@doc, file)
        assert_equal(File.binread(jpeg), image.stream)
      end
    end

    it "works for a grayscale jpeg" do
      jpeg = @images.grep(/gray\.jpg/).first
      image = @loader.load(@doc, jpeg)
      assert_equal(5, image[:Width])
      assert_equal(5, image[:Height])
      assert_equal(:DeviceGray, image[:ColorSpace])
      assert_equal(File.binread(jpeg), image.stream)
    end

    it "works for a standard RGB jpeg" do
      jpeg = @images.grep(/rgb\.jpg/).first
      image = @loader.load(@doc, jpeg)
      assert_equal(5, image[:Width])
      assert_equal(5, image[:Height])
      assert_equal(:DeviceRGB, image[:ColorSpace])
      assert_equal(File.binread(jpeg), image.stream)
    end

    it "works for a jpeg image containing fill bytes" do
      jpeg = @images.grep(/fillbytes\.jpg/).first
      image = @loader.load(@doc, jpeg)
      assert_equal(5, image[:Width])
      assert_equal(5, image[:Height])
      assert_equal(:DeviceRGB, image[:ColorSpace])
      assert_equal(File.binread(jpeg), image.stream)
    end

    it "works for a CMYK jpeg" do
      jpeg = @images.grep(/cmyk\.jpg/).first
      image = @loader.load(@doc, jpeg)
      assert_equal(5, image[:Width])
      assert_equal(5, image[:Height])
      assert_equal(:DeviceCMYK, image[:ColorSpace])
      assert_equal([1.0, 0.0, 1.0, 0.0, 1.0, 0.0, 1.0, 0.0], image[:Decode].value)
      assert_equal(File.binread(jpeg), image.stream)
    end

    it "works for a YCCK jpeg" do
      jpeg = @images.grep(/ycck\.jpg/).first
      image = @loader.load(@doc, jpeg)
      assert_equal(5, image[:Width])
      assert_equal(5, image[:Height])
      assert_equal(:DeviceCMYK, image[:ColorSpace])
      refute(image.key?(:Decode))
      assert_equal(File.binread(jpeg), image.stream)
    end

    it "fails if the JPEG is corrupt" do
      exp = assert_raises(HexaPDF::Error) do
        @loader.load(@doc, StringIO.new("some non JPEG data"))
      end
      assert_match(/marker code/, exp.message)
    end

    it "fails if the JPEG contains components with more/less bits than 8" do
      exp = assert_raises(HexaPDF::Error) do
        @loader.load(@doc, StringIO.new("\xFF\xD8\xFF\xC0\x00\x06\x04\x00\x05\x00\x05\x03".b))
      end
      assert_match(/Unsupported.*bits.*4/, exp.message)
    end
  end
end
