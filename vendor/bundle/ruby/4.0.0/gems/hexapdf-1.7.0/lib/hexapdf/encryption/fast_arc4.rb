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
require 'hexapdf/encryption/arc4'

module HexaPDF
  module Encryption

    begin
      OpenSSL::Cipher.new('rc4')

      # Implementation of the general encryption algorithm ARC4 using OpenSSL as backend.
      #
      # See: PDF2.0 s7.6.3
      class FastARC4

        prepend ARC4

        # Creates a new FastARC4 object using the given encryption key.
        def initialize(key)
          @cipher = OpenSSL::Cipher.new('rc4')
          @cipher.key_len = key.length
          @cipher.key = key
        end

        # Processes the given data.
        #
        # Since this is a symmetric algorithm, the same method can be used for encryption and
        # decryption.
        def process(data)
          @cipher.update(data)
        end
        alias decrypt process
        alias encrypt process

      end
    rescue OpenSSL::Cipher::CipherError
      # Ruby OpenSSL 3.0 needs a special configuration file that enables the legacy provider so that
      # RC4 works. This would need to be done by each user. So we need the fallback.
      require 'hexapdf/encryption/ruby_arc4'
      FastARC4 = RubyARC4
    end

  end
end
