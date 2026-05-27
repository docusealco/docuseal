# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/document'
require 'hexapdf/image_loader/png'

describe HexaPDF::ImageLoader::PNG do
  before do
    @images = Dir.glob(File.join(TEST_DATA_DIR, 'images', '*.png'))
    @doc = HexaPDF::Document.new
    @loader = HexaPDF::ImageLoader::PNG
  end

  describe "handles?" do
    it "works for png files" do
      @images.each do |image|
        assert(@loader.handles?(image))
        File.open(image, 'rb') {|file| assert(@loader.handles?(file)) }
      end
    end
  end

  def build_png(header_data, others = '')
    @loader::MAGIC_FILE_MARKER + [13, "IHDR", *header_data].pack('NA4N2C5N') + others +
      [0, "IEND", 0].pack('NA4N')
  end

  def assert_image(image, width, height, bpc, color_space, stream)
    assert_equal(width, image[:Width])
    assert_equal(height, image[:Height])
    assert_equal(bpc, image[:BitsPerComponent])
    assert_equal(color_space, @doc.unwrap(image[:ColorSpace])) if color_space
    data = stream.map {|row| [row.map {|i| i.to_s(2).rjust(bpc, '0') }.join].pack('B*') }.join
    assert_equal(data, image.stream)
  end

  # NOTE: colors and image data for comparisons were extracted using GIMP and its color tools
  describe "load" do
    before do
      @greyscale_1bit_data = [[1, 1, 0, 0, 0],
                              [1, 1, 0, 1, 0],
                              [1, 1, 1, 1, 1],
                              [0, 1, 0, 1, 0],
                              [0, 0, 0, 0, 0]]
    end

    it "can work with an IO stream instead of a file" do
      png = @images.grep(/greyscale-1bit\.png/).first
      File.open(png, 'rb') do |file|
        image = @loader.load(@doc, file)
        assert_image(image, 5, 5, 1, :DeviceGray, @greyscale_1bit_data)
      end
    end

    it "works for a 1-bit greyscale png" do
      png = @images.grep(/greyscale-1bit\.png/).first
      image = @loader.load(@doc, png)
      assert_image(image, 5, 5, 1, :DeviceGray, @greyscale_1bit_data)
    end

    it "works for a 2-bit greyscale png" do
      png = @images.grep(/greyscale-2bit\.png/).first
      image = @loader.load(@doc, png)
      data = [[2, 2, 0, 0, 0],
              [2, 3, 0, 3, 0],
              [3, 3, 3, 3, 3],
              [1, 3, 0, 3, 0],
              [1, 1, 0, 0, 0]]
      assert_image(image, 5, 5, 2, :DeviceGray, data)
    end

    it "works for a 4-bit greyscale png" do
      png = @images.grep(/greyscale-4bit\.png/).first
      image = @loader.load(@doc, png)
      data = [[15, 12, 9, 6, 3]] * 5
      assert_image(image, 5, 5, 4, :DeviceGray, data)
    end

    it "works for a 8-bit greyscale png" do
      png = @images.grep(/greyscale-8bit\.png/).first
      image = @loader.load(@doc, png)
      data = [[254, 203, 153, 101, 50],
              [253, 203, 152, 100, 50],
              [254, 203, 151, 101, 50],
              [253, 202, 151, 100, 50],
              [253, 202, 151, 100, 49]]
      assert_image(image, 5, 5, 8, :DeviceGray, data)
    end

    it "works for a 8-bit greyscale png with alpha" do
      png = @images.grep(/greyscale-alpha-8bit\.png/).first
      image = @loader.load(@doc, png)
      data = [[254, 203, 153, 101, 50],
              [253, 203, 152, 100, 50],
              [254, 203, 151, 101, 50],
              [255, 202, 151, 101, 50],
              [255, 202, 151, 101, 50]]
      assert_image(image, 5, 5, 8, :DeviceGray, data)

      data = [[255, 255, 255, 255, 255]] * 3 +
        [[129, 129, 129, 129, 129]] * 2
      assert_image(image[:SMask], 5, 5, 8, :DeviceGray, data)
    end

    it "works for a 8-bit greyscale png with a single transparent color" do
      png = @images.grep(/greyscale-trns-8bit\.png/).first
      image = @loader.load(@doc, png)
      data = [[254, 203, 153, 101, 50],
              [253, 203, 152, 100, 50],
              [254, 203, 151, 101, 50],
              [253, 202, 151, 100, 50],
              [253, 202, 151, 100, 49]]
      assert_image(image, 5, 5, 8, :DeviceGray, data)
      assert_equal([203, 203], image[:Mask].value)
    end

    it "works for a greyscale png with a gamma value of 1" do
      png = @images.grep(/greyscale-with-gamma1\.0\.png/).first
      image = @loader.load(@doc, png)
      assert_equal(:DeviceGray, image[:ColorSpace])
    end

    it "works for a greyscale png with a gamma value of 1/1.5" do
      png = @images.grep(/greyscale-with-gamma1\.5\.png/).first
      image = @loader.load(@doc, png)
      assert_equal([:CalGray, {WhitePoint: [1.0, 1.0, 1.0], Gamma: 1 / 1.5}], image[:ColorSpace].value)
    end

    it "works for an indexed 1-bit png" do
      png = @images.grep(/indexed-1bit\.png/).first
      image = @loader.load(@doc, png)
      color_space = [:Indexed, :DeviceRGB, 1, "\xFF".b * 3 << "\x0".b * 3]
      data = [[1, 0, 0, 0, 1]] * 5
      assert_image(image, 5, 5, 1, color_space, data)
    end

    it "works for an indexed 2-bit png" do
      png = @images.grep(/indexed-2bit\.png/).first
      image = @loader.load(@doc, png)
      colors = [44, 117, 63, 55, 118, 165, 97, 172, 110, 164, 189, 209].pack('C*')
      data = [[1, 1, 3, 2, 0]] * 5
      assert_image(image, 5, 5, 2, [:Indexed, :DeviceRGB, 3, colors], data)
    end

    it "works for an indexed 4-bit png" do
      png = @images.grep(/indexed-4bit\.png/).first
      image = @loader.load(@doc, png)
      data = [[0, 6, 13, 11, 3],
              [0, 7, 14, 11, 2],
              [0, 7, 15, 10, 1],
              [4, 8, 12, 9, 5],
              [4, 8, 12, 9, 5]]
      assert_image(image, 5, 5, 4, nil, data)
    end

    it "works for an indexed 8-bit png" do
      png = @images.grep(/indexed-8bit\.png/).first
      image = @loader.load(@doc, png)
      data = [[0, 8, 21, 15, 1],
              [0, 7, 20, 13, 3],
              [0, 10, 17, 14, 5],
              [2, 11, 18, 16, 6],
              [2, 9, 19, 12, 4]]
      assert_image(image, 5, 5, 8, nil, data)
    end

    it "works for an indexed 4-bit png with alpha values" do
      png = @images.grep(/indexed-alpha-4bit\.png/).first
      image = @loader.load(@doc, png)
      data = [[5, 6, 7, 8, 9],
              [5, 10, 11, 8, 9],
              [5, 10, 11, 8, 9],
              [0, 1, 2, 3, 4],
              [0, 1, 2, 3, 4]]
      assert_image(image, 5, 5, 4, nil, data)

      data = [[255, 255, 255, 255, 255]] * 3 +
        [[191, 191, 191, 191, 191]] * 2
      assert_image(image[:SMask], 5, 5, 8, :DeviceGray, data)
    end

    it "works for an indexed 8-bit png with alpha values" do
      png = @images.grep(/indexed-alpha-8bit\.png/).first
      image = @loader.load(@doc, png)
      data = [[5, 10, 11, 7, 6],
              [5, 8, 9, 7, 6],
              [5, 8, 9, 7, 6],
              [0, 1, 4, 2, 3],
              [0, 1, 4, 2, 3]]
      assert_image(image, 5, 5, 8, nil, data)

      data = [[255, 255, 255, 255, 255]] * 3 +
        [[191, 191, 191, 191, 191]] * 2
      assert_image(image[:SMask], 5, 5, 8, :DeviceGray, data)
    end

    it "works for a true color 8-bit png" do
      png = @images.grep(/truecolour-8bit\.png/).first
      image = @loader.load(@doc, png)
      data = [[12, 92, 146, 80, 136, 175, 167, 193, 213, 97, 175, 101, 38, 113, 50],
              [12, 92, 146, 81, 137, 176, 168, 194, 214, 97, 175, 101, 38, 113, 49],
              [12, 92, 146, 81, 137, 176, 169, 195, 214, 96, 175, 101, 37, 113, 49],
              [12, 92, 146, 81, 138, 176, 171, 195, 214, 96, 176, 101, 37, 113, 49],
              [12, 92, 146, 82, 137, 177, 171, 196, 215, 97, 176, 102, 37, 113, 49]]
      assert_image(image, 5, 5, 8, :DeviceRGB, data)
    end

    it "works for a true color 8-bit png with alpha" do
      png_data = File.binread(@images.grep(/truecolour-alpha-8bit\.png/).first)
      png_data[33, 0] = [0, "tRNS", 0].pack('NA4N') # add invalid tRNS chunk
      image = @loader.load(@doc, StringIO.new(png_data))
      data = [[12, 92, 146, 80, 136, 175, 167, 193, 213, 97, 175, 101, 38, 113, 50],
              [12, 92, 146, 81, 137, 176, 168, 194, 214, 97, 175, 101, 38, 113, 49],
              [12, 92, 146, 81, 137, 176, 169, 195, 214, 96, 175, 101, 37, 113, 49],
              [12, 92, 146, 81, 137, 176, 169, 195, 214, 96, 175, 101, 37, 113, 49],
              [12, 92, 146, 81, 137, 176, 169, 195, 214, 96, 175, 101, 37, 113, 49]]
      assert_image(image, 5, 5, 8, :DeviceRGB, data)

      data = [[255, 255, 255, 255, 255]] * 3 +
        [[191, 191, 191, 191, 191]] * 2
      assert_image(image[:SMask], 5, 5, 8, :DeviceGray, data)
    end

    it "works for true color 8-bit pngs with an sRGB chunk or gAMA/cHRM chunks" do
      @images.grep(/truecolour-(?:srgb|gama-chrm)-8bit\.png/).each do |png|
        image = @loader.load(@doc, png)
        # For the literal numbers see http://www.brucelindbloom.com/index.html?Eqn_RGB_XYZ_Matrix.html
        [0.9505, 1.0, 1.0891].zip(image[:ColorSpace][1][:WhitePoint]).each do |r, e|
          assert_in_delta(r, e, 0.0001)
        end
        [0.4124, 0.2126, 0.0193, 0.3576, 0.7152, 0.1192, 0.1805, 0.0722, 0.9505].
          zip(image[:ColorSpace][1][:Matrix]).each do |r, e|
          assert_in_delta(r, e, 0.0001)
        end
        if png.match?(/srgb/)
          assert_equal(:AbsoluteColorimetric, image[:Intent])
        end
      end
    end

    it "fails for unsupported PNG compression methods" do
      data = build_png([0, 0, 8, 0, 1, 0, 0, 4])
      exp = assert_raises(HexaPDF::Error) { @loader.load(@doc, StringIO.new(data)) }
      assert_match(/compression method/, exp.message)
    end

    it "fails for unsupported PNG filter methods" do
      data = build_png([0, 0, 8, 0, 0, 1, 0, 4])
      exp = assert_raises(HexaPDF::Error) { @loader.load(@doc, StringIO.new(data)) }
      assert_match(/filter method/, exp.message)
    end

    it "fails for unsupported PNG interlace methods" do
      data = build_png([0, 0, 8, 0, 0, 0, 1, 4])
      exp = assert_raises(HexaPDF::Error) { @loader.load(@doc, StringIO.new(data)) }
      assert_match(/interlace method/, exp.message)
    end
  end
end
