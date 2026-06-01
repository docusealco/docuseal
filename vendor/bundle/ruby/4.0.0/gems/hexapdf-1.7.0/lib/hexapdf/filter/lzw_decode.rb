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
require 'hexapdf/utils/bit_stream'
require 'hexapdf/filter/predictor'
require 'hexapdf/error'

module HexaPDF
  module Filter

    # Implements the LZW filter.
    #
    # Since LZW uses a tightly packed bit stream in which codes are of varying bit lengths and are
    # not aligned to byte boundaries, this filter is not as fast as the other filters. If speed is
    # a concern, the FlateDecode filter should be used instead.
    #
    # See: HexaPDF::Filter, PDF2.0 s7.4.4
    module LZWDecode

      CLEAR_TABLE = 256 # :nodoc:
      EOD = 257 # :nodoc:

      INITIAL_ENCODER_TABLE = {} #:nodoc:
      0.upto(255) {|i| INITIAL_ENCODER_TABLE[i.chr.freeze] = i }
      INITIAL_ENCODER_TABLE[CLEAR_TABLE] = CLEAR_TABLE
      INITIAL_ENCODER_TABLE[EOD] = EOD

      INITIAL_DECODER_TABLE = {} #:nodoc:
      0.upto(255) {|i| INITIAL_DECODER_TABLE[i] = i.chr }
      INITIAL_DECODER_TABLE[CLEAR_TABLE] = CLEAR_TABLE
      INITIAL_DECODER_TABLE[EOD] = EOD

      # See HexaPDF::Filter
      def self.decoder(source, options = nil)
        fib = Fiber.new do
          # initialize decoder state
          code_length = 9
          table = INITIAL_DECODER_TABLE.dup

          stream = HexaPDF::Utils::BitStreamReader.new
          result = ''.b
          finished = false
          last_code = CLEAR_TABLE

          while !finished && source.alive? && (data = source.resume)
            stream.append_data(data)

            while (code = stream.read(code_length))

              # Decoder is one step behind => subtract 1!
              # We check the table size before entering the next code into it => subtract 1, but
              # there is one exception: After table entry 4095 is written, the clear table code
              # also gets written with code length 12,
              case table.size
              when 510, 1022, 2046
                code_length += 1
              when 4096
                if code != CLEAR_TABLE
                  raise FilterError, "Maximum of 12bit for codes in LZW stream exceeded"
                end
              end

              if code == EOD
                finished = true
                break
              elsif code == CLEAR_TABLE
                # reset decoder state
                code_length = 9
                table = INITIAL_DECODER_TABLE.dup
              elsif last_code == CLEAR_TABLE
                unless table.key?(code)
                  raise FilterError, "Unknown code in LZW encoded stream found"
                end
                result << table[code]
              else
                unless table.key?(last_code)
                  raise FilterError, "Unknown code in LZW encoded stream found"
                end
                last_str = table[last_code]

                str = if table.key?(code)
                        table[code]
                      else
                        last_str + last_str[0]
                      end
                result << str
                table[table.size] = last_str + str[0]
              end

              last_code = code
            end

            Fiber.yield(result)
            result = ''.b
          end
        end

        if options && options[:Predictor]
          Predictor.decoder(fib, options)
        else
          fib
        end
      end

      # See HexaPDF::Filter
      def self.encoder(source, options = nil)
        if options && options[:Predictor]
          source = Predictor.encoder(source, options)
        end

        Fiber.new do
          # initialize encoder state
          code_length = 9
          table = INITIAL_ENCODER_TABLE.dup

          # initialize the bit stream with the clear-table marker
          stream = HexaPDF::Utils::BitStreamWriter.new
          result = stream.write(CLEAR_TABLE, 9)
          str = ''.b

          while source.alive? && (data = source.resume)
            data.each_char do |char|
              newstr = str + char
              if table.key?(newstr)
                str = newstr
              else
                result << stream.write(table[str], code_length)
                table[newstr.freeze] = table.size
                str = char
              end

              case table.size
              when 512 then code_length = 10
              when 1024 then code_length = 11
              when 2048 then code_length = 12
              when 4096
                result << stream.write(CLEAR_TABLE, code_length)
                # reset encoder state
                code_length = 9
                table = INITIAL_ENCODER_TABLE.dup
              end
            end

            Fiber.yield(result)
            result = ''.b
          end

          result = stream.write(table[str], code_length)
          result << stream.write(EOD, code_length)
          result << stream.finalize

          result
        end
      end

    end

  end
end
