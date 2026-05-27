# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/font/encoding'
require 'hexapdf/font/encoding/base'

describe HexaPDF::Font::Encoding::Base do
  before do
    @base = HexaPDF::Font::Encoding::Base.new
    @base.code_to_name[65] = :A
  end

  it "returns nil for the encoding_name" do
    assert_nil(@base.encoding_name)
  end

  describe "name" do
    it "returns a mapped code" do
      assert_equal(:A, @base.name(65))
    end

    it "returns .notdef for an unmapped code" do
      assert_equal(:'.notdef', @base.name(66))
    end
  end

  describe "unicode" do
    it "returns the unicode value of the code" do
      assert_equal("A", @base.unicode(65))
    end

    it "returns an empty string for an unmapped code" do
      assert_nil(@base.unicode(66))
    end
  end

  describe "code" do
    it "returns the code for an existing glyph name" do
      assert_equal(65, @base.code(:A))
    end

    it "returns nil if the glyph name is not referenced" do
      assert_nil(@base.code(:Unknown))
    end
  end

  describe "to_compact_array" do
    before do
      @base.code_to_name[66] = :B
      @base.code_to_name[67] = :C
      @base.code_to_name[20] = :space
      @base.code_to_name[28] = :D
      @base.code_to_name[29] = :E
    end

    it "returns the difference array" do
      assert_equal([20, :space, 28, :D, :E, 65, :A, :B, :C], @base.to_compact_array)
    end

    it "ignores the codes that are the same in the base encoding" do
      std_encoding = HexaPDF::Font::Encoding.for_name(:StandardEncoding)
      assert_equal([20, :space, 28, :D, :E, ], @base.to_compact_array(base_encoding: std_encoding))
    end
  end
end
