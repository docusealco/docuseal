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

require 'hexapdf/error'

module HexaPDF
  module Utils

    # Helper class for reading variable length integers from a bit stream.
    #
    # This class allows one to read integers with a variable width from a bit stream using the #read
    # method. The data from where these bits are read, can be set on intialization and additional
    # data can later be appended.
    class BitStreamReader

      # Creates a new object, optionally providing the string from where the bits should be read.
      def initialize(data = +'')
        @data = data.force_encoding(Encoding::BINARY)
        @pos = 0
        @bit_cache = 0
        @available_bits = 0
      end

      # Appends some data to the string from where bits are read.
      def append_data(str)
        @data.slice!(0, @pos)
        @data << str
        @pos = 0
        self
      end
      alias << append_data

      # Returns the number of remaining bits that can be read.
      def remaining_bits
        (@data.length - @pos) * 8 + @available_bits
      end

      # Returns +true+ if +bits+ number of bits can be read.
      def read?(bits)
        remaining_bits >= bits
      end

      # Reads +bits+ number of bits.
      #
      # Returns +nil+ if not enough bits are available for reading.
      def read(bits)
        while @available_bits < bits
          @bit_cache = (@bit_cache << 8) | (@data.getbyte(@pos) || return)
          @pos += 1
          @available_bits += 8
        end
        @available_bits -= bits
        result = (@bit_cache >> @available_bits)
        @bit_cache &= (1 << @available_bits) - 1
        result
      end

    end

    # Helper class for writing out variable length integers one after another as bit stream.
    #
    # This class allows one to write integers with a variable width of up to 16 bit to a bit
    # stream using the #write method. Every time when at least 16 bits are available, the #write
    # method returns those 16 bits as string and removes them from the internal cache.
    #
    # Once all data has been written, the #finalize method must be called to get the last
    # remaining bits (again as a string).
    class BitStreamWriter

      def initialize # :nodoc:
        @bit_cache = 0
        @available_bits = 0
      end

      # Writes the integer +int+ with a width of +bits+ to the bit stream.
      #
      # Returns a 16bit binary string if enough bits are available or an empty binary string
      # otherwise.
      def write(int, bits)
        @available_bits += bits
        @bit_cache |= int << (32 - @available_bits)
        if @available_bits >= 16
          @available_bits -= 16
          result = (@bit_cache >> 24).chr << ((@bit_cache >> 16) & 0xFF).chr
          @bit_cache = (@bit_cache & 0xFFFF) << 16
          result
        else
          ''.b
        end
      end

      # Retrieves the final (zero padded) bits as a string.
      def finalize
        result = [@bit_cache].pack('N')[0...(@available_bits / 8.0).ceil]
        initialize
        result
      end

    end

  end
end
