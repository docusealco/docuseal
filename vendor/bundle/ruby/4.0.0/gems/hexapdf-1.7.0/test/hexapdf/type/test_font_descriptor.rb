# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/document'
require 'hexapdf/type/font_descriptor'

describe HexaPDF::Type::FontDescriptor do
  before do
    @doc = HexaPDF::Document.new
    @font_desc = @doc.add({Type: :FontDescriptor, FontName: :Test, Flags: 0b1001001,
                           ItalicAngle: 10})
  end

  describe "flags" do
    it "returns all flags" do
      assert_equal([:fixed_pitch, :script, :italic], @font_desc.flags)
    end
  end

  describe "flagged?" do
    it "returns true if the given flag is set" do
      assert(@font_desc.flagged?(:fixed_pitch))
      refute(@font_desc.flagged?(:serif))
    end

    it "raises an error if an unknown flag name is provided" do
      assert_raises(ArgumentError) { @font_desc.flagged?(:unknown) }
    end
  end

  describe "flag" do
    it "sets the given flag bits" do
      @font_desc.flag(:serif)
      assert_equal([:fixed_pitch, :serif, :script, :italic], @font_desc.flags)
      @font_desc.flag(:symbolic, clear_existing: true)
      assert_equal([:symbolic], @font_desc.flags)
    end
  end

  describe "validation" do
    it "fails if more than one of /FontFile{,2,3} are set" do
      assert(@font_desc.validate {|*args| p args })
      @font_desc[:FontFile] = @font_desc[:FontFile2] = @doc.add({}, stream: 'test')
      refute(@font_desc.validate)
    end

    it "deletes the /FontWeight value if it doesn't contain a valid value" do
      @font_desc[:FontWeight] = 350
      refute(@font_desc.validate(auto_correct: false))
      assert(@font_desc.validate)
      refute(@font_desc.key?(:FontWeight))
    end

    it "updates the /Descent value if it is not a negative number" do
      @font_desc[:Descent] = 5
      refute(@font_desc.validate(auto_correct: false))
      assert(@font_desc.validate)
      assert_equal(-5, @font_desc[:Descent])
    end
  end
end
