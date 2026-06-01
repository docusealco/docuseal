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
require 'zlib'
require 'hexapdf/filter/predictor'
require 'hexapdf/configuration'
require 'hexapdf/error'

module HexaPDF
  module Filter

    # Implements the Deflate filter using the Zlib library.
    #
    # See: HexaPDF::Filter, PDF2.0 s7.4.4
    module FlateDecode

      # See HexaPDF::Filter
      #
      # The decoder also handles the case of an empty string not deflated to a correct flate stream
      # but just output as an empty string.
      def self.decoder(source, options = nil)
        fib = Fiber.new do
          inflater = Zlib::Inflate.new
          error_raised = nil

          while source.alive? && (data = source.resume)
            next if data.empty?
            begin
              Fiber.yield(inflater.inflate(data))
            rescue Zlib::DataError, Zlib::BufError => e
              # Only swallow the error if it appears at the end of the stream
              if error_raised || HexaPDF::GlobalConfiguration['filter.flate.on_error'].call(inflater, e)
                raise FilterError, "Problem while decoding Flate encoded stream: #{e}"
              else
                Fiber.yield(inflater.flush_next_out)
                error_raised = e
              end
            end
          end

          begin
            data = inflater.total_in == 0 || (data = inflater.finish).empty? ? nil : data
            inflater.close
            data
          rescue Zlib::DataError, Zlib::BufError => e
            if HexaPDF::GlobalConfiguration['filter.flate.on_error'].call(inflater, e)
              raise FilterError, "Problem while decoding Flate encoded stream: #{e}"
            else
              Fiber.yield(inflater.flush_next_out)
            end
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
          deflater = Zlib::Deflate.new(HexaPDF::GlobalConfiguration['filter.flate.compression'],
                                       Zlib::MAX_WBITS,
                                       HexaPDF::GlobalConfiguration['filter.flate.memory'])
          while source.alive? && (data = source.resume)
            data = deflater.deflate(data)
            Fiber.yield(data)
          end
          data = deflater.finish
          deflater.close
          data
        end
      end

    end

  end
end
