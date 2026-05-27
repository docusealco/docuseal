# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/document'
require 'hexapdf/type/actions/set_ocg_state'

describe HexaPDF::Type::Actions::SetOCGState do
  before do
    @doc = HexaPDF::Document.new
    @action = HexaPDF::Type::Actions::SetOCGState.new({}, document: @doc)
    @ocg = @doc.optional_content.add_ocg('Test')
  end

  describe "add_state_change" do
    it "allows using Ruby-esque and PDF type names for the state change type" do
      @action.add_state_change(:on, @ocg)
      @action.add_state_change(:ON, @ocg)
      @action.add_state_change(:off, @ocg)
      @action.add_state_change(:OFF, @ocg)
      @action.add_state_change(:toggle, @ocg)
      @action.add_state_change(:Toggle, @ocg)
      assert_equal([:ON, @ocg, :ON, @ocg, :OFF, @ocg, :OFF, @ocg, :Toggle, @ocg, :Toggle, @ocg],
                   @action[:State].value)
    end

    it "allows specifying more than one OCG" do
      @action.add_state_change(:on, [@ocg, @doc.optional_content.add_ocg('Test2')])
      assert_equal([:ON, @ocg, @doc.optional_content.ocg('Test2')], @action[:State].value)
    end

    it "raises an error if the provide state change type is invalid" do
      assert_raises(ArgumentError) { @action.add_state_change(:unknown, nil) }
    end

    it "raises an error if an OCG specified via a string does not exist" do
      error = assert_raises(HexaPDF::Error) { @action.add_state_change(:on, "Unknown") }
      assert_match(/Invalid OCG.*Unknown.*specified/, error.message)
    end
  end
end
