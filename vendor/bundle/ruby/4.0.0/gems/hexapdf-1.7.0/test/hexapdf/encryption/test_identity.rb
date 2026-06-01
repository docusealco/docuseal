# -*- encoding: utf-8 -*-

require_relative 'common'
require 'hexapdf/encryption/identity'

describe HexaPDF::Encryption::Identity do
  include EncryptionAlgorithmInterfaceTests

  before do
    @algorithm_class = HexaPDF::Encryption::Identity
  end

  it "returns the data unmodified for encrypt/decrypt" do
    assert_equal('data', @algorithm_class.encrypt('key', 'data'))
  end

  it "returns the source Fiber unmodified for encryption_fiber/decryption_fiber" do
    f = Fiber.new { 'data' }
    assert_equal(f, @algorithm_class.encryption_fiber('key', f))
  end
end
