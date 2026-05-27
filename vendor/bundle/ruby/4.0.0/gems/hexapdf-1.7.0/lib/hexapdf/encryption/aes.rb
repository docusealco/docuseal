# -*- encoding: utf-8; frozen_string_literal: true -*-
#
#--
# This file is part of HexaPDF.
#
# HexaPDF - A Versatile PDF Creation and Manipulation Library For Ruby
# Copyright (C) 2014-2025 Thomas Leitner
#
# HexaPDF is free software: you can redistribute it and/or modify it
# under the terms of the GNU Affero General Public License version 3 as
# published by the Free Software Foundation with the addition of the
# following permission added to Section 15 as permitted in Section 7(a):
# FOR ANY PART OF THE COVERED WORK IN WHICH THE COPYRIGHT IS OWNED BY
# THOMAS LEITNER, THOMAS LEITNER DISCLAIMS THE WARRANTY OF NON
# INFRINGEMENT OF THIRD PARTY RIGHTS.
#
# HexaPDF is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public
# License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with HexaPDF. If not, see <http://www.gnu.org/licenses/>.
#
# The interactive user interfaces in modified source and object code
# versions of HexaPDF must display Appropriate Legal Notices, as required
# under Section 5 of the GNU Affero General Public License version 3.
#
# In accordance with Section 7(b) of the GNU Affero General Public
# License, a covered work must retain the producer line in every PDF that
# is created or manipulated using HexaPDF.
#
# If the GNU Affero General Public License doesn't fit your need,
# commercial licenses are available at <https://gettalong.at/hexapdf/>.
#++

require 'securerandom'
require 'hexapdf/error'

