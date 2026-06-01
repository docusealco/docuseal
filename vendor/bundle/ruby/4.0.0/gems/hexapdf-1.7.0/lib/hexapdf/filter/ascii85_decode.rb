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

require 'fiber'
require 'strscan'
require 'hexapdf/tokenizer'
require 'hexapdf/error'

module HexaPDF
  module Filter

    # This filter module implements the ASCII-85 filter which can encode arbitrary data into an
    # ASCII compatible format that expands the original data only by a factor of 4:5.
    #
    # See: HexaPDF::Filter, PDF2.0 s7.4.2
    module ASCII85Decode

      VALUE_TO_CHAR = {} #:nodoc:
      85.times do |i|
        VALUE_TO_CHAR[i] = (i + 33).chr
      end

      POW85_1 = 85    #:nodoc:
      POW85_2 = 85**2 #:nodoc:
      POW85_3 = 85**3 #:nodoc:
      POW85_4 = 85**4 #:nodoc:

      MAX_VALUE = 0xffffffff #:nodoc:
      FIXED_SUBTRAHEND = 33 * (POW85_4 + POW85_3 + POW85_2 + POW85_1 + 1) #:nodoc:

      # See HexaPDF::Filter
      def self.decoder(source, _ = nil)
        Fiber.new do
          rest = nil
          finished = false

          while !finished && source.alive? && (data = source.resume)
            data.tr!(HexaPDF::Tokenizer::WHITESPACE, '')
            if data.index(/[^!-uz~]/)
              raise FilterError, "Invalid characters in ASCII85 stream"
            end

            if rest
              data = rest << data
              rest = nil
            end

            result = []
            scanner = StringScanner.new(data)
            until scanner.eos?
              if (m = scanner.scan(/[!-u]{5}/))
                num = (m.getbyte(0) * POW85_4 + m.getbyte(1) * POW85_3 +
                  m.getbyte(2) * POW85_2 + m.getbyte(3) * POW85_1 +
                  m.getbyte(4)) - FIXED_SUBTRAHEND
                if num > MAX_VALUE
                  raise FilterError, "Value outside range in ASCII85 stream"
                end
                result << num
              elsif scanner.scan(/z/)
                result << 0
              elsif scanner.scan(/([!-u]{0,4})~>/)
                rest = scanner[1] unless scanner[1].empty?
                finished = true
                break
              else
                rest = scanner.scan(/.+/)
              end
            end
            Fiber.yield(result.pack('N*')) unless result.empty?
          end

          if rest
            if rest.index('z') || rest.index('~')
              raise FilterError, "End of ASCII85 encoded stream is invalid"
            end

            rlen = rest.length
            rest << "u" * (5 - rlen)
            num = (rest.getbyte(0) * POW85_4 + rest.getbyte(1) * POW85_3 +
              rest.getbyte(2) * POW85_2 + rest.getbyte(3) * POW85_1 +
              rest.getbyte(4)) - FIXED_SUBTRAHEND
            if num > MAX_VALUE
              raise FilterError, "Value outside base-85 range in ASCII85 stream"
            end
            [num].pack('N')[0, rlen - 1]
          end
        end
      end

      # See HexaPDF::Filter
      def self.encoder(source, _ = nil)
        Fiber.new do
          rest = nil

          while source.alive? && (data = source.resume)
            data = rest << data if rest

            rlen = data.length % 4
            rest = (rlen != 0 ? data.slice!(-rlen, rlen) : nil)
            next if data.length < 4

            data = data.unpack('N*').inject(''.b) do |memo, num|
              memo << if num == 0
                        'z'
                      else
                        VALUE_TO_CHAR[num / POW85_4 % 85] + VALUE_TO_CHAR[num / POW85_3 % 85] <<
                          VALUE_TO_CHAR[num / POW85_2 % 85] << VALUE_TO_CHAR[num / POW85_1 % 85] <<
                          VALUE_TO_CHAR[num % 85]
                      end
            end

            Fiber.yield(data)
          end

          if rest
            rlen = rest.length
            num = (rest + "\0" * (4 - rlen)).unpack1('N')
            ((VALUE_TO_CHAR[num / POW85_4 % 85] + VALUE_TO_CHAR[num / POW85_3 % 85] <<
              VALUE_TO_CHAR[num / POW85_2 % 85] << VALUE_TO_CHAR[num / POW85_1 % 85] <<
              VALUE_TO_CHAR[num % 85])[0, rlen + 1] << "~>").force_encoding(Encoding::BINARY)
          else
            "~>".b
          end
        end
      end

    end

  end
end
