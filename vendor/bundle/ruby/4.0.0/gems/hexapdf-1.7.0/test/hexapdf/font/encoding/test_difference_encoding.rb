# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/font/encoding/difference_encoding'
require 'hexapdf/font/encoding/win_ansi_encoding'

describe HexaPDF::Font::Encoding::DifferenceEncoding do
  before do
    base = HexaPDF::Font::Encoding::WinAnsiEncoding.new
    @enc = HexaPDF::Font::Encoding::DifferenceEncoding.new(base)
  end

  describe "name" do
    it "takes the encoding differences into account" do
      assert_equal(:A, @enc.name(65))
      @enc.code_to_name[65] = :B
      assert_equal(:B, @enc.name(65))
      assert_equal(:B, @enc.name(66))
    end
  end

  describe "code" do
    it "takes the encoding differences into account" do
      assert_equal(65, @enc.code(:A))
      @enc.code_to_name[65] = :Known
      assert_equal(65, @enc.code(:Known))
    end
  end
end
