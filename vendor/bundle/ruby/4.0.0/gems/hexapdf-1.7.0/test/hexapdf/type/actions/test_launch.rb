# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/document'
require 'hexapdf/type/actions/launch'

describe HexaPDF::Type::Actions::Launch do
  before do
    @doc = HexaPDF::Document.new
    @action = HexaPDF::Type::Actions::Launch.new({}, document: @doc)
  end

  describe "validation" do
    it "needs a launch target" do
      refute(@action.validate)

      @action.value = {Win: {F: "test.exe"}}
      assert(@action.validate)
      @action.value = {Mac: 'test'}
      assert(@action.validate)
      @action.value = {Unix: 'test'}
      assert(@action.validate)

      @action.value = {F: {}}
      assert(@action.validate)
    end
  end
end
