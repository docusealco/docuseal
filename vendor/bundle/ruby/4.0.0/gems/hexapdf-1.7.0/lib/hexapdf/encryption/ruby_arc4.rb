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

require 'hexapdf/encryption/arc4'

module HexaPDF
  module Encryption

    # Pure Ruby implementation of the general encryption algorithm ARC4.
    #
    # Since this algorithm is implemented in pure Ruby, it is not very fast. Therefore the
    # FastARC4 class based on OpenSSL should be used when possible.
    #
    # For reference: This implementation is about 250 times slower than the FastARC4 version.
    #
    # See: PDF2.0 s7.6.3
    class RubyARC4

      prepend ARC4

      # Creates a new ARC4 object using the given encryption key.
      def initialize(key)
        initialize_state(key)
        @i = @j = 0
      end

      # Processes the given data.
      #
      # Since this is a symmetric algorithm, the same method can be used for encryption and
      # decryption.
      def process(data)
        result = data.dup.force_encoding(Encoding::BINARY)
        di = 0
        while di < result.length
          @i = (@i + 1) % 256
          @j = (@j + @state[@i]) % 256
          @state[@i], @state[@j] = @state[@j], @state[@i]
          result.setbyte(di, result.getbyte(di) ^ @state[(@state[@i] + @state[@j]) % 256])
          di += 1
        end
        result
      end
      alias decrypt process
      alias encrypt process

      private

      # The initial state which is then modified by the key-scheduling algorithm
      INITIAL_STATE = (0..255).to_a

      # Performs the key-scheduling algorithm to initialize the state.
      def initialize_state(key)
        i = j = 0
        @state = INITIAL_STATE.dup
        key_length = key.length
        while i < 256
          j = (j + @state[i] + key.getbyte(i % key_length)) % 256
          @state[i], @state[j] = @state[j], @state[i]
          i += 1
        end
      end

    end

  end
end
