require 'aws-sdk-s3/encryptionV3/client'
require 'aws-sdk-s3/encryptionV3/decryption'
require 'aws-sdk-s3/encryptionV3/decrypt_handler'
require 'aws-sdk-s3/encryptionV3/default_cipher_provider'
require 'aws-sdk-s3/encryptionV3/encrypt_handler'
require 'aws-sdk-s3/encryptionV3/errors'
require 'aws-sdk-s3/encryptionV3/io_encrypter'
require 'aws-sdk-s3/encryptionV3/io_decrypter'
require 'aws-sdk-s3/encryptionV3/io_auth_decrypter'
require 'aws-sdk-s3/encryptionV3/key_provider'
require 'aws-sdk-s3/encryptionV3/kms_cipher_provider'
require 'aws-sdk-s3/encryptionV3/materials'
require 'aws-sdk-s3/encryptionV3/utils'
require 'aws-sdk-s3/encryptionV3/default_key_provider'

module Aws
  module S3
    module EncryptionV3
      AES_GCM_TAG_LEN_BYTES = 16
      EC_USER_AGENT = 'S3CryptoV3'
    end
  end
end