module HexaPDF
  module Encryption

    # Common interface for AES algorithms
    #
    # This module defines the common interface that is used by the security handlers to encrypt or
    # decrypt data with AES. It has to be *prepended* by any specific AES algorithm class.
    #
    # See the ClassMethods module for available class level methods of AES algorithms.
    #
    # == Implementing an AES Class
    #
    # An AES class needs to define at least the following methods:
    #
    # initialize(key, iv, mode)::
    #   Initializes the AES algorithm with the given key and initialization vector. The mode
    #   determines how the AES algorithm object works: If the mode is :encrypt, the object
    #   encrypts the data, if the mode is :decrypt, the object decrypts the data.
    #
    # process(data)::
    #   Processes the data and returns the encrypted/decrypted data. The method can assume that
    #   the passed in data always has a length that is a multiple of BLOCK_SIZE.
    module AES

      # Valid AES key lengths
      VALID_KEY_LENGTH = [16, 24, 32].freeze

      # The AES block size
      BLOCK_SIZE = 16

      # Convenience methods for decryption and encryption that operate according to the PDF
      # specification.
      #
      # These methods will be available on the class object that prepends the AES module.
      module ClassMethods

        # Encrypts the given +data+ using the +key+ and a randomly generated initialization
        # vector.
        #
        # The data is padded using the PKCS#5 padding scheme and the initialization vector is
        # prepended to the encrypted data,
        #
        # See: PDF2.0 s7.6.3
        def encrypt(key, data)
          iv = random_bytes(BLOCK_SIZE)
          iv << new(key, iv, :encrypt).process(pad(data))
        end

        # Returns a Fiber object that encrypts the data from the given source fiber with the
        # +key+.
        #
        # Padding and the initialization vector are handled like in #encrypt.
        def encryption_fiber(key, source)
          Fiber.new do
            data = random_bytes(BLOCK_SIZE)
            algorithm = new(key, data, :encrypt)
            Fiber.yield(data)

            data = ''.b
            while source.alive? && (new_data = source.resume)
              data << new_data
              next if data.length < BLOCK_SIZE
              new_data = data.slice!(0, data.length - data.length % BLOCK_SIZE)
              Fiber.yield(algorithm.process(new_data))
            end

            algorithm.process(pad(data))
          end
        end

        # Decrypts the given +data+ using the +key+.
        #
        # It is assumed that the initialization vector is included in the first BLOCK_SIZE bytes
        # of the data. After the decryption the PKCS#5 padding is removed.
        #
        # If a problem is encountered, an error message is yielded. If no block is given or if the
        # supplied block returns +true+, an error is raised.
        #
        # See: PDF2.0 s7.6.3
        def decrypt(key, data) # :yields: error_message
          return data if data.empty? # Handle invalid files with empty strings
          if data.length % BLOCK_SIZE != 0 || data.length < BLOCK_SIZE
            msg = "Invalid data for decryption, need 32 + 16*n bytes"
            (!block_given? || yield(msg)) && raise(HexaPDF::EncryptionError, msg)
          end
          iv = data.slice!(0, BLOCK_SIZE)
          # Handle invalid files with missing padding
          data.empty? ? data : unpad(new(key, iv, :decrypt).process(data))
        end

        # Returns a Fiber object that decrypts the data from the given source fiber with the
        # +key+.
        #
        # Padding, the initialization vector and an optionally given block are handled like in
        # #decrypt.
        def decryption_fiber(key, source) # :yields: error_message
          Fiber.new do
            data = ''.b
            while data.length < BLOCK_SIZE && source.alive? && (new_data = source.resume)
              data << new_data
            end
            next data if data.empty? # Handle invalid files with empty stream

            algorithm = new(key, data.slice!(0, BLOCK_SIZE), :decrypt)

            while source.alive? && (new_data = source.resume)
              data << new_data
              next if data.length < 2 * BLOCK_SIZE
              new_data = data.slice!(0, data.length - BLOCK_SIZE - data.length % BLOCK_SIZE)
              Fiber.yield(algorithm.process(new_data))
            end

            if data.length % BLOCK_SIZE != 0
              msg = "Invalid data for decryption, need 32 + 16*n bytes"
              (!block_given? || yield(msg)) && raise(HexaPDF::EncryptionError, msg)
            end
            if data.empty?
              data # Handle invalid files with missing padding
            else
              unpad(algorithm.process(data))
            end
          end
        end

        # Returns a string of n random bytes.
        #
        # The specific AES algorithm class can override this class method to provide another
        # method for generating random bytes.
        def random_bytes(n)
          SecureRandom.random_bytes(n)
        end

        private

        # Pads the data to a muliple of BLOCK_SIZE using the PKCS#5 padding scheme and returns the
        # result.
        #
        # See: PDF2.0 s7.6.3
        def pad(data)
          padding_length = BLOCK_SIZE - data.size % BLOCK_SIZE
          data + padding_length.chr * padding_length
        end

        # Removes the padding from the data according to the PKCS#5 padding scheme and returns the
        # result.
        #
        # In case the padding is not correct as per the specification, it is assumed that there is
        # no padding and the input is returned as is.
        #
        # See: PDF2.0 s7.6.3
        def unpad(data)
          padding_length = data.getbyte(-1)
          if padding_length > BLOCK_SIZE || padding_length == 0 ||
              data[-padding_length, padding_length].each_byte.any? {|byte| byte != padding_length }
            data
          else
            data[0...-padding_length]
          end
        end

      end

      # Automatically extends the klass with the necessary class level methods.
      def self.prepended(klass) # :nodoc:
        klass.extend(ClassMethods)
      end

      # Creates a new AES object using the given encryption key and initialization vector.
      #
      # The mode must either be :encrypt or :decrypt.
      #
      # Classes prepending this module have to have their own initialization method as this method
      # just performs basic checks.
      def initialize(key, iv, mode)
        unless VALID_KEY_LENGTH.include?(key.length)
          raise HexaPDF::EncryptionError, "AES key length must be 128, 192 or 256 bit"
        end
        unless iv.length == BLOCK_SIZE
          raise HexaPDF::EncryptionError, "AES initialization vector length must be 128 bit"
        end
        mode = mode.intern
        super
      end

    end

  end
end
