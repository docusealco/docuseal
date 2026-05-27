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
require 'brotli'
require 'hexapdf/filter/predictor'
require 'hexapdf/configuration'

module HexaPDF
  module Filter

    # Implements the Brotli filter using the brotli library which must be installed manually.
    #
    # The BrotliDecode specification is not yet available as a standard but will be in the near
    # future. Therefore it is recommended to wait using it for encoding streams until most of the
    # PDF ecosystem has support for it.
    #
    # See: HexaPDF::Filter
    module BrotliDecode

      # See HexaPDF::Filter
      #
      # Note that the brotli gem currently doesn't support a streaming decoder. This means that the
      # whole source must be read and decoded at once.
      def self.decoder(source, options = nil)
        fib = Fiber.new do
          data = Filter.string_from_source(source)
          data.empty? ? data: Brotli.inflate(data)
        end

        if options && options[:Predictor]
          Predictor.decoder(fib, options)
        else
          fib
        end
      end

      # See HexaPDF::Filter
      #
      # As with ::decoder a usable streaming encoder is not available.
      def self.encoder(source, options = nil)
        if options && options[:Predictor]
          source = Predictor.encoder(source, options)
        end

        Fiber.new do
          Brotli.deflate(Filter.string_from_source(source),
                         quality: HexaPDF::GlobalConfiguration['filter.brotli.compression'])
        end
      end

    end

  end
end
