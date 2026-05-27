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

require 'hexapdf/font/true_type/builder'

module HexaPDF
  module Font
    module TrueType

      # Provides methods for optimizing a TrueType font file in various ways.
      module Optimizer

        # Returns for the given font a TrueType font file as binary string that is optimized for use
        # in a PDF (i.e. only the essential tables are retained).
        def self.build_for_pdf(font)
          tables = {
            'head' => font[:head].raw_data,
            'hhea' => font[:hhea].raw_data,
            'maxp' => font[:maxp].raw_data,
            'glyf' => font[:glyf].raw_data,
            'loca' => font[:loca].raw_data,
            'hmtx' => font[:hmtx].raw_data,
          }
          tables['cmap'] = font[:cmap].raw_data if font[:cmap]
          tables['cvt '] = font[:'cvt '].raw_data if font[:'cvt ']
          tables['fpgm'] = font[:fpgm].raw_data if font[:fpgm]
          tables['prep'] = font[:prep].raw_data if font[:prep]
          Builder.build(tables)
        end

      end

    end
  end
end
