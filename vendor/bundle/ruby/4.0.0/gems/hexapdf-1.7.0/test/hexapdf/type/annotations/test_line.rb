# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/document'
require 'hexapdf/type/annotations/line'

describe HexaPDF::Type::Annotations::Line do
  before do
    @doc = HexaPDF::Document.new
    @line = @doc.add({Type: :Annot, Subtype: :Line, Rect: [0, 0, 0, 0], L: [0, 0, 1, 1]})
  end

  describe "line" do
    it "returns the coordinates of the start and end points" do
      @line[:L] = [10, 20, 30, 40]
      assert_equal([10, 20, 30, 40], @line.line)
    end

    it "sets the line points" do
      assert_equal(@line, @line.line(1, 2, 3, 4))
      assert_equal([1, 2, 3, 4], @line[:L])
    end

    it "raises an ArgumentError if not all arguments are provided" do
      assert_raises(ArgumentError) { @line.line(1, 2, 3) }
    end
  end

  describe "leader_line_length" do
    it "returns the leader line length" do
      assert_equal(0, @line.leader_line_length)
      @line[:LL] = 10
      assert_equal(10, @line.leader_line_length)
    end

    it "sets the leader line length" do
      assert_equal(@line, @line.leader_line_length(10))
      assert_equal(10, @line[:LL])
    end
  end

  describe "leader_line_extension_length" do
    it "returns the leader line extension length" do
      assert_equal(0, @line.leader_line_extension_length)
      @line[:LLE] = 10
      assert_equal(10, @line.leader_line_extension_length)
    end

    it "sets the leader line extension length" do
      assert_equal(@line, @line.leader_line_extension_length(10))
      assert_equal(10, @line[:LLE])
    end

    it "raises an error for negative numbers" do
      assert_raises(ArgumentError) { @line.leader_line_extension_length(-10) }
    end
  end

  describe "leader_line_offset" do
    it "returns the leader line offset" do
      assert_equal(0, @line.leader_line_offset)
      @line[:LLO] = 10
      assert_equal(10, @line.leader_line_offset)
    end

    it "sets the leader line offset" do
      assert_equal(@line, @line.leader_line_offset(10))
      assert_equal(10, @line[:LLO])
    end
  end

  describe "captioned" do
    it "returns whether a caption is shown" do
      refute(@line.captioned)
      @line[:Cap] = true
      assert(@line.captioned)
    end

    it "sets whether a caption should be shown" do
      assert_equal(@line, @line.captioned(true))
      assert_equal(true, @line[:Cap])
    end
  end

  describe "caption_position" do
    it "returns the caption position" do
      assert_equal(:inline, @line.caption_position)
      @line[:CP] = :Top
      assert_equal(:top, @line.caption_position)
    end

    it "sets the caption position" do
      assert_equal(@line, @line.caption_position(:top))
      assert_equal(:Top, @line[:CP])
    end

    it "raises an error on invalid caption positions" do
      assert_raises(ArgumentError) { @line.caption_position(:unknown) }
    end
  end

  describe "caption_offset" do
    it "returns the caption offset" do
      assert_equal([0, 0], @line.caption_offset)
      @line[:CO] = [10, 5]
      assert_equal([10, 5], @line.caption_offset)
    end

    it "sets the caption offset" do
      assert_equal(@line, @line.caption_offset(5, 10))
      assert_equal([5, 10], @line[:CO])
      assert_equal(@line, @line.caption_offset(5))
      assert_equal([5, 0], @line[:CO])
      assert_equal(@line, @line.caption_offset(nil, 5))
      assert_equal([0, 5], @line[:CO])
    end
  end

  describe "perform_validation" do
    it "validates that leader line length is set if extension length is set" do
      @line[:LLE] = 10
      m = nil
      refute(@line.validate {|msg| m = msg })
      assert_match(/\/LL required to be non-zero/, m)
    end

    it "ensures leader line extension length is non-negative" do
      @line[:LL] = 10
      @line[:LLE] = -10
      m = nil
      assert(@line.validate {|msg| m = msg })
      assert_equal(10, @line[:LLE])
      assert_match(/non-negative/, m)
    end

    it "ensures leader line offset is non-negative" do
      @line[:LLO] = -10
      m = nil
      assert(@line.validate {|msg| m = msg })
      assert_equal(10, @line[:LLO])
      assert_match(/\/LLO must be a non-negative/, m)
    end
  end
end
