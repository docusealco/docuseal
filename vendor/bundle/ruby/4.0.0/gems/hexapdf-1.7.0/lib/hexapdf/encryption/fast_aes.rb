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

require 'openssl'
require 'hexapdf/error'
require 'hexapdf/encryption/aes'

module HexaPDF
  module Encryption

    # Implementation of the general encryption algorithm AES using OpenSSL as backend.
    #
    # Since OpenSSL is a native Ruby extension (that comes bundled with Ruby) it is much faster
    # than the pure Ruby version and it can use the AES-NI instruction set on CPUs when available.
    #
    # This implementation is using AES in Cipher Block Chaining (CBC) mode.
    #
    # See: PDF2.0 s7.6.3
    class FastAES

      prepend AES

      # Uses OpenSSL to generate the requested random bytes.
      #
      # See AES::ClassMethods#random_bytes for more information.
      def self.random_bytes(n)
        OpenSSL::Random.random_bytes(n)
      end

      # Creates a new FastAES object using the given encryption key and initialization vector.
      #
      # The mode must either be :encrypt or :decrypt.
      def initialize(key, iv, mode)
        @cipher = OpenSSL::Cipher.new("AES-#{key.length << 3}-CBC")
        @cipher.send(mode)
        @cipher.key = key
        @cipher.iv = iv
        @cipher.padding = 0 # Padding handled by HexaPDF, also no @cipher.final call needed
      end

      # Encrypts or decrypts the given data whose length must be a multiple of 16.
      def process(data)
        @cipher.update(data)
      end

    end

  end
end
