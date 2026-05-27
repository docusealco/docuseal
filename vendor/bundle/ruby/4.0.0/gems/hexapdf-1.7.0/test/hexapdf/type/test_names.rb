# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/document'
require 'hexapdf/type/names'

describe HexaPDF::Type::Names do
  before do
    @doc = HexaPDF::Document.new
    @names = @doc.add({}, type: :XXNames)
  end

  it "returns the name tree for the /Dests entry" do
    refute(@names.key?(:Dests))
    dests = @names.destinations
    assert_kind_of(HexaPDF::NameTreeNode, dests)
    assert_same(dests, @names[:Dests])
    assert_same(dests, @names.destinations)
  end
end
