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
require 'hexapdf/error'
require 'hexapdf/configuration'
require 'hexapdf/utils/bit_stream'

module HexaPDF
  module Filter

    # Implements the predictor for the LZWDecode and FlateDecode filters.
    #
    # Although a predictor isn't a full PDF filter, it is implemented as one in HexaPDF terms to
    # allow easy chaining of the predictor.
    #
    # See: PDF2.0 s7.4.4.3, s7.4.4.4, https://partners.adobe.com/public/developer/en/tiff/TIFF6.pdf
    # (p64f), http://www.w3.org/TR/PNG-Filters.html
    #
    #-- Implemenation notes:
    #
    # The TIFF encoding and decoding methods are the same, except for the innermost loop. The way
    # it is implemented is probably not the best but it avoids duplicate code.
    #
    # The situation is similar with PNG encoding and decoding.
    #++
    module Predictor

      PREDICTOR_PNG_NONE = 0    #:nodoc:
      PREDICTOR_PNG_SUB = 1     #:nodoc:
      PREDICTOR_PNG_UP = 2      #:nodoc:
      PREDICTOR_PNG_AVERAGE = 3 #:nodoc:
      PREDICTOR_PNG_PAETH = 4   #:nodoc:
      PREDICTOR_PNG_OPTIMUM = 5 #:nodoc:

      # See HexaPDF::Filter
      def self.decoder(source, options)
        execute(:decoder, source, options)
      end

      # See HexaPDF::Filter
      def self.encoder(source, options)
        execute(:encoder, source, options)
      end

      def self.execute(type, source, options) # :nodoc:
        return source if !options[:Predictor] || options[:Predictor] == 1

        colors = options[:Colors] || 1
        bits_per_component = options[:BitsPerComponent] || 8
        columns = options[:Columns] || 1

        if options[:Predictor] == 2
          tiff_execute(type, source, colors, bits_per_component, columns)
        elsif options[:Predictor] >= 10
          png_execute(type, source, options[:Predictor], colors, bits_per_component, columns)
        else
          raise HexaPDF::InvalidPDFObjectError, "Predictor key is invalid: #{options[:Predictor]}"
        end
      end

      def self.tiff_execute(type, source, colors, bits_per_component, columns) # :nodoc:
        Fiber.new do
          bytes_per_row = (columns * bits_per_component * colors + 7) / 8
          mask = (1 << bits_per_component) - 1

          data = ''.b
          writer = HexaPDF::Utils::BitStreamWriter.new
          pos = 0

          decode_row = lambda do |result, reader|
            last_components = [0] * colors
            (columns * colors).times do |i|
              i %= colors
              tmp = (reader.read(bits_per_component) + last_components[i]) & mask
              result << writer.write(tmp, bits_per_component)
              last_components[i] = tmp
            end
            result << writer.finalize
          end

          encode_row = lambda do |result, reader|
            last_components = [0] * colors
            (columns * colors).times do |i|
              i %= colors
              tmp = reader.read(bits_per_component)
              result << writer.write((tmp - last_components[i]) & mask, bits_per_component)
              last_components[i] = tmp
            end
            result << writer.finalize
          end

          row_action = (type == :decoder ? decode_row : encode_row)

          while source.alive? && (new_data = source.resume)
            data.slice!(0...pos)
            data << new_data

            result = ''.b
            pos = 0

            while pos + bytes_per_row <= data.length
              reader = HexaPDF::Utils::BitStreamReader.new(data[pos, bytes_per_row])
              row_action.call(result, reader)
              pos += bytes_per_row
            end

            Fiber.yield(result) unless result.empty?
          end

          unless pos == data.length
            raise FilterError, "Data is missing for TIFF predictor"
          end
        end
      end

      def self.png_execute(type, source, predictor, colors, bits_per_component, columns) # :nodoc:
        Fiber.new do
          bytes_per_pixel = (bits_per_component * colors + 7) / 8
          bytes_per_row = (columns * bits_per_component * colors + 7) / 8
          bytes_per_row += 1 if type == :decoder

          # Only on encoding: Arbitrarily choose a predictor if we should choose the optimum
          predictor = predictor == 15 ? PREDICTOR_PNG_PAETH : predictor - 10

          data = ''.b
          last_line = "\0".b * (bytes_per_row + 1)
          pos = 0

          decode_row = lambda do |result|
            line = data[pos + 1, bytes_per_row - 1]

            case data.getbyte(pos)
            when PREDICTOR_PNG_SUB
              bytes_per_pixel.upto(bytes_per_row - 2) do |i|
                line.setbyte(i, (line.getbyte(i) + line.getbyte(i - bytes_per_pixel)) % 256)
              end
            when PREDICTOR_PNG_UP
              0.upto(bytes_per_row - 2) do |i|
                line.setbyte(i, (line.getbyte(i) + last_line.getbyte(i)) % 256)
              end
            when PREDICTOR_PNG_AVERAGE
              0.upto(bytes_per_row - 2) do |i|
                a = i < bytes_per_pixel ? 0 : line.getbyte(i - bytes_per_pixel)
                line.setbyte(i, (line.getbyte(i) + ((a + last_line.getbyte(i)) >> 1)) % 256)
              end
            when PREDICTOR_PNG_PAETH
              0.upto(bytes_per_row - 2) do |i|
                a = i < bytes_per_pixel ? 0 : line.getbyte(i - bytes_per_pixel)
                b = last_line.getbyte(i)
                c = i < bytes_per_pixel ? 0 : last_line.getbyte(i - bytes_per_pixel)

                point = a + b - c
                pa = (point - a).abs
                pb = (point - b).abs
                pc = (point - c).abs

                point = ((pa <= pb && pa <= pc) ? a : (pb <= pc ? b : c))

                line.setbyte(i, (line.getbyte(i) + point) % 256)
              end
            end

            result << line
            last_line = line
          end

          encode_row = lambda do |result|
            line = predictor.chr.force_encoding(Encoding::BINARY) << data[pos, bytes_per_row]
            next_last_line = line.dup

            case predictor
            when PREDICTOR_PNG_SUB
              bytes_per_row.downto(bytes_per_pixel + 1) do |i|
                line.setbyte(i, (line.getbyte(i) - line.getbyte(i - bytes_per_pixel)) % 256)
              end
            when PREDICTOR_PNG_UP
              bytes_per_row.downto(1) do |i|
                line.setbyte(i, (line.getbyte(i) - last_line.getbyte(i)) % 256)
              end
            when PREDICTOR_PNG_AVERAGE
              bytes_per_row.downto(1) do |i|
                a = i <= bytes_per_pixel ? 0 : line.getbyte(i - bytes_per_pixel)
                line.setbyte(i, (line.getbyte(i) - ((a + last_line.getbyte(i)) >> 1)) % 256)
              end
            when PREDICTOR_PNG_PAETH
              bytes_per_row.downto(1) do |i|
                a = i <= bytes_per_pixel ? 0 : line.getbyte(i - bytes_per_pixel)
                b = last_line.getbyte(i)
                c = i <= bytes_per_pixel ? 0 : last_line.getbyte(i - bytes_per_pixel)

                point = a + b - c
                pa = (point - a).abs
                pb = (point - b).abs
                pc = (point - c).abs

                point = ((pa <= pb && pa <= pc) ? a : (pb <= pc ? b : c))

                line.setbyte(i, (line.getbyte(i) - point) % 256)
              end
            end

            result << line
            last_line = next_last_line
          end

          row_action = (type == :decoder ? decode_row : encode_row)

          while source.alive? && (new_data = source.resume)
            data.slice!(0...pos)
            data << new_data

            result = ''.b
            pos = 0

            while pos + bytes_per_row <= data.length
              row_action.call(result)
              pos += bytes_per_row
            end

            Fiber.yield(result) unless result.empty?
          end

          if pos != data.length && GlobalConfiguration['filter.predictor.strict']
            raise FilterError, "Data is missing for PNG predictor"
          elsif pos != data.length && data.length != 1
            result = ''.b
            bytes_per_row = data.length - pos
            row_action.call(result)
            result
          end
        end
      end

    end

  end
end
