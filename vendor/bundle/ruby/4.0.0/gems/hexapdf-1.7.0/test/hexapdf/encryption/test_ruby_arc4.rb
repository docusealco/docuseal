# -*- encoding: utf-8 -*-

require_relative 'common'
require 'hexapdf/encryption/ruby_arc4'
require 'hexapdf/encryption/fast_arc4'

describe HexaPDF::Encryption::RubyARC4 do
  include ARC4EncryptionTests

  before do
    @algorithm_class = HexaPDF::Encryption::RubyARC4
  end

  it "is compatible with the OpenSSL based FastARC4 implementation" do
    @keys.each_with_index do |key, i|
      assert_equal(@plain[i], HexaPDF::Encryption::FastARC4.new(key).
                   process(HexaPDF::Encryption::RubyARC4.new(key).process(@plain[i])))
    end
  end
end
