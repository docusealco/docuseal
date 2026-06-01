# -*- encoding: utf-8 -*-

require_relative 'common'
require 'hexapdf/encryption/arc4'

describe HexaPDF::Encryption::ARC4 do
  include EncryptionAlgorithmInterfaceTests

  before do
    @algorithm_class = Class.new do
      prepend HexaPDF::Encryption::ARC4

      def initialize(key)
        @data = +key
      end

      def process(data)
        raise if data.empty?
        result = @data << data
        @data = +''
        result
      end
    end
  end

  it "correctly uses klass.encrypt and klass.decrypt" do
    assert_equal('mykeydata', @algorithm_class.encrypt('mykey', 'data'))
    assert_equal('mykeydata', @algorithm_class.decrypt('mykey', 'data'))
  end

  it "correctly uses klass.encryption_fiber and klass.decryption_fiber" do
    f = Fiber.new { Fiber.yield('first'); Fiber.yield(''); 'second' }
    assert_equal('mykeyfirstsecond',
                 collector(@algorithm_class.encryption_fiber('mykey', f)))
    f = Fiber.new { Fiber.yield('first'); 'second' }
    assert_equal('mykeyfirstsecond',
                 collector(@algorithm_class.decryption_fiber('mykey', f)))
  end
end
