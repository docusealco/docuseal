# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/tokenizer'
require 'stringio'
require_relative 'common_tokenizer_tests'

describe HexaPDF::Tokenizer do
  include CommonTokenizerTests

  def create_tokenizer(str)
    @tokenizer = HexaPDF::Tokenizer.new(StringIO.new(str.b))
  end

  it "handles object references" do
    #HexaPDF::Reference.new(1, 0), HexaPDF::Reference.new(1, 2), 2, -1, 'R', 0, 0, 'R', -1, 0, 'R',
    create_tokenizer("1 0 R +2 +15 R 2 -1 R 0 0 R 0 10 R -1 0 R")
    assert_equal(HexaPDF::Reference.new(1, 0), @tokenizer.next_token)
    assert_equal(HexaPDF::Reference.new(2, 15), @tokenizer.next_token)
    assert_equal(2, @tokenizer.next_token)
    assert_equal(-1, @tokenizer.next_token)
    assert_equal('R', @tokenizer.next_token)
    assert_nil(@tokenizer.next_token)
    assert_nil(@tokenizer.next_token)
    assert_equal(-1, @tokenizer.next_token)
    assert_equal(0, @tokenizer.next_token)
    assert_equal('R', @tokenizer.next_token)
    @tokenizer.pos = 0
    assert_equal(HexaPDF::Reference.new(1, 0), @tokenizer.next_object)
    assert_equal(HexaPDF::Reference.new(2, 15), @tokenizer.next_object)
  end

  it "next_token: should not fail when resetting the position (due to use of an internal buffer)" do
    create_tokenizer("0 1 2 3 4 " * 4000)
    4000.times do
      5.times {|i| assert_equal(i, @tokenizer.next_token) }
    end
  end

  it "next_token: should not fail for strings due to use of an internal buffer" do
    create_tokenizer("(" + ("a" * 8189) + "\\006)")
    assert_equal("a" * 8189 << "\x06", @tokenizer.next_token)
  end

  it "has a special token scanning method for use with xref reconstruction" do
    create_tokenizer(<<-EOF.chomp.gsub(/^ {8}/, ''))
        % Comment
          true
        123 50
        obj
        (ignored)
        /Ignored
        [/Ignored]
        <</Ignored /Values>>
    EOF

    scan_to_newline = proc { @tokenizer.scan_until(/(\n|\r\n?)+|\z/) }

    assert_nil(@tokenizer.next_integer_or_keyword)
    scan_to_newline.call
    assert_equal(true, @tokenizer.next_integer_or_keyword)
    assert_equal(123, @tokenizer.next_integer_or_keyword)
    assert_equal(50, @tokenizer.next_integer_or_keyword)
    assert_equal('obj', @tokenizer.next_integer_or_keyword)
    4.times do
      assert_nil(@tokenizer.next_integer_or_keyword)
      scan_to_newline.call
    end
    assert_equal(HexaPDF::Tokenizer::NO_MORE_TOKENS, @tokenizer.next_integer_or_keyword)
  end

  describe "can correct some problems" do
    describe "invalid inf/-inf/nan/-nan tokens" do
      it "turns them into zeros" do
        count = 0
        on_correctable_error = lambda do |msg, pos|
          count += 1
          assert_match(/Invalid object, got token/, msg)
          assert_equal(8, pos) if count == 2
          false
        end
        tokenizer = HexaPDF::Tokenizer.new(StringIO.new("inf -Inf NaN -nan"),
                                           on_correctable_error: on_correctable_error)
        assert_equal([0, 0, 0, 0], 4.times.map { tokenizer.next_object })
        assert_equal(4, count)
      end

      it "raises an error if configured so" do
        tokenizer = HexaPDF::Tokenizer.new(StringIO.new("inf"), on_correctable_error: proc { true })
        assert_raises(HexaPDF::MalformedPDFError) { tokenizer.next_object }
      end
    end
  end
end
