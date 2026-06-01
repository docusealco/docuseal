# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/content/parser'
require 'hexapdf/content/processor'
require_relative '../common_tokenizer_tests'

describe HexaPDF::Content::Tokenizer do
  include CommonTokenizerTests

  def create_tokenizer(str)
    @tokenizer = HexaPDF::Content::Tokenizer.new(str.b)
  end
end

describe HexaPDF::Content::Parser do
  before do
    @processor = HexaPDF::TestUtils::OperatorRecorder.new
    @parser = HexaPDF::Content::Parser.new
  end

  describe "parse" do
    before do
      @image_data = "x\x9Ccd\xC0\x00\xBB\x1F<\xC6\x14\xA43EI JP)\xB8w\xFDZ\xBA\xA7;Ae\xC4;u\xDB\xF2e\xFD\x95\xE5\x04\x95u/[a`e\x8DK\xD6UA\x96*\xEE\xD9\xBFyS[n6\xD9FQ\xCB\x19\x04\x8DZz\xEC\x84\x98\x944\xB2\bA\x97[\xB8\xB86\xCF\x99G\xA4\xED\x04\x1D\x90^]\e\x92\x9AF\x86FL\x97\x13\xAF\x17\b\n\xDB;\xBD\"\xA3\xF0\xAB\x01\x82\xDA\x94\xA4\x13{v\x13T\x86+:\x16\xF4v/\x9D<\x89rg\xE0J\xDBU\x93\xA7\xCA\xAB\xA8(ija\xD5EI\x00\xD2\bP%a\xD3-w\xCC\xDF\x7FPFQ\t\x97,\xC1\xC8%\xD2\x19X#\xD7':V\xCF\xC2\xC2\xCC\xC1\x91\x9B\x97\x97\x18CH\x02\xD4\n@br\a\x9EdF\xB93(\x89>\xEA\x1AB\x87\xC4@\xE7\x9CN\xD3\xB2\x8Bn>\xA2u\x1A#\xC6\x04\n\xC1\x93\xFB\xF7\x12\x1D\xEDq\xC9\x02C2\xBF\xB5\r\xBF\t\x94xa\xB4E\x84\x06^={\x1Ame\x81G\xC1\xEA\xB3\xE7\x05\x84E\xC8v\x00\xADk@\xFC\xC9\x89\x18\a\x10\xB4\x1D\x7F\x13\x91\xF2\x00\xA4\x1C\xE0\xF7\x021y\x8A\x81\xB8$=s\xFBN\\E\xDC\x9A\xD9\xB3f\xB66\x13\xB4\x85\x18\xC7\x10,\xAB\xF1\xF7z\x18\x06G\xC3\x8C*\x91B\x8C3\xF0D\nA\xED\x90\xF2\x01\x00_\x97\xE3\x80\n".b
    end

    it "parses a simple content stream without inline images" do
      @parser.parse("0 0.500 m q Q /Name SCN", @processor)
      assert_equal([[:move_to, [0, 0.5]], [:save_graphics_state],
                    [:restore_graphics_state],
                    [:set_stroking_color, [:Name]]], @processor.recorded_ops)
    end

    it "parses a content stream with an inline image without EI in image data" do
      @parser.parse("q BI /Name 0.5/Other 1 ID some dataEI Q", @processor)
      assert_equal([[:save_graphics_state],
                    [:inline_image, [{Name: 0.5, Other: 1}, "some data"]],
                    [:restore_graphics_state]], @processor.recorded_ops)
    end

    it "parses a content stream with an inline image with EI in image data" do
      @parser.parse("BI\n/CS/RGB\nID #{@image_data}EI Q\nq 1308 0 0 1 485.996 4531.67 cm\n".b,
                    @processor)
      assert_equal([[:inline_image, [{CS: :RGB}, @image_data]],
                    [:restore_graphics_state],
                    [:save_graphics_state],
                    [:concatenate_matrix, [1308, 0, 0, 1, 485.996, 4531.67]]],
                   @processor.recorded_ops)
    end

    it "parses a content stream with an inline image with EI in image data at end of stream" do
      @parser.parse("BI\n/CS/RGB\nID #{@image_data}EI".b, @processor)
      assert_equal([[:inline_image, [{CS: :RGB}, @image_data]]], @processor.recorded_ops)
    end

    it "fails parsing inline images if the dictionary keys are not PDF names" do
      exp = assert_raises(HexaPDF::Error) do
        @parser.parse("q BI /Name 0.5 Other 1 ID some dataEI Q", @processor)
      end
      assert_match(/keys.*PDF name/, exp.message)
    end

    it "fails parsing inline images when trying to read a dict key and EOS is encountered" do
      exp = assert_raises(HexaPDF::Error) do
        @parser.parse("q BI /Name 0.5", @processor)
      end
      assert_match(/EOS.*dictionary key/, exp.message)
    end

    it "fails parsing inline images when trying to read a dict value and EOS is encountered" do
      exp = assert_raises(HexaPDF::Error) do
        @parser.parse("q BI /Name 0.5 /Other", @processor)
      end
      assert_match(/EOS.*dictionary value/, exp.message)
    end

    it "fails parsing inline images if the EI is not found" do
      exp = assert_raises(HexaPDF::Error) do
        @parser.parse("q BI /Name 0.5 /Other 1 ID test", @processor)
      end
      assert_match(/EI not found/, exp.message)
    end

    it "can use a block instead of the processor object" do
      called = 0
      @parser.parse("/F1 5 Tf") do |obj, params|
        called += 1
        assert_equal(:Tf, obj)
        assert_equal([:F1, 5], params)
      end
      assert_equal(1, called)
    end

    it "fails if neither a processor object or a block is provided" do
      assert_raises(ArgumentError) { @parser.parse("test") }
    end
  end
end
