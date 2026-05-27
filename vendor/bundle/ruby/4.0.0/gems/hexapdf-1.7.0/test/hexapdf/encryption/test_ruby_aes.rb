# -*- encoding: utf-8 -*-

require_relative 'common'
require 'hexapdf/encryption/ruby_aes'
require 'hexapdf/encryption/fast_aes'

describe HexaPDF::Encryption::RubyAES do
  include AESEncryptionTests

  before do
    @algorithm_class = HexaPDF::Encryption::RubyAES
  end

  it "is compatible with the OpenSSL based FastAES implementation" do
    sample = Random.new.bytes(1024)
    key = Random.new.bytes(16)
    iv = Random.new.bytes(16)
    assert_equal(sample, HexaPDF::Encryption::FastAES.new(key, iv, :encrypt).
                 process(HexaPDF::Encryption::RubyAES.new(key, iv, :decrypt).process(sample)))
    assert_equal(sample, HexaPDF::Encryption::FastAES.new(key, iv, :decrypt).
                 process(HexaPDF::Encryption::RubyAES.new(key, iv, :encrypt).process(sample)))
  end
end
