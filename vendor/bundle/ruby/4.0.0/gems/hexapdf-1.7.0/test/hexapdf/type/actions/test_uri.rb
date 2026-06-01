# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/document'
require 'hexapdf/type/actions/uri'

describe HexaPDF::Type::Actions::URI do
  before do
    @doc = HexaPDF::Document.new
    @action = HexaPDF::Type::Actions::URI.new({}, document: @doc)
  end

  describe "validation" do
    it "URI needs to be ASCII only" do
      refute(@action.validate)

      @action[:URI] = "hellö"
      refute(@action.validate(auto_correct: false))
      assert(@action.validate(auto_correct: true))
      assert_equal("hell%C3%B6", @action[:URI])
    end
  end
end
