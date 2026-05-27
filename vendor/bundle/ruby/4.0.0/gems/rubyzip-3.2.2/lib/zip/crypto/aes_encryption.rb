# frozen_string_literal: true

require 'openssl'

module Zip
  module AESEncryption # :nodoc:
    VERIFIER_LENGTH = 2
    BLOCK_SIZE = 16
    AUTHENTICATION_CODE_LENGTH = 10

    VERSION_AE_1 = 0x01
    VERSION_AE_2 = 0x02

    VERSIONS = [
      VERSION_AE_1,
      VERSION_AE_2
    ].freeze

    STRENGTH_128_BIT = 0x01
    STRENGTH_192_BIT = 0x02
    STRENGTH_256_BIT = 0x03

    STRENGTHS = [
      STRENGTH_128_BIT,
      STRENGTH_192_BIT,
      STRENGTH_256_BIT
    ].freeze

    BITS = {
      STRENGTH_128_BIT => 128,
      STRENGTH_192_BIT => 192,
      STRENGTH_256_BIT => 256
    }.freeze

    KEY_LENGTHS = {
      STRENGTH_128_BIT => 16,
      STRENGTH_192_BIT => 24,
      STRENGTH_256_BIT => 32
    }.freeze

    SALT_LENGTHS = {
      STRENGTH_128_BIT => 8,
      STRENGTH_192_BIT => 12,
      STRENGTH_256_BIT => 16
    }.freeze

    def initialize(password, strength)
      @password = password
      @strength = strength
      @bits = BITS[@strength]
      @key_length = KEY_LENGTHS[@strength]
      @salt_length = SALT_LENGTHS[@strength]
    end

    def header_bytesize
      @salt_length + VERIFIER_LENGTH
    end

    def gp_flags
      0x0001
    end
  end

  class AESDecrypter < Decrypter # :nodoc:
    include AESEncryption

    def decrypt(encrypted_data)
      @hmac.update(encrypted_data)

      idx = 0
      decrypted_data = +''
      amount_to_read = encrypted_data.size

      while amount_to_read.positive?
        @cipher.iv = [@counter + 1].pack('Vx12')
        begin_index = BLOCK_SIZE * idx
        end_index = begin_index + [BLOCK_SIZE, amount_to_read].min
        decrypted_data << @cipher.update(encrypted_data[begin_index...end_index])
        amount_to_read -= BLOCK_SIZE
        @counter += 1
        idx += 1
      end

      # JRuby requires finalization of the cipher. This is a bug, as noted in
      # jruby/jruby-openssl#182 and jruby/jruby-openssl#183.
      decrypted_data << @cipher.final if defined?(JRUBY_VERSION)
      decrypted_data
    end

    def reset!(header)
      raise Error, "Unsupported encryption AES-#{@bits}" unless STRENGTHS.include? @strength

      salt = header[0...@salt_length]
      pwd_verify = header[-VERIFIER_LENGTH..]
      key_material = OpenSSL::KDF.pbkdf2_hmac(
        @password,
        salt:       salt,
        iterations: 1000,
        length:     (2 * @key_length) + VERIFIER_LENGTH,
        hash:       'sha1'
      )
      enc_key = key_material[0...@key_length]
      enc_hmac_key = key_material[@key_length...(2 * @key_length)]
      enc_pwd_verify = key_material[-VERIFIER_LENGTH..]

      raise Error, 'Bad password' if enc_pwd_verify != pwd_verify

      @counter = 0
      @cipher = OpenSSL::Cipher::AES.new(@bits, :CTR)
      @cipher.decrypt
      @cipher.key = enc_key
      @hmac = OpenSSL::HMAC.new(enc_hmac_key, OpenSSL::Digest.new('SHA1'))
    end

    def check_integrity!(io)
      auth_code = io.read(AUTHENTICATION_CODE_LENGTH)
      raise Error, 'Integrity fault' if @hmac.digest[0...AUTHENTICATION_CODE_LENGTH] != auth_code
    end
  end
end
