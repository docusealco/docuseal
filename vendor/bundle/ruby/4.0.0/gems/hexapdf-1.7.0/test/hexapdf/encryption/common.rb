# -*- encoding: utf-8 -*-

require 'test_helper'

# Contains tests that validate that an encryption algorithm's class conforms to the general
# interface.
#
# The algorithm class needs to be available in the @algorithm_class variable.
module EncryptionAlgorithmInterfaceTests

  def test_responds_to_necessary_methods
    [:encrypt, :decrypt, :encryption_fiber, :decryption_fiber].each do |method|
      assert_respond_to(@algorithm_class, method)
      assert_equal(2, @algorithm_class.method(method).arity)
    end
  end

end

# Contains common tests for AES algorithms.
#
# The algorithm class needs to be available in the @algorithm_class variable.
module AESEncryptionTests

  include EncryptionAlgorithmInterfaceTests

  TEST_VECTOR_FILES = Dir[File.join(TEST_DATA_DIR, 'aes-test-vectors', '*')]

  def test_processes_the_aes_test_vectors
    TEST_VECTOR_FILES.each do |filename|
      name, size, mode = File.basename(filename, '.data.gz').split('-')
      size = size.to_i / 8
      data = Zlib::GzipReader.open(filename, &:read).force_encoding(Encoding::BINARY)
      data.scan(/(.{#{size}})(.{16})(.{16})(.{16})/m).each_with_index do |(key, iv, plain, cipher), index|
        aes = @algorithm_class.new(key, iv, mode.intern)
        assert_equal(cipher, aes.process(plain),
                     "name: #{name}, size: #{size * 8}, mode: #{mode}, index: #{index}")
      end
    end
  end

  def test_can_accept_one_big_chunk_or_multiple_smaller_ones
    big = @algorithm_class.new('t' * 16, '0' * 16, :encrypt)
    small = @algorithm_class.new('t' * 16, '0' * 16, :encrypt)
    assert_equal(big.process('some' * 16),
                 small.process('some' * 8) << small.process('some' * 4) << small.process('some' * 4))
  end

  def test_raises_error_on_invalid_key_length
    assert_raises(HexaPDF::EncryptionError) { @algorithm_class.new('t' * 7, '0' * 16, :encrypt) }
  end

  def test_raises_error_on_invalid_iv_length
    assert_raises(HexaPDF::EncryptionError) { @algorithm_class.new('t' * 16, '0' * 7, :encrypt) }
  end

end

# Contains common tests for AES algorithms.
#
# The algorithm class needs to be available in the @algorithm_class variable.
module ARC4EncryptionTests

  include EncryptionAlgorithmInterfaceTests

  def setup
    super
    @encrypted = ['BBF316E8D940AF0AD3', '1021BF0420', '45A01F645FC35B383552544B9BF5'].
      map {|c| [c].pack('H*') }
    @plain = ['Plaintext'.b, 'pedia'.b, 'Attack at dawn'.b]
    @keys = ['Key', 'Wiki', 'Secret']
  end

  def test_processes_the_test_vectors_from_the_rc4_wikipeda_page
    @keys.each_with_index do |key, i|
      assert_equal(@encrypted[i], @algorithm_class.new(key).process(@plain[i]))
    end
  end

  def test_can_accept_one_big_chunk_or_multiple_smaller_ones
    big = @algorithm_class.new('key')
    small = @algorithm_class.new('key')
    assert_equal(big.process('some big data chunk'),
                 small.process('some') << small.process(' big') << small.process(' data chunk'))
  end

  def test_works_with_empty_strings
    assert_equal('', @algorithm_class.new('key').process(''))
  end

end
