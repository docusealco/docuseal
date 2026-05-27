# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/filter/crypt'

describe HexaPDF::Filter::Crypt do
  before do
    @obj = HexaPDF::Filter::Crypt
    @source = Fiber.new { "hallo" }
  end

  it "works with the Identity filter" do
    assert_equal(@source, @obj.decoder(@source, nil))
    assert_equal(@source, @obj.encoder(@source, {})) # sic: 'encoder'
    assert_equal(@source, @obj.decoder(@source, {Name: :Identity}))
  end

  it "fails if crypt filter name is not Identity" do
    assert_raises(HexaPDF::FilterError) { @obj.decoder(@source, {Name: :Other}) }
  end
end
