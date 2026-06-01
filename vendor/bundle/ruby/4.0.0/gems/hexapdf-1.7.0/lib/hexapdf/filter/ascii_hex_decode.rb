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
require 'hexapdf/tokenizer'
require 'hexapdf/error'

module HexaPDF
  module Filter

    # This filter module implements the ASCII hex decode/encode filter which can encode arbitrary
    # data into the two byte ASCII hex format that expands the original data by a factor of 1:2.
    #
    # See: HexaPDF::Filter, PDF2.0 s7.4.2
    module ASCIIHexDecode

      # See HexaPDF::Filter
      def self.decoder(source, _ = nil)
        Fiber.new do
          rest = nil
          finished = false

          while !finished && source.alive? && (data = source.resume)
            data.tr!(HexaPDF::Tokenizer::WHITESPACE, '')
            finished = true if data.gsub!(/>.*?\z/m, '')
            if data.index(/[^A-Fa-f0-9]/)
              raise FilterError, "Invalid characters in ASCII hex stream"
            end

            data = rest << data if rest
            rest = (data.size.odd? ? data.slice!(-1, 1) : nil)

            Fiber.yield([data].pack('H*'))
          end
          [rest].pack('H*') if rest
        end
      end

      # See HexaPDF::Filter
      def self.encoder(source, _ = nil)
        Fiber.new do
          while source.alive? && (data = source.resume)
            Fiber.yield(data.unpack1('H*').force_encoding(Encoding::BINARY))
          end
          '>'.b
        end
      end

    end

  end
end
