# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/content/color_space'

module CommonColorSpaceTests
  extend Minitest::Spec::DSL

  it "the color object returns the correct color space" do
    assert_equal(@color_space, @color.color_space)
  end

  it "the color space class accepts the color space definition as argument to ::new" do
    assert_equal(1, @color_space.class.method(:new).arity.abs)
  end

  it "the color space responds to :default_color" do
    assert(@color_space.respond_to?(:default_color))
    assert_equal(0, @color_space.method(:default_color).arity)
  end

  it "the color space responds to :color" do
    assert(@color_space.respond_to?(:color))
  end

  it "the color space returns the correct color space family" do
    assert_equal(@color_space_family, @color_space.family)
  end

  it "the color space returns the correct color space definition" do
    assert_equal(@color_space_definition, @color_space.definition)
  end

  it "the color responds to :components" do
    assert(@color.respond_to?(:components))
  end

  it "the color responds to :color_space" do
    assert(@color.respond_to?(:color_space))
  end

  it "the colors are comparable" do
    refute_equal(@color, @other_color)
  end

  it "the components are returned in the correct order" do
    assert_equal(@components, @color_space.color(*@components).components)
  end

  it "normalizes the colors when using the #color method" do
    return unless defined?(@colors)
    assert_equal(@components, @color_space.color(*@colors).components)
  end

  it "doesn't normalize the colors when using the #prenormalized_color method" do
    return unless defined?(@colors)
    assert_equal(@colors, @color_space.prenormalized_color(*@colors).components)
  end

end

describe HexaPDF::Content::ColorSpace do
  before do
    @class = HexaPDF::Content::ColorSpace
  end

  describe "self.device_color_from_specification" do
    it "works for gray values" do
      assert_equal([0.2], @class.device_color_from_specification(51).components)
    end

    it "works for RGB values" do
      assert_equal([0.2, 1, 0], @class.device_color_from_specification(51, 255, 0).components)
    end

    it "works for RGB values given as full hex string" do
      assert_equal([0.2, 1, 0], @class.device_color_from_specification("33FF00").components)
    end

    it "works for RGB values given as half hex string" do
      assert_equal([0.2, 1, 0], @class.device_color_from_specification("3F0").components)
    end

    it "works for RGB values given as color names" do
      assert_equal([0, 0, 1], @class.device_color_from_specification("blue").components)
    end

    it "works for CMYK values" do
      assert_equal([0.51, 0.9, 1, 0.5],
                   @class.device_color_from_specification(51, 90, 100, 50).components)
    end

    it "works when an array is given" do
      assert_equal([0.2], @class.device_color_from_specification([51]).components)
    end

    it "raises an error if an invalid color string is given" do
      assert_raises(ArgumentError) { @class.device_color_from_specification("unknown") }
    end
  end

  describe "self.serialize_device_color" do
    it "works for device gray colors" do
      color = @class.device_color_from_specification(0.5)
      assert_equal("0.5 g\n", @class.serialize_device_color(color))
      assert_equal("0.5 G\n", @class.serialize_device_color(color, type: :stroke))
    end

    it "works for device RGB colors" do
      color = @class.device_color_from_specification("red")
      assert_equal("1.0 0.0 0.0 rg\n", @class.serialize_device_color(color))
      assert_equal("1.0 0.0 0.0 RG\n", @class.serialize_device_color(color, type: :stroke))
    end

    it "works for device CMYK colors" do
      color = @class.device_color_from_specification([100, 100, 100, 0])
      assert_equal("1.0 1.0 1.0 0.0 k\n", @class.serialize_device_color(color))
      assert_equal("1.0 1.0 1.0 0.0 K\n", @class.serialize_device_color(color, type: :stroke))
    end

    it "fails if no device color is provided" do
      assert_raises(ArgumentError) do
        @class.serialize_device_color(@class::Universal.new([]).default_color)
      end
    end
  end

  it "returns a device color object for prenormalized color values" do
    assert_equal([5, 6, 7], @class.prenormalized_device_color([5, 6, 7]).components)
  end

  describe "self.for_components" do
    it "returns the correct device color space name" do
      assert_equal(:DeviceGray, @class.for_components([1]))
      assert_equal(:DeviceRGB, @class.for_components([1, 2, 3]))
      assert_equal(:DeviceCMYK, @class.for_components([1, 2, 3, 4]))
    end

    it "fails if an array with an invalid length is passed" do
      assert_raises(ArgumentError) { @class.for_components([]) }
    end
  end
end

describe HexaPDF::Content::ColorSpace::Universal do
  include CommonColorSpaceTests

  before do
    @color_space = HexaPDF::Content::ColorSpace::Universal.new([:test, :value])
    @color_space_family = :test
    @color_space_definition = [:test, :value]
    @color = @color_space.default_color
    @other_color = @color_space.color(128, 5, 6, 7, 8)
    @components = [5, 6, 7, 8]
  end

  it "can be compared to another universal color space" do
    other = HexaPDF::Content::ColorSpace::Universal.new([:other])
    same = HexaPDF::Content::ColorSpace::Universal.new([:test, :value])
    assert_equal(same, @color_space)
    refute_equal(other, @color_space)
  end
end

describe HexaPDF::Content::ColorSpace::DeviceRGB do
  include CommonColorSpaceTests

  before do
    @color_space = HexaPDF::Content::ColorSpace::DeviceRGB.new
    @color_space_family = @color_space_definition = :DeviceRGB
    @color = @color_space.default_color
    @other_color = @color_space.color(128, 0, 0)
    @colors = [128, 0, 255]
    @components = @colors.map {|c| c.to_f / 255 }
  end
end

describe HexaPDF::Content::ColorSpace::DeviceCMYK do
  include CommonColorSpaceTests

  before do
    @color_space = HexaPDF::Content::ColorSpace::DeviceCMYK.new
    @color_space_family = @color_space_definition = :DeviceCMYK
    @color = @color_space.default_color
    @other_color = @color_space.color(128, 0, 0, 128)
    @colors = [0, 20, 40, 80]
    @components = [0.0, 0.2, 0.4, 0.8]
  end
end

describe HexaPDF::Content::ColorSpace::DeviceGray do
  include CommonColorSpaceTests

  before do
    @color_space = HexaPDF::Content::ColorSpace::DeviceGray.new
    @color_space_family = @color_space_definition = :DeviceGray
    @color = @color_space.default_color
    @other_color = @color_space.color(128)
    @colors = [128]
    @components = [128.0 / 255]
  end
end
