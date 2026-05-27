# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/type'

describe HexaPDF::Type do
  it "all autoload files have no syntax error" do
    HexaPDF::Type.constants.each do |const|
      HexaPDF::Type.const_get(const) # no assert needed here
    end
    HexaPDF::Type::Actions.constants.each do |const|
      HexaPDF::Type::Actions.const_get(const) # no assert needed here
    end
    HexaPDF::Type::Annotations.constants.each do |const|
      HexaPDF::Type::Annotations.const_get(const) # no assert needed here
    end
  end
end
