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

module HexaPDF
  module Utils

    # Implements encoding conversion functions for the PDFDocEncoding.
    #
    # The PDFDocEncoding is used, together with UTF-16BE, for strings outside content streams.
    # When a PDF file is loaded and a text string in a PDF object does not start with the UTF-16BE
    # BOM U+FEFF, it is automatically converted to UTF-8 on access.
    #
    # The same is done for text strings in UTF-16BE encoding. Therefore all text strings can be
    # assumed to be in UTF-8.
    #
    # When a PDF file is written, text strings are automatically encoded in either PDFDocEncoding
    # or UTF-16BE depending on the characters in the text string.
    #
    # See: PDF2.0 s7.9.2, D.1, D.3
    module PDFDocEncoding

      CHARACTER_MAP = %W[\uFFFD \uFFFD \uFFFD \uFFFD \uFFFD \uFFFD \uFFFD \uFFFD
                         \uFFFD \u0009 \u000A \uFFFD \uFFFD \u000D \uFFFD \uFFFD
                         \uFFFD \uFFFD \uFFFD \uFFFD \uFFFD \uFFFD \uFFFD \uFFFD
                         \u02D8 \u02C7 \u02C6 \u02D9 \u02DD \u02DB \u02DA \u02DC
                         \u0020 \u0021 \u0022 \u0023 \u0024 \u0025 \u0026 \u0027
                         \u0028 \u0029 \u002a \u002b \u002c \u002d \u002e \u002f
                         \u0030 \u0031 \u0032 \u0033 \u0034 \u0035 \u0036 \u0037
                         \u0038 \u0039 \u003a \u003b \u003c \u003d \u003e \u003f
                         \u0040 \u0041 \u0042 \u0043 \u0044 \u0045 \u0046 \u0047
                         \u0048 \u0049 \u004a \u004b \u004c \u004d \u004e \u004f
                         \u0050 \u0051 \u0052 \u0053 \u0054 \u0055 \u0056 \u0057
                         \u0058 \u0059 \u005a \u005b \u005c \u005d \u005e \u005f
                         \u0060 \u0061 \u0062 \u0063 \u0064 \u0065 \u0066 \u0067
                         \u0068 \u0069 \u006a \u006b \u006c \u006d \u006e \u006f
                         \u0070 \u0071 \u0072 \u0073 \u0074 \u0075 \u0076 \u0077
                         \u0078 \u0079 \u007a \u007b \u007c \u007d \u007e \uFFFD
                         \u2022 \u2020 \u2021 \u2026 \u2014 \u2013 \u0192 \u2044
                         \u2039 \u203a \u2212 \u2030 \u201e \u201c \u201d \u2018
                         \u2019 \u201a \u2122 \ufb01 \ufb02 \u0141 \u0152 \u0160
                         \u0178 \u017d \u0131 \u0142 \u0153 \u0161 \u017e \uFFFD
                         \u20ac \u00a1 \u00a2 \u00a3 \u00a4 \u00a5 \u00a6 \u00a7
                         \u00a8 \u00a9 \u00aa \u00ab \u00ac \uFFFD \u00ae \u00af
                         \u00b0 \u00b1 \u00b2 \u00b3 \u00b4 \u00b5 \u00b6 \u00b7
                         \u00b8 \u00b9 \u00ba \u00bb \u00bc \u00bd \u00be \u00bf
                         \u00c0 \u00c1 \u00c2 \u00c3 \u00c4 \u00c5 \u00c6 \u00c7
                         \u00c8 \u00c9 \u00ca \u00cb \u00cc \u00cd \u00ce \u00cf
                         \u00d0 \u00d1 \u00d2 \u00d3 \u00d4 \u00d5 \u00d6 \u00d7
                         \u00d8 \u00d9 \u00da \u00db \u00dc \u00dd \u00de \u00df
                         \u00e0 \u00e1 \u00e2 \u00e3 \u00e4 \u00e5 \u00e6 \u00e7
                         \u00e8 \u00e9 \u00ea \u00eb \u00ec \u00ed \u00ee \u00ef
                         \u00f0 \u00f1 \u00f2 \u00f3 \u00f4 \u00f5 \u00f6 \u00f7
                         \u00f8 \u00f9 \u00fa \u00fb \u00fc \u00fd \u00fe \u00ff].freeze

      # Converts the given string to UTF-8, assuming it contains bytes in PDFDocEncoding.
      def self.convert_to_utf8(str)
        str.each_byte.with_object(+'') {|byte, result| result << CHARACTER_MAP[byte] }
      end

    end
  end
end
